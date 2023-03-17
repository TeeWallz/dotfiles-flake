{ system, pkgs, ... }: {
  my = {
    boot = {
      # system = "aarch64-linux";
      inherit system;
      devNodes = "/dev/disk/by-id/";
      bootDevices = [ "bootDevices_placeholder" ];
      immutable = false;
      # generate unique hostId with
      # head -c4 /dev/urandom | od -A none -t x4
      hostId = "hostId_placeholder";
      isVm = false;
    };

    users = {
      root = {
        # hash: mkpasswd -m SHA-512 -s
        initialHashedPassword = "rootHash_placeholder";
        authorizedKeys = [ "sshKey_placeholder" ];
        isSystemUser = true;
      };

      my-user = {
        # "!" means login disabled
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
    programs = { sway.enable = false; };
  };
}
