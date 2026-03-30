;; Confirm to exit
(add-hook 'kill-emacs-query-functions
          (lambda () (y-or-n-p "Do you really want to exit Emacs? "))
          'append)


;; Disable line numbers in vterm (and multi-vterm)
(add-hook 'vterm-mode-hook
          (lambda ()
            (display-line-numbers-mode -1)))   ; modern Emacs

;; Force Eglot (Prelude’s default since ~2024) and kill any leftover lsp-mode
(setq prelude-lsp-client 'eglot)   ; explicit, though default now

;; Language-specific niceties
(add-hook 'c-mode-common-hook #'eglot-ensure)
(add-hook 'python-mode-hook #'eglot-ensure)
(add-hook 'shell-mode-hook #'eglot-ensure)
(add-hook 'yaml-mode-hook #'eglot-ensure)
(add-hook 'json-mode-hook #'eglot-ensure)
(add-hook 'nix-mode-hook #'eglot-ensure)
(add-hook 'elisp-mode-hook #'eglot-ensure)
(add-hook 'org-mode-hook #'visual-line-mode)

(use-package eglot-booster
  :after eglot
  :config (eglot-booster-mode))

;; Terminal-only optimizations
(unless (display-graphic-p)
  (setenv "COLORTERM" "truecolor")
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (tooltip-mode -1)
  (xterm-mouse-mode 1)
  (setq ring-bell-function 'ignore)
  (setq confirm-kill-emacs nil))

;; Faster terminal rendering
(setq inhibit-startup-echo-area-message user-login-name)
(setq display-line-numbers-type nil)

;; Blazing-fast terminal rendering
(setq redisplay-dont-pause t)
(setq scroll-conservatively 101)

;; Run envrc in every buffer
(envrc-global-mode)

(use-package fzf
  :ensure nil
  ;; :bind
  ;;   ;; Don't forget to set keybinds!
  :config
  (setq fzf/args "-x --color bw --print-query --margin=1,0 --no-hscroll"
        fzf/executable "fzf"
        fzf/git-grep-args "-i --line-number %s"
        fzf/grep-command "rg --no-heading -nH"
        fzf/position-bottom t
        fzf/window-height 15))

;; vterm settings
(add-hook 'vterm-mode-hook
          (lambda ()
            (local-set-key (kbd "C-y" 'vterm-yank))))
