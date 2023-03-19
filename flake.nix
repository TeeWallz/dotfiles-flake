{
  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    # stable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    home-manager.url = "github:nix-community/home-manager/release-22.11";

    # unstable
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # home-manager.url = "github:nix-community/home-manager";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }@inputs:
    let
      lib = nixpkgs.lib;
      my = import ./my { inherit inputs home-manager lib; };
    in {
      nixosConfigurations = {
        exampleHost = let
          # if aarch64, change to aarch64-linux
          # check with "uname -m" command
          system = "systemType_placeholder";
          pkgs = nixpkgs.legacyPackages.${system};
        in my.lib.mkHost (import ./hosts/exampleHost { inherit system pkgs; });
        qinghe = let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in my.lib.mkHost (import ./hosts/qinghe { inherit system pkgs; });
        tieling = let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in my.lib.mkHost (import ./hosts/tieling { inherit system pkgs; });
      };
    };
}
