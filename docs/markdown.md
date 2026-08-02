# Markdown visuals (Obsidian-like chrome)

<p align="left">
  <img src="https://img.shields.io/badge/mode-gfm--mode-blue?style=flat-square" alt="gfm-mode" />
  <img src="https://img.shields.io/badge/markup-hidden-7C3AED?style=flat-square" alt="hidden markup" />
  <img src="https://img.shields.io/badge/focus-olivetti%20%2B%20mixed--pitch-pink?style=flat-square" alt="focus mode" />
</p>

`.md` files open in `gfm-mode` with a reading-view feel while you edit:

- hidden markup / URLs
- scaled headings and Unicode list bullets
- native code-block fontification
- `==highlight==`, math, task checkboxes, tables
- inline images (local + remote)

**Visuals only** — no vault, wiki-link graph, or LSP.

| Key | Action |
|-----|--------|
| `C-c m p` | **Live preview in an Emacs side window** (glow / eww, auto-refresh) |
| `C-c m e` | Built-in `markdown-live-preview-mode` (pandoc → eww) |
| `C-c m b` | External browser preview (impatient-showdown) |
| `C-c m g` | GitHub-style browser preview via grip (Nix `python3Packages.grip`) |
| `C-c m f` | Focus / writing mode (olivetti + mixed-pitch) |
| `C-c m m` | Toggle markup hiding |
| `C-c m i` | Toggle inline images |
| `C-c '` | Edit fenced code block in its native major mode |

`C-c m p` prefers [glow](https://github.com/charmbracelet/glow) for a
terminal-native render, and falls back to pandoc → shr/eww. Force a
backend with `(setq markdown-config-preview-backend 'glow)` or `'eww`.

Set `(setq markdown-config-focus-on-entry t)` in personal config to enter
focus mode automatically when opening Markdown files.

Config lives in [`emacs-config/markdown-config.el`](../emacs-config/markdown-config.el).

## Try it on this branch

```bash
git checkout markdown
nix build .#emacs-nox   # or .#emacs on a GUI host
./result/bin/emacs README.md
# then:
#   C-c m p   live preview in a side window (glow/eww, refreshes as you type)
#   C-c m f   focus mode
#   C-c m m   toggle markup hiding
```
