{
  runCommand,
  emacs-prelude,
  ...
}:
runCommand "emacs-init-dir" { } ''
  mkdir -p $out/

  cp -r ${emacs-prelude}/* $out
  chmod -R u+w $out

  cp -r ${../emacs-config}/* $out/personal/

  mv $out/personal/early-init.el $out/early-init.el

  sed -i.bak $out/core/prelude-packages.el \
    -e '/package-archives/,/melpa.org\/packages/d' \
    -e 's/(prelude-install-packages)/(message "[Nix Prelude] Package installation & refresh DISABLED - everything provided by Nix")/'

  rm -f $out/core/prelude-packages.el.bak
''
