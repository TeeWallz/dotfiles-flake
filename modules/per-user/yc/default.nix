{ config, lib, pkgs, ... }:
with lib; {
  imports = [
    ./mpv
    ./emacs
    ./firefox
    ./tex
    ./mail
    ./tablet
    ./virt
    ./keyboard
    ./hidden
  ];
  options.my.yc.enable = mkOption {
    description = "enable yc options";
    type = with types; bool;
    default = false;
  };
  config = mkIf config.my.yc.enable { my.programs.sway.enable = true; };
}
