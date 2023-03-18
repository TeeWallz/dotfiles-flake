{ config, lib, pkgs, ... }:
with lib; {
  imports = [
    ./emacs
    ./firefox
    ./tex
    ./tablet
    ./virt
    ./keyboard
    ./hidden
    ./home-manager
    ./config-template
    ./tmux
    ./server-config-template
  ];
  options.my.yc.enable = mkOption {
    description = "enable yc options";
    type = with types; bool;
    default = false;
  };
  config = mkIf config.my.yc.enable { my.programs.sway.enable = true; };
}
