;;; lang-support.el --- Syntax highlighting for common languages -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Ensure solid major-mode font-lock (and tree-sitter where available) for:
;; go, rust, python, julia, haskell, bash, typescript/javascript, zig, mojo, ocaml.
;; LSP is configured elsewhere (eglot / lsp-mode); this file is highlighting only.

;;; Code:

(require 'prog-mode)

;;;###autoload
(define-derived-mode mojo-mode python-mode "Mojo"
  "Major mode for Modular Mojo (Python-like syntax with extra keywords)."
  (setq-local font-lock-defaults
              '((mojo-font-lock-keywords)
                nil nil
                ((?\_ . "w"))
                nil))
  (setq-local comment-start "#"
              comment-start-skip "#+\\s-*"))

(defvar mojo-font-lock-keywords
  (let* ((kw (regexp-opt
              '("fn" "struct" "trait" "alias" "var" "let" "def" "class"
                "if" "elif" "else" "for" "while" "return" "yield"
                "import" "from" "as" "with" "try" "except" "finally"
                "raise" "assert" "pass" "break" "continue"
                "owned" "borrowed" "inout" "ref" "mut" "raises"
                "async" "await" "and" "or" "not" "in" "is"
                "True" "False" "None" "Self" "SelfType")
              'symbols))
         (types (regexp-opt
                 '("Int" "Int8" "Int16" "Int32" "Int64"
                   "UInt" "UInt8" "UInt16" "UInt32" "UInt64"
                   "Float16" "Float32" "Float64" "Bool" "String"
                   "SIMD" "DType" "List" "Dict" "Optional" "AnyType")
                 'symbols)))
    `((,kw . font-lock-keyword-face)
      (,types . font-lock-type-face)
      ("\\<\\([A-Z][A-Za-z0-9_]*\\)\\>" . font-lock-type-face)
      ("\\(#.*\\)" 1 font-lock-comment-face)
      ("\\(\"[^\"]*\"\\|'[^']*'\\)" 1 font-lock-string-face)))
  "Font-lock keywords for `mojo-mode'.")

(defun lang-support--setup-file-types ()
  "Register auto-mode-alist entries for supported languages."
  (dolist (pair
           '(("\\.go\\'" . go-mode)
             ("\\.rs\\'" . rust-mode)
             ("\\.py\\'" . python-mode)
             ("\\.pyi\\'" . python-mode)
             ("\\.jl\\'" . julia-mode)
             ("\\.hs\\'" . haskell-mode)
             ("\\.lhs\\'" . haskell-mode)
             ("\\.cabal\\'" . haskell-cabal-mode)
             ("\\.bash\\'" . bash-ts-mode-maybe)
             ("\\.sh\\'" . bash-ts-mode-maybe)
             ("\\.zsh\\'" . sh-mode)
             ("\\.ts\\'" . typescript-mode)
             ("\\.tsx\\'" . typescript-mode)
             ("\\.jsx\\'" . js2-mode)
             ("\\.js\\'" . js2-mode)
             ("\\.mjs\\'" . js2-mode)
             ("\\.cjs\\'" . js2-mode)
             ("\\.zig\\'" . zig-mode)
             ("\\.zon\\'" . zig-mode)
             ("\\.mojo\\'" . mojo-mode)
             ("\\.🔥\\'" . mojo-mode)
             ("\\.ml\\'" . tuareg-mode)
             ("\\.mli\\'" . tuareg-mode)
             ("\\.mll\\'" . tuareg-mode)
             ("\\.mly\\'" . tuareg-mode)
             ("dune\\'" . dune-mode)
             ("dune-project\\'" . dune-mode)))
    (add-to-list 'auto-mode-alist pair)))

(defun bash-ts-mode-maybe ()
  "Use `bash-ts-mode' when the grammar is available, else `sh-mode'."
  (if (and (fboundp 'bash-ts-mode)
           (treesit-language-available-p 'bash))
      (bash-ts-mode)
    (sh-mode)))

(defun lang-support--prefer-ts (mode-symbol ts-mode-symbol lang)
  "Remap MODE-SYMBOL to TS-MODE-SYMBOL when tree-sitter LANG is available."
  (when (and (fboundp ts-mode-symbol)
             (fboundp 'treesit-language-available-p)
             (treesit-language-available-p lang))
    (add-to-list 'major-mode-remap-alist (cons mode-symbol ts-mode-symbol))))

(defun lang-support--setup-treesit ()
  "Enable tree-sitter major modes where grammars are installed."
  (when (require 'treesit nil t)
    (setq treesit-font-lock-level 4)
    (lang-support--prefer-ts 'go-mode 'go-ts-mode 'go)
    (lang-support--prefer-ts 'rust-mode 'rust-ts-mode 'rust)
    (lang-support--prefer-ts 'python-mode 'python-ts-mode 'python)
    (lang-support--prefer-ts 'js-mode 'js-ts-mode 'javascript)
    (lang-support--prefer-ts 'javascript-mode 'js-ts-mode 'javascript)
    (lang-support--prefer-ts 'typescript-mode 'typescript-ts-mode 'typescript)
    (lang-support--prefer-ts 'sh-mode 'bash-ts-mode 'bash)
    (when (fboundp 'zig-ts-mode)
      (lang-support--prefer-ts 'zig-mode 'zig-ts-mode 'zig)))
  (when (require 'treesit-auto nil t)
    ;; Grammars ship via Nix; do not auto-download.
    (setq treesit-auto-install nil)
    (global-treesit-auto-mode 1)))

(defun lang-support--setup-packages ()
  "Load language packages so autoloads/font-lock are available."
  (dolist (feat '(go-mode rust-mode typescript-mode js2-mode zig-mode
                          julia-mode haskell-mode tuareg dune modern-sh))
    (require feat nil t))
  ;; rainbow-delimiters in all prog modes
  (when (fboundp 'rainbow-delimiters-mode)
    (add-hook 'prog-mode-hook #'rainbow-delimiters-mode))
  ;; Line numbers for code
  (when (fboundp 'display-line-numbers-mode)
    (add-hook 'prog-mode-hook #'display-line-numbers-mode)))

(lang-support--setup-packages)
(lang-support--setup-file-types)
(lang-support--setup-treesit)

(provide 'lang-support)
;;; lang-support.el ends here
