;;; org-discover.el --- Multi-root .org discovery with .orgignore -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Discover Org files under configurable search roots (default: $HOME).
;; A directory containing a file named `.orgignore` is pruned entirely
;; (that directory and all children are skipped).
;;
;; Results are cached under the Org state directory (~/.org by default).

;;; Code:

(require 'seq)
(require 'subr-x)

(defgroup org-config nil
  "Personal Org Mode configuration."
  :group 'org)

(defcustom org-config-state-directory
  (let ((env (or (getenv "ORG_STATE_DIRECTORY")
                 (getenv "ORG_DIRECTORY"))))
    (expand-file-name (or env "~/.org")))
  "Directory for inbox, roam, id locations, and discovery cache.
Honors ORG_STATE_DIRECTORY, then ORG_DIRECTORY, then ~/.org."
  :type 'directory
  :group 'org-config)

(defcustom org-config-search-roots
  (let ((dirs (getenv "ORG_DIRECTORIES")))
    (if (and dirs (not (string-empty-p dirs)))
        (mapcar (lambda (d) (expand-file-name (string-trim d)))
                (split-string dirs ";" t "[ \t\r\n]+"))
      (list (expand-file-name "~"))))
  "Roots to scan for .org files.  Defaults to ORG_DIRECTORIES or $HOME."
  :type '(repeat directory)
  :group 'org-config)

(defcustom org-config-prune-dir-names
  '(".git" ".hg" ".svn" ".jj"
    "node_modules" ".cache" "elpa" ".direnv" "result"
    ".Trash" "Library" "Applications"
    ".npm" ".cargo" ".rustup" ".local"
    "vendor" "dist" "build" ".tox" ".venv" "venv"
    ".emacs.d" ".cache")
  "Directory basenames always pruned during discovery."
  :type '(repeat string)
  :group 'org-config)

(defcustom org-config-cache-ttl-seconds 600
  "Reuse discovery cache if younger than this many seconds."
  :type 'integer
  :group 'org-config)

(defun org-config--ensure-state-dir ()
  "Create state directory tree if needed."
  (let* ((root org-config-state-directory)
         (dirs (list root
                     (expand-file-name "cache" root)
                     (expand-file-name "roam" root)
                     (expand-file-name "attachments" root)
                     (expand-file-name "meetings" root))))
    (dolist (d dirs)
      (unless (file-directory-p d)
        (make-directory d t)))
    (let ((inbox (expand-file-name "inbox.org" root)))
      (unless (file-exists-p inbox)
        (write-region "#+title: Inbox\n\n" nil inbox)))
    root))

(defun org-config--cache-file ()
  "Path to the agenda-files cache."
  (expand-file-name "cache/agenda-files" org-config-state-directory))

(defun org-config--path-pruned-p (path)
  "Return non-nil if PATH is under a pruned or .orgignore directory."
  (let* ((path (expand-file-name path))
         (home (expand-file-name "~"))
         (pruned nil)
         (dir (if (file-directory-p path)
                  path
                (file-name-directory path))))
    (while (and dir
                (not pruned)
                (not (string= dir "/"))
                ;; stop above home when scanning home
                (or (not (string-prefix-p home dir))
                    (string-prefix-p home dir)))
      (let ((base (file-name-nondirectory (directory-file-name dir))))
        (when (or (member base org-config-prune-dir-names)
                  (file-exists-p (expand-file-name ".orgignore" dir)))
          (setq pruned t)))
      (let ((parent (file-name-directory (directory-file-name dir))))
        (setq dir (and parent (not (string= parent dir)) parent))))
    pruned))

(defun org-config--discover-with-fd (roots)
  "Use fd to list .org files under ROOTS."
  (let ((fd (executable-find "fd"))
        (files '()))
    (unless fd
      (error "fd not found on PATH"))
    (dolist (root roots)
      (when (file-directory-p root)
        (let* ((exclude-args
                (apply #'append
                       (mapcar (lambda (n) (list "--exclude" n))
                               org-config-prune-dir-names)))
               (args (append exclude-args
                             (list "-e" "org" "-t" "f" "--color" "never"
                                   "." root)))
               (out (with-output-to-string
                      (with-current-buffer standard-output
                        (apply #'call-process fd nil t nil args)))))
          (setq files
                (nconc files
                       (split-string out "\n" t "[ \t\r\n]+"))))))
    files))

(defun org-config--discover-with-find (roots)
  "Fallback discovery using find(1)."
  (let ((files '()))
    (dolist (root roots)
      (when (file-directory-p root)
        (let* ((prune-expr
                (mapconcat
                 (lambda (n)
                   (format "-name %s" (shell-quote-argument n)))
                 org-config-prune-dir-names
                 " -o "))
               (cmd (format
                     "find %s \\( %s -o -name .orgignore \\) -prune -o -type f -name '*.org' -print 2>/dev/null"
                     (shell-quote-argument root)
                     prune-expr))
               (out (shell-command-to-string cmd)))
          (setq files
                (nconc files
                       (split-string out "\n" t "[ \t\r\n]+"))))))
    files))

(defun org-config--discover-org-files (&optional force)
  "Return list of absolute .org paths.  With FORCE, ignore cache TTL."
  (org-config--ensure-state-dir)
  (let* ((cache (org-config--cache-file))
         (use-cache
          (and (not force)
               (file-exists-p cache)
               (let ((age (- (float-time)
                             (float-time (file-attribute-modification-time
                                          (file-attributes cache))))))
                 (< age org-config-cache-ttl-seconds)))))
    (if use-cache
        (with-temp-buffer
          (insert-file-contents cache)
          (split-string (buffer-string) "\n" t))
      (let* ((raw (condition-case nil
                      (org-config--discover-with-fd org-config-search-roots)
                    (error (org-config--discover-with-find
                            org-config-search-roots))))
             (filtered
              (delete-dups
               (seq-filter
                (lambda (f)
                  (and (file-exists-p f)
                       (not (org-config--path-pruned-p f))))
                (mapcar #'expand-file-name raw))))
             ;; Always include state-dir org files
             (state-org
              (when (file-directory-p org-config-state-directory)
                (directory-files-recursively
                 org-config-state-directory "\\.org\\'" nil
                 (lambda (dir)
                   (not (org-config--path-pruned-p dir))))))
             (all (delete-dups (append state-org filtered))))
        (with-temp-file cache
          (insert (mapconcat #'identity all "\n"))
          (insert "\n"))
        all))))

(defun org-config-refresh-agenda-files (&optional force)
  "Rediscover Org files and set `org-agenda-files'.  FORCE bypasses cache."
  (interactive "P")
  (let ((files (org-config--discover-org-files force)))
    (setq org-agenda-files files)
    (message "org-config: %d agenda files" (length files))
    files))

(defun org-config--state-org-files ()
  "Org files under the state directory only (fast)."
  (org-config--ensure-state-dir)
  (directory-files-recursively
   org-config-state-directory "\\.org\\'" nil
   (lambda (dir) (not (org-config--path-pruned-p dir)))))

(defun org-config-setup-discovery ()
  "Initialize state dir; seed agenda from state dir, then scan roots idle.
Full-home discovery can be slow on first run; cache makes later starts cheap."
  (org-config--ensure-state-dir)
  (setq org-directory (file-name-as-directory org-config-state-directory))
  ;; Immediate: state-dir files so capture/agenda work before scan finishes
  (let ((cache (org-config--cache-file)))
    (if (file-exists-p cache)
        (org-config-refresh-agenda-files)
      (setq org-agenda-files (org-config--state-org-files))
      ;; Defer expensive multi-root scan
      (run-with-idle-timer
       1 nil
       (lambda ()
         (org-config-refresh-agenda-files t)
         (message "org-config: background discovery finished (%s files)"
                  (length org-agenda-files)))))))

(provide 'org-discover)
;;; org-discover.el ends here
