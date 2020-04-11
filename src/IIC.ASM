

;; IIC_TX
;; function : transfer 5 bytes from iic_buff to iic bus
;; input    : iic_buff
;; output   : to iic
;; variables: rega, regx
;; constants: scl
;;            sda
;;            iicport
;;            iicont


;; input in a register
byte_iic:       bset            sda,iicont      ; set sda as output port
                ldx             #8              ; count of 8 bits
bit_iic:        rola                            ; shift msb to carry
                bcc             sda_low         ; if no carry(msb low)
sda_high:       bset            sda,iicport     ; carry set msb high
                bra             pulse_scl
sda_low:        bclr            sda,iicport
pulse_scl:      bsr             delay_small     ; delay
                bset            scl,iicport     ; set scl high
                bsr             delay_small
                bclr            scl,iicport     ; then scl is set low
 ;              bsr             delay_small
                decx                            ; is count over
                bne             bit_iic         ; no next bit
                bclr            sda,iicont      ; leave sda high by making it input
                bsr             delay_small
                bsr             delay_small
                bset            scl,iicport
                bsr             delay_small
                clc                             ; normal - clear carry
                brclr           sda,iicport,byte_over ;error if ackn not rcvd
                sec                             ; error - set carry
byte_over:      bclr            scl,iicport     ; set scl low
                bsr             delay_small
                bsr             delay_small
                bclr            sda,iicport     ;
                rts                             ; leave with sda as input

delay_small:    nop
                nop
                nop
                nop
                nop
                nop
                rts


set_eeprom_info
iic_tx:
;; generate start condition
;; first set sda then scl then make sda low while scl is high
;; on return sda is low and scl is low
;; variables : iic_counter,iic_buff(six bytes)

restart_tx:

                bsr             gen_start
                lda             #0a0h
                bsr             byte_iic
                bcs             restart_tx          ; restart if carry set
                lda             e_add
                bsr             byte_iic
                bcs             restart_tx
                lda             e_dat
                bsr             byte_iic
                bcs             restart_tx


;; generate stop condition
;; sda is set as output and low
;; fisrt sda is cleared  the scl is set high
;; then make sda high keeping scl high
;; on return scl is high and sda is also high

gen_stop:       bclr            sda,iicport
                bset            sda,iicont              ; set sda as output
                jsr             delay_small
                bset            scl,iicport
                bsr             delay_small
                bset            sda,iicport             ; leave with sda and
                rts                                     ; scl high and output


gen_start:      bset            sda,iicont              ; sda as o/p
                bset            sda,iicport             ; and high
                bsr             delay_small
                bset            scl,iicport             ; scl also high
                bsr             delay_small

                bclr            sda,iicport
                bsr             delay_small
                bclr            scl,iicport
                rts




get_eeprom_info
;; iic_rx
;; generate start byte
;; transfer address byte with bit 0 set to 1
;; if memory write e_add also
;; read one byte
;; and save in iic_status
;; generate stop byte
;; input : iicbuff (one byte- address of iic)
;; output : iic_status
;; variables : rega,regx
;; constants : scl,sda,iicport,iicont
iic_rx:
restart_rx:

                bsr             gen_start
                lda             #0a0h
dev_addr:       jsr             byte_iic                ; sda is input on return
                bcs             restart_rx
                lda             e_add
                jsr             byte_iic                ; second byte as mem add
                bcs             restart_rx
                bsr             gen_start
                lda             #0a1h
                jsr             byte_iic                ; sda is input on return
read_iicbyte:   ldx             #8
read_iicbit:    bset            scl,iicport             ; set scl high
;               jsr             delay_small             ; delay
;               bclr            scl,iicport             ; and again low
                brset           sda,iicport,iic_1       ; read data bit
iic_0           clc
                bra             read_iic
iic_1           sec
read_iic        rola
                jsr             delay_small             ; delay
                bclr            scl,iicport             ; and again low
                decx
                bne             read_iicbit
                sta             e_dat
                bra             gen_stop


