# Emacs Nix Package

This holds my personal emacs configuration in a Nix package.
The flake provides packages for emacs which are wrapped in my personal config built off emacs-prelude.
The flake also provides an overlay for these packages which exposes:

- `emacs`: The `pkgs.emacs` package with custom configuration or, on MacOS, `emacs-macport`
- `emacs-nox`: The `pkgs.emacs-nox` package with custom configuration
- `emacs-git-nox`: The `pkgs.emacs-git-nox` package from the `emacs-overlay` with custom configuration
- `emacs-unstable-nox`: The `pkgs.emacs-unstable-nox` package from the `emacs-overlay` with custom configuration
- `emacs-config`: My emacs configuration directory
- `orgctl`: Pure-Elisp CLI for Org todos/notes (agent-friendly)

All Emacs flavors are set up so that they:

- do not download any extra packages
- read the configuration directory from the `emacs-config` package in the Nix store
- have some writable cache in `~/.cache/emacs`
- pull in the customizations in `emacs-config` directory

## Org Mode

See `docs/rfcs/2026-08-02-org-mode-modern-tooling.md` for the full design.

### Environment

| Variable | Meaning |
|----------|---------|
| `ORG_STATE_DIRECTORY` | Inbox, roam, id index, discovery cache (default `~/.org`) |
| `ORG_DIRECTORY` | Alias for `ORG_STATE_DIRECTORY` (compat) |
| `ORG_DIRECTORIES` | Semicolon-separated search roots for `.org` files (default `$HOME`) |

### Discovery

- Every `*.org` file under the search roots is agenda-eligible.
- If a directory contains a file named `.orgignore`, that directory **and all children** are skipped.
- Built-in prune names include `.git`, `node_modules`, `.cache`, `Library`, etc.
- Cache: `$ORG_STATE_DIRECTORY/cache/agenda-files` (refresh with `C-c n r` or `orgctl refresh`).

### Keys (additions)

| Key | Action |
|-----|--------|
| `C-c n f` | Find roam note |
| `C-c n i` | Insert roam link |
| `C-c n c` | Roam capture |
| `C-c n l` | Toggle backlinks |
| `C-c n d` | Daily note |
| `C-c n g` | org-roam-ui graph |
| `C-c n r` | Refresh agenda file discovery |
| `C-c a a` | Super-agenda "Today" |

Prelude still owns `C-c a` / `C-c c` / `C-c l` / `C-c b`.

### orgctl

```bash
orgctl help
orgctl path
orgctl inbox add "Buy milk" --tag @errands --due 2026-08-05
orgctl todo list --state NEXT --json
orgctl todo done ID
orgctl agenda today --json
orgctl search "deadline"
```

Built as pure Elisp on top of `org-element` / `org-id` (no separate Org parser).

## Usage

- on headless servers put `emacs-nox` (and optionally `orgctl`) in the environment
- on desktops:
  - on Linux put `emacs` in the environment
  - on MacOS `emacs` will use `emacs-macport` but the configuration directory can also be used from `emacsplus` from Homebrew which can be installed using `nix-darwin`

```bash
nix build .#emacs-nox
nix build .#orgctl
nix run .#orgctl -- help
```
