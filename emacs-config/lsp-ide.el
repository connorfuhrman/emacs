;;; lsp-ide.el --- Fully featured lsp-mode IDE layer -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; VSCode-jealous IDE experience on top of lsp-mode + lsp-ui + dap-mode.
;; Designed for:
;;   - Ghostty / modern terminals (truecolor, mouse)
;;   - GUI frames (posframe popups, mouse hover docs)
;;   - TRAMP + remote direnv/envrc (server started on remote with remote PATH)
;;
;; Switch from eglot is done via `prelude-lsp-client' = lsp-mode in config.el.

;;; Code:

(require 'cl-lib)

;;; --------------------------------------------------------------------------
;;; Terminal / mouse / Ghostty friendliness
;;; --------------------------------------------------------------------------

(defun lsp-ide--setup-terminal-chrome ()
  "Mouse + truecolor niceties for modern terminals (Ghostty, WezTerm, …)."
  (unless (display-graphic-p)
    (xterm-mouse-mode 1)
    (when (fboundp 'mouse-wheel-mode)
      (mouse-wheel-mode 1))
    (setq mouse-wheel-scroll-amount '(1 ((shift) . 1))
          mouse-wheel-progressive-speed nil
          mouse-yank-at-point t)
    ;; Clickable menu bar items in TTY when menu-bar is on
    (setq tty-menu-open-use-tmm t)))

(lsp-ide--setup-terminal-chrome)

;;; --------------------------------------------------------------------------
;;; Core lsp-mode
;;; --------------------------------------------------------------------------

(use-package lsp-mode
  :ensure nil
  :commands (lsp lsp-deferred lsp-deferred-mode)
  :init
  (setq lsp-keymap-prefix "C-c l")
  :custom
  (lsp-auto-guess-root t)
  (lsp-keep-workspace-alive nil)
  (lsp-idle-delay 0.2)
  (lsp-log-io nil)
  (lsp-completion-provider :capf)
  (lsp-enable-snippet t)
  (lsp-enable-symbol-highlighting t)
  (lsp-enable-links t)
  (lsp-enable-file-watchers t)
  (lsp-file-watcher-ignored-directories
   "[/\\\\]\\(?:\\.git\\|\\.hg\\|\\.bzr\\|\\.svn\\|\\.direnv\\|result\\|node_modules\\|dist\\|build\\|target\\|\\.cache\\|elpa\\|__pycache__\\|\\.mypy_cache\\|\\.tox\\|\\.venv\\|venv\\|\\.stack-work\\)\\'")
  (lsp-headerline-breadcrumb-enable t)
  (lsp-headerline-breadcrumb-segments '(path-up-to-project file symbols))
  (lsp-modeline-code-actions-enable t)
  (lsp-modeline-diagnostics-enable t)
  (lsp-modeline-workspace-status-enable t)
  (lsp-signature-auto-activate t)
  (lsp-signature-render-documentation t)
  (lsp-eldoc-render-all nil)
  (lsp-inlay-hint-enable t)
  (lsp-semantic-tokens-enable t)
  (lsp-lens-enable t)
  (lsp-prefer-flymake nil) ;; flycheck
  ;; TRAMP: start language servers on the remote host
  (lsp-auto-register-remote-clients t)
  :config
  (lsp-enable-which-key-integration t)

  ;; Start LSP after envrc has applied direnv (local and remote)
  (defun lsp-ide--maybe-start ()
    "Start lsp-mode once the buffer has a file and env is ready."
    (when (and buffer-file-name
               (not (file-remote-p buffer-file-name 'localname nil)) ; always ok
               (or (not (fboundp 'envrc-mode))
                   (not (bound-and-true-p envrc-mode))
                   t))
      (lsp-deferred)))

  ;; Prefer deferred start on common language hooks
  (dolist (hook '(c-mode-common-hook
                  c-ts-mode-hook c++-ts-mode-hook
                  python-mode-hook python-ts-mode-hook
                  go-mode-hook go-ts-mode-hook
                  rust-mode-hook rust-ts-mode-hook
                  haskell-mode-hook
                  js-mode-hook js-ts-mode-hook js2-mode-hook
                  typescript-mode-hook typescript-ts-mode-hook tsx-ts-mode-hook
                  sh-mode-hook bash-ts-mode-hook
                  yaml-mode-hook yaml-ts-mode-hook
                  json-mode-hook json-ts-mode-hook
                  nix-mode-hook
                  java-mode-hook
                  julia-mode-hook
                  zig-mode-hook
                  tuareg-mode-hook
                  web-mode-hook
                  conf-mode-hook))
    (add-hook hook #'lsp-deferred))

  ;; After envrc reloads on a remote or local project, bounce LSP so it
  ;; picks up new PATH / virtualenv / toolchain.
  (defun lsp-ide--restart-workspaces (&rest _)
    (when (bound-and-true-p lsp-mode)
      (dolist (ws (lsp-workspaces))
        (ignore-errors (lsp-workspace-restart ws)))))
  (with-eval-after-load 'envrc
    (advice-add 'envrc-allow :after #'lsp-ide--restart-workspaces)
    (advice-add 'envrc-reload :after #'lsp-ide--restart-workspaces))

  ;; TRAMP connection defaults: use remote shell, respect remote direnv
  (with-eval-after-load 'tramp
    (add-to-list 'tramp-remote-path 'tramp-own-remote-path)
    (connection-local-set-profile-variables
     'lsp-ide-remote
     '((lsp-prefer-flymake . nil)
       (lsp-enable-file-watchers . nil) ;; watchers over TRAMP are painful
       (lsp-log-io . nil)))
    (connection-local-set-profiles
     '(:application tramp)
     'lsp-ide-remote))

  :bind (:map lsp-mode-map
              ("C-c l a" . lsp-execute-code-action)
              ("C-c l r" . lsp-rename)
              ("C-c l f" . lsp-format-buffer)
              ("C-c l F" . lsp-format-region)
              ("C-c l o" . lsp-organize-imports)
              ("C-c l h" . lsp-describe-thing-at-point)
              ("C-c l R" . lsp-workspace-restart)
              ("C-c l q" . lsp-workspace-shutdown)
              ("C-c l i" . lsp-find-implementation)
              ("C-c l t" . lsp-find-type-definition)
              ("C-c l x" . lsp-find-references)
              ("C-c l g" . lsp-find-definition)
              ("C-c l j" . lsp-ui-find-next-reference)
              ("C-c l k" . lsp-ui-find-prev-reference)
              ("C-c l I" . lsp-ui-imenu)
              ("C-c l S" . lsp-treemacs-symbols)
              ("C-c l e" . lsp-treemacs-errors-list)
              ("C-c l H" . lsp-inlay-hints-mode)))

;;; --------------------------------------------------------------------------
;;; lsp-ui — peeks, sideline, mouse hover docs
;;; --------------------------------------------------------------------------

(use-package lsp-ui
  :ensure nil
  :after lsp-mode
  :commands lsp-ui-mode
  :custom
  (lsp-ui-doc-enable t)
  (lsp-ui-doc-delay 0.35)
  (lsp-ui-doc-position (if (display-graphic-p) 'at-point 'bottom))
  (lsp-ui-doc-show-with-cursor (not (display-graphic-p)))
  (lsp-ui-doc-show-with-mouse t)
  (lsp-ui-doc-include-signature t)
  (lsp-ui-doc-max-height 24)
  (lsp-ui-doc-max-width 90)
  (lsp-ui-doc-use-childframe (display-graphic-p))
  (lsp-ui-doc-use-webkit nil)
  (lsp-ui-sideline-enable t)
  (lsp-ui-sideline-show-hover t)
  (lsp-ui-sideline-show-diagnostics t)
  (lsp-ui-sideline-show-code-actions t)
  (lsp-ui-sideline-delay 0.2)
  (lsp-ui-sideline-update-mode 'line)
  (lsp-ui-peek-enable t)
  (lsp-ui-peek-always-show t)
  (lsp-ui-peek-show-directory t)
  (lsp-ui-imenu-auto-refresh t)
  :bind (:map lsp-ui-mode-map
              ([remap xref-find-definitions] . lsp-ui-peek-find-definitions)
              ([remap xref-find-references] . lsp-ui-peek-find-references)
              ("C-c l ." . lsp-ui-peek-find-definitions)
              ("C-c l ?" . lsp-ui-peek-find-references)
              ("C-c l m" . lsp-ui-imenu)
              ("C-c l D" . lsp-ui-doc-glance)
              ("C-c l u" . lsp-ui-doc-focus-frame))
  :config
  ;; Mouse: right-click / hover friendly in GUI
  (when (display-graphic-p)
    (define-key lsp-ui-mode-map [mouse-3] #'lsp-mouse-click)
    (setq lsp-ui-doc-border (face-foreground 'vertical-border nil t))))

;;; --------------------------------------------------------------------------
;;; Completions, snippets, diagnostics
;;; --------------------------------------------------------------------------

(use-package yasnippet
  :ensure nil
  :hook ((lsp-mode . yas-minor-mode)
         (prog-mode . yas-minor-mode))
  :config
  (yas-reload-all))

(use-package yasnippet-snippets
  :ensure nil
  :after yasnippet)

(use-package company
  :ensure nil
  :custom
  (company-minimum-prefix-length 1)
  (company-idle-delay 0.05)
  (company-tooltip-align-annotations t)
  (company-tooltip-limit 15)
  (company-show-quick-access t)
  (company-selection-wrap-around t)
  :config
  (global-company-mode 1)
  ;; richer LSP captions
  (with-eval-after-load 'lsp-mode
    (setq company-backends
          (cons 'company-capf (remove 'company-capf company-backends)))))

(use-package flycheck
  :ensure nil
  :init (global-flycheck-mode 1)
  :custom
  (flycheck-indication-mode 'left-fringe)
  (flycheck-display-errors-delay 0.25)
  (flycheck-check-syntax-automatically '(save idle-change mode-enabled))
  (flycheck-idle-change-delay 0.5))

;;; --------------------------------------------------------------------------
;;; Navigation popups (consult-lsp) + treemacs project tree
;;; --------------------------------------------------------------------------

(use-package consult-lsp
  :ensure nil
  :after (lsp-mode consult)
  :bind (:map lsp-mode-map
              ("C-c l s" . consult-lsp-file-symbols)
              ("C-c l w" . consult-lsp-symbols)
              ("C-c l E" . consult-lsp-diagnostics)))

(use-package treemacs
  :ensure nil
  :commands (treemacs treemacs-select-window)
  :custom
  (treemacs-width 32)
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-fringe-indicator-mode 'always)
  (treemacs-hide-gitignored-files-mode t)
  ;; Avoid clashing with vterm on C-c t
  :bind (("C-c C-t" . treemacs)
         ("C-c T" . treemacs)
         ("M-0" . treemacs-select-window)))

(use-package treemacs-projectile
  :ensure nil
  :after (treemacs projectile))

(use-package treemacs-magit
  :ensure nil
  :after (treemacs magit))

(use-package treemacs-nerd-icons
  :ensure nil
  :after treemacs
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package lsp-treemacs
  :ensure nil
  :after (lsp-mode treemacs)
  :config
  (lsp-treemacs-sync-mode 1)
  :bind (:map lsp-mode-map
              ("C-c l T" . lsp-treemacs-call-hierarchy)
              ("C-c l y" . lsp-treemacs-type-hierarchy)))

;;; --------------------------------------------------------------------------
;;; DAP debugging
;;; --------------------------------------------------------------------------

(use-package dap-mode
  :ensure nil
  :after lsp-mode
  :custom
  (dap-auto-configure-features '(sessions locals breakpoints expressions controls tooltip))
  :config
  (dap-auto-configure-mode 1)
  (require 'dap-hydra nil t)
  ;; Language adapters (loaded on demand)
  (with-eval-after-load 'python-mode (require 'dap-python nil t))
  (with-eval-after-load 'go-mode (require 'dap-dlv-go nil t))
  (with-eval-after-load 'rust-mode (require 'dap-gdb-lldb nil t))
  (with-eval-after-load 'cpputils-cmake (require 'dap-lldb nil t))
  :bind (:map lsp-mode-map
              ("C-c l b" . dap-breakpoint-toggle)
              ("C-c l B" . dap-breakpoint-condition)
              ("C-c l c" . dap-continue)
              ("C-c l N" . dap-next)
              ("C-c l v" . dap-ui-inspect-thing-at-point)
              ("C-c l z" . dap-hydra)))

;;; --------------------------------------------------------------------------
;;; Visual polish
;;; --------------------------------------------------------------------------

(use-package posframe
  :ensure nil
  :if (display-graphic-p))

(use-package symbol-overlay
  :ensure nil
  :hook (prog-mode . symbol-overlay-mode)
  :bind (("M-i" . symbol-overlay-put)
         ("M-n" . symbol-overlay-jump-next)
         ("M-p" . symbol-overlay-jump-prev)))

(use-package highlight-indent-guides
  :ensure nil
  :hook (prog-mode . highlight-indent-guides-mode)
  :custom
  (highlight-indent-guides-method (if (display-graphic-p) 'bitmap 'character))
  (highlight-indent-guides-responsive 'top)
  (highlight-indent-guides-auto-enabled t))

(use-package breadcrumb
  :ensure nil
  :config
  ;; Prefer breadcrumb when available; lsp headerline already covers symbols.
  (when (fboundp 'breadcrumb-mode)
    (breadcrumb-mode 1)))

;; GUI mouse popups for code actions
(when (display-graphic-p)
  (with-eval-after-load 'lsp-mode
    (define-key lsp-mode-map [S-down-mouse-1] #'lsp-find-definition-mouse)
    (define-key lsp-mode-map [S-mouse-1] #'ignore)))

;;; --------------------------------------------------------------------------
;;; Hydra control panel (quick IDE actions)
;;; --------------------------------------------------------------------------

(use-package pretty-hydra
  :ensure nil
  :after lsp-mode
  :config
  (pretty-hydra-define lsp-ide-hydra
    (:title "LSP IDE" :color blue :quit-key "q")
    ("Navigate"
     (("g" lsp-ui-peek-find-definitions "def")
      ("r" lsp-ui-peek-find-references "refs")
      ("i" lsp-find-implementation "impl")
      ("t" lsp-find-type-definition "type")
      ("s" consult-lsp-file-symbols "file sym")
      ("S" consult-lsp-symbols "ws sym"))
     "Edit"
     (("a" lsp-execute-code-action "action")
      ("R" lsp-rename "rename")
      ("f" lsp-format-buffer "format")
      ("o" lsp-organize-imports "imports"))
     "View"
     (("d" lsp-ui-doc-glance "doc")
      ("e" lsp-treemacs-errors-list "errors")
      ("m" lsp-ui-imenu "imenu")
      ("T" treemacs "tree")
      ("H" lsp-inlay-hints-mode "inlay"))
     "Debug"
     (("b" dap-breakpoint-toggle "break")
      ("c" dap-continue "cont")
      ("n" dap-next "next")
      ("z" dap-hydra "dap hydra"))))
  (define-key lsp-mode-map (kbd "C-c l SPC") #'lsp-ide-hydra/body)
  (global-set-key (kbd "C-c L") #'lsp-ide-hydra/body))

;;; --------------------------------------------------------------------------
;;; Performance knobs
;;; --------------------------------------------------------------------------

(setq read-process-output-max (* 4 1024 1024) ;; 4MB
      gc-cons-threshold (* 100 1024 1024))

(provide 'lsp-ide)
;;; lsp-ide.el ends here
