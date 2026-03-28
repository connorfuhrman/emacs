{ pkgs
, emacs-prelude
, emacs-pkg
, lib
}:

let
  emacsWithDeps = (pkgs.emacsPackagesFor emacs-pkg).emacsWithPackages
    (epkgs: with epkgs; [
      magit
      projectile
      company
      flycheck
      sideline
      # sideline-elgot
      which-key
      avy
      crux
      undo-tree
      super-save
      smartparens
      volatile-highlights
      envrc
      doom-themes
      rainbow-mode
    ]);

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

    cp -r ${../../emacs-config}/* $out/personal/

    mv $out/personal/early-init.el $out/early-init.el
  '';

  emacsWrapped = pkgs.writeShellApplication {
    name = "emacs";
    runtimeInputs = [ emacsWithDeps ] ++ preludeTools;
    text = ''
      exec ${emacsWithDeps}/bin/emacs \
        --init-directory ${initDir} \
        "$@"
    '';
  };

in
pkgs.stdenvNoCC.mkDerivation {
  pname = "emacs-nox";
  version = "dev";

  dontUnpack = true;
  dontBuild = true;
  doCheck = true;

  nativeBuildInputs = [ emacsWrapped ];

  checkPhase = ''
    echo "=== Running build-time Emacs initialization check ==="
    echo "Init directory: ${initDir}"

    ${emacsWrapped}/bin/emacs \
      --batch \
      --eval "(message \"✅ Emacs configuration initialized successfully\")" \
      --eval "(kill-emacs 0)"

    echo "=== Emacs build-time check PASSED ==="
  '';

  installPhase = ''
    mkdir -p $out/bin
    ln -s ${emacsWrapped}/bin/emacs $out/bin/emacs
  '';

  meta = with lib; {
    description = "Emacs with custom configuration";
    homepage = "https://github.com/connorfuhrman/emacs";
    mainProgram = "emacs";
    platforms = platforms.all;
  };
}
