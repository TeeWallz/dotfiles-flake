{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.yc.firefox;
in {
  options.my.yc.firefox = {
    enable = mkOption {
      type = with types; bool;
      default = config.my.yc.enable;
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ tor-browser-bundle-bin ];
    programs.firefox = {
      enable = true;
      package = pkgs.firefox-esr;
      policies = {
        "3rdparty" = {
          Extensions = {
            "uBlock0@raymondhill.net" = {
              adminSettings = {
                advancedUserEnabled = true;
                dynamicFilteringString = ''
                  behind-the-scene * * noop
                  behind-the-scene * inline-script noop
                  behind-the-scene * 1p-script noop
                  behind-the-scene * 3p-script noop
                  behind-the-scene * 3p-frame noop
                  behind-the-scene * image noop
                  behind-the-scene * 3p noop'';
                hostnameSwitchesString = ''
                  no-large-media: behind-the-scene false
                  no-csp-reports: * true
                  no-scripting: * true
                  no-scripting: isis.tu-berlin.de false
                  no-scripting: moseskonto.tu-berlin.de false
                  no-scripting: meet.jit.si false'';
              };
            };
          };
        };
        # captive portal enabled for connecting to free wifi
        CaptivePortal = true;
        DisableBuiltinPDFViewer = true;
        DisableFirefoxAccounts = true;
        DisableFirefoxStudies = true;
        DisableFormHistory = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DisplayMenuBar = "never";
        DNSOverHTTPS = { Enabled = false; };
        EncryptedMediaExtensions = { Enabled = false; };
        ExtensionSettings = {
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url =
              "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
        };
        FirefoxHome = {
          SponsoredTopSites = false;
          Pocket = false;
          SponsoredPocket = false;
        };
        HardwareAcceleration = true;
        Homepage = { StartPage = "none"; };
        NetworkPrediction = false;
        NewTabPage = false;
        NoDefaultBookmarks = false;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;
        OverrideFirstRunPage = "";
        OverridePostUpdatePage = "";
        PasswordManagerEnabled = false;
        PDFjs = { Enabled = false; };
        Permissions = {
          Location = { BlockNewRequests = true; };
          Notifications = { BlockNewRequests = true; };
        };
        PictureInPicture = { Enabled = false; };
        PopupBlocking = { Default = false; };
        PromptForDownloadLocation = true;
        SanitizeOnShutdown = true;
        SearchSuggestEnabled = false;
        ShowHomeButton = true;
        UserMessaging = {
          WhatsNew = false;
          SkipOnboarding = true;
        };
      };
    };
  };
}
