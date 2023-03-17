{ config, lib, ... }:
with lib;

let
  cfg = config.my.users;
  userOpts = { name, config, ... }: {
    options = {
      initialHashedPassword = mkOption {
        type = with types; nullOr (passwdEntry str);
        default = null;
      };
      authorizedKeys = mkOption {
        type = types.listOf types.singleLineStr;
        default = [ ];
      };
      description = mkOption {
        type = types.passwdEntry types.str;
        default = "";
        example = "Alice Q. User";
      };
      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
      };
      group = mkOption {
        type = types.str;
        default = "";
      };
      isSystemUser = mkOption {
        type = types.bool;
        default = false;
      };
      isNormalUser = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
in {
  options.my.users = mkOption {
    default = { };
    type = with types; attrsOf (submodule userOpts);
    example = {
      root = {
        initialHashedPassword = null;
        authorizedKeys = [ ];
      };
    };
  };
  config = {
    security = {
      doas.enable = true;
      sudo.enable = false;
    };
    home-manager.users = listToAttrs (map (u: {
      name = u;
      value = {
        home = {
          username = "${u}";
          homeDirectory = "/home/${u}";
          stateVersion = "22.11";
        };
        programs.home-manager.enable = true;
      };
    }) (attrNames cfg));
    users.mutableUsers = false;
    users.users = listToAttrs (map (u: {
      name = u;
      value = {
        inherit (cfg."${u}")
          initialHashedPassword extraGroups packages isSystemUser isNormalUser;
        openssh.authorizedKeys.keys = cfg."${u}".authorizedKeys;
        description = if (u == "root") then
          "System administrator"
        else
          cfg."${u}".description;
      };
    }) (attrNames cfg));
  };
}
