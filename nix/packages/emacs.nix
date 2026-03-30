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
    for bin in $out/bin/emacs*; do
      if [ -f "$bin" ]; then
        wrapProgram "$bin" \
          --add-flags "--init-directory ${emacs-config}"
      fi
    done
  '';
}
