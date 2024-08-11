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
counter_50:
   DS 1                        ;reserve 1 byte for each counter
counter_2:
   DS 1
counter_1:
   DS 1
counter_bis:
   DS 1
counter_bisbis:
   DS 1
result:
    DS      1
current_digit:
       DS      1
current_position:
       DS      1
dizaine:
       DS      1
hundred:
       DS      1
ten:
       DS      1
one:
       DS      1
button1_counter:
         DS      1
button2_counter:
         DS      1
button3_counter:
         DS      1
button_status:
         DS      1
counter_interrupt:
	DS       1



PSECT reset_vec, class = CODE, delta = 2
reset_vec:
    goto start

PSECT isr_vec, class = CODE, delta = 2
isr_vec:
	  ;ici allumer une led pour voir si on rentre dans la routine d'interruption
	  banksel INTCON
          btfss INTCON, 2 ; check if flag has been raised
          goto  int_
          bcf INTCON, 2

          ; read values at port B bit 0
          banksel PORTB
          ; si bit =  0 on incrémente le compteur debounce_counter, sinon on remet Ã  0 le compteur
          ; skip if bit 0 is cleared => skip if button value is low
          btfsc PORTB, 0
          goto clear_counter_1
          decfsz button1_counter, 1
          goto button_2
          ; if it arrives here, it means that the counter has overflowed
          ; in this part we must tell that the button has been pressed
          clrf  BSR
          movlw 0x01
          xorwf PORTA
	  bsf button_status, 0


button_2: banksel PORTB
          btfsc PORTB, 1
          goto clear_counter_2
          decfsz button2_counter, 1
          goto button_3
          clrf  BSR
	  bsf button_status, 1

button_3: banksel PORTB
          btfsc PORTB, 2
          goto clear_counter_3
          decfsz button3_counter, 1
          goto int_
          clrf BSR
	  bsf button_status, 2 ;set button status to 1 means that the button has been pressed
          goto int_


clear_counter_1:  clrf BSR
		  bcf button_status, 0
		  movlw 0x04
		  movwf button1_counter
                  goto button_2

clear_counter_2:  clrf BSR
		  bcf button_status, 1
		  movlw 0x04
		  movwf button2_counter
                  goto button_3

clear_counter_3:  clrf BSR
		  bcf button_status, 2
		  movlw 0x04
		  movwf button3_counter

 ; here we need to implement a counter that counts the nb
int_:  retfie




PSECT code

;should we configure RD and RC as digital output using ansel REG?

start:
        BANKSEL OSCCON
        MOVLW   0xE8 ; PLL enable, 4MHz HF, FOSC bits in config
        MOVWF   OSCCON

        BANKSEL TRISD         ;move to the bank where TRIS are contained (could also note BSF STATUS,RP0)
        BCF    	TRISD,6       ;make portD connected to RS, RW and E as output
      	BCF    	TRISD,5
      	BCF    	TRISD,4
        CLRF    TRISC         ;make all portC as output, maybe specify which pin later to not influence the one not used

        CLRF    BSR           ;switch to bank0
        /*BCF     PORTD,RD2   ;disable*/
        CLRF    PORTC
      	BCF    	PORTD,6       ;set to 0 portD connected to RS, RW and E
      	BCF    	PORTD,5
      	BCF    	PORTD,4

        ; -------button-----
        banksel ANSELB
        bcf ANSELB,0
        bcf ANSELB,1
        bcf ANSELB,2

        banksel TRISB ; not required to do that since all are one normally
        bsf TRISB,0
        bsf TRISB,1
        bsf TRISB,2
        ; 2: enable internal pull-up resistors on those pins
        banksel OPTION_REG
        bcf OPTION_REG,7 ; ENABLE WPUB
        bcf OPTION_REG, 3 ; prescaler assigned to Timer0
        ; timer rate 1:256 => 2us
        bcf OPTION_REG, 0
        bsf OPTION_REG, 1
        bsf OPTION_REG, 2
        bcf OPTION_REG, 5 ; TMR0 in timer mode

        banksel WPUB
        bsf WPUB,0 ; pull-up enabled RB0
        bsf WPUB,1 ; pull-up enabled RB1
        bsf WPUB,2 ; pull-up enabled RB2

        ; vÃƒÂ©rifier sans ce banksel, ÃƒÂ§a devrait marcher normalement car INTCON
        ; est accessible depuis npt quelle banque
	banksel INTCON
        bsf INTCON,5 ; TMR0IE bit enable the timer 0 interrupt
        bsf INTCON,7 ; enable all interrupts

	banksel PORTA
	movlw 0x04
	movwf button1_counter
	movlw 0x04
	movwf button2_counter
	movlw 0x04
	movwf button3_counter
	clrf button_status

        ;-------- end_button -----------

        CALL delay_1       ;delay of 1s => wait for LCD to warm up
        CALL InitiateLCD

