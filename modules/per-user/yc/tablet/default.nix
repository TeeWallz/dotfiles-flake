{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.yc.tablet;
in {
  options.my.yc.tablet.enable = mkOption {
    type = types.bool;
    default = config.my.yc.enable;
  };
  config =
    mkIf cfg.enable { environment.systemPackages = with pkgs; [ xournalpp ]; };
}
