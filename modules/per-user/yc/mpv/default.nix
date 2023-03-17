{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.yc.mpv;
in {
  options.my.yc.mpv = {
    enable = mkOption {
      type = types.bool;
      default = config.my.yc.enable;
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ mpv ffmpeg yt-dlp ];
  };
}
