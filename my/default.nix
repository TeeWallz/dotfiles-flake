{ inputs, lib, ... }: { lib = import ./lib.nix { inherit inputs lib; }; }
