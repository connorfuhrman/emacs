{ pkgs, ... }:
pkgs.mkShell {
  name = "default";
  packages = with pkgs; [
    go-task
  ];
}
