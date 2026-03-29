{ 
  emacs-prelude
, emacs-pkg
, emacs-config
, emacsPackagesFor
, lib
, writeShellApplication
, git
, ripgrep
, fd
, aspell
, aspellDicts
, libvterm
, silver-searcher
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
    rainbow-delimiters web-mode

    vterm nix-mode yaml-mode helm cmake-mode julia-mode
    envrc doom-themes company multi-vterm helm-xref

    vertico consult orderless marginalia embark
  ];
  
  emacsWithPackages = (emacsPackagesFor emacs-pkg).emacsWithPackages emacsPackages;

  preludeTools = [
    git
    ripgrep
    fd
    aspell
    aspellDicts.en
  ];

  extraTools = [
    libvterm
    silver-searcher
  ];
in
writeShellApplication {
  name = "emacs";
  runtimeInputs = [ emacsWithPackages ] ++ preludeTools ++ extraTools;
  text = ''
    exec ${emacsWithPackages}/bin/emacs \
      --init-directory ${emacs-config} \
      "$@"
  '';
}
