{ pkgs, ... }:
pkgs.mkShellNoCC {
  name = "default";
  packages = with pkgs; [
    go-task
  ];
}
