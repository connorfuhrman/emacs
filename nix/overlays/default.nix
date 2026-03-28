# overlays.nix
{ self, inputs, ... }:
{
  flake.overlays.default = final: prev: {
    # THIS IS THE CORRECT PATTERN
    # • Use final.callPackage (never prev.callPackage in an overlay)
    # • Pass the OLD emacs-nox as emacs-pkg so we never recurse
    emacs-nox = final.callPackage ../packages/default.nix {
      inherit (inputs) emacs-prelude;
      emacs-pkg = prev.emacs-nox;   # ← base Emacs comes from the previous overlay layer
    };
  };
}
