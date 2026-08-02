;;; markdown-config.el --- Obsidian-like Markdown visuals -*- lexical-binding: t; -*-
;;
;;; Commentary:
;;
;; Visual-only Markdown polish inspired by Obsidian's editor chrome.
;; No vault integration, wiki-link navigation, backlinks, or LSP.
;;
;;   - GFM with hidden markup, scaled headings, native code fontification
;;   - ==highlight==, math, task checkboxes, tables, inline images
;;   - Focus writing mode (olivetti + mixed-pitch)
;;   - Soft wrap, typographic quotes, emoji, jinx spell-check
;;   - Optional rendered previews (browser / eww / glow)
;;
;; Keys (markdown / gfm buffers):
;;
;;   C-c m f       toggle focus mode (olivetti + mixed-pitch)
;;   C-c m m       toggle markup hiding
;;   C-c m i       toggle inline images
;;   C-c m p       impatient live browser preview
;;   C-c m g       grip-mode preview (needs grip on PATH)
;;   C-c m w       glow terminal preview
;;   C-c C-c l     side-by-side eww live preview
;;   C-c C-x C-f   toggle native code-block fontification
;;   C-c '         edit fenced code block in native major mode
;;
;;; Code:

(eval-when-compile
  (require 'use-package))


;;; Core markdown-mode / gfm-mode — display polish

(use-package markdown-mode
  :ensure nil
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'" . gfm-mode)
         ("\\.markdown\\'" . gfm-mode)
         ("\\.mdx\\'" . gfm-mode))
  :init
  (setq markdown-command
        (cond
         ((executable-find "pandoc")
          '("pandoc" "--from=gfm" "--to=html5" "--standalone" "--mathjax"))
         ((executable-find "markdown") "markdown")
         (t "pandoc")))
  :custom
  ;; Live-preview feel while editing
  (markdown-hide-markup t)
  (markdown-hide-urls t)
  (markdown-fontify-code-blocks-natively t)
  (markdown-fontify-whole-heading-line t)
  (markdown-header-scaling t)
  (markdown-header-scaling-values '(1.8 1.5 1.3 1.15 1.05 1.0))
  (markdown-marginalize-headers nil)
  (markdown-list-item-bullets '("•" "◦" "▪" "▫" "▸" "▹"))
  (markdown-hr-display-char "─")
  (markdown-blockquote-display-char "┃")

  ;; Syntax highlighting extras (display only)
  (markdown-enable-highlighting-syntax t) ; ==highlight==
  (markdown-enable-math t)
  (markdown-enable-html t)

  ;; GFM chrome
  (markdown-gfm-use-electric-backquote t)
  (markdown-make-gfm-checkboxes-buttons t)
  (markdown-gfm-uppercase-checkbox nil)
  (markdown-indent-on-enter 'indent-and-new-item)
  (markdown-list-indent-width 2)
  (markdown-asymmetric-header t)
  (markdown-italic-underscore nil)
  (markdown-special-ctrl-a/e t)

  ;; Images
  (markdown-display-remote-images t)
  (markdown-max-image-size '(800 . 600))

  ;; eww side-by-side preview layout
  (markdown-split-window-direction 'right)
  (markdown-live-preview-delete-export 'delete-on-export)

  (markdown-nested-imenu-heading-index t)
  :bind (:map markdown-mode-map
              ("C-c m f" . markdown-config-toggle-focus)
              ("C-c m m" . markdown-toggle-markup-hiding)
              ("C-c m i" . markdown-toggle-inline-images)
              ("C-c m p" . markdown-config-live-preview)
              ("C-c m g" . grip-mode)
              ("C-c m w" . markdown-config-glow-preview)
              ("C-c m s" . jinx-correct)
              :map gfm-mode-map
              ("C-c m f" . markdown-config-toggle-focus)
              ("C-c m m" . markdown-toggle-markup-hiding)
              ("C-c m i" . markdown-toggle-inline-images)
              ("C-c m p" . markdown-config-live-preview)
              ("C-c m g" . grip-mode)
              ("C-c m w" . markdown-config-glow-preview)
              ("C-c m s" . jinx-correct))
  :hook ((markdown-mode . markdown-config--buffer-setup)
         (gfm-mode . markdown-config--buffer-setup)))

(defun markdown-config--buffer-setup ()
  "Buffer-local visual niceties for Markdown editing."
  (visual-line-mode 1)
  (variable-pitch-mode -1) ; mixed-pitch owns this when focus is on
  (when (fboundp 'emojify-mode)
    (emojify-mode 1))
  (when (fboundp 'jinx-mode)
    (jinx-mode 1))
  (when (fboundp 'typo-mode)
    (typo-mode 1))
  (when (fboundp 'adaptive-wrap-prefix-mode)
    (adaptive-wrap-prefix-mode 1))
  (auto-fill-mode -1)
  (setq-local fill-column 88)
  (setq-local word-wrap t))


;;; Focus / writing mode

(use-package olivetti
  :ensure nil
  :commands (olivetti-mode)
  :custom
  (olivetti-body-width 88)
  (olivetti-minimum-body-width 40)
  (olivetti-style nil))

(use-package mixed-pitch
  :ensure nil
  :commands (mixed-pitch-mode)
  :custom
  (mixed-pitch-set-height t)
  (mixed-pitch-fixed-pitch-faces
   '(diff-added
     diff-context
     diff-file-header
     diff-function
     diff-header
     diff-hunk-header
     diff-removed
     font-lock-comment-face
     font-lock-comment-delimiter-face
     font-lock-constant-face
     font-lock-doc-face
     font-lock-function-name-face
     font-lock-keyword-face
     font-lock-negation-char-face
     font-lock-preprocessor-face
     font-lock-regexp-grouping-backslash
     font-lock-regexp-grouping-construct
     font-lock-string-face
     font-lock-type-face
     font-lock-variable-name-face
     line-number
     line-number-current-line
     markdown-code-face
     markdown-gfm-checkbox-face
     markdown-inline-code-face
     markdown-language-info-face
     markdown-language-keyword-face
     markdown-math-face
     markdown-pre-face
     markdown-table-face
     org-block
     org-block-begin-line
     org-block-end-line
     org-checkbox
     org-code
     org-document-info-keyword
     org-formula
     org-meta-line
     org-table
     org-verbatim)))

(use-package visual-fill-column
  :ensure nil
  :commands (visual-fill-column-mode)
  :custom
  (visual-fill-column-center-text t)
  (visual-fill-column-width 88))

(use-package typo
  :ensure nil
  :commands (typo-mode))

(use-package adaptive-wrap
  :ensure nil
  :commands (adaptive-wrap-prefix-mode))

(defvar-local markdown-config--focus-on nil
  "Non-nil when focus/writing mode is active in this buffer.")

(defun markdown-config-toggle-focus ()
  "Toggle distraction-free writing mode (olivetti + mixed-pitch)."
  (interactive)
  (setq markdown-config--focus-on (not markdown-config--focus-on))
  (if markdown-config--focus-on
      (progn
        (when (display-graphic-p)
          (mixed-pitch-mode 1))
        (olivetti-mode 1)
        (when (fboundp 'display-line-numbers-mode)
          (display-line-numbers-mode -1))
        (message "Focus mode on"))
    (olivetti-mode -1)
    (when (fboundp 'mixed-pitch-mode)
      (mixed-pitch-mode -1))
    (message "Focus mode off")))


;;; Spell-check + emoji

(use-package jinx
  :ensure nil
  :commands (jinx-mode jinx-correct jinx-languages)
  :bind (("M-$" . jinx-correct)
         ("C-M-$" . jinx-languages))
  :custom
  ;; Enchant exposes locale codes (en_US), not bare "en", on this stack.
  (jinx-languages "en_US"))

(use-package emojify
  :ensure nil
  :commands (emojify-mode)
  :custom
  (emojify-display-style 'unicode)
  (emojify-emoji-styles '(unicode)))

(use-package edit-indirect
  :ensure nil
  :after markdown-mode)


;;; Rendered previews (optional)

(use-package simple-httpd
  :ensure nil
  :defer t
  :custom
  (httpd-port 8080)
  (httpd-host "127.0.0.1"))

(use-package impatient-mode
  :ensure nil
  :commands (impatient-mode))

(use-package impatient-showdown
  :ensure nil
  :commands (impatient-showdown-mode)
  :custom
  (impatient-showdown-flavor 'github)
  (impatient-showdown-background-color "#1e1e2e"))

(defun markdown-config-live-preview ()
  "Toggle auto-refreshing browser preview via impatient-showdown."
  (interactive)
  (require 'impatient-showdown)
  (if (bound-and-true-p impatient-showdown-mode)
      (progn
        (impatient-showdown-mode -1)
        (impatient-mode -1)
        (message "Markdown live preview off"))
    (impatient-mode 1)
    (impatient-showdown-mode 1)
    (unless (process-status "httpd")
      (httpd-start))
    (let ((url (format "http://%s:%d/imp/live/%s/"
                       httpd-host httpd-port
                       (url-hexify-string (buffer-name)))))
      (browse-url url)
      (message "Markdown live preview: %s" url))))

(use-package grip-mode
  :ensure nil
  :commands (grip-mode)
  :custom
  (grip-update-after-change t)
  (grip-preview-use-webkit nil))

(defun markdown-config-glow-preview ()
  "Preview the current Markdown buffer with glow in a compilation buffer."
  (interactive)
  (unless (executable-find "glow")
    (user-error "glow not found on PATH"))
  (let* ((file (or (buffer-file-name)
                   (make-temp-file "glow-md-" nil ".md"
                                   (buffer-string))))
         (cmd (format "glow -p -s dark %s"
                      (shell-quote-argument file))))
    (async-shell-command cmd "*glow-preview*")))


;;; Optional auto-focus on entry

(defcustom markdown-config-focus-on-entry nil
  "When non-nil, enter focus mode automatically in Markdown buffers."
  :type 'boolean
  :group 'markdown)

(defun markdown-config--maybe-focus ()
  (when (and markdown-config-focus-on-entry
             (display-graphic-p)
             (not markdown-config--focus-on))
    (markdown-config-toggle-focus)))

(add-hook 'markdown-mode-hook #'markdown-config--maybe-focus)
(add-hook 'gfm-mode-hook #'markdown-config--maybe-focus)

(provide 'markdown-config)
;;; markdown-config.el ends here
