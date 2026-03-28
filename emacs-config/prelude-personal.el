;; Enable mouse mode for terminal
(xterm-mouse-mode)

;; No sounds
(setq ring-bell-function 'ignore)

;; Confirm to exit
(add-hook 'kill-emacs-query-functions
          (lambda () (y-or-n-p "Do you really want to exit Emacs? "))
          'append)


;; Disable line numbers in vterm (and multi-vterm)
(add-hook 'vterm-mode-hook
          (lambda ()
            (display-line-numbers-mode -1)))   ; modern Emacs
