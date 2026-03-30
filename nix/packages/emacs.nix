{
  emacs-base
, emacs-config
, lib
, writeShellApplication
, git
, ripgrep
, fzf
, fd
, aspell
, aspellDicts
, libvterm
, silver-searcher
, nodePackages
, nixd
, ...
}:
let
  extraTools = [
    ripgrep
    fzf
    fd
    aspell
    aspellDicts.en
    libvterm
    silver-searcher
    nixd
  ] ++ (with nodePackages; [
    bash-language-server
    yaml-language-server
  ]);
  
in
writeShellApplication {
  name = "emacs";
  runtimeInputs = [ emacs-base ] ++ extraTools;
  text = ''
    exec ${emacs-base}/bin/emacs \
      --init-directory ${emacs-config} \
      "$@"
  '';
}
