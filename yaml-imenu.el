;;; yaml-imenu.el --- Enhancement for the imenu support in yaml-mode.

;; Copyright (c) 2018 Akinori MUSHA
;;
;; All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;; SUCH DAMAGE.

;; Author: Akinori MUSHA <knu@iDaemons.org>
;; URL: https://github.com/knu/yaml-imenu.el
;; Created: 25 Sep 2018
;; Version: 0.1.0
;; Package-Requires: ((yaml-mode "0"))
;; Keywords: outlining, convenience, imenu

;;; Commentary:
;;
;; This package enhances the imenu support in `yaml-mode'.  It
;; generates an index containing a full list of keys that contain any
;; child, with key names in the dot-separated path form like
;; `jobs.build.docker' and `ja.activerecord.attributes.user.nickname'.
;; It shines great with `which-function-mode' enabled.

;;; Code:

(require 'yaml-mode)
(require 'json)

(defvar yaml-imenu-source-directory nil
  "Directory of yaml-imenu source files.")

(defun yaml-imenu-source-directory ()
  "Return the source directory of the yaml-imenu package."
  (or yaml-imenu-source-directory
      (setq yaml-imenu-source-directory
            (file-name-directory
             (find-lisp-object-file-name
              'yaml-imenu-source-directory
              (symbol-function 'yaml-imenu-source-directory))))))

;;;###autoload
(defun yaml-imenu-create-index ()
  "Create an imenu index for the current YAML file."
  (yaml-imenu--json-to-index
   (let ((json-object-type 'alist)
         (json-array-type 'list))
     (json-read-from-string
      (with-output-to-string
        (shell-command-on-region
         (point-min)
         (point-max)
         (mapconcat
          'shell-quote-argument
          (list
           "ruby"
           (expand-file-name "parse_yaml.rb" (yaml-imenu-source-directory)))
          " ")
         standard-output))))))

(defun yaml-imenu--json-to-index (alist)
  "Reformat the JSON representation ALIST into an imenu index."
  (loop for (key . value) in alist
        collect (cons (symbol-name key)
                      (if (numberp value)
                          (save-excursion
                            (goto-line value)
                            (point))
                        (yaml-imenu--json-to-index value)))))

;;;###autoload
(defun yaml-imenu-activate ()
  "Set the buffer local `imenu-create-index-function' to `yaml-imenu-create-index'."
  (setq imenu-create-index-function 'yaml-imenu-create-index))

;;;###autoload
(with-eval-after-load 'yaml-mode
  (remove-hook 'yaml-mode-hook 'yaml-set-imenu-generic-expression)
  (add-hook 'yaml-mode-hook 'yaml-imenu-activate))

(provide 'yaml-imenu)
;;; yaml-imenu.el ends here