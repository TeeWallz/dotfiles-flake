{ system, pkgs, ... }: {
  my = {
    boot = {
      inherit system;
      hostId = "e74b069d";
      bootDevices = [ "nvme-SAMSUNG_MZVLV256HCHP-000H1_S2CSNA0J547878" ];
    };
    networking.hostName = "yinzhou";
    yc.config-template.enable = true;
    yc.keyboard.enable = true;
  };
}
