{ pkgs, ... }:
let
  python = pkgs.python3.withPackages (ps: with ps; [
    python-lsp-server
  ]);
in
pkgs.mkShellNoCC {
  name = "emacs-python-ide";
  packages = [ python ] ++ (with pkgs; [ emacs-nox ]);
}
