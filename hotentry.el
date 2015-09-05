;;; hotentry.el --- hotentry script in Emacs Lisp

;; Author: Syohei YOSHIDA <syohex@gmail.com>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'url)
(require 'xml)
(require 'cl-lib)

(eval-when-compile
  (defvar url-http-end-of-headers))

(defun -hotentry-url (keyword users)
  (format "http://b.hatena.ne.jp/search/tag?q=%s&users=%d&mode=rss"
          keyword users))

(defun -parse-rss (url)
  (let ((buf (url-retrieve-synchronously url t)))
    (with-current-buffer buf
      (goto-char url-http-end-of-headers)
      (let* ((data (libxml-parse-xml-region (1+ (point)) (point-max)))
             (items (cddr (cddr data))))
        (cl-loop for item in items
                 for title = (cadr (assoc-default 'title item))
                 for bookmarks = (cadr (assoc-default 'bookmarkcount item))
                 collect
                 (list :title title :bookmarks bookmarks))))))

(defun -format-entry (index entry)
  (format "%2d: %s [%s]\n"
          index (plist-get entry :title) (plist-get entry :bookmarks)))

(defun -hotentry (keyword users count)
  (let* ((url (-hotentry-url keyword users))
         (entries (-parse-rss url)))
    (cl-loop for entry in entries
             for i = 1 then (1+ i)
             when (<= i count)
             do
             (princ (-format-entry i entry)))))

(defun main ()
  (let ((keyword (nth 0 argv))
        (arg1 (nth 1 argv))
        (arg2 (nth 2 argv)))
    (let ((users (if arg1 (string-to-number arg1) 3))
          (count (if arg2 (string-to-number arg2) 20)))
      (-hotentry keyword users count))))

(main)

;;; hotentry.el ends here
