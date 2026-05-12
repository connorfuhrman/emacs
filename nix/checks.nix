{ ... }:
{
  perSystem = { pkgs, ... }: let
    mkEmacsInitCheck = emacsPkg: name:
      pkgs.runCommand "emacs-init-check-${name}" {
        buildInputs = [ emacsPkg pkgs.cfuhrman.emacs-config ];
      } ''
          echo "=== Testing ${name} ==="
          echo ""

          export HOME="$TMPDIR/home"
          CONFIG_DIR="${pkgs.cfuhrman.emacs-config}"

          # Explicitly load the configuration (required for reliable --batch behavior)
          ${emacsPkg}/bin/emacs --batch \
            --init-directory "$CONFIG_DIR" \
            --load "$CONFIG_DIR/early-init.el" \
            --kill 2>&1 | tee $out

          echo ""
          echo "=== Checking for errors ==="

          if grep -qiE "(error|failed|backtrace|prelude.*error)" $out; then
            echo "ERROR: Emacs failed to initialize cleanly!"
            exit 1
          fi

          echo "=== ${name} passed ==="
        '';
  in
    {
  checks = {
    emacs = mkEmacsInitCheck pkgs.emacs-nox "emacs-nox";
  };
};
}
