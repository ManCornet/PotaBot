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


PSECT reset_vec, class = CODE, delta = 2
reset_vec:
        goto    start

PSECT isr_vec, class = CODE, delta = 2
        retfie

PSECT code
start:  banksel OSCCON
        movlw   0xe8    ; PLL disabled, 8MHz HF, FOSC bits in config
        movwf   OSCCON

        ; 1. Disable PWM pin (CCP1) by setting associated TRIS bit
        ; normally bit 2 (RC2) of PORTC is already set to 1 in TRISC
        banksel TRISC
        bsf TRISC,2

        ; PWM Period = [(PR2) + 1]*4*T_OSC*(TMR2 Prescale Value) where T_OSC=1/F_OSC (1)
        ; 2. load the PR2 register with the PWM period value
        banksel PR2
        movlw 0x65    ; PWM period value encoded here (see formula 1)
        movwf PR2

        ; 3. To configure CCP1 for PWM mode, bits 2 and 3 of CCP1CON
        ; must be set, leave 2 LSBs of duty cycle cleared for now
        banksel CCP1CON
        movlw 0x0c ; c for 1100 (PWM mode) and 00 for ls bits of duty cycle
        movwf CCP1CON

        ; Pulse Width = (CCPR1L:CCP1CON<5:4> * T_OSC * (TMR2 Prescale value)) (2)
        ; Duty cycle ratio = (CPR1L:CCP1CON<5:4>)/(4*(PR2 + 1))               (3)
        ; Resolution = log[4(PR2+1)]/log(2)                                   (4)

        ; 4. Set the PWM duty cycle by loading CCPR1L register and
        ; CCP1 bits of the CCP1CON register; set duty cycle = 0
        banksel CCPR1L
        movlw 0x32
        movwf CCPR1L

        ; 5. Need to configure and start Timer2
        ; 5.1 First, Clear the TMR2IF interrupt flag bit of the
        ; PIR1 register
        banksel PIR1
        bcf PIR1,1

        ; 5.2. Configure the T2CKPSbits of the T2CON (2 ls bits of T2CON) register with the Timer prescale value
        ; ie. turn TMR2 on
        banksel T2CON
        bsf T2CON,0
        bcf T2CON,1

        ; 5.3. Enable the Timer by setting the TMR2ON bit of the T2CON register.
        bsf T2CON, 2

        ; 6. Enable PWM output pin
        ; Wait until Timer2 overflows (TMR2IF bit of the PIR1 register is set)
        ; Enable the CCPx pin output driver by clearing the associated TRIS bit.
wait_timer_2:
        banksel PIR1
        btfss PIR1,1 ; btfss skips the newt instruction if bit is set
        goto wait_timer_2
        bcf PIR1,1  ; if here it means that the TMR2IF = 1 and we clear it
        ; set PWM output to start
        banksel TRISC
        bcf TRISC,2

        ;; 3 LEDS CONFIG
        ; 1. Configure the RD0 and RD1 port as digital input ports
        ; RD0: lvl_min signal, RD1: lvl_max
        banksel ANSELD
        bcf ANSELD,0
        bcf ANSELD,1

        banksel TRISD ; not required to do that since all are one normally (input)
        bsf TRISD,0
        bsf TRISD,1

        ; make RE0:2 digital outputs for the leds
        banksel ANSELE
        bcf ANSELE,0
        bcf ANSELE,1
        bcf ANSELE,2

        banksel TRISE
        bcf TRISE,0
        bcf TRISE,1
        bcf TRISE,2

low_lvl:
	; checks the value of RD0 and RD1
  banksel PORTD
	bcf PORTE, 0
	bcf PORTE, 1
	bcf PORTE, 2
        ; if RD0 is 0 it means that level_min is reached and we must not refill the tank
        ; led at port RE0 to light up the led that corresponds to level min
        btfss PORTD, 0
        goto between
        banksel PORTE
        bsf PORTE,0
        goto low_lvl
between:
        ; if RD1 is 1 it means that level_max is not reached and we are btw lvl_min and level_max
        ; led at port ... to light up the led that corresponds to level min
        btfss PORTD, 1
        goto lvl_max
        banksel PORTE
        bsf PORTE,1
        goto low_lvl
lvl_max:
        banksel PORTE
        bsf PORTE,2
        goto low_lvl
        
	end reset_vec
