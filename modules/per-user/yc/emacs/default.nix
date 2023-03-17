{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.my.yc.emacs;
  # buildEmacs is a function that takes a set of emacs packages as input
  buildEmacs = with pkgs; (emacsPackagesFor emacs).emacsWithPackages;
in {
  options.my.yc.emacs = {
    enable = mkOption {
      type = types.bool;
      default = config.my.yc.enable;
    };
    extraPackages = mkOption {
      description = "normal software packages that emacs depends to run";
      type = with types; listOf package;
      default = with pkgs; [
        auctex
        # spell checkers
        enchant
        nuspell
        hunspellDicts.en_US
        hunspellDicts.de_DE
        # used with dired mode to open files
        xdg-utils
      ];
    };
  };
  config = mkIf (cfg.enable) {
    services.emacs = {
      enable = true;
      package = buildEmacs (epkgs:
        with epkgs;
        (with melpaPackages; [ nix-mode cdlatex notmuch ])
        ++ (with elpaPackages; [ use-package auctex pyim pyim-basedict ]));
      defaultEditor = true;
    };
    environment.systemPackages = cfg.extraPackages;
  };
}
