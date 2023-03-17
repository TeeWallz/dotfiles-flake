{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

  outputs = { self, nixpkgs }@inputs:
    let
      my = import ./my {
        inherit inputs;
        lib = inputs.nixpkgs.lib;
      };
      inherit (my) lib;
    in {
      nixosConfigurations = {
        exampleHost = let
          system = "x86_64-linux";
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in my.lib.mkHost (import ./hosts/exampleHost { inherit system pkgs; });
        qinghe = let
          system = "x86_64-linux";
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in my.lib.mkHost (import ./hosts/qinghe { inherit system pkgs; });
      };
    };
}
