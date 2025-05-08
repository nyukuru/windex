{
  description = "Windows Image and VM helpers for Nix.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11-small";

  outputs = {nixpkgs, self, ...}: let

    systems = [
      "x86_64-linux"
    ];

    forAllSystems = func: 
      nixpkgs.lib.genAttrs systems
        (system: (func system nixpkgs.legacyPackages.${system}));

    in {
      packages = forAllSystems (system: pkgs: let
        pkgs' = self.packages.${system};
      in {
        # Final windows image
        windex-image = pkgs.callPackage ./image/windex/package.nix {inherit (pkgs') bootstrap-image autounattended;};

        # Intermediary drive images
        bootstrap-image = pkgs.callPackage ./image/bootstrap/package.nix {inherit (pkgs') win-virtio win-openssh bundle-installer;};

        # Bootstrapping packages
        win-virtio = pkgs.callPackage ./image/bootstrap/win-virtio.nix {};
        win-openssh = pkgs.callPackage ./image/bootstrap/win-openssh.nix {};
        bundle-installer = pkgs.callPackage ./bundle-installer/package.nix {};
        autounattended = pkgs.callPackage ./image/windex/autounattended.nix {};


        # Extra Packages for running the image
        windex-run = pkgs.callPackage ./windex-run/package.nix {};
      });

      nixosModules = {
        default = self.nixosModules.windex;
        windex = import ./windex.nix self.packages;
      };

      devShells = forAllSystems (system: pkgs: {
        default = pkgs.callPackage ./shell.nix {};
      });
    };

}
