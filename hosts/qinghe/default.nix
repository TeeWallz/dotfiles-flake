{ system, pkgs, ... }: {
  my = {
    boot = {
      inherit system;
      bootDevices = [ "ata-TOSHIBA_Q300._46DB5111K1MU" ];
    };
    networking.hostName = "qinghe";
    yc.config-template.enable = true;
  };
}
