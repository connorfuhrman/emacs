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
  ...
}:
let
  envPackages = [
    ripgrep
    fzf
    fd
    aspell
    libvterm
    silver-searcher
    nixd
    ncurses
  ]
  ++ (with nodePackages; [
    bash-language-server
    yaml-language-server
  ]);

  aspell = aspellWithDicts (
    d: with d; [
      en
    ]
  );
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
          --suffix PATH : "${lib.makeBinPath envPackages}"
    done
  '';
}
