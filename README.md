# Emacs

<p align="center">
  <a href="https://www.gnu.org/software/emacs/">
    <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/emacs/emacs-original.svg" alt="Emacs" width="96" height="96" />
  </a>
  &nbsp;&nbsp;&nbsp;&nbsp;
  <a href="https://nixos.org/">
    <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/nixos/nixos-original.svg" alt="Nix" width="96" height="96" />
  </a>
</p>

<p align="center">
  <strong>Personal Emacs configuration, packaged as a Nix flake on top of
  <a href="https://github.com/bbatsov/prelude">Emacs Prelude</a>.</strong>
</p>

<p align="center">
  <a href="https://www.gnu.org/software/emacs/">
    <img src="https://img.shields.io/badge/Emacs-30+-7F5AB6?style=for-the-badge&logo=gnuemacs&logoColor=white" alt="Emacs 30+" />
  </a>
  <a href="https://nixos.org/">
    <img src="https://img.shields.io/badge/Nix-flake-5277C3?style=for-the-badge&logo=nixos&logoColor=white" alt="Nix flake" />
  </a>
  <a href="https://github.com/bbatsov/prelude">
    <img src="https://img.shields.io/badge/base-Prelude-orange?style=for-the-badge" alt="Prelude" />
  </a>
  <a href="https://github.com/nix-community/emacs-overlay">
    <img src="https://img.shields.io/badge/emacs--overlay-enabled-blue?style=for-the-badge" alt="emacs-overlay" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-personal-lightgrey?style=for-the-badge" alt="personal config" />
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Linux-black?style=flat-square&logo=linux&logoColor=white" alt="Linux" />
  <img src="https://img.shields.io/badge/platform-macOS-black?style=flat-square&logo=apple&logoColor=white" alt="macOS" />
  <img src="https://img.shields.io/badge/packages-Nix%20store%20only-5277C3?style=flat-square&logo=nixos&logoColor=white" alt="Nix store packages" />
  <img src="https://img.shields.io/badge/markdown-Obsidian--like%20visuals-7C3AED?style=flat-square" alt="Markdown visuals" />
</p>

---

## What this is

A Nix-packaged Emacs with personal config based on **Emacs Prelude**. The flake
exposes ready-to-run Emacs binaries and an overlay. 

| Attribute | Description |
|-----------|-------------|
| `emacs` | GUI Emacs (`emacs-macport` on macOS, `emacs` on Linux) |
| `emacs-nox` | Terminal Emacs |
| `emacs-git-nox` | `emacs-git-nox` from [emacs-overlay](https://github.com/nix-community/emacs-overlay) |
| `emacs-unstable-nox` | `emacs-unstable-nox` from emacs-overlay |
| `emacs-config` | Init directory (Prelude + `emacs-config/`) |

Every flavor:

- does **not** download extra ELPA/MELPA packages at startup
- uses `--init-directory` pointing at the immutible ‘nix/store/‘ config
- keeps writable state under `~/.cache/emacs`
- loads customizations from `emacs-config/`

---

## Quick start

```bash
# Build (from this repo)
nix build .#emacs          # GUI
nix build .#emacs-nox      # terminal

# Run
./result/bin/emacs

# Or add via overlay / nix profile / home-manager / nix-darwin
```

### Usage by host

| Host | Package |
|------|---------|
| Headless servers | `emacs-nox` |
| Linux desktop | `emacs` |
| macOS | `emacs` → `emacs-macport` (config also works with Homebrew `emacs-plus` via nix-darwin) |

---

## Repo Layout

```
.
├── emacs-config/          # personal Prelude config (loaded from store)
│   ├── early-init.el      # writable cache dirs under ~/.cache/emacs
│   ├── config.el
│   ├── markdown-config.el
│   ├── org-config.el
│   └── prelude-modules.el
├── docs/
│   └── markdown.md        # Markdown visuals docs
├── nix/                   # flake modules (packages, overlay, checks, fmt)
├── flake.nix
└── README.md
```

---

## Inputs

| Input | Role |
|-------|------|
| [nixpkgs](https://github.com/NixOS/nixpkgs) | Package set |
| [emacs-overlay](https://github.com/nix-community/emacs-overlay) | Extra Emacs builds |
| [prelude](https://github.com/bbatsov/prelude) | Base Emacs config |
| [flake-parts](https://github.com/hercules-ci/flake-parts) | Flake structure |
| [treefmt-nix](https://github.com/numtide/treefmt-nix) | Formatting |
