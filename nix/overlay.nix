{ lib, self, inputs, ... }:
let
  mkPackage = pkgs: { emacs-pkg, ...}@args: pkgs.callPackage ./emacs.nix {
    inherit (inputs) emacs-prelude;
    inherit (pkgs.cfuhrman) emacs-config;
    emacs-base = pkgs.callPackage ./emacsBase.nix { inherit emacs-pkg; };
  } // args;
in
{
  flake.overlays.default = lib.composeManyExtensions [
    inputs.emacs-overlay.overlays.default
    inputs.libvterm.overlays.default

    (final: prev: {
      emacs = mkPackage final {
        emacs-pkg = if final.stdenv.isDarwin then prev.emacs-macport
                    else prev.emacs;
      };
      
      emacs-nox = mkPackage final {
        emacs-pkg = prev.emacs-nox;
      };

      emacs-git-nox = mkPackage final {
        emacs-pkg = prev.emacs-git-nox;
      };

      emacs-pgtk = mkPackage final {
        emacs-pkg = prev.emacs-pgtk;
      };
      
      emacs-git-pgtk = mkPackage final {
        emacs-pkg = prev.emacs-git-pgtk;
      };
      
      emacs-macport = mkPackage final {
        emacs-pkg = prev.emacs-macport;
      };

      cfuhrman = {
        emacs-config = final.callPackage ./emacsInitDir.nix {
          inherit (inputs) emacs-prelude;
        };
      };
    })
  ];
}
