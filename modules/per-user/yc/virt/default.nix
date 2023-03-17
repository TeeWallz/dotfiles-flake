{ config, lib, pkgs, ... }:
with lib;
let cfg = config.my.yc.virt;
in {
  options.my.yc.virt.enable = mkOption {
    type = types.bool;
    default = config.my.yc.enable;
  };
  config = mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = false;
      };
    };
    environment.systemPackages = with pkgs; [ virt-manager ];
  };
}
