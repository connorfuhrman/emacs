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
      # projectile
      # company
      # flycheck
      # which-key
      # avy
      # crux
      # zenburn-theme
      # undo-tree
      # super-save
      # smartparens
      # volatile-highlights
      # Add any other packages you enable via prelude-modules.el
    ]);

  # Runtime CLI tools that Prelude and its modules expect
  preludeTools = with pkgs; [
    git
    ripgrep
    fd
    aspell
    aspellDicts.en
    # Add more language servers / tools here as needed
  ];

in
pkgs.writeShellApplication {
  name = "emacs-nox";

  runtimeInputs = [ emacsWithPreludeDeps ] ++ preludeTools;

  text = ''
    exec ${emacsWithPreludeDeps}/bin/emacs \
      --init-directory ${emacs-prelude} \
      "$@"
  '';

  meta = with lib; {
    description = "Emacs (nox) with Prelude configuration baked in";
    homepage = "https://prelude.emacsredux.com/";
    license = licenses.gpl3Plus;
    mainProgram = "emacs-nox";
    platforms = platforms.all;
  };
}
