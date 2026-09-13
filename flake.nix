{
  description = "Emacs package with prelude + custom configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-prelude = {
      type = "github";
      owner = "bbatsov";
      repo = "prelude";
      ref = "master";
      flake = false;
    };

    libvterm = {
      type = "github";
      owner = "connorfuhrman";
      repo = "vterm-nixpkg-darwin";
      ref = "main";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        ./nix/devshell.nix
        ./nix/overlay.nix
        ./nix/packages.nix
        ./nix/checks.nix
        ./nix/format.nix
      ];
    };
}
