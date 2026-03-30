{
  emacs-base
, emacs-config
, symlinkJoin
, makeWrapper
, ...
}:
symlinkJoin {
  name = "emacs";
  paths = [ emacs-base ];
  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    wrapProgram $out/bin/emacs \
       --add-flags "--init-directory ${emacs-config}"
  '';
}
