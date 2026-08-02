;;; org-ui.el --- Pretty Org rendering -*- lexical-binding: t; -*-

;;; Code:

(require 'org-discover)

(defun org-config--setup-ui ()
  "Enable modern Org chrome; GUI-only features are guarded."
  (when (require 'org-modern nil t)
    ;; Defaults match org-modern 2026 API (star is fold|replace|nil; checkbox is alist)
    (setq org-modern-star 'fold
          org-modern-table t
          org-modern-priority t
          org-modern-todo t
          org-modern-block-name t
          org-modern-keyword t)
    (add-hook 'org-mode-hook #'org-modern-mode)
    (add-hook 'org-agenda-finalize-hook #'org-modern-agenda))

  (when (require 'org-appear nil t)
    (add-hook 'org-mode-hook #'org-appear-mode)
    (setq org-appear-autolinks t
          org-appear-autoentities t
          org-appear-autosubmarkers t
          org-appear-autoemphasis t))

  (when (display-graphic-p)
    (when (require 'visual-fill-column nil t)
      (setq visual-fill-column-width 96
            visual-fill-column-center-text t)
      (add-hook 'org-mode-hook #'visual-fill-column-mode))
    (when (require 'mixed-pitch nil t)
      (add-hook 'org-mode-hook #'mixed-pitch-mode))
    (when (require 'valign nil t)
      (add-hook 'org-mode-hook #'valign-mode))
    (when (require 'org-fragtog nil t)
      (add-hook 'org-mode-hook #'org-fragtog-mode)))

  (when (require 'org-download nil t)
    (setq org-download-image-dir
          (expand-file-name "attachments" org-config-state-directory)
          org-download-heading-lvl nil
          org-download-timestamp "%Y%m%d-%H%M%S_")
    (add-hook 'dired-mode-hook #'org-download-enable))

  (when (require 'org-cliplink nil t)
    (with-eval-after-load 'org
      (define-key org-mode-map (kbd "C-c C-x l") #'org-cliplink))))

(provide 'org-ui)
;;; org-ui.el ends here
