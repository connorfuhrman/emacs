{ ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      mkEmacsInitCheck =
        emacsPkg: name:
        pkgs.runCommand "emacs-init-check-${name}"
          {
            buildInputs = [
              emacsPkg
              pkgs.cfuhrman.emacs-config
              pkgs.cfuhrman.orgctl
            ];
          }
          ''
            echo "=== Testing ${name} ==="
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            export ORG_STATE_DIRECTORY="$HOME/.org"
            export ORG_DIRECTORIES="$HOME"
            CONFIG_DIR="${pkgs.cfuhrman.emacs-config}"

            # Batch skips init files; load Prelude explicitly.
            ${emacsPkg}/bin/emacs --batch \
              --load "$CONFIG_DIR/early-init.el" \
              --load "$CONFIG_DIR/init.el" \
              --eval '(message "org-config-ok state=%s files=%s"
                        org-config-state-directory
                        (length org-agenda-files))' \
              2>&1 | tee $out

            echo ""
            echo "=== Checking for fatal errors ==="
            if grep -qiE "^(Error:|Debugger entered)" $out; then
              echo "ERROR: Emacs failed to initialize cleanly!"
              exit 1
            fi
            if ! grep -q "org-config: ready" $out; then
              echo "ERROR: org-config did not finish setup"
              exit 1
            fi

            echo "=== orgctl smoke ==="
            ${pkgs.cfuhrman.orgctl}/bin/orgctl path | tee -a $out
            ${pkgs.cfuhrman.orgctl}/bin/orgctl inbox add "check-task" | tee -a $out
            ${pkgs.cfuhrman.orgctl}/bin/orgctl todo list --json | tee -a $out

            echo "=== ${name} passed ==="
          '';
    in
    {
      checks = {
        emacs = mkEmacsInitCheck pkgs.emacs-nox "emacs-nox";
      };
    };
}
