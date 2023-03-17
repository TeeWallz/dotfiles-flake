{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.yc.mail;
in {
  options.my.yc.mail.enable = mkOption {
    type = types.bool;
    default = config.my.yc.enable;
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      isync
      notmuch
      msmtp
      (pass.withExtensions (exts: with exts; [ pass-otp pass-import ]))
    ];
    programs.gnupg.agent = {
      enable = true;
      # must use graphical pinentry, else would mess up terminal
      pinentryFlavor = "qt";
    };
  };
}
