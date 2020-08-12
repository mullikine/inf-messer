;;; Commentary:

;; inf-messer.el provides a REPL buffer connected to a messer shell
;; (messer) subprocess.

;; In your emacs config:

;; (add-to-list 'load-path "~/.emacs.d/vendor/inf-messer")
;; (require 'inf-messer)

;; Usage

;; Run with `M-x inf-messer'

;;; Code:

;; (require 'js)
(require 'comint)

;;;###autoload
(defgroup inf-messer nil
  "Run a messer shell (messer) process in a buffer."
  :group 'inf-messer)

;;;###autoload
(defcustom inf-messer-command "messer"
  "Default messer shell command used.")

;;;###autoload
(defcustom inf-messer-mode-hook nil
  "*Hook for customizing inf-messer mode."
  :type 'hook
  :group 'inf-messer)

(add-hook 'inf-messer-mode-hook 'ansi-color-for-comint-mode-on)

;;;###autoload
(defun inf-messer (cmd &optional dont-switch-p)
  "Major mode for interacting with an inferior messer shell (messer) process.

The following commands are available:
\\{inf-messer-mode-map}

A messer shell process can be fired up with M-x inf-messer.

Customisation: Entry to this mode runs the hooks on comint-mode-hook and
inf-messer-mode-hook (in that order)."
  (interactive (list (read-from-minibuffer "Run messer shell: "
                                           inf-messer-command)))

  (if (not (comint-check-proc "*messer*"))
      (save-excursion (let ((cmdlist (split-string cmd)))
        (set-buffer (apply 'make-comint "messer" (car cmdlist)
                           nil (cdr cmdlist)))
        (inf-messer-mode)
        (setq inf-messer-command cmd) 
        (setq inf-messer-buffer "*messer*")
        ;; (inf-messer-setup-autocompletion)
        )))
  (if (not dont-switch-p)
      (pop-to-buffer "*messer*")))

;;;###autoload
(defun messer-send-region (start end)
  "Send the current region to the inferior messer process."
  (interactive "r")
  (inf-messer inf-messer-command t)
  (comint-send-region inf-messer-buffer start end)
  (comint-send-string inf-messer-buffer "\n"))

;;;###autoload
(defun messer-send-region-and-go (start end)
  "Send the current region to the inferior messer process."
  (interactive "r")
  (inf-messer inf-messer-command t)
  (comint-send-region inf-messer-buffer start end)
  (comint-send-string inf-messer-buffer "\n")
  (switch-to-inf-messer inf-messer-buffer))

;;;###autoload
(defun messer-send-last-sexp-and-go ()
  "Send the previous sexp to the inferior messer process."
  (interactive)
  (messer-send-region-and-go (save-excursion (backward-sexp) (point)) (point)))

;;;###autoload
(defun messer-send-last-sexp ()
  "Send the previous sexp to the inferior messer process."
  (interactive)
  (messer-send-region (save-excursion (backward-sexp) (point)) (point)))

;;;###autoload
(defun messer-send-buffer ()
  "Send the buffer to the inferior messer process."
  (interactive)
  (messer-send-region (point-min) (point-max)))

;;;###autoload
(defun messer-send-buffer-and-go ()
  "Send the buffer to the inferior messer process."
  (interactive)
  (messer-send-region-and-go (point-min) (point-max)))

;;;###autoload
(defun switch-to-inf-messer (eob-p)
  "Switch to the messer process buffer.
With argument, position cursor at end of buffer."
  (interactive "P")
  (if (or (and inf-messer-buffer (get-buffer inf-messer-buffer))
          (messer-interactively-start-process))
      (pop-to-buffer inf-messer-buffer)
    (error "No current process buffer. See variable inf-messer-buffer."))
  (when eob-p
    (push-mark)
    (goto-char (point-max))))

(defvar inf-messer-buffer)

;; (defvar inf-messer-auto-completion-setup-code
;;   "function INFMONGO__getCompletions(prefix) {
;;       shellAutocomplete(prefix);
;;       return(__autocomplete__.join(\";\"));
;;   }"
;;   "Code executed in inferior messer to setup autocompletion.")

;; (defun inf-messer-setup-autocompletion ()
;;   "Function executed to setup autocompletion in inf-messer."
;;   (comint-send-string (get-buffer-process inf-messer-buffer) inf-messer-auto-completion-setup-code)
;;   (comint-send-string (get-buffer-process inf-messer-buffer) "\n")
;;   (define-key inf-messer-mode-map "\t" 'complete-symbol))

(defvar inf-messer-prompt "\n> \\|\n.+> "
  "String used to match inf-messer prompt.")

(defvar inf-messer--shell-output-buffer "")

(defvar inf-messer--shell-output-filter-in-progress nil)

(defun inf-messer--shell-output-filter (string)
  "This function is used by `inf-messer-get-result-from-inf'.
It watches the inferior process until, the process returns a new prompt,
thus marking the end of execution of code sent by
`inf-messer-get-result-from-inf'.  It stores all the output from the
process in `inf-messer--shell-output-buffer'.  It signals the function
`inf-messer-get-result-from-inf' that the output is ready by setting
`inf-messer--shell-output-filter-in-progress' to nil"
  (setq string (ansi-color-filter-apply string)
	inf-messer--shell-output-buffer (concat inf-messer--shell-output-buffer string))
  (let ((prompt-match-index (string-match inf-messer-prompt inf-messer--shell-output-buffer)))
    (when prompt-match-index
      (setq inf-messer--shell-output-buffer
	    (substring inf-messer--shell-output-buffer
		       0 prompt-match-index))
      (setq inf-messer--shell-output-filter-in-progress nil)))
  "")

(defun inf-messer-get-result-from-inf (code)
  "Helper function to execute the given CODE in inferior messer and return the result."
  (let ((inf-messer--shell-output-buffer nil)
        (inf-messer--shell-output-filter-in-progress t)
        (comint-preoutput-filter-functions '(inf-messer--shell-output-filter))
        (process (get-buffer-process inf-messer-buffer)))
    (with-local-quit
      (comint-send-string process code)
      (comint-send-string process "\n")
      (while inf-messer--shell-output-filter-in-progress
        (accept-process-output process))
      (prog1
          inf-messer--shell-output-buffer
        (setq inf-messer--shell-output-buffer nil)))))

(defun inf-messer-shell-completion-complete-at-point ()
  "Perform completion at point in inferior-messer.
Most of this is borrowed from python.el"
  ;; (let* ((start
  ;;         (save-excursion
  ;;           (with-syntax-table js-mode-syntax-table
  ;;             (let* ((syntax-list (append (string-to-syntax ".")
	;; 				  (string-to-syntax "_")
	;; 				  (string-to-syntax "w"))))
  ;;               (while (member
  ;;                       (car (syntax-after (1- (point)))) syntax-list)
  ;;                 (skip-syntax-backward ".w_")
  ;;                 (when (or (equal (char-before) ?\))
  ;;                           (equal (char-before) ?\"))
  ;;                   (forward-char -1)))
  ;;               (point)))))
  ;;        (end (point)))
  ;;   (list start end
  ;;         (completion-table-dynamic
  ;;          (apply-partially
  ;;           #'inf-messer-get-completions-at-point))))
  )

(defun inf-messer-get-completions-at-point (prefix)
  "Get completions for PREFIX using inf-messer."
  (if (equal prefix "") 
      nil
    (split-string (inf-messer-get-result-from-inf (concat "INFMONGO__getCompletions('" prefix "');")) ";")))

;;;###autoload
(defvar inf-messer-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-x\C-e" 'messer-send-last-sexp)
    map))

;;;###autoload
(define-derived-mode inf-messer-mode comint-mode "Inferior messer mode"
  (make-local-variable 'font-lock-defaults)
  ;; (setq font-lock-defaults (list js--font-lock-keywords))

  ;; (make-local-variable 'syntax-propertize-function)
  ;; (setq syntax-propertize-function #'js-syntax-propertize)

  ;; (add-hook 'before-change-functions #'js--flush-caches t t)
  ;; (js--update-quick-match-re)

  (add-to-list (make-local-variable 'comint-dynamic-complete-functions)
               'inf-messer-shell-completion-complete-at-point)

  (use-local-map inf-messer-mode-map))

(provide 'inf-messer)
;;; inf-messer.el ends here
