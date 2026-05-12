{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      emacs = inputs.nixpkgs.legacyPackages.${system}.emacs-nox;

      formatElisp = pkgs.writeShellApplication {
        name = "format-elisp";
        runtimeInputs = [ emacs ];
        text = ''
          set -euo pipefail
          for f in "$@"; do
            ${emacs}/bin/emacs --batch \
              --eval "(setq indent-tabs-mode nil)" \
              --eval "(setq lisp-indent-offset 2)" \
              --eval "(find-file \"$f\")" \
              --eval "(when (or (derived-mode-p 'emacs-lisp-mode) (derived-mode-p 'lisp-mode)) (indent-region (point-min) (point-max)))" \
              --eval "(save-buffer)" \
              --kill
          done
        '';
      };
    in
    {
      treefmt = {
        projectRootFile = "flake.nix";

        programs.nixfmt.enable = true;

        settings.formatter.elisp = {
          command = formatElisp;
          includes = [
            "**/*.el"
            "**/*.eld"
            "**/*.el.in"
          ];
        };
      };
    };
}
