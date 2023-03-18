{
  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }@inputs:
    let
      lib = nixpkgs.lib;
      my = import ./my { inherit inputs home-manager lib; };
    in {
      nixosConfigurations = {
        exampleHost = let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in my.lib.mkHost (import ./hosts/exampleHost { inherit system pkgs; });
        qinghe = let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in my.lib.mkHost (import ./hosts/qinghe { inherit system pkgs; });
      };
    };
}
