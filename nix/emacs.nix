{
  lib,
  emacs-base,
  emacs-config,
  symlinkJoin,
  makeWrapper,
  git,
  ripgrep,
  fzf,
  fd,
  aspellWithDicts,
  libvterm,
  silver-searcher,
  nodePackages,
  nixd,
  ncurses,
  pandoc,
  enchant,
  hunspell,
  hunspellDicts,
  glow,
  grip,
  stdenv,
  ...
}:
let
  aspell = aspellWithDicts (
    d: with d; [
      en
    ]
  );

  hunspellWithDicts = hunspell.withDicts (
    d: with d; [
      en_US
    ]
  );

  envPackages = [
    ripgrep
    fzf
    fd
    aspell
    libvterm
    silver-searcher
    nixd
    ncurses
    # Markdown visuals / preview toolchain
    pandoc
    enchant
    hunspellWithDicts
    glow
  ]
  # grip is Linux-only in nixpkgs; grip-mode still works if grip is on PATH.
  ++ lib.optional stdenv.hostPlatform.isLinux grip
  ++ (with nodePackages; [
    bash-language-server
    yaml-language-server
  ]);
in
symlinkJoin {
  name = "emacs";
  paths = [ emacs-base ];
  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    for bin in $out/bin/emacs $out/bin/emacs-*; do
       echo "Wrapping program $bin"
       wrapProgram "$bin" \
          --add-flags "--init-directory ${emacs-config}" \
          --suffix PATH : "${lib.makeBinPath envPackages}" \
          --prefix DICPATH : "${hunspellDicts.en_US}/share/hunspell"
    done
  '';
}
