{ config, lib, ... }:
with lib;

let cfg = config.my.networking;
in {
  options.my.networking = {
    hostName = mkOption {
      description = "The name of the machine.  Used by nix flake.";
      type = types.str;
      default = "exampleHost";
    };
    timeZone = mkOption {
      type = types.str;
      default = "Etc/UTC";
    };
    wirelessNetworks = mkOption {
      description = "configure wireless networks with NetworkManager";
      type = with types; attrsOf str;
      default = { };
      example = { "network_ssid" = "password"; };
    };
  };
  config = {
    services.openssh = {
      enable = true;
      settings = { PasswordAuthentication = false; };
    };
    environment.etc = mkMerge (mapAttrsToList (name: pwd: {
      "NetworkManager/system-connections/${name}.nmconnection" = {
        # networkmanager demands secure permission
        mode = "0600";
        text = ''
          [connection]
          id=${name}
          type=wifi

          [wifi]
          mode=infrastructure
          ssid=${name}

          [wifi-security]
          auth-alg=open
          key-mgmt=wpa-psk
          psk=${pwd}
        '';
      };
    }) cfg.wirelessNetworks);
    time.timeZone = cfg.timeZone;
    networking = {
      networkmanager = {
        enable = mkDefault true;
        wifi = { macAddress = "random"; };
      };
      firewall.enable = mkDefault true;
      hostName = cfg.hostName;
    };
  };
}
