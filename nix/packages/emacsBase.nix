{
  lib
  # Build tooling
, writeShellApplication
, symlinkJoin
, makeWrapper
  # Emacs packages
, emacs-pkg
, emacsPackagesFor
  # Env dependencies
, git
, ripgrep
, fzf
, fd
, aspell
, aspellDicts
, libvterm
, silver-searcher
, nodePackages
, nixd
, ...
}:
let
  emacsPackages = epkgs: with epkgs; [
    ace-window ag avy browse-kill-ring crux discover-my-major diff-hl
    diminish easy-kill editorconfig expand-region flycheck gist
    git-timemachine git-modes guru-mode hl-todo imenu-anywhere
    projectile magit move-text operate-on-number smartparens smartrep
    super-save undo-tree volatile-highlights which-key zenburn-theme
    zop-to-char rainbow-mode elisp-slime-nav exec-path-from-shell
    rainbow-delimiters web-mode ripgrep code-cells ein elpy
    ob-async ob-ipython ob-tmux ob-deno ob-typescript
    vterm nix-mode yaml-mode helm cmake-mode julia-mode
    envrc doom-themes company multi-vterm helm-xref fzf
    vertico consult orderless marginalia embark
  ];

  emacsWithPackages = (emacsPackagesFor emacs-pkg).emacsWithPackages emacsPackages;

  envPackages = [
    ripgrep
    fzf
    fd
    aspell
    aspellDicts.en
    libvterm
    silver-searcher
    nixd
  ] ++ (with nodePackages; [
    bash-language-server
    yaml-language-server
  ]);

  emacsBin = writeShellApplication {
    name = "emacs";
    runtimeInputs = [ emacsWithPackages ] ++ envPackages;
    text = ''
      ${emacsWithPackages}/bin/emacs "$@"
    '';
  };
  
in
# symlinkJoin {
#   name = "emacs-base";
#   paths = [ emacsWithPackages ];
#   nativeBuildInputs = [ makeWrapper ];

#   postBuild = ''
#     for bin in $out/bin/emacs*; do
#       if [ -f "$bin" ]; then
#         wrapProgram "$bin" \
#           --suffix PATH : ${lib.makeBinPath envPackages}
#       fi
#     done
#   '';
# }
emacsBin
