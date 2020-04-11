

;;*****************************************************************************
;;              PROJECT         :- ACCESS CONTROL (GENERAL)
;;              VERSION         :- 01
;;              STARTING DATE   :- 09-10-2k  day - monday
;;              IC              :- KJ1
;;              HARDWARE        :- 12 KEYS\1LED\1HOOTER\1MEMORY
;;              HARDWARE REC.   :- 06-10-2k
;;              FEATURES        :- ENTER PASSWORD TO OPEN DOOR
;;****************************************************************************


                org             0c0h
$setnot         testing
$include        "stdj1.asm"
$include        "ports.asm"
$include        "variable.asm"

key_word        equ           14h
key_word1       equ           28h
second_last_kw  equ           5h
last_key_word   equ           7h

et_buff         db              2

                org             300h

$include        "iic.asm"
$include        "macro.asm"
$include        "readkbd2.asm"

start:          rsp

;***************************** INITIALISE PORT ********************************

                init_port       ddra            ;; initialise port a
                init_port       porta

                init_port       ddrb            ;; initialise port b
                init_port       portb

;************************** CLEAR MEMORY\INITIALISE TIMER **********************************

                clear_mem                       ;; clear Ram

                init_timer                      ;; initialise timer

                chk_mem                         ;; check EEPROM


;; if bad_mem flag = 1 then goto read_defval
;; if bad_mem flag = 0 then read values from eeprom

                brset   bad_mem,status,read_defval


;; program comes here when bad_mem flag = 00
;; at power on e_add & mem_ptr = 00
;;************************* READ VALUES FROM EEPROM **************************
;; read 2 byte password/entry time from EEPROM
read_mem_val    clr     mem_ptr
                clr     e_add
read_nxt_val:   jsr     get_eeprom_info ;; read from eeprom
                lda     e_dat           ;; save read value in e_dat
                ldx     mem_ptr         ;; set index reg as pointer
                sta     password,x      ;; save read value in
                cmp     #0ffh           ;; if value read from EEPROM is ff then
                                        ;; goto read def val
                beq     read_defval
                inc     e_add           ;; increment e_add
                inc     mem_ptr         ;; increment ptr
                lda     mem_ptr
                cmp     #max_iic_bytes  ;; is all 3 bytes read
                bne     read_nxt_val    ;; if no goto read_mem_val
                bra     main_loop       ;; if yes goto main_loop


read_defval:    jsr     read_def_val

;;************************* MAIN LOOP ****************************************
;; after every one tick over call sense_kbd
;; after every half second over call chk_set_beep
;; after every second check kbd_timeout\entry_time_out
main_loop:      brclr   one_tick,tim_status,main_loop
                bclr    one_tick,tim_status
                jsr     kbd_sense

chk_hs_over     brclr   half_sec,tim_status,chk_1_sec
                bclr    half_sec,tim_status
                jsr     chk_set_beep

chk_1_sec       brclr   one_sec,tim_status,ret_act1sec
                bclr    one_sec,tim_status

;; program comes here after every second over
; ************************ DECREMENT KBD TIMEOUT *******************************
a1s_tstkbd      tst     kbd_timeout             ; if timeout = 0 then
                beq     tst_eto                 ; goto check for entry time
                dec     kbd_timeout             ; else decrement kbd time
                tst     kbd_timeout             ; again chk kbd timeout
                bne     tst_eto                 ; if # 0 goto tst_eto
                jsr     wrong_entry             ; give wrong entry signal


;************************* DECREMENT ENTRY TIME ******************************
;; check for entry time = 00
tst_eto:        tst     entry_time_out          ; if timeout = 00 then
                beq     ret_act1sec             ; ret_act1sec
                dec     entry_time_out          ; else decrement timeout
                tst     entry_time_out          ; again chk entry time
                bne     ret_act1sec             ; if # zero goto ret_act1sec
                bclr    led_arm,led_port        ; else ON led arm

ret_act1sec


; *********************** CHECK FOR KEY ***************************************
; if new key found flag set then goto act kbd else goto main_loop
chkbd           brclr   new_key_found,status,ret_chkbd  ; if new key found then set
                bclr    new_key_found,status            ; flag
                jsr     act_kbd                         ; call actkbd
ret_chkbd       jmp     main_loop                       ; else goto main loop


;***************************** ACTKBD ******************************************
;; set key press timeout to 10 seconds
act_kbd:        lda     #10t                    ; set key press timeout = 10secs
                sta     kbd_timeout

                lda     kbd_pos                 ; read kbd pos

;*************************** KEY PROGRAM OK PRESSED ****************************
act_kbd1:       cmp     #k_pgm_ok               ; is pgm ok key pressed
                bne     act_kbd2                ; if no goto act_kbd2
                jsr     chk_po_status           ; if yes call chk_po_status
                bra     ret_actkbd              ; goto ret_actkbd

