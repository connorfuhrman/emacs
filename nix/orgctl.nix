{
  lib,
  writeShellApplication,
  emacs-base,
  ...
}:
let
  # Elisp modules live next to the personal config; copy path into the store.
  orgLisp = ../emacs-config/org;
in
writeShellApplication {
  name = "orgctl";
  runtimeInputs = [ emacs-base ];
  text = ''
    # Pure-Elisp CLI. Uses the Nix-wrapped Emacs (packages on load-path) without
    # booting Prelude — org-agent loads org-element / org-id / optional org-ql.
    export EMACS_ORGCTL=1
    exec emacs --batch \
      --eval "(add-to-list 'load-path \"${orgLisp}\")" \
      --load "${orgLisp}/org-agent.el" \
      --funcall orgctl-main \
      -- "$@"
  '';
}
