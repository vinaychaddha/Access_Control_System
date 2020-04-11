

scan_table:    db    0eh,0dh,0bh,07h
key_scan_port   equ     porta

;; sense2 line is at irq

kbd_sense
sense_line      lda     key_port                ;read key port
                and     #30h
                bil     key_found
                ora     #40h
                cmp     #70h
                bne     key_found               ; no some key pressed
                bra     no_key_found            ; yes no key pressed

key_found       sta     kbd_temp
                lda     key_port                ;compare key_port with kbd table
                and     #0fh                    ; remove unused line
                ora     kbd_temp
                clrx

try_nxt_code    cmp     kbd_table,x
                beq     key_matched             ;if equal goto key matched
                incx                            ;else increment index register
                cmpx    #max_keys               ;compare it with maximum keys
                bne     try_nxt_code            ;if not equal goto try nxt code

no_key_found    ldx     #0fh                    ;
key_matched     txa                              ;load accumulator with 'X'
                cmp     kbd_pos                  ;compare it with kbd pos
                beq     ret_kbs                  ;if equal return
                cmp     last_key                 ;compare it with last key
                bne     new_key                  ;if equal return
                inc     same_key                 ;else goto new key & inc same
                lda     same_key                 ;for max debounce load same key
                cmp     #max_debounce            ;compare it with 4
                bne     ret_kbs                  ;if not equal goto ret kbs
upd_key         lda     last_key                 ;load last key
                sta     kbd_pos                  ;store it at kbd pos
                cmp     #0fh                    ;is it key release
                beq     ret_kbs                  ;yes-do not set flag
                bset    new_key_found,status     ;set bit of new key found in
                bra     ret_kbs                  ;status and goto ret kbs

new_key         sta     last_key
                clr     same_key
                bra     kbs_over

ret_kbs         lda     kbd_pos                  ;load kbd pos
                cmp     #0fh                    ;
                bne     kbs_over                 ;



change_sense    inc     key_scan_cntr
                lda     key_scan_cntr
                cmp     #04
                blo     cs1
                clr     key_scan_cntr

cs1:            lda     key_scan_port
                and     #0f0h
                sta     key_scan_port           ; reset all scan lines to zero on ports

                ldx     key_scan_cntr           ; output scan table to scan port one by one
                lda     scan_table,x
                ora     key_scan_port
                sta     key_scan_port
ret_sense_line
kbs_over        rts

max_keys        equ     12t

$if testing
max_debounce    equ     1
$elseif
max_debounce    equ     3t
$endif

;; code1                pin
;;scan0           bit     pa0     ; 16
;;scan1           bit     pa1     ; 15
;;scan2           bit     pa2     ; 14
;;scan3           bit     pa3     ; 13
;;sense0          bit     pa4     ; 12
;;sense1          bit     pa5     ; 11
;;sense2          bit     irq

;; code 0       13-irq  (pa3-pa5)
;; code 1       16-12   (pa0-pa4)
;; code 2       16-11   (pa0-pa5)

;; code 3       16-irq  (pa0-irq)
;; code 4       15-12   (pa1-pa4)
;; code 5       15-11   (pa1-pa5)

;; code 6       15-irq  (pa1-irq)
;; code 7       14-12   (pa2-pa4)
;; code 8       14-11   (pa2-pa5)

;; code 9       14-irq  (pa2-irq)
;; code 10      13-12   (pa3-pa4)       ;; key program

;; code 12      13-11   (pa3-irq)       ;; key program ok


kbd_table       db      057h            ;; code for 00
                db      06eh            ;; code for 01
                db      05eh            ;; code for 02
                db      03eh            ;; code for 03
                db      06dh            ;; code for 04
                db      05dh            ;; code for 05
                db      03dh            ;; code for 06
                db      06bh            ;; code for 07
                db      05bh            ;; code for 08
                db      03bh            ;; code for 09
                db      067h            ;; code for pgm key
                db      037h            ;; code for pgm ok key