;; program here checks for po_password\po_entry_time flag
;; if po_password\po_entry_time flag = 1 and if some other key press
;; accept pgm_ok_key then goto wrong entry
;; else goto chk_pgm_key
act_kbd2        brclr   po_password,entry_status,chk4poet
                jmp     wrong_entry

chk4poet:       brclr   po_entry_time,entry_status,chk_pgm_key
                jmp     wrong_entry

;*************************** KEY PROGRAM PRESSED *****************************
chk_pgm_key:    cmp     #k_program              ; is pgm_ok key press
                bne     act_kbd3                ; if no goto act_kbd3
                bset    pgm_mode,status         ; if yes set flag of pgm_mode
                clr     buff_pointer            ; clear all pointers
                clr     entry_status            ; clear entry status
                clr     kbd_timeout
                bra     ret_actkbd              ; give beep while returning



;************************** OTHER KEY PRESSED *********************************
;; check for password code
;; first chk for buff pointer is buffer pointer > 3 if yes then goto is_it_mode
;; else take first digit pressed in kbd_buff,second digit in kbd_buff+1
;; third digit in kbd_buff+2 & fourth digit in  kbd_buff+3

act_kbd3        ldx     buff_pointer    ;; is all 4 digit password enters
                cpx     #3
                bhi     is_it_mode      ;; if yes then goto is_it_mode
                lda     kbd_pos         ;; else store kbd_pos in kbd_buff+ptr
                sta     kbd_buff,x
                inc     buff_pointer    ;; increment pointer
                lda     buff_pointer    ;; is it 4th digit to be entered
                cmp     #4              ;; if no then return
                bne     ret_actkbd

;; program comes here when all 4 keys entered
;; check for valid code
;; if not valid code then give long beep and clear buff_pointer\kbd_timeout
;; and return
;; else clear sys_arm flag and give accp beep
                jsr     pack_buff               ; call pack buffer

;; check for 4 key press
;; if it is equals to password then
;;    return
;; if it is not equals to password then goto wrong entry
                lda    kbd_buff
                cmp    password
                bne    chk4master_kw
                lda    kbd_buff+1
                cmp    password+1
                bne    chk4master_kw

;; PROGRAM COMES HERE WHEN 4 DIGIT CORRECT PASSWORD IS ENTERED
                brset   pgm_mode,status,ret_actkbd
                bset    led_arm,led_port        ; off led arm
                lda     entry_time              ; set entry_time_out
                sta     entry_time_out          ;
                jmp     entry_over              ; call entry_over

;; here program checks for master key word
;; if key sequence entered is equals to first 4 mater key word then
;;    e_key_word flag is set
;; else
;;     long beep is heard as wrong entry

chk4master_kw:
                lda     kbd_buff
                cmp     #key_word                       ;; 14
                bne     wrong_entry
                lda     kbd_buff+1
                cmp     #key_word1                      ;; 28
                bne     wrong_entry
                bset    es_key_word,entry_status
                bra     ret_actkbd

;; program comes here when unit is in programming mode and 4 digit password enters
;; if 4 digit entered # password then goto wrong entry
;; else return
xxxx:           lda     kbd_buff                ; compare kbd_buff with
                cmp     password                ; password
                bne     wrong_entry             ; if # goto wrong entry
                lda     kbd_buff+1              ; if = compare kbd_buff+1 with
                cmp     password+1              ; password+1
                bne     wrong_entry             ; if # goto wrong entry
ret_actkbd      jmp     quick_beep              ; give small beep after every
                                                ; key press
ret_actkbd1:    rts                             ; return


is_it_mode:     cpx     #04                     ; is buffer pointer = 4
                bne     chk4parameters          ; if # goto chk4parameters
                inc     buff_pointer            ; else increment pointer


                brclr es_key_word,entry_status,iim1
;; program comes here when key word entry is checked
;; check is 5th key press = 8 then return
;; else
;;     goot wrong key and give long beep
                lda   kbd_pos
                cmp   #second_last_kw            ;; next digit is 5
                bne   wrong_entry
                jmp   ret_actkbd


iim1:
;; key 1 is for entry time
;; key 2 for password change
                lda     kbd_pos                 ; read kbd_pos
                cmp     #01                     ; is key 1 press
                bne     chk2                    ; if # goto chk2
set_entry_time  bset    es_entry_time,entry_status ; set flag of es_entry_time
                bra     ret_actkbd              ; return

chk2:           cmp     #02                     ; is key 2 press
                bne     chk3                    ; if # goto chk3
set_new_password bset   es_password,entry_status ; else set flag of es_password
                bra     ret_actkbd              ; return

