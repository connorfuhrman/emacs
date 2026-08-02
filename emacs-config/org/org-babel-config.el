;;; org-babel-config.el --- Jupyter-style literate execution -*- lexical-binding: t; -*-

;;; Commentary:
;; G10: notebook-style code execution and inline results in Org.

;;; Code:

(defun org-config--setup-babel ()
  "Configure Org Babel for interactive notebook-like use."
  (setq org-confirm-babel-evaluate nil
        org-startup-with-inline-images t
        org-image-actual-width '(640)
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-src-preserve-indentation t
        org-edit-src-content-indentation 0
        org-babel-min-lines-for-block-output 100)

  (let ((langs '((emacs-lisp . t)
                 (shell . t)
                 (python . t)
                 (C . t)
                 (js . t)
                 (latex . t)
                 (org . t))))
    ;; Optional languages — skip cleanly if package/binary missing
    (when (require 'ob-haskell nil t)
      (push '(haskell . t) langs))
    (when (require 'jupyter nil t)
      (push '(jupyter . t) langs))
    (org-babel-do-load-languages 'org-babel-load-languages langs))

  ;; Async babel when available
  (when (require 'ob-async nil t)
    (setq ob-async-no-async-languages-alist '("jupyter-python" "jupyter-R")))

  ;; Show images after execution
  (add-hook 'org-babel-after-execute-hook #'org-redisplay-inline-images)

  ;; Convenience: C-c C-c on src blocks already executes; add tangle helper
  (with-eval-after-load 'org
    (define-key org-mode-map (kbd "C-c C-v t") #'org-babel-tangle)
    (define-key org-mode-map (kbd "C-c C-v C-z") #'org-babel-switch-to-session)))

(provide 'org-babel-config)
;;; org-babel-config.el ends here
