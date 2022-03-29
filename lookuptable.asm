;/// CODE IN ASSEMBLER TO PRINT CHARACTERS IN AN LCD
;/// USING PIC16(L)F1788
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


PROCESSOR       16F1789 ;informing the compiler that we are using PIC16F1788/9 microcontroller
#include        <xc.inc>

;tout les CONFIG....
;RC0 ... 7 = D0 .... 7
;RD6 = RS
;RD5 = Rw
;RD4 = E

CONFIG  FOSC = INTOSC         ; INTOSC oscillator
CONFIG  WDTE = OFF            ; Watchdog Timer disabled
CONFIG  PWRTE = ON            ; Power-up Timer enabled
CONFIG  MCLRE = ON            ; MCLR/VPP pin function is MCLR
CONFIG  CP = OFF              ; Flash Program Memory Code Protection off
CONFIG  CPD = OFF             ; Data Memory Code Protection off
CONFIG  BOREN = ON            ; Brown-out Reset enabled
CONFIG  CLKOUTEN = OFF        ; Clock Out disabled
CONFIG  IESO = ON             ; Internal/External Switchover enabled
CONFIG  FCMEN = ON            ; Fail-Safe Clock Monitor enabled
CONFIG  WRT = OFF             ; Flash Memory Self-Write Protection off
CONFIG  VCAPEN = OFF          ; Voltage Regulator Capacitor disabled
CONFIG  PLLEN = OFF            ; 4x PLL enabled
CONFIG  STVREN = ON           ; Stack Overflow/Underflow Reset enabled
CONFIG  BORV = LO             ; Brown-out Reset Voltage trip point low
CONFIG  LPBOR = OFF           ; Low Power Brown-Out Reset disabled
CONFIG  LVP = OFF             ; Low-Voltage Programming disabled


;object in bank0 memory
PSECT udata_bank0, class = BANK0




PSECT reset_vec, class = CODE, delta = 2
reset_vec:
   goto start

PSECT isr_vec, class = CODE, delta = 2
isr_vec:
   retfie

PSECT code

;should we configure RD and RC as digital output using ansel REG?

start:
        BANKSEL OSCCON
        MOVLW   0xE8 ; PLL enable, 4MHz HF, FOSC bits in config
        MOVWF   OSCCON

        movlw 0x01
        CALL table
        banksel PORTA
        mvwf PORTA

table:
    BRW
    RETLW 0x01
    RETLW 0x02
    RETLW 0x03
    RETLW 0x04
