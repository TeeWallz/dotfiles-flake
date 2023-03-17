{ config, pkgs, lib, ... }:
with lib;
let cfg = config.my.yc.tmux;
in {
  options.my.yc.tmux.enable = mkOption {
    type = types.bool;
    default = config.my.yc.enable;
  };
  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      keyMode = "emacs";
      newSession = true;
      secureSocket = true;
      extraConfig = ''
        unbind C-b
        set -g prefix f7
        bind -N "Send the prefix key through to the application" \
          f7 send-prefix

        bind-key -T prefix t new-session
        # toggle status bar with f7+f8
        set -g status off
        bind-key -T prefix f8 set-option -g status
      '';
    };
  };
}
