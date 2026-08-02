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

## LSP IDE (lsp-mode)

This config uses **lsp-mode** (not eglot) as the language server client
(`prelude-lsp-client` = `lsp-mode`). The IDE layer is `emacs-config/lsp-ide.el`:

| Feature | Package / binding |
|---------|-------------------|
| Completions | company + capf + yasnippet |
| Diagnostics | flycheck + lsp-ui sideline |
| Hover docs | lsp-ui-doc (mouse in GUI, cursor in TTY) |
| Peeks | `C-c l .` def, `C-c l ?` refs |
| Breadcrumbs | lsp headerline |
| Inlay hints | `C-c l H` / enabled by default |
| Project tree | treemacs (`C-c T`, `C-c C-t`) |
| Symbols / errors | lsp-treemacs, consult-lsp |
| Debug | dap-mode (`C-c l b` breakpoint, `C-c l z` hydra) |
| Command palette | `C-c l SPC` / `C-c L` pretty-hydra |
| Prefix | `C-c l` (lsp-mode keymap) |

**TRAMP:** remote clients auto-register; file watchers disabled on tramp;
`envrc` reload restarts LSP workspaces so remote direnv PATH/toolchains apply.

**Terminal (Ghostty etc.):** xterm-mouse-mode, truecolor, sideline + bottom docs.

Language servers themselves come from your project env (direnv/nix/devshell),
not from this flake — put `gopls`, `rust-analyzer`, `pyright`, `nil`/`nixd`,
`typescript-language-server`, etc. on PATH.

## Usage

- on headless servers put `emacs-nox` in the environment
- on desktops:
  - on Linux put `emacs` in the environment
  - on MacOS `emacs` will use `emacs-macport` but the configuration directory can also be used from `emacsplus` from Homebrew which can be installed using `nix-darwin`
