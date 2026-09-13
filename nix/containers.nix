{
  self,
  inputs,
  lib,
  ...
}:
let
  mkEmacsNoxContainer =
    pkgs: emacsPkg: name:
    pkgs.dockerTools.buildLayeredImage {
      inherit name;
      tag = "latest";
      contents = [
        emacsPkg
        pkgs.bash
        pkgs.coreutils
      ];
      config = {
        Entrypoint = [ "/bin/emacs" ];
        Cmd = [ "-nw" ];
      };
    };
in
{
  perSystem =
    { system, ... }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };
    in
    {
      packages =
        lib.optionalAttrs (lib.hasSuffix "-linux" system) {
          emacs-nox-container = mkEmacsNoxContainer pkgs pkgs.emacs-nox "emacs-nox";
          emacs-unstable-nox-container = mkEmacsNoxContainer pkgs pkgs.emacs-unstable-nox "emacs-unstable-nox";
        };
    };
}