chk3:
;;************************* WRONG ENTRY *****************************************
wrong_entry     jsr     long_beep               ; give long beep
                jmp     entry_over              ; goto entry over


;; program comes here when buffer pointer is > 4
chk4parameters:
                cpx     #05                     ; if buff_pointer > 5 then
                bne     more_parameters         ; goto more_parameters
                inc     buff_pointer            ; else increment pointer


                 brclr     es_key_word,entry_status,c4p1
                 lda       kbd_pos
                 cmp       #last_key_word       ; last digit for master key word is 7
                 bne       wrong_entry
                 jmp       master_reset_eeprom


c4p1:
;; program comes here when buff_pointer = 6
;; check is it es_entry_time = 1
;;      if yes then store key press in last_key _val
;;      set flag of po_entry_time
;;      return
;;      if no then goto chk4es_pw
                brclr   es_entry_time,entry_status,chk4es_pw
                lda     kbd_pos
                sta     et_buff
                jmp     ret_actkbd


;; program comes here when buff_pointer = 6 and es_entry_time = 0
;; check es_password flag
;;      if flag set then
;;      save key press in kbd_buff
;;      else goto wrong entry
more_parameters:
                brclr   es_entry_time,entry_status,chk4es_pw
                bset    po_entry_time,entry_status
                lda     kbd_pos
                sta     et_buff+1
                tst     et_buff
                bne     ret_actkbd
                tst     et_buff+1
                bne     ret_actkbd
                jmp     wrong_entry



chk4es_pw:      brclr   es_password,entry_status,wrong_entry
                lda     buff_pointer            ; subtract buff_pointer with 6
                sub     #6
                tax                             ; set subtracted val as pointer
                lda     kbd_pos                 ; read kbd_pos
                sta     kbd_buff,x              ; save in kbd_buff+ptr
                inc     buff_pointer            ; increment pointer
                lda     buff_pointer            ; if pointer = 10
                cmp     #10t                    ; if no then return
                bne     ret_actkbd
                bset    po_password,entry_status ; else set po_password flag
                bra     ret_actkbd              ; return


entry_table     db      5t,2,4,6,8,10t,12t,14t,16t,18t

;; program comes here when pgm_ok key press
;; chck is po_entry_time flag = 1
;; if yes then
;;      set last key press as pointer
;;      take corresponding entry time from entry table
;;      and save in entry_time
;;      goto com_po_ret
chk_po_status:  brclr   po_entry_time,entry_status,chk4popassword
                bclr    po_entry_time,entry_status
                jsr     pack_et_buff
                bra     com_po_ret

;; program comes here when po_entry_time = 0
;; program here checks for po_password
;; if po_password = 1 then
;;      call pack_buff
;;      store change password in password variable
;;      store in eeprom
;;      call entry_over
;;      give acc_beep
;;      return
chk4popassword
                brclr   po_password,entry_status,chk4more
                bclr    po_password,entry_status
upd_password    jsr     pack_buff               ; call pack_buff
                lda     kbd_buff                ; save kbd_buff in
                sta     password                ; password
                lda     kbd_buff+1              ; save kbd_buff+1 in
                sta     password+1              ; password+1

com_po_ret      jsr     store_memory            ; save changed parameter in eeprom
                jsr     entry_over              ; call entry over
                jsr     acc_beep                ; give acceptance beep
                jmp     ret_actkbd1             ; return


chk4more        bra    wrong_entry              ; else give long beep


;; SUBROUTINES :-
;;****************



;**************************** ACCEPTANCE BEEP ********************************
;; give beep thrice
acc_beep        jsr     short_beep
                jsr     short_delay
                jsr     short_delay
                jsr     short_beep
                jsr     short_delay
                jsr     short_delay
                jmp     short_beep

;**************************** ENTRY OVER **************************************
;; clear pointer\timeout\entry_status\pgm_mode flag
entry_over:     bclr    pgm_mode,status
                clr     buff_pointer
                clr     kbd_timeout
                clr     entry_status
                rts

; *************************** SHORT DELAY ************************************
short_delay     lda     running_ticks
                add     #beep_time
                sta     delay_temp
sd_wait         lda     delay_temp
                cmp     running_ticks
                bne     sd_wait
                rts


;***************************** LONG ENTRY ************************************
;; give this beep when wrong entry
;; giva a long beep for around 1 sec
;; stay here till 1 second is over
long_beep       lda     #ticks_1_sec
                sta     buzzer_time_out
                bclr    buzzer,buzzer_port
lb_wait:        bsr     delay
                bsr     toggle_buzzer_pin
                tst     buzzer_time_out
                bne     lb_wait
                bset    buzzer,buzzer_port
                rts


