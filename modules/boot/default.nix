{ config, lib, ... }:
with lib;

let cfg = config.my.boot;
in {
  options.my.boot = {
    enable = mkOption {
      description = "Enable root on ZFS support";
      type = types.bool;
      default = true;
    };
    devNodes = mkOption {
      description = "Specify where to discover ZFS pools";
      type = types.str;
      apply = x:
        assert (strings.hasSuffix "/" x
          || abort "devNodes '${x}' must have trailing slash!");
        x;
      default = "/dev/disk/by-id/";
    };
    hostId = mkOption {
      description = "Set host id";
      type = types.str;
      default = "4e98920d";
    };
    bootDevices = mkOption {
      description = "Specify boot devices";
      type = types.nonEmptyListOf types.str;
      default = [ "ata-foodisk" ];
    };
    immutable = mkOption {
      description = "Enable root on ZFS immutable root support";
      type = types.bool;
      default = false;
    };
    isVm = mkOption {
      description = "if virtual machine, disable firmware and microcode";
      type = types.bool;
      default = false;
    };
    partitionScheme = mkOption {
      default = {
        biosBoot = "-part5";
        efiBoot = "-part1";
        swap = "-part4";
        bootPool = "-part2";
        rootPool = "-part3";
      };
      description = "Describe on disk partitions";
      type = with types; attrsOf types.str;
    };
    system = mkOption {
      description = "Set system architecture";
      type = types.str;
      default = "x86_64-linux";
    };
  };
  config = mkIf (cfg.enable) (mkMerge [
    {
      my.fileSystems = {
        datasets = {
          "rpool/nixos/home" = mkDefault "/home";
          "rpool/nixos/var/lib" = mkDefault "/var/lib";
          "rpool/nixos/var/log" = mkDefault "/var/log";
          "bpool/nixos/root" = "/boot";
        };
      };
    }
    (mkIf (!cfg.immutable) {
      my.fileSystems = { datasets = { "rpool/nixos/root" = "/"; }; };
    })
    (mkIf cfg.immutable {
      my.fileSystems = {
        datasets = {
          "rpool/nixos/empty" = "/";
          "rpool/nixos/root" = "/oldroot";
        };
        bindmounts = {
          "/oldroot/nix" = "/nix";
          "/oldroot/etc/nixos" = "/etc/nixos";
        };
      };
      boot.initrd.postDeviceCommands = ''
        if ! grep -q zfs_no_rollback /proc/cmdline; then
          zpool import -N rpool
          zfs rollback -r rpool/nixos/empty@start
          zpool export -a
        fi
      '';
    })
    (mkIf (!cfg.isVm) {
      hardware = {
        enableRedistributableFirmware = mkDefault true;
        cpu = (if (cfg.system == "x86_64-linux") then {
          intel.updateMicrocode = true;
          amd.updateMicrocode = true;
        } else
          { });
      };

    })
    {
      my.fileSystems = {
        efiSystemPartitions =
          (map (diskName: diskName + cfg.partitionScheme.efiBoot)
            cfg.bootDevices);
        swapPartitions =
          (map (diskName: diskName + cfg.partitionScheme.swap) cfg.bootDevices);
      };
      networking.hostId = cfg.hostId;
      nix.settings.experimental-features = mkDefault [ "nix-command" "flakes" ];
      programs.git.enable = true;
      zramSwap.enable = mkDefault true;
      boot = {
        tmpOnTmpfs = mkDefault true;
        kernelPackages =
          mkDefault config.boot.zfs.package.latestCompatibleLinuxPackages;
        supportedFilesystems = [ "zfs" ];
        zfs = {
          devNodes = cfg.devNodes;
          forceImportRoot = false;
        };
        loader.efi = {
          canTouchEfiVariables = false;
          efiSysMountPoint = with builtins;
            ("/boot/efis/" + (head cfg.bootDevices)
              + cfg.partitionScheme.efiBoot);
        };
        loader.generationsDir.copyKernels = true;
        loader.grub = {
          devices = (map (diskName: cfg.devNodes + diskName) cfg.bootDevices);
          efiInstallAsRemovable = true;
          enable = true;
          version = 2;
          copyKernels = true;
          efiSupport = true;
          zfsSupport = true;
          extraInstallCommands = with builtins;
            (toString (map (diskName: ''
              cp -r ${config.boot.loader.efi.efiSysMountPoint}/EFI /boot/efis/${diskName}${cfg.partitionScheme.efiBoot}
            '') (tail cfg.bootDevices)));
        };
      };
    }
  ]);
}
