{ pkgs, ... }:
pkgs.mkShellNoCC {
  name = "emacs-c-ide";

  packages = with pkgs; [
    emacs-nox
    clang-tools
    clang
    cmake
  ];
}
