
;***********************************************************
; File Header(lab3exdslave, pwm)
;***********************************************************

    list p=18F25k50, r=hex, n=0
    #include <p18F25k50.inc>

X1 equ  0x00
Y1 equ  0x01
CTR equ 0x02
CTR2 equ 0x03
dutycycle equ 0x04

;***********************************************************
; Reset Vector
;***********************************************************

    ORG     0x1000   ; Reset Vector
    		     ; When debugging:0x000; when loading: 0x800
    GOTO    START


;***********************************************************
; Interrupt Vector
;***********************************************************



    ORG     0x1008	; Interrupt Vector  HIGH priority
    GOTO    inter_high	; When debugging:0x008; when loading: 0x808
    ORG     0x1018	; Interrupt Vector  HIGH priority
    GOTO    inter_low	; When debugging:0x008; when loading: 0x808



;***********************************************************
; Program Code Starts Here
;***********************************************************

    ORG     0x1020		; When debugging:0x020; when loading: 0x820

START
    movlw   0x80		; load value 0x80 in work register
    movwf   OSCTUNE		
    movlw   0x70		; load value 0x70 in work register
    movwf   OSCCON		
    movlw   0x10		; load value 0x10 to work register
    movwf   OSCCON2		
    clrf    PORTA 		; Initialize PORTA by clearing output data latches
    movlw   0x00 		; Value used to initialize data direction
    movwf   TRISA 		; Set PORTA as output
    movlw   0x00 		; Configure A/D for digital inputs 0000 1111
    movwf   ANSELA 		;
    movlw   0x00
    movwf   ANSELB
    movlw   0x00		;RC1 is analog output
    movwf   ANSELC
    movlw   0x00 		; Configure comparators for digital input
    movwf   CM1CON0
    clrf    PORTB 		; Initialize PORTB by clearing output data latches
    movlw   0x03 		; b00010001 Value used to initialize data direction
    movwf   TRISB 		; Set PORTB as output
    clrf    PORTC 		; Initialize PORTC by clearing output data latches
    movlw   0x00		; Value used to initialize data direction
    movwf   TRISC		; Set RC0 as input

    bcf     UCON,3		; to be sure to disable USB module
    bsf     UCFG,3		; disable internal USB transceiver
    bcf	    PIR1,TMR2IF
    
    movlw   0x35; alought disable ss, it still keeps blinking
    movwf   SSP1CON1
    movlw   0x40
    movwf   SSP1STAT
    movlw   0x00
    movwf   SSP1CON3
    movlw   0xff
    movwf   PR2
    movlw   0x0f
    movwf    CCP2CON
    movlw   0x1F
    movwf   T2CON	;timer2 is on now
   
    
    
    
main
    clrf    X1			; clear registers
    clrf    Y1
    clrf    CTR
    clrf    CTR2
    clrf    dutycycle
    ;movlw   0x04
    ;movwf   T2CON	;timer2 is on now
    ;bsf	    T2CON, TMR2ON  

wait
    BTFSS   SSP1STAT, BF
    BRA	    wait
    movff   SSP1BUF,dutycycle
    ;movff   SSP1BUF, LATA
    MOVFF   dutycycle, LATA
    movff    dutycycle,CCPR2L
    bcf	    PIR1,TMR2IF
    
    
waitpwm	    
    btfss   PIR1, TMR2IF
    goto    waitpwm
    bcf	    PIR1,TMR2IF
    clrf	    TMR2
    
    
    GOTO    wait
    
 
    
    
delay
    INCFSZ CTR
    GOTO delay
    INCFSZ CTR2
    GOTO delay
    return   

inter_high
    nop
    RETFIE
inter_low
    nop
    retfie

    END






