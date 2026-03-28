{ pkgs
, emacs-prelude
, emacs-pkg
, lib
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
    envrc doom-themes company sideline-eglot multi-vterm

    vertico consult orderless marginalia embark
  ];
  
  emacsWithPackages = (pkgs.emacsPackagesFor emacs-pkg).emacsWithPackages emacsPackages;

  preludeTools = with pkgs; [
    git
    ripgrep
    silver-searcher
    fd
    aspell
    aspellDicts.en
  ];

  extraTools = with pkgs; [
    libvterm
  ];

  initDir = pkgs.runCommand "emacs-init-dir" { } ''
    mkdir -p $out/

    cp -r ${emacs-prelude}/* $out
    chmod -R u+w $out

    cp -r ${../../emacs-config}/* $out/personal/

    mv $out/personal/early-init.el $out/early-init.el

    sed -i.bak $out/core/prelude-packages.el \
      -e '/package-archives/,/melpa.org\/packages/d' \
      -e 's/(prelude-install-packages)/(message "[Nix Prelude] Package installation & refresh DISABLED - everything provided by Nix")/'

    rm -f $out/core/prelude-packages.el.bak
  '';

in
pkgs.writeShellApplication {
  name = "emacs";
  runtimeInputs = [ emacsWithPackages ] ++ preludeTools ++ extraTools;
  text = ''
    exec ${emacsWithPackages}/bin/emacs \
      --init-directory ${initDir} \
      "$@"
  '';
}
