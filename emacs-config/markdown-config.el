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
;;   - Live rendered preview in an Emacs side window (glow / eww)
;;   - Optional external browser preview
;;
;; Keys (markdown / gfm buffers):
;;
;;   C-c m p       live preview in Emacs side window (glow/eww, auto-refresh)
;;   C-c m e       markdown-mode eww live preview (built-in)
;;   C-c m b       external browser live preview (impatient-showdown)
;;   C-c m g       grip-mode browser preview (needs grip on PATH)
;;   C-c m f       toggle focus mode (olivetti + mixed-pitch)
;;   C-c m m       toggle markup hiding
;;   C-c m i       toggle inline images
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
              ("C-c m p" . markdown-config-side-preview-mode)
              ("C-c m e" . markdown-live-preview-mode)
              ("C-c m b" . markdown-config-browser-preview)
              ("C-c m g" . grip-mode)
              ("C-c m f" . markdown-config-toggle-focus)
              ("C-c m m" . markdown-toggle-markup-hiding)
              ("C-c m i" . markdown-toggle-inline-images)
              ("C-c m s" . jinx-correct)
              :map gfm-mode-map
              ("C-c m p" . markdown-config-side-preview-mode)
              ("C-c m e" . markdown-live-preview-mode)
              ("C-c m b" . markdown-config-browser-preview)
              ("C-c m g" . grip-mode)
              ("C-c m f" . markdown-config-toggle-focus)
              ("C-c m m" . markdown-toggle-markup-hiding)
              ("C-c m i" . markdown-toggle-inline-images)
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


;;; Live preview inside Emacs (side window)

