{
  emacs-pkg
, emacsPackagesFor
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
in
emacsWithPackages
