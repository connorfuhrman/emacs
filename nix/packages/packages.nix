{ self, inputs, ...}:
let
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [ inputs.self.overlays.default ];
  };
in
{
  flake.packages = {
    inherit (pkgs)
      emacs-nox;
  };
}
