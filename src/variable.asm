
last_key_val    db      00
entry_status    db      00
es_password     equ     1
es_entry_time   equ     2
po_entry_time   equ     3
po_password     equ     4
es_key_word     equ     5


temp            db      00
active_scan     db      00
kbd_temp        db      00
delay_temp      db      00
running_ticks   db      00
mem_ptr         db      00

kbd_timeout     db      00
buff_pointer    db      00
kbd_buff        db      00,00,00,00

status          db      00
new_key_found   equ     7
key_alarm       equ     6
bad_mem         equ     5
sys_arm         equ     4
pgm_mode        equ     3

password        db      00,00           ;; stored in eeprom
entry_time      db      00              ;; stored in eeprom

buzzer_time_out db      00
beep_time       equ     10t

entry_time_out  db      00
hooter_time     equ     2
hooter_alarm_tout db    00

e_add           db      00
e_dat           db      00
iic_buff        db      00

kbd_pos         db      00
last_key        db      00
same_key        db      00

def_timer       equ     14h

tim_status      db      00
one_tick        equ     7
half_sec        equ     6
one_sec         equ     5
one_min         equ     4

mins            db      00
ticks_1_sec     equ     122t
ticks_in_hsec   equ     61t
ticks           db      00
max_iic_bytes   equ     3

key_scan_cntr   db      00
