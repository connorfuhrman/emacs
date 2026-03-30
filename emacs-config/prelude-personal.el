;; Confirm to exit
(add-hook 'kill-emacs-query-functions
          (lambda () (y-or-n-p "Do you really want to exit Emacs? "))
          'append)


;; Disable line numbers in vterm (and multi-vterm)
(add-hook 'vterm-mode-hook
          (lambda ()
            (display-line-numbers-mode -1)))

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
  (setq display-line-numbers-type nil)
  (setq redisplay-dont-pause t)
  (setq scroll-conservatively 101)
  (setq ring-bell-function 'ignore)
  (setq confirm-kill-emacs nil))

;; Run envrc in every buffer
(envrc-global-mode)

;; (use-package fzf
;;   :ensure nil
;;   :bind ("C-c f" . fzf)
;;   :config
;;   (setq fzf/args "-x --color bw --print-query --margin=1,0 --no-hscroll"
;;         fzf/executable "fzf"
;;         fzf/git-grep-args "-i --line-number %s"
;;         fzf/grep-command "rg --no-heading -nH"
;;         fzf/position-bottom t
;;         fzf/window-height 15))

(use-package fzf
  :ensure nil
  :bind (("C-s " . my/fzf-current-buffer)   ; ← fuzzy lines in THIS buffer
         ;; ("C-s f s" . fzf-grep)                ; ← see below
         ;; ("C-s f p" . fzf-grep-dwim))          ; ← project search
	 )
  :config
  ;; your existing settings (keep the --ansi + rg color ones)
  (setq fzf/args "-x --ansi --color=16,fg+:bright-red,hl:bright-blue,hl+:green,query:blue,prompt:yellow,info:magenta,pointer:bright-yellow,marker:bright-blue,spinner:bright-blue,header:blue --print-query --margin=1,0 --no-hscroll"
        fzf/executable "fzf"
        fzf/git-grep-args "-i --line-number %s"
        fzf/grep-command "rg --no-heading -nH --color=always"
        fzf/position-bottom t
        fzf/window-height 15)

  ;; ← NEW: fzf inside the current buffer
  (defun my/fzf-current-buffer ()
    "Fuzzy search lines in the current buffer with fzf and jump to the match."
    (interactive)
    (let ((lines (split-string (buffer-substring-no-properties (point-min) (point-max)) "\n" t)))
      (fzf-with-entries lines
        (lambda (line)
          (goto-char (point-min))
          (re-search-forward (regexp-quote line) nil t)
          (recenter))))))

;; vterm settings
(add-hook 'vterm-mode-hook
          (lambda ()
            (local-set-key (kbd "C-y" 'vterm-yank))))