loop2:  CALL print
        GOTO loop2

InitiateLCD:BCF PORTD,6       ; Send command to the LCD
	    MOVLW 0x30              ; initialization 1
	    MOVWF PORTC             ; send data to the lcd
	    CALL Enable             ; let the data float in it
	    CALL delay_2	    ; wait for more than 4,1ms
	    CALL delay_2

	    MOVLW 0x30              ; initialization 2
	    MOVWF PORTC             ; send data to the lcd
	    CALL Enable             ; let the data float in it
	    CALL delay_50
	    CALL delay_50             ; wait for more than 100 us

	    MOVLW 0x30              ; initialization 3
	    MOVWF PORTC             ; send data to the lcd
	    CALL Enable             ; let the data float in it
	    CALL delay_50		          ; wait for more than 100 us
	    CALL delay_50


	    MOVLW 0x01          ; clear display
	    MOVWF PORTC
	    CALL Enable
	    CALL delay_2          ;1.52 ms?

	    MOVLW 0x38          ;function set ( bit, 8 line, 5*8 point)
	    MOVWF PORTC
	    CALL Enable
	    CALL delay_50      ;37Âµs

	    MOVLW 0x0F      ; display on/off (on, cursor on, blink on)
	    MOVWF PORTC
	    CALL Enable
	    CALL delay_50      ;37Âµs

	    MOVLW 0x06      ; entry mod set (display shift, left decrement)
	    MOVWF PORTC
	    CALL Enable
	    CALL delay_50      ;37Âµs

	    MOVLW   0x00            ; Print character "0"
	    movwf   hundred

	    MOVLW   0x05            ; Print character "5"
	    movwf   ten

	    MOVLW   0x00            ; Print character "0"
	    movwf   one

	    return

print:  BCF     PORTD,6       ; Send command to the LCD
        MOVLW   0x02           ; Set cursor home
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_2       ; 1.52 ms

        BSF     PORTD,6       ; Send data to LCD
        CALL    delay_2

        MOVLW   0x4D          ; Print character "M"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x65           ; Print character "e"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x61           ; Print character "a"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x73            ; Print character "s"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x75            ; Print character "u"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x72            ; Print character "r"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x65           ; Print character "e"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x3A           ; Print character ":"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        BCF     PORTD,6       ; Send command to the LCD
        MOVLW   0xC0          ; Set cursor to the 2e line
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_2       ; 1.52 ms

        BSF     PORTD,6       ; Send data to LCD
        CALL    delay_2

        MOVLW   0x54          ; Print character "T"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x61           ; Print character "a"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x72           ; Print character "r"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x67            ; Print character "g"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x65            ; Print character "e"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x74            ; Print character "t"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x3A           ; Print character ":"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        ;set default value of humidity level

        MOVLW   0x20            ; Print character "  "
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x30
	ADDWF   hundred,0
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x30
	ADDWF   ten,0
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50


        MOVLW   0x30
	ADDWF   one,0
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

        MOVLW   0x25           ; Print character "%"
        MOVWF   PORTC
        CALL    Enable
        CALL    delay_50

if_button_inc:     call delay_2 ; ici réimplémenter un compteur
		   call delay_2
		   call delay_2
		   call delay_2
		   call delay_2
		   call delay_2
		   call delay_2
		   call delay_2
		   call delay_2
		   call delay_2
		   call delay_2
		   call delay_2
		   call delay_2
		   bcf INTCON,7 ; disable all interrupts
		   movf button_status, 0
		   bsf INTCON,7 ; enable all interrupts
		   BTFSC WREG,0
		    ; si le boutton est appuyÃ© fait insrt suivante
                   GOTO then_button_inc
                   GOTO    finish

