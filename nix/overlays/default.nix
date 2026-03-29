{ lib, self, inputs, ... }:
{
  flake.overlays.default = lib.composeManyExtensions [
    inputs.emacs-overlay.overlays.default
    inputs.libvterm.overlays.default

    (final: prev: {
      emacs = final.callPackage ../packages/emacs.nix {
        inherit (inputs) emacs-prelude;
        inherit (final.cfuhrman) emacs-config;
        emacs-pkg = if final.stdenv.isDarwin then prev.emacs-macport
                    else prev.emacs;
      };
      
      emacs-nox = final.callPackage ../packages/emacs.nix {
        inherit (inputs) emacs-prelude;
        inherit (final.cfuhrman) emacs-config;
        emacs-pkg = prev.emacs-nox;
      };

      emacs-git-nox = final.callPackage ../packages/emacs.nix {
        inherit (inputs) emacs-prelude;
        inherit (final.cfuhrman) emacs-config;
        emacs-pkg = prev.emacs-git-nox;
      };

      emacs-unstable-nox = final.callPackage ../packages/emacs.nix {
        inherit (inputs) emacs-prelude;
        inherit (final.cfuhrman) emacs-config;
        emacs-pkg = prev.emacs-unstable-nox;
      };

      cfuhrman = {
        emacs-config = final.callPackage ../packages/emacsInitDir.nix {
          inherit (inputs) emacs-prelude;
        };
      };
    })
  ];
}
