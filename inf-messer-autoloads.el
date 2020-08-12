;;; inf-messer-autoloads.el --- automatically extracted autoloads
;;
;;; Code:

(add-to-list 'load-path (directory-file-name
                         (or (file-name-directory #$) (car load-path))))


;;;### (autoloads nil "inf-messer" "inf-messer.el" (0 0 0 0))
;;; Generated autoloads from inf-messer.el

(let ((loads (get 'inf-messer 'custom-loads))) (if (member '"inf-messer" loads) nil (put 'inf-messer 'custom-loads (cons '"inf-messer" loads))))

(defvar inf-messer-command "/home/shane/scripts/messer" "\
Default messer shell command used.")

(custom-autoload 'inf-messer-command "inf-messer" t)

(defvar inf-messer-mode-hook nil "\
*Hook for customizing inf-messer mode.")

(custom-autoload 'inf-messer-mode-hook "inf-messer" t)

(autoload 'inf-messer "inf-messer" "\
Major mode for interacting with an inferior messer shell (messer) process.

The following commands are available:
\\{inf-messer-mode-map}

A messer shell process can be fired up with M-x inf-messer.

Customisation: Entry to this mode runs the hooks on comint-mode-hook and
inf-messer-mode-hook (in that order).

\(fn CMD &optional DONT-SWITCH-P)" t nil)

(autoload 'messer-send-region "inf-messer" "\
Send the current region to the inferior messer process.

\(fn START END)" t nil)

(autoload 'messer-send-region-and-go "inf-messer" "\
Send the current region to the inferior messer process.

\(fn START END)" t nil)

(autoload 'messer-send-last-sexp-and-go "inf-messer" "\
Send the previous sexp to the inferior messer process.

\(fn)" t nil)

(autoload 'messer-send-last-sexp "inf-messer" "\
Send the previous sexp to the inferior messer process.

\(fn)" t nil)

(autoload 'messer-send-buffer "inf-messer" "\
Send the buffer to the inferior messer process.

\(fn)" t nil)

(autoload 'messer-send-buffer-and-go "inf-messer" "\
Send the buffer to the inferior messer process.

\(fn)" t nil)

(autoload 'switch-to-inf-messer "inf-messer" "\
Switch to the messer process buffer.
With argument, position cursor at end of buffer.

\(fn EOB-P)" t nil)

(defvar inf-messer-mode-map (let ((map (make-sparse-keymap))) (define-key map "" 'messer-send-last-sexp) map))

(autoload 'inf-messer-mode "inf-messer" "\


\(fn)" t nil)

(if (fboundp 'register-definition-prefixes) (register-definition-prefixes "inf-messer" '("inf-messer-")))

;;;***

;;;### (autoloads nil nil ("inf-messer-pkg.el") (0 0 0 0))

;;;***

;; Local Variables:
;; version-control: never
;; no-byte-compile: t
;; no-update-autoloads: t
;; coding: utf-8
;; End:
;;; inf-messer-autoloads.el ends here
