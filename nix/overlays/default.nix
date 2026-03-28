# overlays.nix
{ self, inputs, ... }:
{
  flake.overlays.default = final: prev: {
    emacs-nox = final.callPackage ../packages/emacs.nix {
      inherit (inputs) emacs-prelude;
      emacs-pkg = prev.emacs-nox;
    };
  };
}
