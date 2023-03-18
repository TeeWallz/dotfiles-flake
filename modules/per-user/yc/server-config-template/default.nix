{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.yc.server-config-template;
in {
  imports = [ ./bt.nix ];
  options.my.yc.server-config-template = {
    enable = mkOption {
      description = "Enable server config template by yc";
      type = types.bool;
      default = false;
    };
  };
  config = mkIf cfg.enable {
    my = {
      boot = {
        devNodes = "/dev/disk/by-id/";
        immutable = true;
      };
      users = {
        root = {
          initialHashedPassword =
            "$6$UwiWDVTi2tq7DEVi$yTbo5I3wt1aZwPVjAWTfTOY5oKed7wxxXrnPuYwrOBJA8gCXQopJJ2cFy06k5ynvF.DUXc1u0In8hsjoMmc640";
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINN0Jghx8opezUJS0akfLG8wpQ8U1rdZZw/e3v+nk70G yc@yc-eb820g4"
          ];
        };
        our = {
          group = "users";
          isNormalUser = true;
          authorizedKeys = [
            "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDTc3A1qJl/v0Fkm3MgVom6AaYeSHr7GMHMWgYLzCAAPmfmZBEc3YWNTjnwinGHfuTun5F8hIwg1I/Of0wUYKNwH4Fx7fWQfOkOPxdeVLvy5sHVskwEMYeYteG4PPSDPqov+lQ6jYdL7KjlqQn4nLG5jLQsj47/axwBtdE5uS13cGOnyIuIq3O3djIWWOPv2RWEnc/xHHvsISg6e4HNZJr3W0AOcdd5NPk5Mf9BVj45kdR5TpypvPdTdI5jXYSmlousd5V2dNKqreBj7RX3Fap/vSViPM8EEbgFPC1i7hOWlWTMt12baAFFKZwRvjD6kr/FjUbGzh6Yx14NzJM+yFjwla71nbancL9kQr8S3WBF3OVLT26X43PltiVSfOPR7xsVx5pGbaesEuUPB6b394Z0w3zXAuQANwQbJZTDmjyvPvMDlEDwtoq/wQJvzwfi/n1NTimu3yjWvKFYTMPVH5HUQqj7FrG2c8aldAl18Z+dV/Mymky7CGIgHtT/oG99TSk= comment"
          ];
        };
        yc = {
          group = "users";
          isNormalUser = true;
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINN0Jghx8opezUJS0akfLG8wpQ8U1rdZZw/e3v+nk70G yc@yc-eb820g4"
          ];
        };
      };
      yc = {
        hidden.enable = true;
        emacs.enable = true;
      };
    };
    programs = {
      tmux = {
        enable = true;
        keyMode = "emacs";
        newSession = true;
        extraConfig = ''
          unbind C-b
          set -g prefix C-\\
          bind C-\\ send-prefix
        '';
      };
    };
    services.openssh = {
      ports = [ 22 65222 ];
      allowSFTP = true;
      openFirewall = true;
    };
    environment.etc = {
      "ssh/ssh_host_ed25519_key" = {
        source = "/oldroot/etc/ssh/ssh_host_ed25519_key";
        mode = "0600";
      };
      "ssh/ssh_host_ed25519_key.pub" = {
        source = "/oldroot/etc/ssh/ssh_host_ed25519_key.pub";
        mode = "0600";
      };
      "ssh/ssh_host_rsa_key" = {
        source = "/oldroot/etc/ssh/ssh_host_rsa_key";
        mode = "0600";
      };
      "ssh/ssh_host_rsa_key.pub" = {
        source = "/oldroot/etc/ssh/ssh_host_rsa_key.pub";
        mode = "0600";
      };
    };
    nix.settings.substituters =
      [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
    services.yggdrasil.persistentKeys = true;
    services.i2pd.inTunnels = {
      ssh-server = {
        enable = true;
        address = "::1";
        destination = "::1";
        #keys = "‹name›-keys.dat";
        #key is generated if missing
        port = 65222;
        accessList = [ ]; # to lazy to only allow my laptops
      };
    };
  };
}
