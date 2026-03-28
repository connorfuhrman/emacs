;; Enable mouse mode for terminal
(xterm-mouse-mode)

;; No sounds
(setq ring-bell-function 'ignore)

;; Confirm to exit
(add-hook 'kill-emacs-query-functions
          (lambda () (y-or-n-p "Do you really want to exit Emacs? "))
          'append)
