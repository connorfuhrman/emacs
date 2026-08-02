;;; org-agenda-config.el --- Super-agenda Today view -*- lexical-binding: t; -*-

;;; Code:

(defun org-config--setup-agenda ()
  "Configure agenda commands for a messy-human workflow."
  (when (require 'org-super-agenda nil t)
    (org-super-agenda-mode 1))

  (setq org-agenda-span 1
        org-agenda-start-with-log-mode t
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-deadline-warning-days 7)

  (setq org-agenda-custom-commands
        '(("a" "Today"
           ((agenda ""
                    ((org-agenda-span 1)
                     (org-super-agenda-groups
                      '((:name "Overdue"
                               :and (:deadline past :todo ("TODO" "NEXT" "IN-PROGRESS" "WAITING")))
                        (:name "Due today"
                               :deadline today)
                        (:name "In progress"
                               :todo "IN-PROGRESS")
                        (:name "Next"
                               :todo "NEXT")
                        (:name "Waiting"
                               :todo "WAITING")
                        (:name "Habits"
                               :habit t)
                        (:name "Rest"
                               :time-grid t
                               :deadline t)))))
            (tags-todo "+TODO=\"TODO\"+PRIORITY=\"A\""
                       ((org-agenda-overriding-header "Urgent unscheduled")))))
          ("i" "Inbox"
           ((alltodo ""
                     ((org-agenda-files
                       (list (expand-file-name "inbox.org" org-config-state-directory)))
                      (org-agenda-overriding-header "Inbox")))))
          ("n" "Next & in progress"
           ((todo "NEXT|IN-PROGRESS")))
          ("w" "Waiting" ((todo "WAITING")))
          ("p" "Projects" ((tags-todo "project"))))))

(provide 'org-agenda-config)
;;; org-agenda-config.el ends here
