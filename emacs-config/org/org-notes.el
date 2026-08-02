;;; org-notes.el --- org-roam + navigation -*- lexical-binding: t; -*-

;;; Commentary:
;; org-roam chosen for mind-map (org-roam-ui), IDs/backlinks, and consult jump.
;; Roam directory is under the state dir; project .org files remain agenda-only
;; via discovery + org-id.

;;; Code:

(require 'org-discover)

(defun org-config--setup-notes ()
  "Configure org-roam, roam-ui, and C-c n keymap."
  (let ((roam-dir (expand-file-name "roam" org-config-state-directory)))
    (unless (file-directory-p roam-dir)
      (make-directory roam-dir t))

    (when (require 'org-roam nil t)
      (setq org-roam-directory roam-dir
            org-roam-db-location
            (expand-file-name "cache/org-roam.db" org-config-state-directory)
            org-roam-completion-everywhere t
            org-roam-node-display-template
            (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))

      (org-roam-db-autosync-mode 1)

      (setq org-roam-capture-templates
            '(("d" "default" plain "%?"
               :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                                  "#+title: ${title}\n#+filetags: \n")
               :unnarrowed t)
              ("p" "project" plain
               "* Outcome\n%?\n* Tasks\n"
               :target (file+head "projects/%<%Y%m%d%H%M%S>-${slug}.org"
                                  "#+title: ${title}\n#+filetags: :project:\n")
               :unnarrowed t)))

      ;; Global note map (Prelude keeps C-c a/c/l/b)
      (define-prefix-command 'org-config-notes-map)
      (global-set-key (kbd "C-c n") 'org-config-notes-map)
      (define-key org-config-notes-map (kbd "f") #'org-roam-node-find)
      (define-key org-config-notes-map (kbd "i") #'org-roam-node-insert)
      (define-key org-config-notes-map (kbd "c") #'org-roam-capture)
      (define-key org-config-notes-map (kbd "l") #'org-roam-buffer-toggle)
      (define-key org-config-notes-map (kbd "d") #'org-roam-dailies-goto-today)
      (define-key org-config-notes-map (kbd "s") #'org-config-search-org-files)
      (define-key org-config-notes-map (kbd "g") #'org-config-roam-ui)
      (define-key org-config-notes-map (kbd "r") #'org-config-refresh-agenda-files)

      (when (require 'consult-org-roam nil t)
        (consult-org-roam-mode 1)
        (define-key org-config-notes-map (kbd "F") #'consult-org-roam-file-find)
        (define-key org-config-notes-map (kbd "b") #'consult-org-roam-backlinks)
        (define-key org-config-notes-map (kbd "S") #'consult-org-roam-search)))))

(defun org-config-search-org-files ()
  "Ripgrep across discovered Org agenda files via consult when available."
  (interactive)
  (let ((dir org-config-state-directory)
        (roots org-config-search-roots))
    (cond
     ((fboundp 'consult-ripgrep)
      (consult-ripgrep (if (= (length roots) 1) (car roots) dir)))
     ((fboundp 'rg)
      (rg "" "*.org" (if (= (length roots) 1) (car roots) dir)))
     (t
      (project-find-regexp "")))))

(defun org-config-roam-ui ()
  "Start org-roam-ui if available."
  (interactive)
  (if (require 'org-roam-ui nil t)
      (org-roam-ui-mode 1)
    (user-error "org-roam-ui not available")))

(provide 'org-notes)
;;; org-notes.el ends here
