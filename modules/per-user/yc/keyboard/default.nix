{ config, lib, ... }:
with lib;
let cfg = config.my.yc.keyboard;
in {
  options.my.yc.keyboard.enable = mkOption {
    default = config.my.yc.enable;
    type = types.bool;
  };
  config = mkIf cfg.enable {
    console.useXkbConfig = true;
    services.xserver = {
      layout = "yc";
      extraLayouts."yc" = {
        description = "my layout";
        languages = [ "eng" ];
        symbolsFile = ./symbols.txt;
      };
    };
    environment.variables = { XKB_DEFAULT_LAYOUT = "yc"; };
  };
}
