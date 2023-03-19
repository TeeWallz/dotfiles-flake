{ my, inputs, pkgs, lib, ... }: {
  # load module config to here
  inherit my;
  # Let 'nixos-version --json' know about the Git revision
  # of this flake.
  system.configurationRevision = if (inputs.self ? rev) then
    inputs.self.rev
  else
    throw "refuse to build: git tree is dirty";
  system.stateVersion = "22.11";

  services.emacs = { enable = lib.mkDefault true; };
  programs.neovim = {
    enable = lib.mkDefault true;
    viAlias = true;
    vimAlias = true;
  };

  boot = {
    initrd.kernelModules = [ "i915" ];
    kernelModules = [ "kvm-intel" "kvm-amd" ];
    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "virtio_blk"
        "ehci_pci"
        "nvme"
        "uas"
        "sd_mod"
        "sr_mod"
        "sdhci_pci"
      ];
    };
  };

  environment.systemPackages = with pkgs; [ ];
}
