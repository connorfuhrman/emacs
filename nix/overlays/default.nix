{ lib, self, inputs, ... }:
# {
#   flake.overlays.default = final: prev: {
#     emacs = final.callPackage ../packages/emacs.nix {
#       inherit (inputs) emacs-prelude;
#       emacs-pkg = if final.stdenv.isDarwin then prev.emacs-macport
#                   else prev.emacs;
#     };
    
#     emacs-nox = final.callPackage ../packages/emacs.nix {
#       inherit (inputs) emacs-prelude;
#       emacs-pkg = prev.emacs-nox;
#     };
#   };
# }
{
  flake.overlays.default = lib.composeManyExtensions [
    inputs.emacs-overlay.overlays.default

    (final: prev: {
      emacs = final.callPackage ../packages/emacs.nix {
        inherit (inputs) emacs-prelude;
        emacs-pkg = if final.stdenv.isDarwin then prev.emacs-macport
                    else prev.emacs;
      };
      emacs-nox = final.callPackage ../packages/emacs.nix {
        inherit (inputs) emacs-prelude;
        emacs-pkg = prev.emacs-nox;
      };
    })
  ];
}
