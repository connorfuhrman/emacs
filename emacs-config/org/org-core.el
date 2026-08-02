;;; org-core.el --- TODOs, tags, capture, ids, edna -*- lexical-binding: t; -*-

;;; Code:

(require 'org-discover)

(defun org-config--setup-core ()
  "Configure core Org behavior."
  (require 'org-id)
  (setq org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id
        org-id-locations-file
        (expand-file-name "org-id-locations" org-config-state-directory)
        org-id-track-globally t)

  ;; Keywords: no SCHEDULED-centric flow; IN-PROGRESS for active work
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "IN-PROGRESS(p!)" "WAITING(w@/!)" "SOMEDAY(s)"
                    "|" "DONE(d!)" "CANCELLED(c@/!)")))

  (setq org-todo-keyword-faces
        '(("NEXT" . (:foreground "#98be65" :weight bold))
          ("IN-PROGRESS" . (:foreground "#da8548" :weight bold))
          ("WAITING" . (:foreground "#ecbe7b" :weight bold))
          ("SOMEDAY" . (:foreground "#5b6268" :weight normal))
          ("CANCELLED" . (:foreground "#5b6268" :strike-through t))))

  (setq org-tag-alist
        '((:startgroup)
          ("@work" . ?w) ("@home" . ?h) ("@computer" . ?c)
          ("@phone" . ?p) ("@errands" . ?e)
          (:endgroup)
          (:startgroup)
          ("deep" . ?d) ("shallow" . ?s)
          (:endgroup)
          ("project" . ?P) ("meeting" . ?m) ("waiting_on" . ?W)
          ("urgent" . ?u) ("read" . ?r) ("idea" . ?i)))

  (setq org-log-done 'time
        org-log-into-drawer t
        org-use-tag-inheritance t
        org-startup-indented t
        org-return-follows-link t
        org-hide-emphasis-markers t)

  (setq org-refile-targets '((org-agenda-files :maxlevel . 3))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm)

  (let ((inbox (expand-file-name "inbox.org" org-config-state-directory))
        (meetings (expand-file-name "meetings/meetings.org"
                                    org-config-state-directory)))
    (unless (file-exists-p (file-name-directory meetings))
      (make-directory (file-name-directory meetings) t))
    (setq org-default-notes-file inbox)
    (setq org-capture-templates
          `(("i" "Inbox" entry (file ,inbox)
             "* %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n%i\n"
             :empty-lines 1)
            ("t" "Todo" entry (file ,inbox)
             "* TODO %?\nDEADLINE: %^t\n:PROPERTIES:\n:CREATED: %U\n:END:\n"
             :empty-lines 1)
            ("n" "Next" entry (file ,inbox)
             "* NEXT %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n"
             :empty-lines 1)
            ("p" "In progress" entry (file ,inbox)
             "* IN-PROGRESS %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n"
             :empty-lines 1)
            ("m" "Meeting" entry (file+olp+datetree ,meetings)
             "* %^{Title} :meeting:\n%^T\n** Notes\n%?\n** Actions\n*** TODO %^{First action}\n"
             :empty-lines 1))))

  ;; Dependencies via org-edna
  (when (require 'org-edna nil t)
    (org-edna-mode 1))

  ;; Optional local overrides
  (let ((config-file (expand-file-name "config.el" org-config-state-directory)))
    (when (file-exists-p config-file)
      (load config-file t t))))

(provide 'org-core)
;;; org-core.el ends here
