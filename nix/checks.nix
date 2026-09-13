{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      # Copy the store config to a writable tmpdir. Emacs writes native-comp
      # caches and other files under the init directory, so a read-only
      # /nix/store path makes --init-directory fail.
      mkEmacsInitCheck =
        emacsPkg: name:
        pkgs.runCommand "emacs-init-check-${name}"
          {
            nativeBuildInputs = [
              emacsPkg
              pkgs.coreutils
            ];
          }
          ''
            set -euo pipefail
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            CONFIG_DIR="$TMPDIR/emacs.d"
            cp -R ${pkgs.cfuhrman.emacs-config} "$CONFIG_DIR"
            chmod -R u+w "$CONFIG_DIR"

            ${emacsPkg}/bin/emacs --batch \
              --init-directory "$CONFIG_DIR" \
              --eval "(message \"emacs-init-check-${name}: ok\")" \
              --kill

            touch "$out"
          '';
    in
    {
      checks = {
        emacs = mkEmacsInitCheck pkgs.emacs-nox "emacs-nox";
      };
    };
}
