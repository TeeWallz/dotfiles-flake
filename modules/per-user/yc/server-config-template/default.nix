{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.yc.server-config-template;
in {
  options.my.yc.server-config-template = {
    enable = mkOption {
      description = "Enable server config template by yc";
      type = types.bool;
      default = false;
    };
  };
  config = mkIf cfg.enable {
    my.fileSystems.datasets = {
      "rpool/nixos/home" = "/oldroot/home";
      "rpool/data/file" = "/home";
    };
    fileSystems = {
      "/tmp/BitTorrent" = {
        device = "rpool/data/bt";
        fsType = "zfs";
        options = [ "noatime" "X-mount.mkdir=755" ];
      };

      "/var/lib/transmission/.config" = {
        device = "/tmp/BitTorrent/.config";
        fsType = "none";
        options = [ "bind" "X-mount.mkdir=755" ];
      };
    };

    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "quarterly";
      };
      autoSnapshot = {
        enable = true;
        flags = "-k -p --utc";
        monthly = 48;
      };
    };
    services.samba = {
      enable = true;
      openFirewall = true;
      extraConfig = ''
        guest account = nobody
        map to guest = bad user
        server smb encrypt = off
      '';
      shares = {
        bt = {
          path = "/tmp/BitTorrent";
          "read only" = true;
          browseable = "yes";
          "guest ok" = "yes";
        };
      };
    };

    services.transmission = {
      enable = true;
      openFirewall = true;
      home = "/var/lib/transmission";
      performanceNetParameters = true;
      settings = {
        dht-enabled = true;
        download-dir = "/tmp/BitTorrent/已下载";
        download-queue-enabled = false;
        idle-seeding-limit-enabled = false;
        incomplete-dir = "/tmp/BitTorrent/未完成";
        incomplete-dir-enabled = true;
        lpd-enabled = true;
        message-level = 1;
        pex-enabled = true;
        port-forwarding-enabled = false;
        preallocation = 1;
        prefetch-enabled = true;
        queue-stalled-enabled = true;
        rename-partial-files = true;
        rpc-authentication-required = false;
        rpc-bind-address = "0.0.0.0";
        rpc-enabled = true;
        rpc-host-whitelist = "";
        rpc-host-whitelist-enabled = true;
        rpc-port = 9091;
        rpc-url = "/transmission/";
        rpc-username = "";
        rpc-whitelist = "127.0.0.1,::1";
        rpc-whitelist-enabled = true;
        scrape-paused-torrents-enabled = true;
        script-torrent-done-enabled = false;
        seed-queue-enabled = false;
        utp-enabled = true;
      };
    };
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
      "ssh/ssh_host_rsa_key" = {
        source = "/oldroot/etc/ssh/ssh_host_rsa_key";
        mode = "0600";
      };
    };
    nix.settings.substituters =
      [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
    services.yggdrasil.persistentKeys = true;
    boot.initrd.secrets = { "/oldroot/etc/zfs-key-rpool-data-file" = null; };
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
    environment.shellAliases = {
      Nb =
        "git -C /etc/nixos pull && nixos-rebuild boot --option substituters https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store";
      tm = "tmux attach-session";
      e = "$EDITOR";
    };
    services.emacs.enable = true;
    swapDevices = [ ];
  };
}
