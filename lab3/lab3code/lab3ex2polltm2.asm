;***********************************************************
; File Header
;***********************************************************

    list p=18F25k50, r=hex, n=0
    #include <p18F25k50.inc>

X1 equ  0x00
Y1 equ  0x01
CTR equ 0x02
CTR2 equ 0x03
COUNTER equ 0x04

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
    movlw   0x00
    movwf   ANSELC
    movlw   0x00 		; Configure comparators for digital input
    movwf   CM1CON0
    clrf    PORTB 		; Initialize PORTB by clearing output data latches
    movlw   0x11 		; b00010001 Value used to initialize data direction
    movwf   TRISB 		; Set PORTB as output
    clrf    PORTC 		; Initialize PORTC by clearing output data latches
    movlw   0x01		; Value used to initialize data direction
    movwf   TRISC		; Set RC0 as input

    bcf     UCON,3		; to be sure to disable USB module
    bsf     UCFG,3		; disable internal USB transceiver
    
    movlw   0x33
    movwf   SSP1CON1		;use timer2 for the clock
    movlw   0xC0
    movwf   SSP1STAT
    clrf	    TMR2    
    movlw   0xFF		
    movwf   PR2			;enable timer2
    movlw   0x7F
    movwf   T2CON
    

main
    clrf    X1			; clear registers
    clrf    Y1
    clrf    CTR
    clrf    CTR2
    clrf    COUNTER
    ;movlw   0x01		; move 0x01 to Register X1
    ;movwf   X1
  
ifstart
    call    delay
    call    delay
    call    delay
    call    delay
    call    delay
    call    delay
    btfss   PORTC,0		; check RC0, if it?s equal ?1? continue
    goto    counter          ; else go back
    goto    ifstart

counter				; Linear Feedback Shift Register
    ;movf    X1,0	      ; move X1 into W register
    ;movff   X1,Y1            ; move X1 value to Y1
    ;rlcf    Y1               ; shift 1bit to left
    ;xorwf   Y1,1             ; xor W with Y1, store the result in Y1
    btfsc   PORTB,4             ; test if Y1bit 3 is 0,skip to the State2
    goto    upcounter
    goto    downcounter

upcounter
    ;rlcf    X1                ; shift 1 bit to left
    ;bsf     X1,0              ; set bit 0 to 1
    incf    COUNTER
    movf    COUNTER, W	; move COUNTER to SSP1BUF
    call    serial_write   
    goto    ifstart

downcounter
    ;rlcf    X1
    ;bcf     X1,0
    decf    COUNTER
    movf    COUNTER, W	; move COUNTER to SSP1BUF
    call    serial_write  
    goto    ifstart

serial_write  
    movwf   SSP1BUF

wait
    BTFSS   SSP1STAT, BF
    BRA	    wait
    movff   SSP1BUF, LATA
    RETURN
    
 
    
    
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