(defgroup markdown-config nil
  "Obsidian-like Markdown visuals and in-Emacs preview."
  :group 'markdown)

(defcustom markdown-config-preview-backend 'auto
  "How to render the in-Emacs side preview.
`auto' prefers glow (best in TTY / truecolor terminals), else eww/pandoc.
`glow' always uses glow.  `eww' always uses pandoc → eww."
  :type '(choice (const auto) (const glow) (const eww))
  :group 'markdown-config)

(defcustom markdown-config-preview-idle 0.35
  "Seconds of idle time before refreshing the side preview."
  :type 'number
  :group 'markdown-config)

(defcustom markdown-config-preview-side 'right
  "Side window placement for the live preview buffer."
  :type '(choice (const right) (const left) (const bottom) (const top))
  :group 'markdown-config)

(defcustom markdown-config-preview-width 0.45
  "Width (or height) fraction of the frame used by the side preview."
  :type 'number
  :group 'markdown-config)

(defcustom markdown-config-glow-style "dark"
  "glow -s style name (or path to a JSON style)."
  :type 'string
  :group 'markdown-config)

(defvar-local markdown-config--preview-buffer nil
  "Buffer object showing the live preview for this source buffer.")

(defvar-local markdown-config--preview-timer nil
  "Idle timer that refreshes the live preview.")

(defvar-local markdown-config--preview-source nil
  "Source markdown buffer for a preview buffer.")

(defun markdown-config--preview-buffer-name (&optional source)
  "Return preview buffer name for SOURCE (defaults to current buffer)."
  (format "*md-preview: %s*"
          (buffer-name (or source (current-buffer)))))

(defun markdown-config--preview-backend ()
  "Resolve `markdown-config-preview-backend' to `glow' or `eww'."
  (pcase markdown-config-preview-backend
    ('glow (if (executable-find "glow")
               'glow
             (user-error "glow not found on PATH")))
    ('eww 'eww)
    (_ (if (executable-find "glow") 'glow 'eww))))

(defun markdown-config--preview-ensure-buffer ()
  "Return the live preview buffer for the current markdown buffer."
  (let ((name (markdown-config--preview-buffer-name)))
    (or (and (buffer-live-p markdown-config--preview-buffer)
             markdown-config--preview-buffer)
        (setq markdown-config--preview-buffer
              (get-buffer-create name)))))

(defun markdown-config--preview-display (preview)
  "Show PREVIEW buffer in a side window."
  (let ((window
         (display-buffer
          preview
          `(display-buffer-in-side-window
            (side . ,markdown-config-preview-side)
            (slot . 1)
            (window-width . ,markdown-config-preview-width)
            (window-height . ,markdown-config-preview-width)
            (preserve-size . (t . t))
            (window-parameters . ((no-other-window . t)
                                 (no-delete-other-windows . t)))))))
    (when window
      (set-window-dedicated-p window t))
    window))

(defun markdown-config--apply-ansi ()
  "Colorize ANSI escape sequences in the current buffer."
  (let ((inhibit-read-only t)
        (raw (buffer-string)))
    (erase-buffer)
    (insert (cond
             ((fboundp 'xterm-color-filter)
              (xterm-color-filter raw))
             ((fboundp 'ansi-color-apply)
              (ansi-color-apply raw))
             (t raw)))))

(defun markdown-config--write-temp-source ()
  "Write current buffer contents to a temp .md file; return its path."
  (let ((path (make-temp-file "md-preview-" nil ".md")))
    (write-region (point-min) (point-max) path nil 'silent)
    path))

(defun markdown-config--render-glow (source preview)
  "Render SOURCE markdown into PREVIEW buffer using glow."
  (let ((tmp (with-current-buffer source
               (markdown-config--write-temp-source)))
        (style markdown-config-glow-style)
        (width (let* ((win (get-buffer-window preview))
                      (cols (if win (window-body-width win) fill-column)))
                 (max 40 (min 120 cols)))))
    (unwind-protect
        (with-current-buffer preview
          (let ((inhibit-read-only t)
                (pos (point)))
            (fundamental-mode)
            (erase-buffer)
            (setq-local markdown-config--preview-source source)
            ;; -s style, -w width; no pager so output goes to stdout.
            (let ((status (call-process
                           "glow" nil t nil
                           "-s" style
                           "-w" (number-to-string width)
                           tmp)))
              (unless (eq status 0)
                (insert (format "\n[glow exited with status %s]\n" status))))
            (markdown-config--apply-ansi)
            (goto-char (min pos (point-max)))
            (special-mode)
            (setq-local mode-line-format
                        (list " MD preview (glow) | "
                              (buffer-name source)
                              " | C-c m p to close"))))
      (when (and tmp (file-exists-p tmp))
        (delete-file tmp)))))

(defun markdown-config--render-eww (source preview)
  "Render SOURCE markdown into PREVIEW buffer using pandoc → shr/eww."
  (require 'shr)
  (let* ((tmp-md (with-current-buffer source
                   (markdown-config--write-temp-source)))
         (tmp-html (make-temp-file "md-preview-" nil ".html"))
         (pandoc (executable-find "pandoc")))
    (unwind-protect
        (progn
          (unless pandoc
            (user-error "pandoc not found on PATH (needed for eww preview)"))
          (with-temp-buffer
            (let ((status (call-process
                           pandoc nil t nil
                           tmp-md
                           "-f" "gfm"
                           "-t" "html5"
                           "--standalone"
                           "-o" tmp-html)))
              (unless (eq status 0)
                (user-error "pandoc failed:\n%s" (buffer-string)))))
          (with-current-buffer preview
            (let ((inhibit-read-only t)
                  (pos (point))
                  (dom nil))
              (fundamental-mode)
              (erase-buffer)
              (setq-local markdown-config--preview-source source)
              (insert-file-contents tmp-html)
              (setq dom (libxml-parse-html-region (point-min) (point-max)))
              (erase-buffer)
              (let ((shr-width (let ((win (get-buffer-window preview)))
                                 (if win (window-body-width win) 80)))
                    (shr-use-fonts (display-graphic-p)))
                (shr-insert-document dom))
              (goto-char (min pos (point-max)))
              (special-mode)
              (setq-local mode-line-format
                          (list " MD preview (eww) | "
                                (buffer-name source)
                                " | C-c m p to close")))))
      (when (and tmp-md (file-exists-p tmp-md))
        (delete-file tmp-md))
      (when (and tmp-html (file-exists-p tmp-html))
        (delete-file tmp-html)))))
(defun markdown-config--preview-refresh (&optional source)
  "Refresh the side preview for SOURCE (or current buffer)."
  (let* ((source (or source (current-buffer)))
         (preview (buffer-local-value 'markdown-config--preview-buffer source)))
    (when (and (buffer-live-p source)
               (buffer-live-p preview)
               (buffer-local-value 'markdown-config-side-preview-mode source))
      ;; Show the window first so glow/eww can size to the side pane.
      (markdown-config--preview-display preview)
      (pcase (with-current-buffer source (markdown-config--preview-backend))
        ('glow (markdown-config--render-glow source preview))
        ('eww (markdown-config--render-eww source preview))))))

(defun markdown-config--preview-schedule-refresh (&rest _)
  "Debounce a preview refresh after edits."
  (when markdown-config-side-preview-mode
    (when (timerp markdown-config--preview-timer)
      (cancel-timer markdown-config--preview-timer))
    (setq markdown-config--preview-timer
          (run-with-idle-timer
           markdown-config-preview-idle nil
           #'markdown-config--preview-refresh
           (current-buffer)))))

(defun markdown-config--preview-cleanup ()
  "Tear down preview buffer and timers for the current source buffer."
  (when (timerp markdown-config--preview-timer)
    (cancel-timer markdown-config--preview-timer)
    (setq markdown-config--preview-timer nil))
  (when (buffer-live-p markdown-config--preview-buffer)
    (let ((win (get-buffer-window markdown-config--preview-buffer)))
      (when win (delete-window win)))
    (kill-buffer markdown-config--preview-buffer))
  (setq markdown-config--preview-buffer nil))

(define-minor-mode markdown-config-side-preview-mode
  "Live Markdown preview in an Emacs side window.

Renders with glow (preferred) or pandoc→eww and refreshes on idle
after edits.  Toggle with \\[markdown-config-side-preview-mode]
(bound to \\`C-c m p' in markdown/gfm buffers)."
  :lighter " MD⟹"
  :group 'markdown-config
  (if markdown-config-side-preview-mode
      (progn
        (setq markdown-config--preview-buffer
              (markdown-config--preview-ensure-buffer))
        (add-hook 'after-change-functions
                  #'markdown-config--preview-schedule-refresh nil t)
        (add-hook 'after-save-hook
                  #'markdown-config--preview-schedule-refresh nil t)
        (add-hook 'kill-buffer-hook
                  #'markdown-config--preview-cleanup nil t)
        (markdown-config--preview-refresh (current-buffer))
        (message "Markdown side preview on (%s)"
                 (markdown-config--preview-backend)))
    (remove-hook 'after-change-functions
                 #'markdown-config--preview-schedule-refresh t)
    (remove-hook 'after-save-hook
                 #'markdown-config--preview-schedule-refresh t)
    (remove-hook 'kill-buffer-hook
                 #'markdown-config--preview-cleanup t)
    (markdown-config--preview-cleanup)
    (message "Markdown side preview off")))


;;; External browser previews (optional)

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

(defun markdown-config-browser-preview ()
  "Toggle auto-refreshing external browser preview via impatient-showdown."
  (interactive)
  (require 'impatient-showdown)
  (if (bound-and-true-p impatient-showdown-mode)
      (progn
        (impatient-showdown-mode -1)
        (impatient-mode -1)
        (message "Markdown browser preview off"))
    (impatient-mode 1)
    (impatient-showdown-mode 1)
    (unless (process-status "httpd")
      (httpd-start))
    (let ((url (format "http://%s:%d/imp/live/%s/"
                       httpd-host httpd-port
                       (url-hexify-string (buffer-name)))))
      (browse-url url)
      (message "Markdown browser preview: %s" url))))

(use-package grip-mode
  :ensure nil
  :commands (grip-mode)
  :custom
  (grip-update-after-change t)
  (grip-preview-use-webkit nil))


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
