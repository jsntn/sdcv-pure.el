;;; sdcv-pure.el --- Elisp version of sdcv -*- lexical-binding: t; -*-

;; Author: Jason Tian <hi@jsntn.com>
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: dictionary
;; URL: https://github.com/jsntn/sdcv-pure.el

;; This file is *NOT* part of GNU Emacs

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; A copy of the GNU General Public License can be obtained from this
;; program's author (send electronic mail to andyetitmoves@gmail.com)
;; or from the Free Software Foundation, Inc.,
;; 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

;;; Commentary:

;; This is based on the codes from,
;; https://github.com/redguardtoo/emacs.d/blob/be57e47c974015bb4623b1d32f41fed5b126d229/lisp/init-dictionary.el
;; with some updates to support multiple dictionaries lookup.

;; Usage,
;;
;; (defvar sdcv-simple-dict
;;   `("~/.stardict/dic/stardict-lazyworm-ec-2.4.2")
;;   "Dictionary to search")
;; (defvar sdcv-multiple-dicts
;;   `(("~/.stardict/dic/stardict-lazyworm-ec-2.4.2")
;;     ("~/.stardict/dic/stardict-langdao-ce-gb-2.4.2")
;;     ("~/.stardict/dic/stardict-langdao-ec-gb-2.4.2")
;;     ("~/.stardict/dic/stardict-cedict-gb-2.4.2")
;;     ("~/.stardict/dic/stardict-DrEye4in1-2.4.2"))
;;   "List of dictionaries to search.")

