{
  lib,
  self,
  inputs,
  ...
}:
let
  mkPackage =
    pkgs:
    { emacs-pkg, ... }@args:
    pkgs.callPackage ./emacs.nix {
      inherit (inputs) emacs-prelude;
      inherit (pkgs.cfuhrman) emacs-config;
      emacs-base = pkgs.callPackage ./emacsBase.nix { inherit emacs-pkg; };
    };

  emacsVariantSpecs = [
    {
      name = "emacs";
      getPkg = final: prev: if final.stdenv.isDarwin then prev.emacs-macport else prev.emacs;
    }
    {
      name = "emacs-nox";
      getPkg = final: prev: prev.emacs-nox;
    }
    {
      name = "emacs-git-nox";
      getPkg = final: prev: prev.emacs-git-nox;
    }
    {
      name = "emacs-pgtk";
      getPkg = final: prev: prev.emacs-pgtk;
    }
    {
      name = "emacs-git-pgtk";
      getPkg = final: prev: prev.emacs-git-pgtk;
    }
    {
      name = "emacs-macport";
      getPkg = final: prev: prev.emacs-macport;
    }
    {
      name = "emacs-unstable";
      getPkg = final: prev: prev.emacs-unstable;
    }
    {
      name = "emacs-unstable-nox";
      getPkg = final: prev: prev.emacs-unstable-nox;
    }
  ];
in
{
  flake.overlays.default = lib.composeManyExtensions [
    inputs.emacs-overlay.overlays.default
    inputs.libvterm.overlays.default

    (
      final: prev:
      {
        cfuhrman = {
          emacs-config = final.callPackage ./emacsInitDir.nix {
            inherit (inputs) emacs-prelude;
          };
        };
      }
      // lib.listToAttrs (
        map (spec: {
          name = spec.name;
          value = mkPackage final {
            emacs-pkg = spec.getPkg final prev;
          };
        }) emacsVariantSpecs
      )
    )
  ];
}
