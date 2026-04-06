;;; org-config.el --- Personal Org Mode setup driven by environment variables -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Connor Fuhrman
;; Author: Connor Fuhrman
;; URL: https://github.com/connorfuhrman/emacs
;; Version: 0.3
;; Package-Requires: ((emacs "28.1"))
;; Keywords: org, productivity

;;; Commentary:

;; Self-contained, Org Mode configuration package.
;;
;; Supported environment variables:
;;
;;   ORG_DIRECTORIES=/path/to/dir1;/path/to/dir2;/path/to/dir3
;;     → Each directory (and **all** .org files recursively inside it
;;        and its subdirectories) is automatically added to org-agenda-files.
;;
;; Capture, tags, refiling, and TODO keywords are set up automatically
;; when the package activates.

;;; Code:

(defgroup org-config nil
  "Personal Org Mode configuration controlled by environment variables."
  :group 'org)

(defun org-config--agenda-files ()
  "Build org-agenda-files ONLY from ORG_DIRECTORIES (recursive).
Always includes $ORG_DIRECTORY/inbox.org if ORG_DIRECTORY is set."
  (let ((agenda '()))

    ;; 1. ORG_DIRECTORIES — recursive *.org files from every listed directory
    (when-let ((dirs-str (getenv "ORG_DIRECTORIES")))
      (dolist (d (split-string dirs-str ";" t "[ \t\r\n]+"))
        (let ((dir (file-name-as-directory (expand-file-name (string-trim d)))))
          (when (file-directory-p dir)
            (setq agenda
                  (nconc agenda (directory-files-recursively dir "\\.org\\'" nil t)))))))

    ;; 2. Always ensure inbox.org is in the agenda (and create it if missing)
    (when-let ((root (getenv "ORG_DIRECTORY")))
      (let ((inbox (expand-file-name "inbox.org" root)))
        (unless (file-exists-p inbox)
          (write-region "" nil inbox)
          (message "✅ Created inbox file: %s" inbox))
        (push inbox agenda)))

    ;; Remove duplicates and keep only real files/directories
    (delete-dups (seq-filter #'file-exists-p agenda))))

(defun org-config--setup ()
  "Configure Org Mode only when ORG_DIRECTORY or ORG_DIRECTORIES is set."
  (let ((root (getenv "ORG_DIRECTORY")))

    ;; Set main org-directory (used by capture templates, etc.)
    (when root
      (setq org-directory (file-name-as-directory (expand-file-name root))))

    ;; Build and set agenda files
    (let ((agenda-files (org-config--agenda-files)))
      (when agenda-files
        (setq org-agenda-files agenda-files)))

    ;; Only proceed with full config if we actually have something to configure
    (when (or root (getenv "ORG_DIRECTORIES"))

      ;; Capture templates (C-c c)
      (setq org-capture-templates
            `(("i" "Inbox (quick note/TODO)" entry (file "inbox.org")
               "* %?\n  %i\n  %a" :empty-lines 1)

              ("m" "Meeting note" entry (file+datetree "meetings/meetings.org")
               "* %? :meeting:\n** TODO %^{Task description}\n   %i\n   %a" :empty-lines 1)

              ("t" "Standalone TODO" entry (file "inbox.org")
               "* TODO %?\n  %i\n  %a" :empty-lines 1)))

      ;; TODO keywords
      (setq org-todo-keywords
            '((sequence "TODO(t)" "NEXT(n)" "WAITING(w@/!)" "|" "DONE(d!)" "CANCELLED(c@/!)")))

      ;; Tags (work on *any* headline, not just TODOs)
      (setq org-tag-alist
            '((:startgroup)
              ("@work" . ?w) ("@home" . ?h) ("@computer" . ?c)
              (:endgroup)
              ("meeting" . ?m) ("project" . ?p) ("urgent" . ?u) ("read" . ?r)))

      ;; Refiling (C-c C-w)
      (setq org-refile-targets '((org-agenda-files :maxlevel . 3))
            org-refile-use-outline-path 'file
            org-outline-path-complete-in-steps nil
            org-refile-allow-creating-parent-nodes 'confirm)

      ;; Other sensible defaults
      (setq org-log-done 'time
            org-log-into-drawer t
            org-use-tag-inheritance t)

      ;; Automatically load config.el from your Org root (or ~/org/) if it exists
      (let ((config-file (if org-directory
                             (expand-file-name "config.el" org-directory)
                           (expand-file-name "~/org/config.el"))))
        (when (file-exists-p config-file)
          (load config-file t t))))))   ; noerror + nomessage

;; Activate the setup
(org-config--setup)

(provide 'org-config)
;;; org-config.el ends here
