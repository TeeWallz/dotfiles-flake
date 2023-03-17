{ config, lib, pkgs, ... }:
with lib;

let cfg = config.my.programs.sway;
in {
  options.my.programs.sway.enable = mkOption {
    description = "enable sway window manager and my favorite programs";
    type = types.bool;
    default = false;
  };
  config = mkIf (cfg.enable) {
    hardware = {
      opengl = {
        extraPackages = with pkgs; [ vaapiIntel intel-media-driver ];
        enable = true;
      };
      bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      pulseaudio.enable = false;
    };
    services = {
      blueman.enable = true;
      logind = {
        extraConfig = ''
          HandlePowerKey=suspend
        '';
        lidSwitch = "suspend";
        lidSwitchDocked = "ignore";
        lidSwitchExternalPower = "suspend";
      };
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
      };
    };
    sound.enable = true;
    programs.sway = {
      extraSessionCommands = ''
        export MOZ_ENABLE_WAYLAND=1
        export QT_WAYLAND_FORCE_DPI=physical
        export QT_QPA_PLATFORMTHEME=qt5ct
        export QT_QPA_PLATFORM=wayland-egl
        export XCURSOR_THEME=Adwaita
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
      enable = true;
      extraPackages = with pkgs; [
        swaylock
        swayidle
        foot
        gammastep
        brightnessctl
        fuzzel
        grim
        w3m
        gsettings-desktop-schemas
        pavucontrol
        waybar
        wl-clipboard
        qt5ct
        adwaita-qt
      ];
    };
    xdg.portal = {
      enable = true;
      wlr.enable = true;
    };
    fonts.fontconfig.defaultFonts = {
      monospace = [ "Source Code Pro" ];
      sansSerif = [ "Noto Sans Display" ];
      serif = [ "Noto Sans Display" ];
    };
    fonts.fonts = with pkgs; [ noto-fonts noto-fonts-emoji source-code-pro ];
  };
}
