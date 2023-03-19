use strict;
use warnings;
use Class::Struct;
use XML::LibXML;
use File::Basename;
use File::Path;
use File::stat;
use File::Copy;
use File::Copy::Recursive qw(rcopy pathrm);
use File::Slurp;
use File::Temp;
use JSON;
use File::Find;
require List::Compare;
use POSIX;
use Cwd;

# system.build.toplevel path
my $defaultConfig = $ARGV[1] or die;

# Grub config XML generated by grubConfig function in grub.nix
my $dom = XML::LibXML->load_xml(location => $ARGV[0]);

sub get { my ($name) = @_; return $dom->findvalue("/expr/attrs/attr[\@name = '$name']/*/\@value"); }

sub getList {
    my ($name) = @_;
    my @list = ();
    foreach my $entry ($dom->findnodes("/expr/attrs/attr[\@name = '$name']/list/string/\@value")) {
        $entry = $entry->findvalue(".") or die;
        push(@list, $entry);
    }
    return @list;
}

sub readFile {
    my ($fn) = @_; local $/ = undef;
    open FILE, "<$fn" or return undef; my $s = <FILE>; close FILE;
    local $/ = "\n"; chomp $s; return $s;
}

sub writeFile {
    my ($fn, $s) = @_;
    open FILE, ">$fn" or die "cannot create $fn: $!\n";
    print FILE $s or die;
    close FILE or die;
}

sub runCommand {
    my ($cmd) = @_;
    open FILE, "$cmd 2>/dev/null |" or die "Failed to execute: $cmd\n";
    my @ret = <FILE>;
    close FILE;
    return ($?, @ret);
}

my $grub = get("grub");
my $grubVersion = int(get("version"));
my $grubTarget = get("grubTarget");
my $extraConfig = get("extraConfig");
my $extraPrepareConfig = get("extraPrepareConfig");
my $extraPerEntryConfig = get("extraPerEntryConfig");
my $extraEntries = get("extraEntries");
my $extraEntriesBeforeNixOS = get("extraEntriesBeforeNixOS") eq "true";
my $splashImage = get("splashImage");
my $splashMode = get("splashMode");
my $entryOptions = get("entryOptions");
my $subEntryOptions = get("subEntryOptions");
my $backgroundColor = get("backgroundColor");
my $configurationLimit = int(get("configurationLimit"));
my $copyKernels = get("copyKernels") eq "true";
my $timeout = int(get("timeout"));
my $defaultEntry = get("default");
my $fsIdentifier = get("fsIdentifier");
my $grubEfi = get("grubEfi");
my $grubTargetEfi = get("grubTargetEfi");
my $bootPath = get("bootPath");
my $storePath = get("storePath");
my $canTouchEfiVariables = get("canTouchEfiVariables");
my $efiInstallAsRemovable = get("efiInstallAsRemovable");
my $efiSysMountPoint = get("efiSysMountPoint");
my $gfxmodeEfi = get("gfxmodeEfi");
my $gfxmodeBios = get("gfxmodeBios");
my $gfxpayloadEfi = get("gfxpayloadEfi");
my $gfxpayloadBios = get("gfxpayloadBios");
my $bootloaderId = get("bootloaderId");
my $forceInstall = get("forceInstall");
my $font = get("font");
my $theme = get("theme");
my $saveDefault = $defaultEntry eq "saved";
$ENV{'PATH'} = get("path");

die "unsupported GRUB version\n" if $grubVersion != 1 && $grubVersion != 2;

print STDERR "updating GRUB $grubVersion menu...\n";

mkpath("$bootPath/grub", 0, 0700);

# Discover whether the bootPath is on the same filesystem as / and
# /nix/store.  If not, then all kernels and initrds must be copied to
# the bootPath.
if (stat($bootPath)->dev != stat("/nix/store")->dev) {
    $copyKernels = 1;
}

