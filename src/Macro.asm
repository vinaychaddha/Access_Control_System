
$macro          chk_mem
                bclr            bad_mem,status  ;; clear flag bad_mem
                jsr             gen_start       ;; call gen_start
                lda             #0a0h           ;; send device add = 0a0h
                jsr             byte_iic        ;; to memory
                bcc             cm_over         ;; of carry clear then return
                bset            bad_mem,status  ;; if carry set then set flag
cm_over                                         ;; bad mem
$macroend


;; clear memory from 0c0h
$macro          clear_mem
                ldx     #0c0h          ;clear memory
next_mm         clr     ,x
                incx
                bne     next_mm
$macroend


;; intialise timer
$macro          init_timer
                lda     #def_timer
                sta     tscr
                cli                     ;enable interrupt
$macroend



;; intialise porta , portb
$macro          init_port       port
                lda             #def_%1
                sta             %1
$macroend


