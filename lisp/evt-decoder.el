;; unit test framwork
;; (require 'ert)


;;; Code:
(defconst event-type-table-evt21
      '(("0" . "D-")
        ("1" . "D+")
        ("8" . "TH")
        ("A" . "T!")
        ("E" . "*" )
        )
      "Table of event type in EVT2.1 format."
      )

(defconst event-type-table-evt30
      '(("0" . "CDY")
        ("2" . "XPOS")
        ("3" . "XBAS")
        ("4" . "V12")
        ("5" . "V8")
        ("6" . "TL")
        ("8" . "TH")
        ("A" . "T!")
        ("E" . "*" )
        )
      "Table of event type in EVT3.0 format."
      )


(defvar hex-dump-highlight-colors
  '(
    ;; Common
    ("TL" . "#000070")
    ("TH" . "#700070")
    ("T!" . "#F00000")
    ("*"  . "#707070")
    ;; EVT21 only
    ("D-" . "#007000")
    ("D+" . "#700000")
    ;; EVT30 only
    ("V8"  . "green")
    ("V12" . "dark-green")
    )
  "Backgroud color for each type.")


;; helper to get one hexadecimal byte string with optional space
(defconst hex-digit-byte (concat
                     "\\(?:"                                   ;; start shy group
                     "[[:xdigit:]][[:xdigit:]][[:space:]]?"    ;; "XX" with option space at the end
                     "\\)"                                     ;; stop shy group
                     ))

;; helper to swap endiannes
(defun swap-endianness (hex-string)
  "Convert endianness of HEX-STRING in 4-byte (8 hex digits) chunks.
Input may optionally contain spaces between bytes."
  (let* ((cleaned (replace-regexp-in-string "[ \t\n]+" "" hex-string))  ; remove all whitespace
         (result "")
         (i 0))
    (let* ((bytes (seq-reverse (seq-partition cleaned 2)))
           (reversed (apply #'concat bytes)))
      (setq result (concat result reversed)))
    result))

;; unit test
(ert-deftest test-swap-endianness ()
  (should (string-equal (swap-endianness "00 00 00 00 E1 35 04 80") "800435E100000000" ))
  (should (string-equal (swap-endianness "00 40 00 00 00 00 C4 12") "12C4000000004000" ))
  ;; with optional space
  (should (string-equal (swap-endianness "00400000 0000C412") "12C4000000004000" ))
  (should (string-equal (swap-endianness "0000 0000 E135 0480") "800435E100000000" ))
  )


;; evt21 decoder
(defun decode-evt21 (hex-string-little-endian)
  "Decode event type and related value:
    - input: hexa string in big endian (starting with MSB) without space
    - output: list with event type name and value
   Example: \"800435E100000000\" => (\"TH\". #x435E1)
"
  (let* (
         (hex-string-big-endian (swap-endianness hex-string-little-endian))
         (type-nibble (substring hex-string-big-endian 0 1))
         (type (cdr (assoc type-nibble event-type-table-evt21)))
         (value-str (substring hex-string-big-endian 1 8))
         (value (string-to-number value-str 16)))
    (cons (or type "?") value))
  )

;; unit test
(ert-deftest test-decode-evt21 ()
  (should (equal (decode-evt21 "00 00 00 00 01 00 00 80") '("TH" . 1)))
  (should (equal (decode-evt21 "00 00 00 00 10 00 00 80") '("TH" . 16)))
  (should (equal (decode-evt21 "00 00 00 00 00 01 00 80") '("TH" . 256)))
  (should (equal (decode-evt21 "00 00 00 00 E1 35 04 80") '("TH" . #x435E1)))
  (should (equal (decode-evt21 "00 00 00 00 00 01 00 00") '("D-" . 256)))
  )

;; evt30 decoder
(defun decode-evt30 (hex-string-little-endian)
  "Decode event type and related value:
    - input: hexa string in big endian (starting with MSB) without space
    - output: list with event type name and value
   Example: \"800435E100000000\" => (\"TH\". #x435E1)
"
  (let* (
         (hex-string-big-endian (swap-endianness hex-string-little-endian))
         (type-nibble (substring hex-string-big-endian 0 1))
         (type (cdr (assoc type-nibble event-type-table-evt30)))
         (value-str (substring hex-string-big-endian 1 4))
         (value (string-to-number value-str 16)))
    (cons (or type "?") value))
  )

;; unit test
(ert-deftest test-decode-evt30 ()
  (should (equal (decode-evt30 "c4 81") '("TH" . #x1c4)))
  (should (equal (decode-evt30 "c481") '("TH" . #x1c4)))
  )


;; main function that parse the buffer to highlight
(defun evt-highlight-hex-blocks (decode-fct evt-size-in-bytes)
  (save-excursion
    ;;(goto-char (point-min))
    (let ((case-fold-search nil))
      ;; Recherche de lignes avec dump hexadécimal.
      (while (re-search-forward
              (concat
               ;; 00000: 00 00 00 00 45 F2 68 00 00 00 00 00 46 F2 68 80
               "^[[:xdigit:]]+:[[:space:]]+"             ;; "0000: "
               "\\("                                     ;; start numbered group 1
               hex-digit-byte                            ;; "XX "
               "\\{16\\}"                                ;; 16 times
               "\\)"                                     ;; stop numbered group 1
               )
              nil t)
        (let ((start (match-beginning 1))
              (end (match-end 1)))
          (save-excursion
            (goto-char start)
            ;; Découpage en 8 blocs de 4 octets - evt3
            ;; (dotimes (i 8)

            ;; Découpage en 2 blocs de 8 octets - evt2.1
            (dotimes (i (/ 16 evt-size-in-bytes))
	      (let* ((event-str-search
                      ;; (re-search-forward (concat "\\(" hex-digit-byte "\\{2\\}" "\\)")))
                      (re-search-forward (concat "\\(" hex-digit-byte "\\{" (format "%d" evt-size-in-bytes) "\\}" "\\)")))
                     (block-start (match-beginning 1))
                     (block-end (match-end 1))
                     (hex-block (buffer-substring-no-properties block-start block-end))
                     (type-value (funcall decode-fct hex-block))
                     (type (car type-value))
                     (face-color (or (cdr (assoc type hex-dump-highlight-colors)) "darkgray"))
                     (decoded-content (format "%-4s" type))
                     ;;; (decoded-content (format "%-3s: %08x" type (cdr type-value)))
                     )
                (when (<= block-end (point-max))
                  (save-excursion
                    (end-of-line)
                    (insert (concat "  " decoded-content)
                    )
                  (let ((ov (make-overlay block-start block-end)))
                    (overlay-put ov 'face `(:background ,face-color))
                    (overlay-put ov 'help-echo decoded-content))))))))))
    )
  )


(defun evt21-highlight-hex-blocks ()
  "Parcourt le buffer et applique une coloration de fond aux blocs de 8 octets."
  (interactive)
  (evt-highlight-hex-blocks 'decode-evt21 8)
  )

(defun evt3-highlight-hex-blocks ()
  "Parcourt le buffer et applique une coloration de fond aux blocs de 8 octets."
  (interactive)
  (evt-highlight-hex-blocks 'decode-evt30 2)
  )


(provide 'evt-decoder)