then_button_inc:
                   MOVLW   0X01                  ; met le register W à 1
                   XORWF   hundred,0             ; si digit = 1 tout les bit dans W sont à 0
                   MOVWF   result
                   INCF    result                ; si digit = 1 result = 00000001
                   DECFSZ  result                ; si 100 ignore incrémentation et passe à l'autre boutton
                   GOTO    inc_unit
                   GOTO    finish

inc_unit:
		                MOVLW   0xCA
                    MOVWF   current_position       ; adresse unit
                    CALL    move_cursor
                    movlw   0X09                  ; met le register W à 9
                    XORWF   one,0                  ; si digit = 9 tout les bit dans W sont à 0
                    MOVWF   result
                    INCF    result                ; si digit = 9 result = 00000001
                    DECFSZ  result
                    GOTO    else_9_unit

then_9_unit:
                    MOVLW   0x30                   ; met le digit courant à 0
                    MOVWF   PORTC
                    CALL    Enable
                    CALL    delay_50

                    MOVLW   0x00
                    MOVWF   one
                    GOTO    inc_ten
else_9_unit:

                    INCF    one;          ;incrémente le digit courant
                    MOVLW   0x30
                    ADDWF   one,0
                    MOVWF   PORTC
                    CALL    Enable
                    CALL    delay_50
                    GOTO    finish

inc_ten:
                    MOVLW   0xC9
                    MOVWF   current_position       ; adresse ten
                    CALL    move_cursor

                    movlw   0X09                  ; met le register W à 9
                    XORWF   ten,0        ; si digit = 9 tout les bit dans W sont à 0
                    MOVWF   result
                    INCF    result                ; si digit = 9 result = 00000001
                    DECFSZ  result
                    GOTO    else_9_ten

then_9_ten:
                  MOVLW   0x30                   ; met le digit courant à 0
                  MOVWF   PORTC
                  CALL    Enable
                  CALL    delay_50

                  MOVLW   0x00
                  MOVWF   ten
                  GOTO    inc_hundred
else_9_ten:
                  INCF    ten;          ;incrémente le digit courant
                  MOVLW   0x30
                  ADDWF   ten,0
                  MOVWF   PORTC
                  CALL    Enable
                  CALL    delay_50
                  GOTO    finish

inc_hundred:
                  MOVLW   0xC8
                  MOVWF   current_position       ; adresse hundred
                  CALL    move_cursor

                  INCF    hundred;          ;incrémente le digit courant
                  MOVLW   0x30
                  ADDWF   hundred,0
                  MOVWF   PORTC
                  CALL    Enable
                  CALL    delay_50
                  GOTO    finish


finish:
	RETURN

move_cursor:
	      BCF     PORTD,6       ; Send command to the LCD
              MOVF    current_position,0
	      MOVWF   PORTC
	      CALL    Enable
	      CALL    delay_2       ; 1.52 ms

	      BSF     PORTD,6       ; Send data to LCD
	      CALL    delay_2
	      RETURN


Enable:  BSF PORTD,4 ; E pin is high, (LCD is processing the incoming data)
         NOP         ; 1us delay
         BCF PORTD,4 ; E pin is low, (LCD does not care what is happening)
         return


delay_50:   MOVLW  0x19        ; 50us = 25 itÃ©rations vu chaque instruction = 2 cycle et 1 cycle = 4 clock = 1us
            MOVWF   counter_50
delay_loop_50:  DECFSZ  counter_50, 1
		GOTO   delay_loop_50
		return

delay_2:  MOVLW  0x04            ;2ms = 1000 = 256 * 4 itÃ©rations vu chaque instruction = 2 cycle et 1 cycle = 4 clock
          MOVWF  counter_2
	  clrf counter_bis

delay_loop_2: DECFSZ  counter_2, 1
	      GOTO  delay_loop_2
	      MOVLW   0x04
	      MOVWF   counter_2
	      INCFSZ  counter_bis, 1
	      GOTO    delay_loop_2
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


;//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

end reset_vec