# Discover information about the location of the bootPath
struct(Fs => {
    device => '$',
    type => '$',
    mount => '$',
});
sub PathInMount {
    my ($path, $mount) = @_;
    my @splitMount = split /\//, $mount;
    my @splitPath = split /\//, $path;
    if ($#splitPath < $#splitMount) {
        return 0;
    }
    for (my $i = 0; $i <= $#splitMount; $i++) {
        if ($splitMount[$i] ne $splitPath[$i]) {
            return 0;
        }
    }
    return 1;
}

# Figure out what filesystem is used for the directory with init/initrd/kernel files
sub GetFs {
    my ($dir) = @_;
    my $bestFs = Fs->new(device => "", type => "", mount => "");
    foreach my $fs (read_file("/proc/self/mountinfo")) {
        chomp $fs;
        my @fields = split / /, $fs;
        my $mountPoint = $fields[4];
        next unless -d $mountPoint;
        my @mountOptions = split /,/, $fields[5];

        # Skip the optional fields.
        my $n = 6; $n++ while $fields[$n] ne "-"; $n++;
        my $fsType = $fields[$n];
        my $device = $fields[$n + 1];
        my @superOptions = split /,/, $fields[$n + 2];

        # Skip the bind-mount on /nix/store.
        next if $mountPoint eq "/nix/store" && (grep { $_ eq "rw" } @superOptions);
        # Skip mount point generated by systemd-efi-boot-generator?
        next if $fsType eq "autofs";

        # Ensure this matches the intended directory
        next unless PathInMount($dir, $mountPoint);

        # Is it better than our current match?
        if (length($mountPoint) > length($bestFs->mount)) {
            $bestFs = Fs->new(device => $device, type => $fsType, mount => $mountPoint);
        }
    }
    return $bestFs;
}
struct (Grub => {
    path => '$',
    search => '$',
});
my $driveid = 1;
sub GrubFs {
    my ($dir) = @_;
    my $fs = GetFs($dir);
    my $path = substr($dir, length($fs->mount));
    if (substr($path, 0, 1) ne "/") {
        $path = "/$path";
    }
    my $search = "";

    if ($grubVersion > 1) {
        # ZFS is completely separate logic as zpools are always identified by a label
        # or custom UUID
        if ($fs->type eq 'zfs') {
            my $sid = index($fs->device, '/');

            if ($sid < 0) {
                $search = '--label ' . $fs->device;
                $path = '/@' . $path;
            } else {
                $search = '--label ' . substr($fs->device, 0, $sid);
                $path = '/' . substr($fs->device, $sid) . '/@' . $path;
            }
        } else {
            my %types = ('uuid' => '--fs-uuid', 'label' => '--label');

            if ($fsIdentifier eq 'provided') {
                # If the provided dev is identifying the partition using a label or uuid,
                # we should get the label / uuid and do a proper search
                my @matches = $fs->device =~ m/\/dev\/disk\/by-(label|uuid)\/(.*)/;
                if ($#matches > 1) {
                    die "Too many matched devices"
                } elsif ($#matches == 1) {
                    $search = "$types{$matches[0]} $matches[1]"
                }
            } else {
                # Determine the identifying type
                $search = $types{$fsIdentifier} . ' ';

                # Based on the type pull in the identifier from the system
                my ($status, @devInfo) = runCommand("@utillinux@/bin/blkid -o export @{[$fs->device]}");
                if ($status != 0) {
                    die "Failed to get blkid info (returned $status) for @{[$fs->mount]} on @{[$fs->device]}";
                }
                my @matches = join("", @devInfo) =~ m/@{[uc $fsIdentifier]}=([^\n]*)/;
                if ($#matches != 0) {
                    die "Couldn't find a $types{$fsIdentifier} for @{[$fs->device]}\n"
                }
                $search .= $matches[0];
            }

            # BTRFS is a special case in that we need to fix the referrenced path based on subvolumes
            if ($fs->type eq 'btrfs') {
                my ($status, @id_info) = runCommand("@btrfsprogs@/bin/btrfs subvol show @{[$fs->mount]}");
                if ($status != 0) {
                    die "Failed to retrieve subvolume info for @{[$fs->mount]}\n";
                }
                my @ids = join("\n", @id_info) =~ m/^(?!\/\n).*Subvolume ID:[ \t\n]*([0-9]+)/s;
                if ($#ids > 0) {
                    die "Btrfs subvol name for @{[$fs->device]} listed multiple times in mount\n"
                } elsif ($#ids == 0) {
                    my ($status, @path_info) = runCommand("@btrfsprogs@/bin/btrfs subvol list @{[$fs->mount]}");
                    if ($status != 0) {
                        die "Failed to find @{[$fs->mount]} subvolume id from btrfs\n";
                    }
                    my @paths = join("", @path_info) =~ m/ID $ids[0] [^\n]* path ([^\n]*)/;
                    if ($#paths > 0) {
                        die "Btrfs returned multiple paths for a single subvolume id, mountpoint @{[$fs->mount]}\n";
                    } elsif ($#paths != 0) {
                        die "Btrfs did not return a path for the subvolume at @{[$fs->mount]}\n";
                    }
                    $path = "/$paths[0]$path";
                }
            }
        }
        if (not $search eq "") {
            $search = "search --set=drive$driveid " . $search;
            $path = "(\$drive$driveid)$path";
            $driveid += 1;
        }
    }
    return Grub->new(path => $path, search => $search);
}
my $grubBoot = GrubFs($bootPath);
my $grubStore;
if ($copyKernels == 0) {
    $grubStore = GrubFs($storePath);
}

