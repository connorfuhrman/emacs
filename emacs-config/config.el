;;; config.el --- Personal configuration and tweaks -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Personal configuration and tweaks.
;;
;;; Code:

;; Confirm to exit
(add-hook 'kill-emacs-query-functions
          (lambda () (y-or-n-p "Do you really want to exit Emacs? "))
          'append)


(setq prelude-lsp-client 'eglot)

;; Language-specific niceties
(add-hook 'c-mode-common-hook #'eglot-ensure)
(add-hook 'python-mode-hook #'eglot-ensure)
(add-hook 'shell-mode-hook #'eglot-ensure)
(add-hook 'yaml-mode-hook #'eglot-ensure)
(add-hook 'json-mode-hook #'eglot-ensure)
(add-hook 'nix-mode-hook #'eglot-ensure)
(add-hook 'elisp-mode-hook #'eglot-ensure)
(add-hook 'org-mode-hook #'visual-line-mode)

;; (use-package eglot-booster
;;   :after eglot
;;   :config (eglot-booster-mode))

;; Terminal-only optimizations
(unless (display-graphic-p)
  (setenv "COLORTERM" "truecolor")
  (menu-bar-mode -1)
  (tool-bar-mode -1)
  (tooltip-mode -1)
  (xterm-mouse-mode 1)
  (setq inhibit-startup-echo-area-message user-login-name)
  (setq redisplay-dont-pause t)
  (setq scroll-conservatively 1)
  (setq ring-bell-function 'ignore)
  (setq confirm-kill-emacs nil))

;; Run envrc in every buffer
(use-package envrc
  :ensure nil
  :hook (envrc-global-mode))

;; Make C-s a prefix for search commands (overrides default isearch!)
(define-prefix-command 'search-map)
(global-set-key (kbd "C-s") 'search-map)

;; Search methods with helm-ag
;; C-s f  → search current file/buffer
;; C-s p  → search project root (uses .git / projectile / etc.)
(use-package helm-ag
  :ensure nil
  :commands (helm-do-ag-this-file helm-do-ag-project-root)  ; crucial for custom package
  :custom
  (helm-ag-insert-at-point 'symbol)
  ;; Use ripgrep
  (helm-ag-base-command "rg --color=never --no-heading --smart-case")
  :bind
  (("C-s f" . helm-do-ag-this-file)
   ("C-s p" . helm-do-ag-project-root)))

;; vterm settings
(add-hook 'vterm-mode-hook
          (lambda ()
            (local-set-key (kbd "C-y" 'vterm-yank))
            (display-line-numbers-mode -1)))


(setq prelude-whitespace nil)

(with-eval-after-load 'magit-mode
  (add-hook 'after-save-hook #'magit-after-save-refresh-status t))


(use-package dashboard
  :ensure nil
  :config
  ;; Core setup — this makes the dashboard appear on startup
  (dashboard-setup-startup-hook)

  ;; Nice terminal-friendly defaults
  (setq dashboard-banner-logo-title "Emacs")
  (setq dashboard-startup-banner 'official)
  (setq dashboard-center-content t)
  (setq dashboard-vertically-center-content t)

  ;; What to show (customize as you like)
  (setq dashboard-items '((recents   . 5)
                          (bookmarks . 5)
                          (projects  . 5)
                          (agenda    . 5)
                          (registers . 5)))
  
  (setq dashboard-display-icons-p t)
  (setq dashboard-icon-type 'nerd-icons)

  (setq dashboard-set-heading-icons t)
  (setq dashboard-set-file-icons t)

  (setq dashboard-projects-backend 'projectile)

  ;; Refresh automatically when you change config
  (dashboard-refresh-buffer))

(setq initial-buffer-choice 'dashboard-open)

;; For icons to work properly with emacsclient
(add-hook 'server-after-make-frame-hook #'dashboard-open)


(provide 'config)
;;; config.el ends here
