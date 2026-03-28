;; Enable mouse mode for terminal
(xterm-mouse-mode)

;; No sounds
(setq ring-bell-function 'ignore)

;; ;; MacOS use option key as Meta
;; (setq mac-command-key-is-meta nil)
;; (setq mac-option-key-is-meta t)

;; Confirm to exit
(add-hook 'kill-emacs-query-functions
          (lambda () (y-or-n-p "Do you really want to exit Emacs? "))
          'append)
