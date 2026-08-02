;;; org-config.el --- Personal Org Mode setup (loader) -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Connor Fuhrman
;; Author: Connor Fuhrman
;; Version: 0.4
;; Package-Requires: ((emacs "28.1"))
;; Keywords: org, productivity

;;; Commentary:
;;
;; Multi-root Org discovery + modern tooling.
;;
;; Environment:
;;   ORG_STATE_DIRECTORY  state/cache/inbox/roam (default ~/.org)
;;   ORG_DIRECTORY        alias for ORG_STATE_DIRECTORY (compat)
;;   ORG_DIRECTORIES      semicolon-separated search roots (default $HOME)
;;
;; Any directory containing `.orgignore` is pruned (dir + children).

;;; Code:

;; When orgctl boots us in --batch with EMACS_ORGCTL=1, skip interactive setup.
(when (not (equal (getenv "EMACS_ORGCTL") "1"))

  (let ((org-dir (expand-file-name
                  "org"
                  (file-name-directory (or load-file-name buffer-file-name)))))
    (add-to-list 'load-path org-dir)
    (require 'org-discover)
    (require 'org-core)
    (require 'org-ui)
    (require 'org-agenda-config)
    (require 'org-notes)
    (require 'org-babel-config)

    (org-config-setup-discovery)
    (org-config--setup-core)
    (org-config--setup-ui)
    (org-config--setup-agenda)
    (org-config--setup-notes)
    (org-config--setup-babel)

    (message "org-config: ready (state=%s, agenda-files=%s)"
             org-config-state-directory
             (if (listp org-agenda-files)
                 (length org-agenda-files)
               "?"))))

(provide 'org-config)
;;; org-config.el ends here
