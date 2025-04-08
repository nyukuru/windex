{
  description = "Windows Image and VM helpers for Nix.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11-small";

  outputs = {nixpkgs, self, ...}: let
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    forAllSystems = func: 
      nixpkgs.lib.genAttrs systems
        (system: (func system nixpkgs.legacyPackages.${system}));

    in {
      packages = forAllSystems (system: pkgs: let
        pkgs' = self.packages.${system};
      in {
        windex-image = pkgs.callPackage ./image/package.nix {inherit (pkgs') virtio-drivers;};
        virtio-drivers = pkgs.callPackage ./image/virtio-drivers.nix {};
        windex-run = pkgs.callPackage ./windex-run/package.nix {};
      });

      nixosModules = forAllSystems (system: pkgs: let
        pkgs' = self.packages.${system};
      in {
        default = self.nixosModules.windex;
        windex = import ./windex.nix {inherit (pkgs') windex-image;};
      });

      devShells = forAllSystems (system: pkgs: {
        default = pkgs.callPackage ./shell.nix {};
      });
    };

}
