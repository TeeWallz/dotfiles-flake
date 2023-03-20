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

  imports =
    [ "${inputs.nixpkgs}/nixos/modules/installer/scan/not-detected.nix" ];

  environment.systemPackages = with pkgs; [
    mg # emacs-like editor
    busybox # vi-like editor
  ];
}
