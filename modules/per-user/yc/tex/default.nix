{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.yc.tex;
in {
  options.my.yc.tex.enable = mkOption {
    default = config.my.yc.enable;
    type = types.bool;
  };
  config = mkIf cfg.enable {
    environment.systemPackages = [
      (with pkgs;
        texlive.combine {
          inherit (texlive)
          # necessary for org-mode
            scheme-basic dvipng latexmk wrapfig amsmath ulem hyperref capt-of
            # maths
            collection-mathscience
            # languages
            collection-langgerman
            # pictures and tikz
            collection-pictures;
        })
    ];
  };
}
