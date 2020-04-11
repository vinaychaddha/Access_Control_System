
k_program       equ     10t
k_pgm_ok        equ     11t

scl             equ     2
sda             equ     3
iicport         equ     portb
iicont          equ     ddrb
                               ;; 7     6    5    4    3     2     1     0
def_ddra        equ     0cfh   ;; hoot  led  sen1 sen0 scan3 scan2 scan1 scan0
def_porta       equ     080h   ;; active low hooter and led
;; at power on system armed led
def_ddrb        equ     0ch    ;; x     x    x    x    sda   scl   x     x
def_portb       equ     00


key_port        equ     porta

scan0           equ     0     ; 16
scan1           equ     1     ; 15
scan2           equ     2     ; 14
scan3           equ     3     ; 13
sense0          equ     4     ; 12
sense1          equ     5     ; 11
;;sense2        equ     irq     ; irq

led_port        equ     porta
led_arm         equ     6
toggle_led      equ     40h

buzzer_port     equ     porta
buzzer          equ     7
