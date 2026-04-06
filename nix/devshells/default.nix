{ pkgs, ... }:
pkgs.mkShell {
  name = "default";
  packages = with pkgs; [
    emacsclient-commands
    go-task
  ];
}