;; (global-set-key (kbd "C-c d") 'sdcv-simple-definition)
;; (global-set-key (kbd "C-c D") 'sdcv-complete-definition)

;;; Code:


(require 'stardict)
(require 'popup)

(defvar sdcv-result-buffer-name "*SDCV*"
  "The buffer of my dictionary lookup.")

(defvar sdcv-mode-font-lock-keywords
  '(;; Dictionary name
    ("^-->\\(.*\\)\n-" . (1 font-lock-type-face))
    ;; Search word
    ("^-->\\(.*\\)[ \t\n]*" . (1 font-lock-function-name-face))
    ;; Serial number
    ("\\(^[0-9] \\|[0-9]+:\\|[0-9]+\\.\\)" . (1 font-lock-constant-face))
    ;; Type name
    ("^<<\\([^>]*\\)>>$" . (1 font-lock-comment-face))
    ;; Phonetic symbol
    ("^/\\([^>]*\\)/$" . (1 font-lock-string-face))
    ("^\\[\\([^]]*\\)\\]$" . (1 font-lock-string-face)))
  "Expressions to highlight in `sdcv-mode'.")

(define-derived-mode sdcv-mode nil "SDCV"
  "Major mode for displaying StarDict dictionary results."
  (setq font-lock-defaults '(sdcv-mode-font-lock-keywords t))
  (setq buffer-read-only t))

(defvar sdcv-simple-dict-cache nil "Internal variable.")
(defvar sdcv-multiple-dicts-cache nil "Internal variable.")

(defun sdcv-prompt-input ()
  "Prompt input for translate."
  (let* ((word (if mark-active
		   (buffer-substring-no-properties (region-beginning)
						   (region-end))
		 (thing-at-point 'word))))
    (setq word (read-string (format "Word (%s): " (or word ""))
			    nil nil
			    word))
    (if word (downcase word))))

(defun sdcv-quit-window ()
  "Quit window."
  (interactive)
  (quit-window t))

(defun sdcv-jump-to-next-dict ()
  "Jump to the next dictionary entry in the buffer."
  (interactive)
  (let ((start-pos (point)))
    ;; If we're on a dictionary line, move forward first
    (when (looking-at "^--> \\[")
      (forward-line 1))
    ;; Search for the next dictionary marker
    (if (re-search-forward "^--> \\[" nil t)
        (progn
          (beginning-of-line)
          (recenter 0)) ; Scroll to show dictionary name at top
      ;; If not found, stay at original position
      (goto-char start-pos)
      (message "No more dictionaries below"))))

(defun sdcv-jump-to-prev-dict ()
  "Jump to the previous dictionary entry in the buffer."
  (interactive)
  (let ((start-pos (point)))
    ;; Move to beginning of line to avoid matching current line
    (beginning-of-line)
    ;; Search backwards for previous dictionary marker
    (if (re-search-backward "^--> \\[" nil t)
        (progn
          (beginning-of-line)
          (recenter 0)) ; Scroll to show dictionary name at top
      ;; If not found, stay at original position
      (goto-char start-pos)
      (message "No more dictionaries above"))))

(defun sdcv-get-cache (dict-path dict-name)
  "Retrieve or initialize the cache for DICT-PATH and DICT-NAME."
  (or (cdr (assoc dict-path sdcv-multiple-dicts-cache))
      (let ((cache (stardict-open dict-path dict-name t)))
	(push (cons dict-path cache) sdcv-multiple-dicts-cache)
	cache)))

(defmacro sdcv-search-detail (word dict cache)
  "Return WORD's definition with DICT, CACHE."
  `(when ,word
     (unless (featurep 'stardict) (require 'stardict))
     (unless ,cache
       (setq ,cache
	     (stardict-open (nth 0 ,dict)
			    (sdcv-get-dict-name (nth 0 ,dict))
			    t)))
     (stardict-lookup ,cache word)))

(defun sdcv-find-ifo-file (dict-path)
  "Find the .ifo file in the DICT-PATH.
Returns the full path of the .ifo file or nil if not found."
  (let ((ifo-file (car (directory-files dict-path t "\\.ifo$"))))
    (when (and ifo-file (file-exists-p ifo-file))
      ifo-file)))

(defun sdcv-get-bookname (dict-path)
  "Retrieve the bookname from the .ifo file in DICT-PATH.
Searches for the .ifo file dynamically in the dictionary folder."
  (let ((ifo-file (sdcv-find-ifo-file dict-path))
	(bookname nil))
    (when ifo-file
      (with-temp-buffer
	(insert-file-contents ifo-file)
	(goto-char (point-min))
	(when (re-search-forward "^bookname=\\(.*\\)$" nil t)
	  (setq bookname (match-string 1)))))
    bookname))

(defun sdcv-find-dict-file (dict-path)
  "Find the .dict.dz file in the DICT-PATH.
Returns the full path of the .dict.dz file or nil if not found."
  (let ((dict.dz-file (car (directory-files dict-path t "\\.dict.dz$"))))
    (when (and dict.dz-file (file-exists-p dict.dz-file))
      dict.dz-file)))

(defun sdcv-get-dict-name (dict-path)
  "Retrieve the dict-name based on the .dict.dz file in DICT-PATH."
  (let ((dict.dz-file (sdcv-find-dict-file dict-path))
	(dict-name nil))
    (string-remove-suffix ".dict.dz"
			  (file-name-nondirectory dict.dz-file))))

(defun sdcv-search-all (word)
  "Search WORD in all dictionaries and return concatenated results.
Uses the bookname from the dictionary's .ifo file as the dictionary name.
Returns nil if no results are found."
  (let ((results
	 (delq nil ; remove nil entries
	       (mapcar
		(lambda (dict)
		  (let* ((dict-path (nth 0 dict))
			 (dict-name (sdcv-get-dict-name dict-path))
			 (dict-name-display (or (sdcv-get-bookname dict-path)
						"Unknown Dictionary")) ; fallback if bookname is missing
			 (cache (sdcv-get-cache dict-path dict-name))
			 (result (stardict-lookup cache word)))
		    (when result
		      (format "--> [%s]\n\n%s" dict-name-display result))))
		sdcv-multiple-dicts))))
    (when results
      (mapconcat #'identity results "\n\n\n")) ; combine with a blank lines in between
    ))

(defun sdcv-complete-definition ()
  "Show multiple dictionaries lookup in buffer."
  (interactive)
  (let* ((word (sdcv-prompt-input))
	 (defs (sdcv-search-all word)))
    (if defs
	(let ((buf (get-buffer-create sdcv-result-buffer-name))
	      win)
	  (with-current-buffer buf
	    (sdcv-mode) ; See https://github.com/redguardtoo/emacs.d/pull/1073
	    (setq buffer-read-only nil)
	    (erase-buffer)
	    (insert defs)
	    (goto-char (point-min))

            (local-set-key (kbd "q") 'sdcv-quit-window)
            (local-set-key (kbd "C-f") 'sdcv-jump-to-next-dict)
            (local-set-key (kbd "C-k") 'sdcv-jump-to-prev-dict)
            (when (and (boundp 'evil-mode) evil-mode)
              (evil-local-set-key 'normal (kbd "q") 'sdcv-quit-window)
              (evil-local-set-key 'normal (kbd "C-f") 'sdcv-jump-to-next-dict)
              (evil-local-set-key 'normal (kbd "C-k") 'sdcv-jump-to-prev-dict)))

          (unless (eq (current-buffer) buf)
            (if (null (setq win (get-buffer-window buf)))
                (switch-to-buffer-other-window buf)
              (select-window win))))
      (message "No results found.") ; inform the user if no results are found
      )))

(defun sdcv-simple-definition ()
  "Show dictionary lookup in popup."
  (interactive)
  (let* ((word (sdcv-prompt-input))
	 (def (sdcv-search-detail word sdcv-simple-dict sdcv-simple-dict-cache)))
    (when def
      (unless (featurep 'popup) (require 'popup))
      (popup-tip def))))


(provide 'sdcv-pure)
;;; sdcv-pure.el ends here
