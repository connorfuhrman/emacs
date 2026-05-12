{ self, inputs, ... }:
{
  perSystem = { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      packages = {
        inherit (pkgs)
          emacs
          emacs-nox
          emacs-git-nox
          emacs-unstable-nox;
        inherit (pkgs.cfuhrman)
          emacs-config;
      };

      _module.args.pkgs = pkgs;
      legacyPackages = pkgs;
    };
}
