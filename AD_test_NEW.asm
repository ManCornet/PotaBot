PROCESSOR 16F1789

#include <xc.inc>

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
CONFIG  PLLEN = OFF           ; 4x PLL enabled
CONFIG  STVREN = ON           ; Stack Overflow/Underflow Reset enabled
CONFIG  BORV = LO             ; Brown-out Reset Voltage trip point low
CONFIG  LPBOR = OFF           ; Low Power Brown-Out Reset disabled
CONFIG  LVP = OFF             ; Low-Voltage Programming disabled

; Etapes :
;1. Port configuration
;2. Channel selection
;   - Single-ended
;   - Differential
;3. ADC voltage reference selection
;4. ADC conversion clock source
;5. Interrupt control
;6. Result formatting

;BEGINNING OF THE PROGRAM

PSECT udata_bank0
counter_10:
           DS 1     ;reserve 1 byte for each counter
counter_1:
           DS 1
counter_bis:
           DS 1
counter_bisbis:
           DS 1


PSECT reset_vec, class = CODE, delta = 2
reset_vec:
        goto    start

PSECT isr_vec, class = CODE, delta = 2
    banksel PIR1
    btfss PIR1, 6
    goto end_adc
    bcf PIR1, 6

    banksel ADRESL ; rï¿½cupï¿½rer le rï¿½sultat de la conversion
    movf ADRESL, 0 ; mov adresl in w
    banksel PORTD
    movwf PORTD
    banksel ADRESH
    movf ADRESH, 0
    banksel PORTC
    movwf PORTC

end_adc:
            retfie

PSECT code
start:
    	call	initialisation      ; initialisation routine configuring the MCU
    	goto	main_loop           ; main loop

initialisation:
              ;0. Configuration of clock - 4MHz - internal
               banksel OSCCON
               movlw  0xe8 ; PLL enable, 4MHz HF, FOSC bits in config
               movwf  OSCCON
              ;1. Pin configuration
               banksel TRISA
               bsf TRISA, 0 ; Set RA0 to input
               banksel ANSELA
               bsf ANSELA,0 ; RA0 is an analog input
               banksel WPUA
               bcf WPUA, 0   ; disable weak pull-up on RA0

               banksel TRISD
               movlw 0x00
               movwf TRISD
               banksel ANSELD
               movlw 0x00
               movwf ANSELD
               banksel TRISC
               movlw 0x00
               movwf TRISC
               banksel ANSELC
               movlw 0x00
               movwf ANSELC

               ;2. ADC module configuration
               banksel ADCON1
               movlw 0xc0         ; 0c0 for 2's compliment format ,0x40 if in Sign-Magnitude format
               movwf ADCON1		    ; Sign-magnitude format, FOSC/4, VREF+=VDD, VREF-=VSS
               movlw 0x0f
               movwf ADCON2		    ; Auto-conversion Disabled, ADC Negative reference=VSS
               movlw 0x01                      ;      0x81 sur 10 bits
               movwf ADCON0		    ; 12-bits, channel 0, ADC enabled

               ;Configure ADC interrupt (optional)
               banksel PIR1
               bcf PIR1, 6
               banksel PIE1
               bsf PIE1, 6
               banksel INTCON
               bsf	INTCON,	6	; enable peripheral interrupts
               bsf	INTCON,	7	; enable global interrupts
	             clrf BSR
               call acquisition_time

main_loop:   banksel ADCON0
             bsf ADCON0, 1 ; start conversion
             ;btfsc ADCON0, 1   ; Is conversion done?
             ;goto $-1
             ;banksel ADRESL ; rï¿½cupï¿½rer le rï¿½sultat de la conversion
	     ;movf ADRESL, 0 ; mov adresl in w
	     ;banksel PORTD
	     ;movwf PORTD
	     ;banksel ADRESH
	     ;movf ADRESH, 0
	     ;banksel PORTC
	     ;movwf PORTC
	     clrf BSR ;goes back to bank 0
               ;mettre le rï¿½sultat qq part
             call delay_1
               ; si il y a interrupt
              ;banksel PIR1
              ;bcf PIR1, 6
               ; mettre un compteur ici pour pas recommencer direct une conversion
             goto main_loop


acquisition_time:   movlw  0x3c        ; 10us = 5 itï¿½rations vu chaque instruction = 2 cycle et 1 cycle = 4 clock = 1us
                                      ; since 10 Bits conversion and Tad = 1us
                    movwf  counter_10
delay_loop_acqu_time:   decfsz  counter_10, 1
			goto   delay_loop_acqu_time
               		return

delay_1:  MOVLW   0x08      ; 1 seconde = 256*256*8 itÃ©rations vu chaque instruction = 2 cycles et 1 cycle = 4 clock
          MOVWF   counter_1
          CLRF    counter_bis
          CLRF    counter_bisbis

delay_loop_1:	DECFSZ  counter_1, 1
          		GOTO    delay_loop_1
          		MOVLW   0x08    ; 1 seconde = 256*256*8 itÃ©rations vu chaque instruction = 2 cycles et 1 cycle = 4 clock
          		MOVWF   counter_1
          		INCFSZ  counter_bis, 1
          		GOTO    delay_loop_1
          		INCFSZ  counter_bisbis, 1
          		GOTO    delay_loop_1
          		return

end reset_vec
