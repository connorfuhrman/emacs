;;; org-agent.el --- Pure-Elisp orgctl CLI entrypoints -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Invoked by the `orgctl` shell wrapper:
;;   emacs --batch -l org-agent.el --funcall orgctl-main -- ARGS...
;;
;; Uses stock org-element / org-id and optional org-ql.  No external Org parser.

;;; Code:

(require 'json)
(require 'seq)
(require 'subr-x)
(require 'cl-lib)

;; Minimal load path bootstrap when not running under full config
(defconst org-agent--dir
  (file-name-directory (or load-file-name buffer-file-name default-directory)))

(add-to-list 'load-path org-agent--dir)

(require 'org)
(require 'org-id)
(require 'org-element)
(require 'org-discover)

(defvar orgctl--json nil
  "Non-nil when --json was requested.")

(defun orgctl--args ()
  "Return CLI args after the batch `--` separator.
Strips a leading bare `--` that Emacs leaves in `command-line-args-left'."
  (let ((args (or command-line-args-left
                  (let ((out nil)
                        (seen-sep nil))
                    (dolist (a command-line-args)
                      (if seen-sep
                          (push a out)
                        (when (string= a "--")
                          (setq seen-sep t))))
                    (nreverse out)))))
    ;; Drop one leading "--" if present (emacs --funcall ... -- ARGS)
    (while (and args (string= (car args) "--"))
      (setq args (cdr args)))
    args))

(defun orgctl--alist-p (obj)
  "Return non-nil if OBJ looks like an alist of (SYM . VAL) pairs."
  (and (listp obj)
       obj
       (consp (car obj))
       (symbolp (caar obj))))

(defun orgctl--print-alist (alist)
  "Print one ALIST as tab-separated key=value fields."
  (princ (mapconcat
          (lambda (kv)
            (format "%s=%s"
                    (car kv)
                    (let ((v (cdr kv)))
                      (cond
                       ((null v) "")
                       ((listp v) (mapconcat #'identity v ":"))
                       (t v)))))
          alist
          "\t"))
  (princ "\n"))

(defun orgctl--print (obj)
  "Print OBJ as JSON if `orgctl--json', else as readable text."
  (if orgctl--json
      (progn
        (princ (json-encode obj))
        (princ "\n"))
    (cond
     ((stringp obj) (princ obj) (princ "\n"))
     ((orgctl--alist-p obj) (orgctl--print-alist obj))
     ((and (listp obj) (seq-every-p #'orgctl--alist-p obj))
      (dolist (item obj) (orgctl--print-alist item)))
     ((and (listp obj) (seq-every-p #'stringp obj))
      (dolist (line obj) (princ line) (princ "\n")))
     (t (pp obj)))))

(defun orgctl--fail (fmt &rest args)
  (princ (apply #'format (concat "orgctl: " fmt "\n") args) #'external-debugging-output)
  (kill-emacs 1))

(defun orgctl--ensure ()
  (org-config--ensure-state-dir)
  (setq org-directory (file-name-as-directory org-config-state-directory)
        org-id-locations-file
        (expand-file-name "org-id-locations" org-config-state-directory)
        org-agenda-files (org-config--discover-org-files)
        org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "IN-PROGRESS(p!)" "WAITING(w@/!)" "SOMEDAY(s)"
                    "|" "DONE(d!)" "CANCELLED(c@/!)"))
        org-log-done 'time
        org-log-into-drawer t)
  ;; Make keyword table current in batch sessions
  (when (fboundp 'org-set-regexps-and-options)
    (with-temp-buffer
      (org-mode)
      (org-set-regexps-and-options))))

(defun orgctl--parse-headline ()
  "Parse headline at point into an alist."
  (let* ((el (org-element-at-point))
         (type (org-element-type el)))
    (when (eq type 'headline)
      (let* ((title (org-element-property :raw-value el))
             (todo (org-element-property :todo-keyword el))
             (tags (org-element-property :tags el))
             (priority (org-element-property :priority el))
             (begin (org-element-property :begin el))
             (id (org-entry-get begin "ID"))
             (deadline (org-entry-get begin "DEADLINE"))
             (scheduled (org-entry-get begin "SCHEDULED"))
             (blocker (org-entry-get begin "BLOCKER")))
        `((id . ,(or id ""))
          (state . ,(or todo ""))
          (title . ,(or title ""))
          (file . ,(or (buffer-file-name) ""))
          (tags . ,(vconcat (or tags '())))
          (priority . ,(if priority (format "%c" priority) ""))
          (deadline . ,(or deadline ""))
          (scheduled . ,(or scheduled ""))
          (blockers . ,(or blocker ""))
          (begin . ,begin))))))

(defun orgctl--collect-todos (&optional states)
  "Collect TODO headlines across agenda files, optional STATES list."
  (orgctl--ensure)
  (let ((states (or states '("TODO" "NEXT" "IN-PROGRESS" "WAITING" "SOMEDAY")))
        (results '()))
    (dolist (file org-agenda-files)
      (when (and (file-exists-p file)
                 (file-readable-p file))
        (with-current-buffer (find-file-noselect file t)
          (org-with-wide-buffer
           (goto-char (point-min))
           (while (re-search-forward org-heading-regexp nil t)
             (when (org-get-todo-state)
               (let ((item (orgctl--parse-headline)))
                 (when (and item
                            (member (alist-get 'state item) states))
                   (push item results)))))))))
    (nreverse results)))

(defun orgctl--find-by-id (id)
  "Visit entry with ID and return parsed headline alist."
  (orgctl--ensure)
  (org-id-locations-load)
  (let ((m (org-id-find id 'marker)))
    (unless m
      (orgctl--fail "unknown id: %s" id))
    (with-current-buffer (marker-buffer m)
      (goto-char (marker-position m))
      (orgctl--parse-headline))))

(defun orgctl--with-id (id fn)
  "Call FN at headline with ID; save buffer."
  (orgctl--ensure)
  (org-id-locations-load)
  (let ((m (org-id-find id 'marker)))
    (unless m
      ;; Rescan agenda files once if the id index is stale
      (org-id-update-id-locations org-agenda-files 'silent)
      (setq m (org-id-find id 'marker)))
    (unless m
      (orgctl--fail "unknown id: %s" id))
    (with-current-buffer (marker-buffer m)
      (org-mode)
      (goto-char (marker-position m))
      (funcall fn)
      (save-buffer)
      (orgctl--parse-headline))))

(defun orgctl-cmd-help (&rest _)
  (princ "orgctl — pure-Elisp Org CLI for agents and humans

Usage: orgctl [--json] <command> [args]

Commands:
  path                         Print ORG state directory
  refresh                      Rediscover .org files (bypass cache)
  files                        List agenda files
  inbox list                   List inbox headlines
  inbox add TITLE [--tag TAG] [--due YYYY-MM-DD]
  todo list [--state S] [--tag TAG] [--due-before DATE]
  todo get ID
  todo done ID
  todo state ID STATE
  todo deadline ID YYYY-MM-DD
  todo block ID --on OTHER_ID
  search QUERY                 Ripgrep titles/bodies (rg)
  agenda today                 Compact today-ish todo dump
  notes list                   List org-roam note files
  help

Environment:
  ORG_STATE_DIRECTORY   state/cache/inbox/roam (default ~/.org)
  ORG_DIRECTORY         alias for ORG_STATE_DIRECTORY
  ORG_DIRECTORIES       semicolon-separated search roots (default $HOME)

Discovery skips any directory containing .orgignore (and its children).
"))

(defun orgctl-cmd-path (&rest _)
  (orgctl--ensure)
  (orgctl--print org-config-state-directory))

(defun orgctl-cmd-refresh (&rest _)
  (orgctl--ensure)
  (let ((files (org-config--discover-org-files t)))
    (setq org-agenda-files files)
    (orgctl--print (if orgctl--json
                       `((count . ,(length files)) (files . ,files))
                     (format "refreshed %d files" (length files))))))

(defun orgctl-cmd-files (&rest _)
  (orgctl--ensure)
  (orgctl--print org-agenda-files))

(defun orgctl-cmd-inbox (sub &rest args)
  (orgctl--ensure)
  (let ((inbox (expand-file-name "inbox.org" org-config-state-directory)))
    (pcase sub
      ("list"
       (with-current-buffer (find-file-noselect inbox t)
         (let ((items '()))
           (org-with-wide-buffer
            (goto-char (point-min))
            (while (re-search-forward org-heading-regexp nil t)
              (push (orgctl--parse-headline) items)))
           (orgctl--print (nreverse (delq nil items))))))
      ("add"
       (let* ((title nil)
              (tag nil)
              (due nil)
              (rest args))
         (while rest
           (pcase (car rest)
             ("--tag" (setq tag (cadr rest) rest (cddr rest)))
             ("--due" (setq due (cadr rest) rest (cddr rest)))
             (_ (setq title (if title (concat title " " (car rest)) (car rest))
                      rest (cdr rest)))))
         (unless title
           (orgctl--fail "inbox add requires TITLE"))
         (with-current-buffer (find-file-noselect inbox t)
           (org-mode)
           (goto-char (point-max))
           (unless (bolp) (insert "\n"))
           (insert (format "* TODO %s%s\n"
                           title
                           (if tag (format " :%s:" (string-trim tag ":" ":")) "")))
           (when due
             (insert (format "DEADLINE: <%s>\n" due)))
           (insert ":PROPERTIES:\n:CREATED: "
                   (format-time-string "[%Y-%m-%d %a %H:%M]")
                   "\n:END:\n")
           (outline-previous-heading)
           (let ((id (org-id-get-create)))
             (org-id-add-location id (buffer-file-name))
             (save-buffer)
             (org-id-locations-save)
             (orgctl--print (orgctl--parse-headline))))))
      (_ (orgctl--fail "unknown inbox subcommand: %s" sub)))))

(defun orgctl-cmd-todo (sub &rest args)
  (pcase sub
    ("list"
     (let ((state nil)
           (tag nil)
           (due-before nil)
           (rest args))
       (while rest
         (pcase (car rest)
           ("--state" (setq state (cadr rest) rest (cddr rest)))
           ("--tag" (setq tag (cadr rest) rest (cddr rest)))
           ("--due-before" (setq due-before (cadr rest) rest (cddr rest)))
           (_ (orgctl--fail "unknown todo list option: %s" (car rest)))))
       (let ((items (orgctl--collect-todos (and state (list state)))))
         (when tag
           (setq items
                 (seq-filter
                  (lambda (it)
                    (member tag (append (alist-get 'tags it) nil)))
                  items)))
         (when due-before
           (setq items
                 (seq-filter
                  (lambda (it)
                    (let ((d (alist-get 'deadline it)))
                      (and d (not (string-empty-p d))
                           (string-lessp d due-before))))
                  items)))
         (orgctl--print items))))
    ("get"
     (let ((id (car args)))
       (unless id (orgctl--fail "todo get requires ID"))
       (orgctl--print (orgctl--find-by-id id))))
    ("done"
     (let ((id (car args)))
       (unless id (orgctl--fail "todo done requires ID"))
       (orgctl--print
        (orgctl--with-id id (lambda () (org-todo 'done))))))
    ("state"
     (let ((id (car args))
           (state (cadr args)))
       (unless (and id state)
         (orgctl--fail "todo state requires ID STATE"))
       (orgctl--print
        (orgctl--with-id id (lambda () (org-todo state))))))
    ("deadline"
     (let ((id (car args))
           (date (cadr args)))
       (unless (and id date)
         (orgctl--fail "todo deadline requires ID YYYY-MM-DD"))
       (orgctl--print
        (orgctl--with-id
         id
         (lambda ()
           (org-deadline nil date))))))
    ("block"
     (let ((id (car args))
           (on nil)
           (rest (cdr args)))
       (while rest
         (pcase (car rest)
           ("--on" (setq on (cadr rest) rest (cddr rest)))
           (_ (orgctl--fail "usage: todo block ID --on OTHER_ID"))))
       (unless (and id on)
         (orgctl--fail "todo block requires ID --on OTHER_ID"))
       (orgctl--print
        (orgctl--with-id
         id
         (lambda ()
           (org-set-property "BLOCKER" (format "ids(%s)" on)))))))
    (_ (orgctl--fail "unknown todo subcommand: %s" sub))))

(defun orgctl-cmd-search (query &rest _)
  (unless query
    (orgctl--fail "search requires QUERY"))
  (orgctl--ensure)
  (let ((rg (executable-find "rg")))
    (unless rg
      (orgctl--fail "rg not found on PATH"))
    (let* ((roots org-config-search-roots)
           (args (append '("--color" "never" "-n" "-S" "-g" "*.org" "--json")
                         (list query)
                         roots))
           (out (with-output-to-string
                  (with-current-buffer standard-output
                    (apply #'call-process rg nil t nil args)))))
      (if orgctl--json
          (princ out)
        (dolist (line (split-string out "\n" t))
          (when (string-match "\"path\":{\"text\":\"\\([^\"]+\\)\"}" line)
            (let ((path (match-string 1 line))
                  (text (when (string-match "\"lines\":{\"text\":\"\\([^\"]*\\)\"" line)
                          (match-string 1 line))))
              (princ (format "%s: %s\n" path (or text ""))))))))))

(defun orgctl-cmd-agenda (sub &rest _)
  (pcase sub
    ("today"
     (let* ((items (orgctl--collect-todos
                    '("TODO" "NEXT" "IN-PROGRESS" "WAITING")))
            (today (format-time-string "%Y-%m-%d"))
            (interesting
             (seq-filter
              (lambda (it)
                (let ((st (alist-get 'state it))
                      (dl (alist-get 'deadline it)))
                  (or (member st '("NEXT" "IN-PROGRESS" "WAITING"))
                      (and dl (string-match-p today dl))
                      (and dl (string-lessp dl today)))))
              items)))
       (orgctl--print interesting)))
    (_ (orgctl--fail "unknown agenda subcommand: %s" sub))))

(defun orgctl-cmd-notes (sub &rest _)
  (orgctl--ensure)
  (let ((roam (expand-file-name "roam" org-config-state-directory)))
    (pcase sub
      ("list"
       (if (file-directory-p roam)
           (orgctl--print
            (directory-files-recursively roam "\\.org\\'"))
         (orgctl--print [])))
      (_ (orgctl--fail "unknown notes subcommand: %s" sub)))))

(defun orgctl-main ()
  "CLI entrypoint for orgctl."
  (let* ((raw (orgctl--args))
         (json nil)
         (args raw))
    (when (member "--json" args)
      (setq json t
            args (delete "--json" (copy-sequence args))))
    (setq orgctl--json json)
    (let* ((cmd (or (car args) "help"))
           (rest (cdr args)))
      (condition-case err
          (pcase cmd
            ("help" (apply #'orgctl-cmd-help rest))
            ("path" (apply #'orgctl-cmd-path rest))
            ("refresh" (apply #'orgctl-cmd-refresh rest))
            ("files" (apply #'orgctl-cmd-files rest))
            ("inbox" (apply #'orgctl-cmd-inbox rest))
            ("todo" (apply #'orgctl-cmd-todo rest))
            ("search" (apply #'orgctl-cmd-search rest))
            ("agenda" (apply #'orgctl-cmd-agenda rest))
            ("notes" (apply #'orgctl-cmd-notes rest))
            (_ (orgctl--fail "unknown command: %s (try help)" cmd)))
        (error
         (orgctl--fail "%s" (error-message-string err)))))
    (kill-emacs 0)))

(provide 'org-agent)
;;; org-agent.el ends here
