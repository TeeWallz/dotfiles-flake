(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(LaTeX-mode-hook
   '(preview-mode-setup auto-fill-mode TeX-source-correlate-mode))
 '(TeX-auto-save t)
 '(TeX-source-correlate-mode t)
 '(TeX-source-correlate-start-server t)
 '(TeX-view-program-selection '((output-pdf "Zathura")))
 '(custom-enabled-themes nil)
 '(default-input-method "german-postfix")
 '(elpy-rpc-virtualenv-path 'system)
 '(inhibit-startup-screen t)
 '(interprogram-cut-function 'wl-copy)
 '(interprogram-paste-function 'wl-paste)
 '(mail-envelope-from 'header)
 '(mail-host-address "lan")
 '(mail-specify-envelope-from t)
 '(menu-bar-mode nil)
 '(message-kill-buffer-on-exit t)
 '(message-send-mail-function 'message-send-mail-with-sendmail)
 '(message-sendmail-envelope-from 'header)
 '(mml-secure-openpgp-sign-with-sender t)
 '(notmuch-saved-searches
   '((:name "inbox" :query "tag:inbox not tag:flagged not tag:passed" :key "i")
     (:name "unread" :query "tag:unread" :key "u")
     (:name "passed" :query "tag:passed" :key "p")
     (:name "flagged" :query "tag:flagged" :key "f")
     (:name "sent" :query "tag:sent" :key "t")
     (:name "drafts" :query "tag:draft" :key "d")
     (:name "all mail" :query "*" :key "a")))
 '(org-export-with-smart-quotes t)
 '(org-highlight-latex-and-related '(latex))
 '(org-latex-classes
   '(("article" "\\documentclass[a4paper,12pt]{article}"
      ("\\section{%s}" . "\\section*{%s}")
      ("\\subsection{%s}" . "\\subsection*{%s}")
      ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
      ("\\paragraph{%s}" . "\\paragraph*{%s}")
      ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))
     ("report" "\\documentclass[11pt]{report}"
      ("\\part{%s}" . "\\part*{%s}")
      ("\\chapter{%s}" . "\\chapter*{%s}")
      ("\\section{%s}" . "\\section*{%s}")
      ("\\subsection{%s}" . "\\subsection*{%s}")
      ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))
     ("book" "\\documentclass[11pt]{book}"
      ("\\part{%s}" . "\\part*{%s}")
      ("\\chapter{%s}" . "\\chapter*{%s}")
      ("\\section{%s}" . "\\section*{%s}")
      ("\\subsection{%s}" . "\\subsection*{%s}")
      ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))))
 '(org-latex-packages-alist
   '("\\linespread{1.1}"
     ("sc" "mathpazo" nil)
     ("AUTO" "babel" nil)
     ("margin=2cm" "geometry" nil)))
 '(read-buffer-completion-ignore-case t)
 '(read-file-name-completion-ignore-case t)
 '(reftex-plug-into-AUCTeX t)
 '(send-mail-function 'sendmail-send-it)
 '(sendmail-program "msmtp")
 '(shr-cookie-policy nil)
 '(shr-inhibit-images t)
 '(shr-use-colors nil)
 '(tool-bar-mode nil))

(define-key key-translation-map [?\C-h] [?\C-?])
(define-key key-translation-map [?\C-?] [?\C-h])
(define-key key-translation-map [?\M-h] [?\M-\d])
(define-key key-translation-map [?\M-\d] [?\M-h])

(global-set-key (kbd "C-c l") #'org-store-link) 
(global-set-key (kbd "C-c a") #'org-agenda)
(global-set-key (kbd "C-c c") #'org-capture)
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "M-n") #'org-next-link)
  (define-key org-mode-map (kbd "M-p") #'org-previous-link)
  (define-key org-cdlatex-mode-map (kbd "^") nil)
  (define-key org-cdlatex-mode-map (kbd "_") nil)
  (add-to-list 'ispell-skip-region-alist '("#\\+begin_src". "#\\+end_src")))

(add-hook 'org-mode-hook 'turn-on-auto-fill)
(add-hook 'text-mode-hook 'turn-on-auto-fill)
(add-hook 'TeX-after-compilation-finished-functions
           #'TeX-revert-document-buffer)
(add-hook 'message-setup-hook 'mml-secure-message-sign)

(defun dired-open-file ()
  "In dired, open the file named on this line."
  (interactive)
  (let* ((file (dired-get-filename nil t)))
    (call-process "xdg-open" nil 0 nil file)))

(eval-after-load "dired" '(progn
  (define-key dired-mode-map (kbd "C-o") 'dired-open-file)))

(use-package cdlatex
  :config
  (add-hook 'LaTeX-mode-hook #'turn-on-cdlatex)
  (add-hook 'latex-mode-hook #'turn-on-cdlatex)
  (add-hook 'org-mode-hook #'turn-on-org-cdlatex))

(use-package pyim-basedict
  :init
  (pyim-basedict-enable))

(use-package pyim)

(use-package notmuch
  :config
  (setq notmuch-always-prompt-for-sender nil)
  (setq notmuch-fcc-dirs "apvc.uk/Sent/")
  (define-key notmuch-search-mode-map "d"
	      (lambda (&optional beg end)
		"mark message as passed"
		(interactive (notmuch-interactive-region))
		(notmuch-search-tag (list "+passed") beg end)
		(notmuch-search-next-thread)))
  (define-key notmuch-search-mode-map "f"
	      (lambda (&optional beg end)
		"mark message as flagged"
		(interactive (notmuch-interactive-region))
		(notmuch-search-tag (list "+flagged") beg end)
		(notmuch-search-next-thread))))

(add-hook 'LaTeX-mode-hook 'turn-on-reftex)
(add-hook 'latex-mode-hook 'turn-on-reftex)

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(electric-pair-mode t)

;; wayland paste
;; credit: yorickvP on Github
(setq wl-copy-process nil)

(defun wl-copy (text)
  (setq wl-copy-process
	(make-process
	 :name "wl-copy"
         :buffer nil
         :command '("wl-copy" "-f" "-n")
         :connection-type 'pipe))
  (process-send-string wl-copy-process text)
  (process-send-eof wl-copy-process))

(defun wl-paste ()
  (if (and wl-copy-process (process-live-p wl-copy-process))
      nil ; should return nil if we're the current paste owner
    (shell-command-to-string "wl-paste -n | tr -d \r")))
