{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.yc.home-manager;
in {
  options.my.yc.home-manager = {
    enable = mkOption {
      type = types.bool;
      default = config.my.yc.enable;
    };
  };
  config = mkIf cfg.enable {
    # have a clean home
    my.fileSystems.datasets = { "rpool/nixos/home" = "/oldroot/home"; };
    fileSystems."/home/yc" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "rw" "size=1G" "uid=yc" "gid=users" "mode=1700" ];
    };
    programs.gnupg.agent = {
      enable = true;
      pinentryFlavor = (if config.programs.sway.enable then "qt" else "tty");
    };

    home-manager.users.yc = {
      home.packages = with pkgs; [ ];

      gtk = {
        enable = true;
        font = { name = "Noto Sans Display 14"; };
        theme = {
          name = "Adwaita-dark";
          package = pkgs.gnome.gnome-themes-extra;
        };
        iconTheme = {
          package = pkgs.gnome.adwaita-icon-theme;
          name = "Adwaita";
        };
      };
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          enable-animations = false;
          document-font-name = "Noto Sans Display 12";
          monospace-font-name = "Source Code Pro 10";
          gtk-key-theme = "Emacs";
          cursor-size = 48;
        };
      };
      programs.bash = {
        enable = true;
        initExtra =
          "if [ -f ~/.config/yc.sh ]; then source ~/.config/yc.sh; fi";
      };
      programs = {
        git = {
          enable = true;
          userEmail = "jasper@apvc.uk";
          userName = "Maurice Zhou";
        };
        mbsync.enable = true;
        msmtp.enable = true;
        notmuch.enable = true;
      };
      accounts.email = {
        maildirBasePath = "Maildir"; # relative to user home
        accounts = {
          "apvc.uk" = {
            aliases = [ "gyc@apvc.uk" ];
            address = "yuchen@apvc.uk";
            passwordCommand = "pass show email/email-gycAtapvc.uk | head -n1";
            primary = true;
            userName = "gyc@apvc.uk";
            realName = "Yuchen Guo";
            imap = {
              host = "mail.gandi.net";
              port = 993;
            };
            smtp = {
              host = "mail.gandi.net";
              port = 465;
            };
            mbsync = {
              enable = true;
              create = "both";
              remove = "both";
              expunge = "both";
            };
            msmtp = {
              enable = true;
              extraConfig = { auth = "plain"; };
            };
            notmuch.enable = true;
            gpg = {
              key = "gyc@apvc.uk";
              encryptByDefault = false;
              signByDefault = true;
            };
          };
        };
      };
      programs.mpv = {
        enable = true;
        config = {
          gpu-context = "wayland";
          hwdec = "vaapi";
          player-operation-mode = "pseudo-gui";
          audio-pitch-correction = "no";
        };
      };
      programs.yt-dlp = {
        enable = true;
        settings = { format-sort = "codec:h264"; };
      };
      programs.zathura = {
        enable = true;
        mappings = {
          "<C-b>" = "scroll left";
          "<C-n>" = "scroll down";
          "<C-p>" = "scroll up";
          "<C-f>" = "scroll right";
          "<C-g>" = "abort";
          "<C-[>" = "abort";
          "<A-<>" = "goto top";
          "<A->>" = "goto bottom";
          "a" = "adjust_window best-fit";
          "s" = "adjust_window width";
          "F" = "display_link";
          "<C-c>" = "copy_link";
          "f" = "follow";
          "m" = "mark_add";
          "\\'" = "mark_evaluate";
          "\\," = "navigate next";
          "\\." = "navigate previous";
          "<A-Right>" = "navigate next";
          "<A-Left>" = "navigate previous";
          "<C-P>" = "print";
          "c" = "recolor";
          "R" = "reload";
          "v" = "rotate rotate_cw";
          "V" = "rotate rotate_ccw";
          "<Left>" = "scroll left";
          "<Up>" = "scroll up";
          "<Down>" = "scroll down";
          "<Right>" = "scroll right";
          "<A-a>" = "scroll half-left";
          "<C-V>" = "scroll half-down";
          "<A-V>" = "scroll half-up";
          "<A-e>" = "scroll half-right";
          "<C-a>" = "scroll full-left";
          "<C-v>" = "scroll full-down";
          "<Return>" = "scroll full-down";
          "<A-v>" = "scroll full-up";
          "<C-e>" = "scroll full-right";
          "<Space>" = "scroll full-down";
          "<A-Space>" = "scroll full-up";
          "<C-h>" = "scroll full-up";
          "<BackSpace>" = "scroll full-up";
          "<S-Space>" = "scroll full-up";
          "l" = "jumplist backward";
          "r" = "jumplist forward";
          "<A-r>" = "bisect forward";
          "<A-l>" = "bisect backward";
          "<C-s>" = "search forward";
          "<C-r>" = "search backward";
          "p" = "snap_to_page";
          "<C-i>" = "toggle_index";
          "i" = "toggle_index";
          "<Tab>" = "toggle_index";
          "<A-s>" = "toggle_statusbar";
          "<A-i>" = "focus_inputbar";
          "d" = "toggle_page_mode";
          "q" = "quit";
          "+" = "zoom in";
          "-" = "zoom out";
          "<C-+>" = "zoom in";
          "<C-->" = "zoom out";
          "=" = "zoom in";
          "<A-P>" = "toggle_presentation";
          "<A-F>" = "toggle_fullscreen";
          "j" = "toggle_fullscreen";

        };
        options = {
          selection-clipboard = "clipboard";
          window-title-basename = true;
          adjust-open = "width";
          scroll-page-aware = true;
          scroll-full-overlap = "0.1";
          statusbar-home-tilde = true;
          synctex = true;
          font = "Monospace bold 16";
          guioptions = "hv";
          zoom-step = 3;
        };
      };
      programs.firefox = {
        enable = true;
        profiles = {
          default = {
            settings = {
              # https://raw.githubusercontent.com/pyllyukko/user.js/master/user.js
              "toolkit.zoomManager.zoomValues" = "1,1.7,2,2.3";
              "browser.urlbar.quicksuggest.enabled" = false;
              "browser.backspace_action" = 0;
              "browser.search.suggest.enabled" = false;
              "browser.urlbar.suggest.searches" = false;
              "browser.casting.enabled" = false;
              "media.gmp-gmpopenh264.enabled" = false;
              "media.gmp-manager.url" = "";
              "network.http.speculative-parallel-limit" = 0;
              "browser.aboutHomeSnippets.updateUrl" = "";
              "browser.search.update" = false;
              "browser.topsites.contile.enabled" = false;
              "browser.newtabpage.activity-stream.feeds.topsites" = false;
              "browser.newtabpage.activity-stream.showSponsoredTopSites" =
                false;
              "network.dns.blockDotOnion" = true;
              "browser.uidensity" = 1;
              "dom.security.https_only_mode" = true;
              "general.smoothScroll" = false;
              "media.ffmpeg.vaapi.enabled" = true;
              "media.ffmpeg.low-latency.enabled" = true;
              "media.navigator.mediadatadecoder_vpx_enabled" = true;
              "browser.chrome.site_icons" = false;
              "browser.tabs.firefox-view" = false;
              "browser.contentblocking.category" = "strict";
              "apz.allow_double_tap_zooming" = false;
              "apz.allow_zooming" = false;
              "apz.gtk.touchpad_pinch.enabled" = false;
              "privacy.resistFingerprinting" = true;
              "webgl.min_capability_mode" = true;
              "dom.serviceWorkers.enabled" = false;
              "dom.webnotifications.enabled" = false;
              "dom.enable_performance" = false;
              "dom.enable_user_timing" = false;
              "dom.webaudio.enabled" = false;
              "geo.enabled" = false;
              "geo.wifi.uri" =
                "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
              "geo.wifi.logging.enabled" = false;
              "dom.mozTCPSocket.enabled" = false;
              "dom.netinfo.enabled" = false;
              "dom.network.enabled" = false;
              "media.peerconnection.ice.no_host" = true;
              "dom.battery.enabled" = false;
              "dom.telephony.enabled" = false;
              "beacon.enabled" = false;
              "dom.event.clipboardevents.enabled" = false;
              "dom.allow_cut_copy" = false;
              "media.webspeech.recognition.enable" = false;
              "media.webspeech.synth.enabled" = false;
              "device.sensors.enabled" = false;
              "browser.send_pings" = false;
              "browser.send_pings.require_same_host" = true;
              "dom.gamepad.enabled" = false;
              "dom.vr.enabled" = false;
              "dom.vibrator.enabled" = false;
              "dom.archivereader.enabled" = false;
              "webgl.disabled" = true;
              "webgl.disable-extensions" = true;
              "webgl.disable-fail-if-major-performance-caveat" = true;
              "webgl.enable-debug-renderer-info" = false;
              "javascript.options.wasm" = false;
              "camera.control.face_detection.enabled" = false;
              "browser.search.countryCode" = "US";
              "browser.search.region" = "US";
              "browser.search.geoip.url" = "";
              "intl.accept_languages" = "en-US = en";
              "intl.locale.matchOS" = false;
              "browser.search.geoSpecificDefaults" = false;
              "clipboard.autocopy" = false;
              "javascript.use_us_english_locale" = true;
              "browser.urlbar.trimURLs" = false;
              "browser.fixup.alternate.enabled" = false;
              "browser.fixup.hide_user_pass" = true;
              "network.proxy.socks_remote_dns" = true;
              "network.manage-offline-status" = false;
              "security.mixed_content.block_active_content" = true;
              "security.mixed_content.block_display_content" = true;
              "network.jar.open-unsafe-types" = false;
              "security.xpconnect.plugin.unrestricted" = false;
              "javascript.options.asmjs" = false;
              "gfx.font_rendering.opentype_svg.enabled" = false;
              "browser.urlbar.filter.javascript" = true;
              "media.video_stats.enabled" = false;
              "general.buildID.override" = "20100101";
              "browser.startup.homepage_override.buildID" = "20100101";
              "browser.display.use_document_fonts" = 0;
              "browser.newtabpage.activity-stream.asrouter.userprefs.cfr" =
                false;
              "devtools.webide.enabled" = false;
              "devtools.webide.autoinstallADBHelper" = false;
              "devtools.webide.autoinstallFxdtAdapters" = false;
              "devtools.debugger.remote-enabled" = false;
              "devtools.chrome.enabled" = false;
              "devtools.debugger.force-local" = true;
              "dom.flyweb.enabled" = false;
              "privacy.userContext.enabled" = true;
              "privacy.resistFingerprinting.block_mozAddonManager" = true;
              "extensions.webextensions.restrictedDomains" = "";
              "network.IDN_show_punycode" = true;
              "browser.urlbar.autoFill" = false;

            };
          };
        };
      };
      programs.ssh = {
        enable = true;
        hashKnownHosts = true;
        matchBlocks = let
          dotSshPath =
            "${config.home-manager.users.yc.home.homeDirectory}/.ssh/";
        in {
          "github.com" = {
            # github.com:ne9z
            user = "git";
            identityFile = dotSshPath + "yc";
          };
          "gitlab.com" = {
            # gitlab.com:john8931
            user = "git";
            identityFile = dotSshPath + "tub_latex_repokey";
          };
          "tl.yc" = {
            user = "yc";
            identityFile = dotSshPath + "yc";
            port = 65222;
          };
          "3ldetowqifu5ox23snmoblv7xapkd26qyvex6fwrg6zpdwklcatq.b32.i2p" = {
            user = "yc";
            identityFile = dotSshPath + "yc";
            port = 65222;
            proxyCommand = "${pkgs.libressl.nc}/bin/nc -x localhost:4447 %h %p";
          };
        };
      };
      programs.foot = {
        enable = true;
        server.enable = true;
        settings = {
          main = {
            term = "xterm-256color";
            font = "monospace:size=15";
            dpi-aware = "yes";
          };

          url = { launch = "wl-copy \${url}"; };
          mouse = { hide-when-typing = "yes"; };
          cursor = { color = "000000 ffffff"; };
          colors = {
            alpha = "1.0";
            background = "000000";
            foreground = "ffffff";
          };
        };
      };
      xdg = {
        mimeApps = {
          enable = true;
          defaultApplications = {
            "application/pdf" = "org.pwmt.zathura.desktop";
            "inode/directory" = "emacsclient.desktop";
            "text/plain" = "emacsclient.desktop";
            "text/org" = "emacsclient.desktop";
            "text/x-tex" = "emacsclient.desktop";
            "text/english" = "emacsclient.desktop";
            "text/x-makefile" = "emacsclient.desktop";
            "text/x-c++hdr" = "emacsclient.desktop";
            "text/x-c++src" = "emacsclient.desktop";
            "text/x-chdr" = "emacsclient.desktop";
            "text/x-csrc" = "emacsclient.desktop";
            "text/x-java" = "emacsclient.desktop";
            "text/x-moc" = "emacsclient.desktop";
            "text/x-pascal" = "emacsclient.desktop";
            "text/x-tcl" = "emacsclient.desktop";
            "application/x-shellscript" = "emacsclient.desktop";
            "text/x-c" = "emacsclient.desktop";
            "text/x-c++" = "emacsclient.desktop";
            "x-scheme-handler/mailto" = "emacsclient-mail.desktop";
          };
        };
        configFile = {
          "xournalpp/settings.xml" = {
            source = ./not-nix-config-files/xournalpp-settings.xml;
          };
          "xournalpp/toolbar.ini" = {
            source = ./not-nix-config-files/xournalpp-toolbar.ini;
          };
          "qt5ct/qt5ct.conf" = {
            source = ./not-nix-config-files/xournalpp-toolbar.ini;
          };
          "sway/yc-sticky-keymap" = {
            source = ./not-nix-config-files/sway-yc-sticky-keymap;
          };
          "latexmk/latexmkrc" = { text = ''$pdf_previewer = "zathura"''; };
          "emacs/init.el" = { source = ./not-nix-config-files/emacs-init.el; };
          "yc.sh" = { source = ./not-nix-config-files/bashrc-config.sh; };
          "w3m/bookmark.html" = {
            source = ./not-nix-config-files/w3m-bookmark.html;
          };
          "fuzzel/fuzzel.ini" = {
            text = ''
              [main]
              font=Noto Sans:size=18:weight=bold'';
          };
          "w3m/config" = { source = ./not-nix-config-files/w3m-config; };
          "w3m/keymap" = { source = ./not-nix-config-files/w3m-keymap; };
        };

      };
      programs.password-store = {
        enable = true;
        package = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
        settings = {
          PASSWORD_STORE_GENERATED_LENGTH = "8";
          PASSWORD_STORE_CHARACTER_SET = "[:alnum:].,";
          PASSWORD_STORE_DIR = "$HOME/.password-store";
        };
      };
      programs.waybar = {
        enable = true;
        style = ./not-nix-config-files/waybar-style.css;
        systemd = {
          enable = true;
          target = "sway-session.target";
        };
        settings = {
          mainBar = {
            id = "bar-0";
            idle_inhibitor = {
              format = "{icon}";
              format-icons = {
                activated = "NOLOCK";
                deactivated = "LOCK";
              };
            };
            ipc = true;
            layer = "bottom";
            modules-center = [ "wlr/taskbar" ];
            modules-left = [ "sway/workspaces" "sway/mode" ];
            modules-right = [
              "idle_inhibitor"
              "pulseaudio"
              "network"
              "backlight"
              "battery"
              "clock"
            ];
            position = "bottom";
            network = {
              format = "{ifname}";
              format-disconnected = "";
              format-ethernet = "{ipaddr}/{cidr}";
              format-wifi = "NET";
              max-length = 50;
              tooltip-format = "{ifname} via {gwaddr}";
              tooltip-format-disconnected = "Disconnected";
              tooltip-format-ethernet = "{ifname}";
              tooltip-format-wifi = "{essid} ({signalStrength}%)";
            };
            pulseaudio = {
              format = "VOL {volume}%";
              format-muted = "MUTED";
              on-click = "amixer set Master toggle";
            };
            backlight = {
              device = "intel_backlight";
              format = "BRI {percent}%";
              on-click-right = "brightnessctl set 100%";
              on-click = "brightnessctl set 1%";
              on-scroll-down = "brightnessctl set 1%-";
              on-scroll-up = "brightnessctl set +1%";
            };
            "wlr/taskbar" = {
              active-first = true;
              format = "{name}";
              on-click = "activate";
            };
            battery = { format = "BAT {capacity}%"; };
            clock = { format-alt = "{:%a, %d. %b  %H:%M}"; };
            "sway/workspaces" = {
              disable-scroll-wraparound = true;
              enable-bar-scroll = true;
            };

          };
        };
      };
      services.swayidle = {
        enable = true;
        events = [
          {
            event = "before-sleep";
            command = "${pkgs.swaylock}/bin/swaylock";
          }
          {
            event = "lock";
            command = "lock";
          }
        ];
        timeouts = [
          {
            timeout = 900;
            command = "${pkgs.swaylock}/bin/swaylock -fF";
          }
          {
            timeout = 910;
            command = "systemctl suspend";
          }
        ];
      };
      programs.swaylock.settings = {
        color = "808080";
        font-size = 24;
        indicator-idle-visible = true;
        indicator-radius = 100;
        line-color = "ffffff";
        show-failed-attempts = true;
      };
      wayland.windowManager.sway = {
        enable = true;
        # this package is installed by NixOS
        # not home-manager
        package = null;
        xwayland = false;
        systemdIntegration = true;
        extraConfig = ''
          mode "default" {
           bindsym --no-warn Mod4+Backspace focus mode_toggle
           bindsym --no-warn Mod4+Control+Shift+Space move left
           bindsym --no-warn Mod4+Control+Space move right
           bindsym --no-warn Mod4+Control+b move left
           bindsym --no-warn Mod4+Control+e focus parent; focus right
           bindsym --no-warn Mod4+Control+f move right
           bindsym --no-warn Mod4+Control+n move down
           bindsym --no-warn Mod4+Control+p move up
           bindsym --no-warn Mod4+Shift+Backspace floating toggle
           bindsym --no-warn Mod4+Shift+Space focus left
           bindsym --no-warn Mod4+Space focus right
           bindsym --no-warn Mod4+b focus left
           bindsym --no-warn Mod4+e focus parent
           bindsym --no-warn Mod4+f focus right
           bindsym --no-warn Mod4+f11 fullscreen
           bindsym --no-warn Mod4+k kill
           bindsym --no-warn Mod4+n focus down
           bindsym --no-warn Mod4+o workspace next
           bindsym --no-warn Mod4+p focus up
           bindsym --no-warn Mod4+w move scratchpad
           bindsym --no-warn Mod4+x workspace back_and_forth
           bindsym --no-warn Mod4+y scratchpad show
           bindsym --no-warn Shift+Print exec ${pkgs.grim}/bin/grim
           bindsym --no-warn Mod4+o exec ${pkgs.foot}/bin/foot ${pkgs.tmux}/bin/tmux attach-session
          }

          mode "resize" {
           bindsym --no-warn b resize shrink width 10px
           bindsym --no-warn f resize grow width 10px
           bindsym --no-warn n resize grow height 10px
           bindsym --no-warn p resize shrink height 10px
           bindsym --no-warn Space mode default
          }
          titlebar_padding 1
          titlebar_border_thickness 0
        '';
        config = {
          modes = {
            default = { };
            resize = { };
          };
          seat = {
            "*" = {
              hide_cursor = "when-typing enable";
              xcursor_theme = "Adwaita 48";
            };
          };
          output = {
            DP-1 = { mode = "2560x1440@60Hz"; };
            DP-2 = { mode = "2560x1440@60Hz"; };
          };
          input = {
            "type:keyboard" = (if (config.my.yc.keyboard.enable) then {
              xkb_file = "$HOME/.config/sway/yc-sticky-keymap";
            } else
              { });
            "type:touchpad" = {
              tap = "enabled";
              natural_scroll = "enabled";
              middle_emulation = "enabled";
              scroll_method = "edge";
              pointer_accel = "0.3";
            };
            "1149:8257:Kensington_Kensington_Slimblade_Trackball" = {
              left_handed = "enabled";
              pointer_accel = "1";
            };
          };
          modifier = "Mod4";
          menu = "${pkgs.fuzzel}/bin/fuzzel";
          startup = [{
            command = "systemctl --user restart waybar";
            always = true;
          }];
          terminal =
            "${pkgs.foot}/bin/foot ${pkgs.tmux}/bin/tmux attach-session";
          window = { hideEdgeBorders = "both"; };
          workspaceAutoBackAndForth = true;
          workspaceLayout = "tabbed";
          focus = {
            followMouse = "always";
            # wrapping = "force";
            forceWrapping = true;
          };
          gaps = {
            smartBorders = "no_gaps";
            smartGaps = true;
          };
          bars = [{
            command = "${pkgs.waybar}/bin/waybar";
            id = "bar-0";
            mode = "hide";
            position = "bottom";
          }];
        };
      };
    };
  };
}
