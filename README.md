# Emacs Nix Package

This holds my personal emacs configuration in a Nix package.
The flake provides packages for emacs which are wrapped in my personal config built off emacs-prelude. 
The flake also provides an overlay for these packages which exposes:
- `emacs`: The `pkgs.emacs` package with custom configuration or, on MacOS, `emacs-macport`
- `emacs-nox`: The `pkgs.emacs-nox` package with custom configuration
- `emacs-git-nox`: The `pkgs.emacs-git-nox` package from the `emacs-overlay` with custom configuration
- `emacs-unstable-nox`: The `pkgs.emacs-unstable-nox` package from the `emacs-overlay` with custom configuration
- `emacs-config`: My emacs configuration directory

All Emacs flavors are set up so that they:
- do not download any extra packages
- read the configuration directory from the `emacs-config` package in the Nix store
- have some writable cache in `~/.cache/emacs`
- pull in the customizations in `emacs-config` directory

Usage: 
- on headless servers put `emacs-nox` in the environment
- on desktops:
  - on Linux put `emacs` in the environment
  - on MacOS `emacs` will use `emacs-macport` but the configuration directory can also be used from `emacsplus` from Homebrew which can be installed using `nix-darwin`
