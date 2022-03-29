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
CONFIG  PLLEN = OFF            ; 4x PLL enabled
CONFIG  STVREN = ON           ; Stack Overflow/Underflow Reset enabled
CONFIG  BORV = LO             ; Brown-out Reset Voltage trip point low
CONFIG  LPBOR = OFF           ; Low Power Brown-Out Reset disabled
CONFIG  LVP = OFF             ; Low-Voltage Programming disabled



PSECT udata_bank0, class = BANK0
button1_counter:
        DS      1
button2_counter:
        DS      1
button3_counter:
        DS      1
button_status:
        DS      1

;PSECT udata_bank1, class = BANK1
;button4_counter:
;        DS      1

; Goal of this code
PSECT reset_vec, class = CODE, delta = 2
reset_vec:
        goto    start


PSECT isr_vec, class = CODE, delta = 2
isr_vec:
	  ;ici allumer une led pour voir si on rentre dans la routine d'interruption
	        banksel INTCON
          btfss INTCON, 2 ; check if flag has been raised
          goto  int_
          bcf INTCON, 2

          ; read values at port B bit 0
          banksel PORTB
          ; si bit Ã  0 on incrÃ©mente le compteur debounce_counter, sinon on remet Ã  0 le compteur
          ; skip if bit 0 is cleared => skip if button value is low
          btfsc PORTB, 0
          goto clear_counter_1
          decfsz button1_counter, 1
          goto button_2
          ; if it arrives here, it means that the counter has overflowed
          ; in this part we must tell that the button has been pressed
          clrf  BSR
          ;movlw 0x01
          ;xorwf PORTA
	  bsf button_status, 0

button_2: banksel PORTB
          btfsc PORTB, 1
          goto clear_counter_2
          decfsz button2_counter, 1
          goto button_3
          clrf  BSR
          ;movlw 0x02
          ;xorwf PORTA
	  bsf button_status, 1

button_3: banksel PORTB
          btfsc PORTB, 2
          goto clear_counter_3
          decfsz button3_counter, 1
          goto int_
          clrf  BSR
          ;movlw 0x04
          ;xorwf PORTA
	  bsf button_status, 2 ;set button status to 1 means that the button has been pressed
          goto int_


clear_counter_1:  movlw 0x04
		              movwf button1_counter
                  goto button_2

clear_counter_2:  movlw 0x04
		              movwf button2_counter
                  goto button_3

clear_counter_3:  movlw 0x04
		  movwf button3_counter

        ; here we need to implement a counter that counts the nb
int_:  retfie


PSECT code
start:  banksel OSCCON
        movlw   0xe8   ; PLL disabled, 4MHz HF, FOSC bits in config
        movwf   OSCCON
        ; Three buttons are connected to RB0, RB1 and RB2 pins
        ; 1: make those pins digital inputs
        banksel ANSELB
        bcf ANSELB,0
        bcf ANSELB,1
        bcf ANSELB,2

        banksel TRISB ; not required to do that since all are one normally
        bsf TRISB,0
        bsf TRISB,1
        bsf TRISB,2

        ; Make pin RA0 digital output
        ;banksel ANSELA
        ;bcf ANSELA,0 ; first controlled led
        ;bcf ANSELA,1 ; second controlled led
        ;bcf ANSELA,2 ; third controlled led
        ;banksel TRISA
        ;bcf TRISA,0
        ;bcf TRISA,1
        ;bcf TRISA,2

        ; 2: enable internal pull-up resistors on those pins
        banksel OPTION_REG
        bcf OPTION_REG,7 ; ENABLE WPUB
        bcf OPTION_REG, 3 ; prescaler assigned to Timer0
        ; timer rate 1:2 => 2us
        bsf OPTION_REG, 0
        bsf OPTION_REG, 1
        bcf OPTION_REG, 2
        bcf OPTION_REG, 5 ; TMR0 in timer mode

        banksel WPUB
        bsf WPUB,0 ; pull-up enabled RB0
        bsf WPUB,1 ; pull-up enabled RB1
        bsf WPUB,2 ; pull-up enabled RB2

        ; vÃ©rifier sans ce banksel, Ã§a devrait marcher normalement car INTCON
        ; est accessible depuis npt quelle banque
	      banksel INTCON
        bsf INTCON,5 ; TMR0IE bit enable the timer 0 interrupt
        bsf INTCON,7 ; enable all interrupts
        clrf button1_counter
        clrf button2_counter
        clrf button3_counter

      	;banksel PORTA
      	;movlw button1_counter
      	;movwf PORTA

      	;movlw button4_counter
      	;movwf PORTA

        ;bcf PORTA, 0 ; led initialized
        ;bcf PORTA, 1
        ;bcf PORTA, 2



nothing: movlw   0x00
  	     goto    nothing

        end	reset_vec
