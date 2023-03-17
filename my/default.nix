{ inputs, lib, home-manager, ... }: {
  lib = import ./lib.nix { inherit inputs lib home-manager; };
}
