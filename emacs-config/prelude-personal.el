;; Enable mouse mode for terminal
(xterm-mouse-mode)

;; No sounds
(setq ring-bell-function 'ignore)

;; ;; MacOS use option key as Meta
;; (setq mac-command-key-is-meta nil)
;; (setq mac-option-key-is-meta t)

;; Confirm to exit
(add-hook 'kill-emacs-query-functions
          (lambda () (y-or-n-p "Do you really want to exit Emacs? "))
          'append)

;; (package-initialize)
;; (add-to-list `package-archives
;; 	     '("melpa" . "https://melpa.org/packages/") t)

;; (require `package)
;; (unless (package-installed-p 'use-package)
;;   (package-refresh-contents)
;;   (package-install 'use-package))

;; (eval-when-compile
;;   (require 'use-package))

;; ;; envrc global setup
;; (use-package envrc
;;   :ensure t)


;; ================================================
;; C/C++ Development (Prelude + modern Eglot + tree-sitter)
;; ================================================
;; (require 'prelude-c)
;; ;; Prefer tree-sitter modes (Emacs 29+)
;; (when (and (fboundp 'treesit-available-p) (treesit-available-p 'c))
;;   (add-to-list 'major-mode-remap-alist '(c-mode . c-ts-mode))
;;   (add-to-list 'major-mode-remap-alist '(c++-mode . c++-ts-mode)))

;; ;; Auto-start Eglot (built-in LSP client) for C/C++
;; (add-hook 'c-mode-hook 'eglot-ensure)
;; (add-hook 'c++-mode-hook 'eglot-ensure)
;; (add-hook 'c-ts-mode-hook 'eglot-ensure)
;; (add-hook 'c++-ts-mode-hook 'eglot-ensure)

;; ;; Sensible indentation
;; (setq c-basic-offset 4)
;; (setq-default c-default-style "linux")  ; or "k&r", "gnu", etc.


;; ;; ================================================
;; ;; Python Development (Prelude + modern Eglot + tree-sitter)
;; ;; ================================================
;; (require 'prelude-python)

;; ;; Prefer tree-sitter Python mode
;; (when (and (fboundp 'treesit-available-p) (treesit-available-p 'python))
;;   (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))

;; ;; Auto-start Eglot for Python
;; (add-hook 'python-mode-hook 'eglot-ensure)
;; (add-hook 'python-ts-mode-hook 'eglot-ensure)

;; ;; Nice defaults
;; (setq python-indent-offset 4)
;; (setq python-shell-interpreter "python3")

;; ;; auto-format on save with ruff (if you add ruff to PATH)
;; (add-hook 'python-mode-hook (lambda () (add-hook 'before-save-hook #'eglot-format-buffer nil t)))


;; Core editor + smartparens (required before any language modules!)
;; (require 'prelude-editor)
;; (require 'prelude-smartparens)

;; ;; Modern completion / UI
;; (require 'prelude-vertico)     ; or (require 'prelude-ivy) if you prefer
;; (require 'prelude-company)

;; General programming support
;; (require 'prelude-programming)

;; ;; Language-specific modules
;; (require 'prelude-c)
;; (require 'prelude-python)
