# flake.nix
{
  description = "Emacs Prelude (nox) – proper overlay that overrides emacs-nox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    emacs-prelude = {
      type = "github";
      owner = "bbatsov";
      repo = "prelude";
      ref = "master";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      imports = [
        ./nix/overlays/default.nix
        ./nix/packages/packages.nix
      ];

      perSystem = { system, ... }:
        # let
        #   pkgs = import inputs.nixpkgs {
        #     inherit system;
        #     overlays = [ inputs.self.overlays.default ];
        #   };
        # in {
        #   # Now pkgs.emacs-nox is the Prelude-wrapped version
        #   packages.emacs-nox = pkgs.emacs-nox;
        #   devShells = import ./nix/devshells/devshells.nix { inherit pkgs; };
        # };
        {
          inherit (inputs.self)
            packages;
        };
    };
}
