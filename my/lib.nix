{ inputs, lib, ... }: {
  mkHost = { my }:
    let
      system = my.boot.system;
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in lib.nixosSystem {
      inherit system;
      modules = [
        ../modules
        (import ../configuration.nix { inherit my inputs pkgs lib; })
      ];
    };
}