# Generate the header.
my $conf .= "# Automatically generated.  DO NOT EDIT THIS FILE!\n";

if ($grubVersion == 1) {
    # $defaultEntry might be "saved", indicating that we want to use the last selected configuration as default.
    # Incidentally this is already the correct value for the grub 1 config to achieve this behaviour.
    $conf .= "
        default $defaultEntry
        timeout $timeout
    ";
    if ($splashImage) {
        copy $splashImage, "$bootPath/background.xpm.gz" or die "cannot copy $splashImage to $bootPath: $!\n";
        $conf .= "splashimage " . ($grubBoot->path eq "/" ? "" : $grubBoot->path) . "/background.xpm.gz\n";
    }
}

else {
    my @users = ();
    foreach my $user ($dom->findnodes('/expr/attrs/attr[@name = "users"]/attrs/attr')) {
        my $name = $user->findvalue('@name') or die;
        my $hashedPassword = $user->findvalue('./attrs/attr[@name = "hashedPassword"]/string/@value');
        my $hashedPasswordFile = $user->findvalue('./attrs/attr[@name = "hashedPasswordFile"]/string/@value');
        my $password = $user->findvalue('./attrs/attr[@name = "password"]/string/@value');
        my $passwordFile = $user->findvalue('./attrs/attr[@name = "passwordFile"]/string/@value');

        if ($hashedPasswordFile) {
            open(my $f, '<', $hashedPasswordFile) or die "Can't read file '$hashedPasswordFile'!";
            $hashedPassword = <$f>;
            chomp $hashedPassword;
        }
        if ($passwordFile) {
            open(my $f, '<', $passwordFile) or die "Can't read file '$passwordFile'!";
            $password = <$f>;
            chomp $password;
        }

        if ($hashedPassword) {
            if (index($hashedPassword, "grub.pbkdf2.") == 0) {
                $conf .= "\npassword_pbkdf2 $name $hashedPassword";
            }
            else {
                die "Password hash for GRUB user '$name' is not valid!";
            }
        }
        elsif ($password) {
            $conf .= "\npassword $name $password";
        }
        else {
            die "GRUB user '$name' has no password!";
        }
        push(@users, $name);
    }
    if (@users) {
        $conf .= "\nset superusers=\"" . join(' ',@users) . "\"\n";
    }

    if ($copyKernels == 0) {
        $conf .= "
            " . $grubStore->search;
    }
    # FIXME: should use grub-mkconfig.
    my $defaultEntryText = $defaultEntry;
    if ($saveDefault) {
        $defaultEntryText = "\"\${saved_entry}\"";
    }
    $conf .= "
        " . $grubBoot->search . "
        if [ -s \$prefix/grubenv ]; then
          load_env
        fi

        # ‘grub-reboot’ sets a one-time saved entry, which we process here and
        # then delete.
        if [ \"\${next_entry}\" ]; then
          set default=\"\${next_entry}\"
          set next_entry=
          save_env next_entry
          set timeout=1
          set boot_once=true
        else
          set default=$defaultEntryText
          set timeout=$timeout
        fi

        function savedefault {
            if [ -z \"\${boot_once}\"]; then
            saved_entry=\"\${chosen}\"
            save_env saved_entry
            fi
        }

        # Setup the graphics stack for bios and efi systems
        if [ \"\${grub_platform}\" = \"efi\" ]; then
          insmod efi_gop
          insmod efi_uga
        else
          insmod vbe
        fi
    ";

    if ($font) {
        copy $font, "$bootPath/converted-font.pf2" or die "cannot copy $font to $bootPath: $!\n";
        $conf .= "
            insmod font
            if loadfont " . ($grubBoot->path eq "/" ? "" : $grubBoot->path) . "/converted-font.pf2; then
              insmod gfxterm
              if [ \"\${grub_platform}\" = \"efi\" ]; then
                set gfxmode=$gfxmodeEfi
                set gfxpayload=$gfxpayloadEfi
              else
                set gfxmode=$gfxmodeBios
                set gfxpayload=$gfxpayloadBios
              fi
              terminal_output gfxterm
            fi
        ";
    }
    if ($splashImage) {
        # Keeps the image's extension.
        my ($filename, $dirs, $suffix) = fileparse($splashImage, qr"\..[^.]*$");
        # The module for jpg is jpeg.
        if ($suffix eq ".jpg") {
            $suffix = ".jpeg";
        }
        if ($backgroundColor) {
            $conf .= "
            background_color '$backgroundColor'
            ";
        }
        copy $splashImage, "$bootPath/background$suffix" or die "cannot copy $splashImage to $bootPath: $!\n";
        $conf .= "
            insmod " . substr($suffix, 1) . "
            if background_image --mode '$splashMode' " . ($grubBoot->path eq "/" ? "" : $grubBoot->path) . "/background$suffix; then
              set color_normal=white/black
              set color_highlight=black/white
            else
              set menu_color_normal=cyan/blue
              set menu_color_highlight=white/blue
            fi
        ";
    }

    rmtree("$bootPath/theme") or die "cannot clean up theme folder in $bootPath\n" if -e "$bootPath/theme";

    if ($theme) {
        # Copy theme
        rcopy($theme, "$bootPath/theme") or die "cannot copy $theme to $bootPath\n";
        $conf .= "
            # Sets theme.
            set theme=" . ($grubBoot->path eq "/" ? "" : $grubBoot->path) . "/theme/theme.txt
            export theme
            # Load theme fonts, if any
        ";

        find( { wanted => sub {
            if ($_ =~ /\.pf2$/i) {
                $font = File::Spec->abs2rel($File::Find::name, $theme);
                $conf .= "
                    loadfont " . ($grubBoot->path eq "/" ? "" : $grubBoot->path) . "/theme/$font
                ";
            }
        }, no_chdir => 1 }, $theme );
    }
}

$conf .= "$extraConfig\n";


# Generate the menu entries.
$conf .= "\n";

my %copied;
mkpath("$bootPath/kernels", 0, 0755) if $copyKernels;

sub copyToKernelsDir {
    my ($path) = @_;
    return $grubStore->path . substr($path, length("/nix/store")) unless $copyKernels;
    $path =~ /\/nix\/store\/(.*)/ or die;
    my $name = $1; $name =~ s/\//-/g;
    my $dst = "$bootPath/kernels/$name";
    # Don't copy the file if $dst already exists.  This means that we
    # have to create $dst atomically to prevent partially copied
    # kernels or initrd if this script is ever interrupted.
    if (! -e $dst) {
        my $tmp = "$dst.tmp";
        copy $path, $tmp or die "cannot copy $path to $tmp: $!\n";
        rename $tmp, $dst or die "cannot rename $tmp to $dst: $!\n";
    }
    $copied{$dst} = 1;
    return ($grubBoot->path eq "/" ? "" : $grubBoot->path) . "/kernels/$name";
}

sub addEntry {
    my ($name, $path, $options) = @_;
    return unless -e "$path/kernel" && -e "$path/initrd";

    my $kernel = copyToKernelsDir(Cwd::abs_path("$path/kernel"));
    my $initrd = copyToKernelsDir(Cwd::abs_path("$path/initrd"));

    # Include second initrd with secrets
    if (-e -x "$path/append-initrd-secrets") {
        my $initrdName = basename($initrd);
        my $initrdSecretsPath = "$bootPath/kernels/$initrdName-secrets";

        mkpath(dirname($initrdSecretsPath), 0, 0755);
        my $oldUmask = umask;
        # Make sure initrd is not world readable (won't work if /boot is FAT)
        umask 0137;
        my $initrdSecretsPathTemp = File::Temp::mktemp("$initrdSecretsPath.XXXXXXXX");
        system("$path/append-initrd-secrets", $initrdSecretsPathTemp) == 0 or die "failed to create initrd secrets: $!\n";
        # Check whether any secrets were actually added
        if (-e $initrdSecretsPathTemp && ! -z _) {
            rename $initrdSecretsPathTemp, $initrdSecretsPath or die "failed to move initrd secrets into place: $!\n";
            $copied{$initrdSecretsPath} = 1;
            $initrd .= " " . ($grubBoot->path eq "/" ? "" : $grubBoot->path) . "/kernels/$initrdName-secrets";
        } else {
            unlink $initrdSecretsPathTemp;
            rmdir dirname($initrdSecretsPathTemp);
        }
        umask $oldUmask;
    }

    my $xen = -e "$path/xen.gz" ? copyToKernelsDir(Cwd::abs_path("$path/xen.gz")) : undef;

    # FIXME: $confName

    my $kernelParams =
        "init=" . Cwd::abs_path("$path/init") . " " .
        readFile("$path/kernel-params");
    my $xenParams = $xen && -e "$path/xen-params" ? readFile("$path/xen-params") : "";

    if ($grubVersion == 1) {
        $conf .= "title $name\n";
        $conf .= "  $extraPerEntryConfig\n" if $extraPerEntryConfig;
        $conf .= "  kernel $xen $xenParams\n" if $xen;
        $conf .= "  " . ($xen ? "module" : "kernel") . " $kernel $kernelParams\n";
        $conf .= "  " . ($xen ? "module" : "initrd") . " $initrd\n";
        if ($saveDefault) {
            $conf .= "  savedefault\n";
        }
        $conf .= "\n";
    } else {
        $conf .= "menuentry \"$name\" " . ($options||"") . " {\n";
        if ($saveDefault) {
            $conf .= "  savedefault\n";
        }
        $conf .= $grubBoot->search . "\n";
        if ($copyKernels == 0) {
            $conf .= $grubStore->search . "\n";
        }
        $conf .= "  $extraPerEntryConfig\n" if $extraPerEntryConfig;
        $conf .= "  multiboot $xen $xenParams\n" if $xen;
        $conf .= "  " . ($xen ? "module" : "linux") . " $kernel $kernelParams\n";
        $conf .= "  " . ($xen ? "module" : "initrd") . " $initrd\n";
        $conf .= "}\n\n";
    }
}


# Add default entries.
$conf .= "$extraEntries\n" if $extraEntriesBeforeNixOS;

addEntry("NixOS - Default", $defaultConfig, $entryOptions);

$conf .= "$extraEntries\n" unless $extraEntriesBeforeNixOS;

# Find all the children of the current default configuration
# Do not search for grand children
my @links = sort (glob "$defaultConfig/specialisation/*");
foreach my $link (@links) {

    my $entryName = "";

    my $cfgName = readFile("$link/configuration-name");

    my $date = strftime("%F", localtime(lstat($link)->mtime));
    my $version =
        -e "$link/nixos-version"
        ? readFile("$link/nixos-version")
        : basename((glob(dirname(Cwd::abs_path("$link/kernel")) . "/lib/modules/*"))[0]);

    if ($cfgName) {
        $entryName = $cfgName;
    } else {
        my $linkname = basename($link);
        $entryName = "($linkname - $date - $version)";
    }
    addEntry("NixOS - $entryName", $link);
}

my $grubBootPath = $grubBoot->path;
# extraEntries could refer to @bootRoot@, which we have to substitute
$conf =~ s/\@bootRoot\@/$grubBootPath/g;

# Emit submenus for all system profiles.
sub addProfile {
    my ($profile, $description) = @_;

    # Add entries for all generations of this profile.
    $conf .= "submenu \"$description\" --class submenu {\n" if $grubVersion == 2;

    sub nrFromGen { my ($x) = @_; $x =~ /\/\w+-(\d+)-link/; return $1; }

    my @links = sort
        { nrFromGen($b) <=> nrFromGen($a) }
        (glob "$profile-*-link");

    my $curEntry = 0;
    foreach my $link (@links) {
        last if $curEntry++ >= $configurationLimit;
        if (! -e "$link/nixos-version") {
            warn "skipping corrupt system profile entry ‘$link’\n";
            next;
        }
        my $date = strftime("%F", localtime(lstat($link)->mtime));
        my $version =
            -e "$link/nixos-version"
            ? readFile("$link/nixos-version")
            : basename((glob(dirname(Cwd::abs_path("$link/kernel")) . "/lib/modules/*"))[0]);
        addEntry("NixOS - Configuration " . nrFromGen($link) . " ($date - $version)", $link, $subEntryOptions);
    }

    $conf .= "}\n" if $grubVersion == 2;
}

addProfile "/nix/var/nix/profiles/system", "NixOS - All configurations";

if ($grubVersion == 2) {
    for my $profile (glob "/nix/var/nix/profiles/system-profiles/*") {
        my $name = basename($profile);
        next unless $name =~ /^\w+$/;
        addProfile $profile, "NixOS - Profile '$name'";
    }
}

# extraPrepareConfig could refer to @bootPath@, which we have to substitute
$extraPrepareConfig =~ s/\@bootPath\@/$bootPath/g;

# Run extraPrepareConfig in sh
if ($extraPrepareConfig ne "") {
    system((get("shell"), "-c", $extraPrepareConfig));
}

# write the GRUB config.
my $confFile = $grubVersion == 1 ? "$bootPath/grub/menu.lst" : "$bootPath/grub/grub.cfg";
my $tmpFile = $confFile . ".tmp";
writeFile($tmpFile, $conf);


# check whether to install GRUB EFI or not
sub getEfiTarget {
    if ($grubVersion == 1) {
        return "no"
    } elsif (($grub ne "") && ($grubEfi ne "")) {
        # EFI can only be installed when target is set;
        # A target is also required then for non-EFI grub
        if (($grubTarget eq "") || ($grubTargetEfi eq "")) { return "both" }
        else { return "both" }
    } elsif (($grub ne "") && ($grubEfi eq "")) {
        # TODO: It would be safer to disallow non-EFI grub installation if no taget is given.
        #       If no target is given, then grub auto-detects the target which can lead to errors.
        #       E.g. it seems as if grub would auto-detect a EFI target based on the availability
        #       of a EFI partition.
        #       However, it seems as auto-detection is currently relied on for non-x86_64 and non-i386
        #       architectures in NixOS. That would have to be fixed in the nixos modules first.
        return "no"
    } elsif (($grub eq "") && ($grubEfi ne "")) {
        # EFI can only be installed when target is set;
        if ($grubTargetEfi eq "") { die }
        else {return "only" }
    } else {
        # prevent an installation if neither grub nor grubEfi is given
        return "neither"
    }
}

my $efiTarget = getEfiTarget();

# Append entries detected by os-prober
if (get("useOSProber") eq "true") {
    if ($saveDefault) {
        # os-prober will read this to determine if "savedefault" should be added to generated entries
        $ENV{'GRUB_SAVEDEFAULT'} = "true";
    }

    my $targetpackage = ($efiTarget eq "no") ? $grub : $grubEfi;
    system(get("shell"), "-c", "pkgdatadir=$targetpackage/share/grub $targetpackage/etc/grub.d/30_os-prober >> $tmpFile");
}

# Atomically switch to the new config
rename $tmpFile, $confFile or die "cannot rename $tmpFile to $confFile: $!\n";


# Remove obsolete files from $bootPath/kernels.
foreach my $fn (glob "$bootPath/kernels/*") {
    next if defined $copied{$fn};
    print STDERR "removing obsolete file $fn\n";
    unlink $fn;
}


#
# Install GRUB if the parameters changed from the last time we installed it.
#

struct(GrubState => {
    name => '$',
    version => '$',
    efi => '$',
    devices => '$',
    efiMountPoint => '$',
    extraGrubInstallArgs => '@',
});
# If you add something to the state file, only add it to the end
# because it is read line-by-line.
sub readGrubState {
    my $defaultGrubState = GrubState->new(name => "", version => "", efi => "", devices => "", efiMountPoint => "", extraGrubInstallArgs => () );
    open FILE, "<$bootPath/grub/state" or return $defaultGrubState;
    local $/ = "\n";
    my $name = <FILE>;
    chomp($name);
    my $version = <FILE>;
    chomp($version);
    my $efi = <FILE>;
    chomp($efi);
    my $devices = <FILE>;
    chomp($devices);
    my $efiMountPoint = <FILE>;
    chomp($efiMountPoint);
    # Historically, arguments in the state file were one per each line, but that
    # gets really messy when newlines are involved, structured arguments
    # like lists are needed (they have to have a separator encoding), or even worse,
    # when we need to remove a setting in the future. Thus, the 6th line is a JSON
    # object that can store structured data, with named keys, and all new state
    # should go in there.
    my $jsonStateLine = <FILE>;
    # For historical reasons we do not check the values above for un-definedness
    # (that is, when the state file has too few lines and EOF is reached),
    # because the above come from the first version of this logic and are thus
    # guaranteed to be present.
    $jsonStateLine = defined $jsonStateLine ? $jsonStateLine : '{}'; # empty JSON object
    chomp($jsonStateLine);
    if ($jsonStateLine eq "") {
        $jsonStateLine = '{}'; # empty JSON object
    }
    my %jsonState = %{decode_json($jsonStateLine)};
    my @extraGrubInstallArgs = exists($jsonState{'extraGrubInstallArgs'}) ? @{$jsonState{'extraGrubInstallArgs'}} : ();
    close FILE;
    my $grubState = GrubState->new(name => $name, version => $version, efi => $efi, devices => $devices, efiMountPoint => $efiMountPoint, extraGrubInstallArgs => \@extraGrubInstallArgs );
    return $grubState
}

my @deviceTargets = getList('devices');
my $prevGrubState = readGrubState();
my @prevDeviceTargets = split/,/, $prevGrubState->devices;
my @extraGrubInstallArgs = getList('extraGrubInstallArgs');
my @prevExtraGrubInstallArgs = @{$prevGrubState->extraGrubInstallArgs};

my $devicesDiffer = scalar (List::Compare->new( '-u', '-a', \@deviceTargets, \@prevDeviceTargets)->get_symmetric_difference());
my $extraGrubInstallArgsDiffer = scalar (List::Compare->new( '-u', '-a', \@extraGrubInstallArgs, \@prevExtraGrubInstallArgs)->get_symmetric_difference());
my $nameDiffer = get("fullName") ne $prevGrubState->name;
my $versionDiffer = get("fullVersion") ne $prevGrubState->version;
my $efiDiffer = $efiTarget ne $prevGrubState->efi;
my $efiMountPointDiffer = $efiSysMountPoint ne $prevGrubState->efiMountPoint;
if (($ENV{'NIXOS_INSTALL_GRUB'} // "") eq "1") {
    warn "NIXOS_INSTALL_GRUB env var deprecated, use NIXOS_INSTALL_BOOTLOADER";
    $ENV{'NIXOS_INSTALL_BOOTLOADER'} = "1";
}
my $requireNewInstall = $devicesDiffer || $extraGrubInstallArgsDiffer || $nameDiffer || $versionDiffer || $efiDiffer || $efiMountPointDiffer || (($ENV{'NIXOS_INSTALL_BOOTLOADER'} // "") eq "1");

# install a symlink so that grub can detect the boot drive
my $tmpDir = File::Temp::tempdir(CLEANUP => 1) or die "Failed to create temporary space: $!";
symlink "$bootPath", "$tmpDir/boot" or die "Failed to symlink $tmpDir/boot: $!";

# install non-EFI GRUB
if (($requireNewInstall != 0) && ($efiTarget eq "no" || $efiTarget eq "both")) {
    foreach my $dev (@deviceTargets) {
        next if $dev eq "nodev";
        print STDERR "installing the GRUB $grubVersion boot loader on $dev...\n";
        my @command = ("$grub/sbin/grub-install", "--recheck", "--root-directory=$tmpDir", Cwd::abs_path($dev), @extraGrubInstallArgs);
        if ($forceInstall eq "true") {
            push @command, "--force";
        }
        if ($grubTarget ne "") {
            push @command, "--target=$grubTarget";
        }
        (system @command) == 0 or die "$0: installation of GRUB on $dev failed: $!\n";
    }
}


# install EFI GRUB
if (($requireNewInstall != 0) && ($efiTarget eq "only" || $efiTarget eq "both")) {
    print STDERR "installing the GRUB $grubVersion EFI boot loader into $efiSysMountPoint...\n";
    my @command = ("$grubEfi/sbin/grub-install", "--recheck", "--target=$grubTargetEfi", "--boot-directory=$bootPath", "--efi-directory=$efiSysMountPoint", @extraGrubInstallArgs);
    if ($forceInstall eq "true") {
        push @command, "--force";
    }
    if ($canTouchEfiVariables eq "true") {
        push @command, "--bootloader-id=$bootloaderId";
    } else {
        push @command, "--no-nvram";
        push @command, "--removable" if $efiInstallAsRemovable eq "true";
    }

    (system @command) == 0 or die "$0: installation of GRUB EFI into $efiSysMountPoint failed: $!\n";
}


# update GRUB state file
if ($requireNewInstall != 0) {
    # Temp file for atomic rename.
    my $stateFile = "$bootPath/grub/state";
    my $stateFileTmp = $stateFile . ".tmp";

    open FILE, ">$stateFileTmp" or die "cannot create $stateFileTmp: $!\n";
    print FILE get("fullName"), "\n" or die;
    print FILE get("fullVersion"), "\n" or die;
    print FILE $efiTarget, "\n" or die;
    print FILE join( ",", @deviceTargets ), "\n" or die;
    print FILE $efiSysMountPoint, "\n" or die;
    my %jsonState = (
        extraGrubInstallArgs => \@extraGrubInstallArgs
    );
    my $jsonStateLine = encode_json(\%jsonState);
    print FILE $jsonStateLine, "\n" or die;
    close FILE or die;

    # Atomically switch to the new state file
    rename $stateFileTmp, $stateFile or die "cannot rename $stateFileTmp to $stateFile: $!\n";
}
