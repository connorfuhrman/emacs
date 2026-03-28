# Emacs Nix Package

This holds my personal emacs configuration in a Nix package.
The flake provides packages for emacs which are wrapped in my personal config built off emacs-prelude. 
The flake also provides an overlay for these packages which exposes:
- `emacs`
- `emacs-nox`
as overrides which wrap the configuration
