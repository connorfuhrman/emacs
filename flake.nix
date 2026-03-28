# flake.nix
{
  description = "Emacs Prelude (nox) – proper overlay that overrides emacs-nox";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # Your Prelude source (pin to a commit + add sha256 for reproducibility)
    emacs-prelude = {
      type = "github";
      owner = "bbatsov";
      repo = "prelude";
      ref = "master";   # ← change to a specific commit when you want stability
      # sha256 = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      imports = [
        ./nix/overlays/default.nix
        # ./nix/packages/default.nix
      ];

      # === THIS IS THE PART THAT WAS MISSING ===
      # flake-parts does NOT automatically apply flake.overlays.default to perSystem.pkgs
      # We must build a custom pkgs that includes our overlay.
      perSystem = { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [ inputs.self.overlays.default ];
          };
        in {
          # Now pkgs.emacs-nox is the Prelude-wrapped version
          packages.emacs-nox = pkgs.emacs-nox;
        };
    };
}
