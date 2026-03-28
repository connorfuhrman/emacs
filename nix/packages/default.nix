# packages.nix
{ pkgs
, emacs-prelude
, emacs-pkg
, lib
}:

let
  # Emacs binary that already contains the minimal Prelude core packages
  emacsWithPreludeDeps = (pkgs.emacsPackagesFor emacs-pkg).emacsWithPackages
    (epkgs: with epkgs; [
      magit
      projectile
      company
      flycheck
      which-key
      avy
      crux
      undo-tree
      super-save
      smartparens
      volatile-highlights
      doom-themes
    ]);

  # Runtime CLI tools that Prelude and its modules expect
  preludeTools = with pkgs; [
    git
    ripgrep
    silver-searcher
    fd
    aspell
    aspellDicts.en
  ];

  initDir = pkgs.runCommand "make-emacs-init-dir" { } ''
    mkdir -p $out/

    cp -r ${emacs-prelude}/* $out
    chmod -R u+w $out

    cp -r ${../../emacs-config}/* $out/personal/preload

    mv $out/personal/preload/early-init.el $out/early-init.el
  '';

in
pkgs.writeShellApplication {
  name = "emacs";

  runtimeInputs = [ emacsWithPreludeDeps ] ++ preludeTools;

  text = ''
    exec ${emacsWithPreludeDeps}/bin/emacs \
      --init-directory ${initDir} \
      "$@"
  '';

  meta = with lib; {
    description = "Emacs with custom configuration";
    homepage = "https://github.com/connorfuhrman/emacs";
    # license = licenses.gpl3Plus;
    mainProgram = "emacs";
    platforms = platforms.all;
  };
}