;**************************** SHORT BEEP **************************************
;; this routine is called from accp_beep and when entry time # 0
;; and after every key press
;; beep for small time
;; set buzzer_time_out = beep_time
;; wait untill buzzer time out # 00
quick_beep:
short_beep      lda     #beep_time
                sta     buzzer_time_out
                bclr    buzzer,buzzer_port
sb_wait:        bsr     delay
                bsr     toggle_buzzer_pin
                tst     buzzer_time_out
                bne     sb_wait
                bset    buzzer,buzzer_port
                rts


;;************************* TOGGLE BUZZER PIN ********************************
;; if buzzer time out # 00 then toggle buzzer pin
toggle_buzzer_pin:
                brset   buzzer,buzzer_port,reset_buzzer
                bset    buzzer,buzzer_port
                bra     ret_tbp
reset_buzzer:   bclr    buzzer,buzzer_port
ret_tbp:        rts


;; ************************ DELAY FOR HALF MSEC *******************************
;; this delay is approximately = 499usec
;; 2+4+[(5+4+3)83]= 10998cycles
;; 998/.5 = 499usec = .5msec
delay:          lda     #83t
                sta     temp
wait_0:         dec     temp
                tst     temp
                bne     wait_0
                rts
;***************************** PACK BUFFER ************************************
pack_buff       lda     kbd_buff
                lsla
                lsla
                lsla
                lsla
                ora     kbd_buff+1
                sta     kbd_buff
                lda     kbd_buff+2
                lsla
                lsla
                lsla
                lsla
                ora     kbd_buff+3
                sta     kbd_buff+1
                rts


;**************************** STORE MEMORY ***********************************
;; store 2byte password in eeprom
store_memory:   brset   bad_mem,status,ret_sm
                clr     e_add           ;; clear e_add
                clr     mem_ptr         ;; clear mem_ptr
nxt_data:
;; read data from RAM location
;; and store it in memory
                ldx     mem_ptr         ;; set index register as ptr
                lda     password,x      ;; read upper byte of password
                sta     e_dat           ;; save in e_dat
                jsr     set_eeprom_info ;; tx to eeprom
                inc     e_add           ;; increment address
                inc     mem_ptr         ;; increment pointer
                lda     mem_ptr         ;; is all 3 bytes written
                cmp     #max_iic_bytes  ;; if not goto nxt_data
                bne     nxt_data        ;; else return
ret_sm:         rts

;;************************* TIMINT ********************************************
timint:         lda             #def_timer      ;; set tscr = 14h
                sta             tscr
                bset            one_tick,tim_status ;; set flag for 0ne tick over
                inc             ticks           ;; increment ticks
                inc             running_ticks
;; if buzzer time out is not zero
;; then decrement buzzer timeout
;; interrupt comes here afetr every 8.2msec

                tst             buzzer_time_out
                beq             chk_half_sec
                dec             buzzer_time_out

chk_half_sec:   lda             ticks           ;; compare ticks with
                cmp             #ticks_in_hsec  ;; ticks in half sec
                bne             chk4secover     ;; if # goto chk4secover
                bset            half_sec,tim_status ;; set flag of half sec over

chk4secover     lda             ticks           ;; compare ticks with
                cmp             #ticks_1_sec    ;; ticks in one second
                bne             ret_timint      ;; if # then return
                bset            half_sec,tim_status ;; set flag of half sec
                bset            one_sec,tim_status  ;; set flag of one sec

;                clr             running_ticks
                clr             ticks           ;; clear ticks
dummy:
ret_timint:     rti


;; start beep when entry or exit time is not zero
chk_set_beep    tst     entry_time_out
                beq     ret_csb
                jsr     short_beep
ret_csb         rts



;; master key word received
;; if key entered in following sequence then reset EEPROm to default settings
;; Key word is 142587
;; default setting is that password entry will change to 1111
master_reset_eeprom:
                bsr     read_def_val
                jsr     acc_beep                ; give acceptance beep
                jsr     entry_over
                bra     store_memory



read_def_val    clrx
rdv_loop:       lda     def_table,x
                sta     password,x
                incx
                cpx     #max_iic_bytes
                bne     rdv_loop
                rts


;; here program pack entry time from et_buff\et_buff+1
;; first byte is in et_buff
;; second byte is in et_buff+1
;; output to entry_time var

;; for decimal selection multiply first number by 10t and then add with next number

pack_et_buff:   lda     et_buff
                ldx     #10t
                mul
                add     et_buff+1
                sta     entry_time
                rts

;;*************************** DEFAULT TABLE ***********************************
def_table       db      11h     ; password     ;; change defult password from 1234 to 1111
                db      11h     ; password+1
                db      10t     ; entry time


                org     7cdh
                jmp     start

                org     7f1h
                db      20h

                org     7f8h
                fdb     timint

                org     7fah
                fdb     dummy

                org     7fch
                fdb     dummy

                org     7feh
                fdb     start


