;***********************************************************
; File Header
;***********************************************************

    list p=18F25k50, r=hex, n=0
    #include <p18F25k50.inc>

X1 equ  0x00
Y1 equ  0x01

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
    movlw   0x00 		; Configure comparators for digital input
    movwf   CM1CON0
    clrf    PORTB 		; Initialize PORTB by clearing output data latches
    movlw   0x00 		; Value used to initialize data direction
    movwf   TRISB 		; Set PORTB as output
    clrf    PORTC 		; Initialize PORTC by clearing output data latches
    movlw   0x01	    ; Value used to initialize data direction
    movwf   TRISC		; Set RC0 as input

    bcf     UCON,3		; to be sure to disable USB module
    bsf     UCFG,3		; disable internal USB transceiver

main
    clrf    X1			; clear registers
    clrf    Y1
    movlw   0x01             ; move 0x01 to Register X1
    movwf   X1
  
ifstart
    btfss   PORTC,0          ; check RC0, if it?s equal ?1? continue
    goto    shifter          ; else go back
    goto    ifstart

shifter          	     ; Linear Feedback Shift Register
    movf    X1,0             ; move X1 into W register
    movff   X1,Y1            ; move X1 value to Y1
    rlcf    Y1               ; shift 1bit to left
    xorwf   Y1,1             ; xor W with Y1, store the result in Y1
    btfsc   Y1,3             ; test if Y1bit 3 is 0,skip to the State2
    goto    state1
    goto    state2

state1
    rlcf    X1                ; shift 1 bit to left
    bsf     X1,0              ; set bit 0 to 1
    movf    X1,0              ; move X1 to PORTB
    movwf   PORTB
    goto    ifstart

state2
    rlcf    X1
    bcf     X1,0
    movf    X1,0
    movwf   PORTB
    goto    ifstart

inter_high
    nop
    RETFIE
inter_low
    nop
    retfie

    END

