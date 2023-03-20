# #
##
##  per-host configuration for exampleHost
##
##

{ system, pkgs, ... }: {
  my = {
    boot = {
      inherit system;
      devNodes = "/dev/disk/by-id/";
      bootDevices = [ "bootDevices_placeholder" ];
      immutable = false;
      hostId = "hostId_placeholder";
      availableKernelModules = [
        # for booting virtual machine
        # with virtio disk controller
        "virtio_pci"
        "virtio_blk"
        # for sata drive
        "ahci"
        # for nvme drive
        "nvme"
        # for external usb drive
        "uas"
      ];
    };

    users = {
      root = {
        # generate hash with:
        # mkpasswd -m SHA-512 -s
        # set hash to "!" to disable login
        initialHashedPassword = "rootHash_placeholder";

        authorizedKeys = [ "sshKey_placeholder" ];
        isSystemUser = true;
      };

      my-user = {
        initialHashedPassword = "!";
        description = "J. Magoo";

        # a default group must be set
        group = "users";

        extraGroups = [ "wheel" ];
        packages = with pkgs; [ mg nixfmt ];
        isNormalUser = true;
      };
    };
    networking = {
      hostName = "exampleHost";
      timeZone = "Europe/Berlin";
      wirelessNetworks = { "myWifi" = "myPass"; };
    };

    # enable sway, a tiling Wayland window manager
    # Usage:
    #   Step: change "false" to "true".
    #   Step: add a normal user, see above.
    #   Step: generate and set password hash for the new user.
    #   Step: apply configuration, then reboot.
    #   Step: after reboot, at text console, login as normal user.
    #   Step: enter "sway" command then press "Return".
    programs = { sway.enable = false; };
  };
}
