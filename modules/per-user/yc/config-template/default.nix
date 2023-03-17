{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.yc.config-template;
in {
  options.my.yc.config-template = {
    enable = mkOption {
      description = "Enable system config template by yc";
      type = types.bool;
      default = false;
    };
  };
  config = mkIf cfg.enable {
    programs.gnupg.agent = {
      enable = true;
      pinentryFlavor = "tty";
    };
    my = {
      boot = {
        # system = "aarch64-linux";
        devNodes = "/dev/disk/by-id/";
        immutable = true;
        # generate unique hostId with
        # head -c4 /dev/urandom | od -A none -t x4
        hostId = "abcd1234";
        isVm = false;
      };

      users = {
        yc = {
          # "!" means login disabled
          initialHashedPassword =
            "$6$UxT9KYGGV6ik$BhH3Q.2F8x1llZQLUS1Gm4AxU7bmgZUP7pNX6Qt3qrdXUy7ZYByl5RVyKKMp/DuHZgk.RiiEXK8YVH.b2nuOO/";
          description = "Yuchen Guo";
          # a default group must be set
          group = "users";
          extraGroups = [
            # use doas
            "wheel"
            # manage VMs
            "libvirtd"
            # manage network
            "networkmanager"
            # connect to /dev/ttyUSB0
            "dialout"
          ];
          packages = with pkgs; [
            mg
            nixfmt
            qrencode
            minicom
            zathura
            pdftk
            android-file-transfer
          ];
          isNormalUser = true;
        };
      };
      networking = {
        timeZone = "Europe/Berlin";
        wirelessNetworks = {
          "TP-Link_48C2" = "77017543";
          "1203-5G" = "hallo stranger";
        };
      };

      yc.enable = true;
    };
  };
}
