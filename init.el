(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(dired-listing-switches "-alh")
 '(dired-omit-files "^\\.?#\\|^\\.$\\|^\\.[^.]")
 '(grep-files-aliases
   '(("all" . "* .*") ("el" . "*.el") ("ch" . "*.[ch] *.cpp")
     ("c" . "*.c") ("cc" . "*.cc *.cxx *.cpp *.C *.CC *.c++")
     ("cchh" . "*.cc *.[ch]xx *.[ch]pp *.[CHh] *.CC *.HH *.[ch]++")
     ("hh" . "*.hxx *.hpp *.[Hh] *.HH *.h++") ("h" . "*.h")
     ("l" . "[Cc]hange[Ll]og*") ("m" . "[Mm]akefile*")
     ("tex" . "*.tex") ("texi" . "*.texi") ("asm" . "*.[sS]")))
 '(lsp-clangd-binary-path "/usr/bin/clangd")
 '(package-selected-packages
   '(use-package abyss-theme bash-completion editorconfig editorconfig-generate lsp-mode magit nhexl-mode python-mode seq vlf yaml-imenu yasnippet ztree)
 '(warning-suppress-types '((comp) (comp))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


;; ==========================
;; package
;; ==========================

;; packages configuration
(require 'package)
(setq package-archives '(
;;;                         ("melpa-stable" . "http://stable.melpa.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")
                         ("gnu" . "http://elpa.gnu.org/packages/")
                         )
      )
(package-initialize)

(unless package-archive-contents
  (package-refresh-contents))

;; use-package installation
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t) ;; installe les packages manquants automatiquement

;; fix
(setq package-install-upgrade-built-in t)

;; edit init.el

;; ==========================
;; key short cut
;; ==========================
(defun switch-to-buffer-emacs ()
  (interactive)
  (find-file "~/.emacs.d/init.el")
  ;;(switch-to-buffer "init.el" )
  )
(global-set-key (kbd "C-<f1>") 'switch-to-buffer-emacs)

;; window split helper in french keyboard
(global-set-key (kbd "M-œ")  'delete-window)
(global-set-key (kbd "M-&")  'delete-other-windows )
(global-set-key (kbd "M-é")  'split-window-vertically)
(global-set-key (kbd "M-\"") 'split-window-horizontally)

;; windows navigation
(global-set-key (kbd "C-<tab>") 'other-window)
(global-set-key (kbd "C-œ") 'other-window)

;; buffer navigation
(global-set-key (kbd "M-<left>") 'previous-buffer) ; ALT+ flèche gauche
(global-set-key (kbd "M-<right>")  'next-buffer) ; ALT + flèche droite

;; shortcut for developement
(global-set-key [f1] 'dired-sources-file)
(global-set-key [f12] 'compile)
(global-set-key [(control f12)] 'recompile)
(global-set-key [f11] 'shell)
(global-set-key (kbd "<f9>") 'my-grep)

;; windows short cut
(global-set-key (kbd "C-z") 'undo)

;; magit short cut
(global-set-key (kbd "C-<escape>") 'magit-status)


(defun dired-sources-file ()
  (interactive)
  (dired default-directory)
  ;;(replace-in-string (buffer-file-name) "/[^/]+$" "/."))
)

;; ==========================
;; nice
;; ==========================

;; theme
(require 'abyss-theme)
(abyss-theme)


;; dired
(require 'dired-x)
(add-hook 'dired-mode-hook (lambda () (dired-omit-mode)))
;; and simplier shortcut
(global-set-key (kbd "M-o") 'dired-omit-mode)

;; ansicolor in compile buffer
;(require 'ansi-color)
;(defun colorize-compilation-buffer ()
;  (toggle-read-only)
;  (ansi-color-apply-on-region compilation-filter-start (point))
;  (toggle-read-only))
;(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

;; get line number everywhere
(global-display-line-numbers-mode)

;; tips
(put 'erase-buffer 'disabled nil)

;; ==========================
;; lsp mode
;; ==========================
(use-package lsp-mode
    :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
            (c-mode . lsp-deferred)
            (c++-mode . lsp-deferred)
            (python-mode . lsp-deferred)
            (java-mode . lsp-deferred)
            ;; if you want which-key integration
            (lsp-mode . lsp-enable-which-key-integration))
    :commands lsp-deferred
    :custom (lsp-clients-clangd-executable
             ;; from https://github.com/clangd/clangd/releases/tag/11.0.0
             ;; "~/.emacs.d/lsp-server/clangd_11.0.0/bin/clangd")
             ;; "/home/mkapfer/.emacs.d/lsp-server/clangd_11.0.0/bin/clangd"
             "/usr/bin/clangd"
             )
    )

;; ==========================
;; C++ ide
;; ==========================

;; force c++ mode for *.h files
(add-to-list 'auto-mode-alist '("\\.h\\'" . c++-mode))


;; ==========================
;; C++ ide
;; ==========================
(add-to-list 'load-path "~/.emacs.d/lisp")
(require 'evt-decoder)
(require 'nhexl-mode)


;; ==========================
;; improve shell
;; ==========================
;; adding search in history
(require 'shell)
(define-key shell-mode-map (kbd "C-r") 'comint-history-isearch-backward)

(use-package bash-completion
  :ensure t
  :config
  (bash-completion-setup))


;; ==========================
;; tooling 
;; ==========================
;; ** recursive directory tree comparison: M-x ztree-diff
(use-package ztree
  :ensure t) ; needs GNU diff utility
   
;; Code spacing
;; ==========================
(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))
