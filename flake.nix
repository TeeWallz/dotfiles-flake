{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

  outputs = { self, nixpkgs }@inputs:
    let
      my = import ./my {
        inherit inputs;
        lib = inputs.nixpkgs.lib;
      };
      inherit (my) lib;
    in {
      nixosConfigurations = {
        exampleHost = let
          system = "x86_64-linux";
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in my.lib.mkHost {
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
        };
        qinghe = let
          system = "x86_64-linux";
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in my.lib.mkHost {
          my = {
            boot = {
              # system = "aarch64-linux";
              inherit system;
              devNodes = "/dev/disk/by-id/";
              bootDevices = [ "ata-TOSHIBA_Q300._46DB5111K1MU" ];
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
              hostName = "qinghe";
              timeZone = "Europe/Berlin";
              wirelessNetworks = {
                "TP-Link_48C2" = "77017543";
                "1203-5G" = "hallo stranger";
              };
            };

            yc.enable = true;
          };
        };
      };
    };
}
