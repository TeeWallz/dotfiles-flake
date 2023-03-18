{ config, lib, ... }:
with lib;

let cfg = config.my.fileSystems;
in {
  options.my.fileSystems = {
    datasets = mkOption {
      description = "Set mountpoint for datasets";
      type = types.attrsOf types.str;
      default = { };
    };
    bindmounts = mkOption {
      description = "Set mountpoint for bindmounts";
      type = types.attrsOf types.str;
      default = { };
    };
    efiSystemPartitions = mkOption {
      description = "Set mountpoint for efi system partitions";
      type = types.listOf types.str;
      default = [ ];
    };
    swapPartitions = mkOption {
      description = "Set swap partitions";
      type = types.listOf types.str;
      default = [ ];
    };
  };
  config.fileSystems = mkMerge (mapAttrsToList (dataset: mountpoint: {
    "${mountpoint}" = {
      device = "${dataset}";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
      neededForBoot = true;
    };
  }) cfg.datasets ++ mapAttrsToList (bindsrc: mountpoint: {
    "${mountpoint}" = {
      device = "${bindsrc}";
      fsType = "none";
      options = [ "bind" "X-mount.mkdir" ];
    };
  }) cfg.bindmounts ++ map (esp: {
    "/boot/efis/${esp}" = {
      device = "${config.my.boot.devNodes}/${esp}";
      fsType = "vfat";
      options = [
        "x-systemd.idle-timeout=1min"
        "x-systemd.automount"
        "noauto"
        "nofail"
        "X-mount.mkdir"
      ];
    };
  }) cfg.efiSystemPartitions);
  config.swapDevices = mkDefault (map (swap: {
    device = "${config.my.boot.devNodes}/${swap}";
    discardPolicy = mkDefault "both";
    randomEncryption = {
      enable = true;
      allowDiscards = mkDefault true;
    };
  }) cfg.swapPartitions);
}
