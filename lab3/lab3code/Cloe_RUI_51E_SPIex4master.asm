;***********************************************************
; File Header(lab3ex4mastertimer2int, ADC)
;***********************************************************

    list p=18F25k50, r=hex, n=0
    #include <p18F25k50.inc>

X1 equ  0x00
Y1 equ  0x01
CTR equ 0x02
CTR2 equ 0x03
COUNTER equ 0x04
flag equ 0x05
flagadc	equ 0x06
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
    movlw   0x01 		; Value used to initialize data direction
    movwf   TRISA 		; Set PORTA as output, RAO is ADC input
    movlw   0x01 		; Configure A/D for digital inputs 0000 1111
    movwf   ANSELA 		; RAO is analog input
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
    
    ;movlw   0x31
    ;movwf   SSP1CON1
    ;movlw   0xC0
    ;movwf   SSP1STAT
    
    bcf	INTCON,7		;configure interrupt
    bcf	PIE1,1			;disable TMR2IE
    bsf INTCON,6
    bsf PIE1,3
    bcf PIR1,3
    ;interrupt for ADC
    bsf	PIE1,ADIE
    bcf PIR1, ADIF
    
    
    ;configue SPI
    movlw   0x33
    movwf   SSP1CON1		;use timer2 for the clock
    movlw   0xC0
    movwf   SSP1STAT
    clrf	    TMR2    
    movlw   0xFF		
    movwf   PR2			;enable timer2
    movlw   0x7F
    movwf   T2CON
    
    ;configue ADC
    movlw   0x01
    movwf   ADCON0
    movlw   0x00
    movwf   ADCON1
    MOVLW   0x16
    MOVWF   ADCON2
    
    bsf INTCON, 7		;enable GIE
    

main
    clrf    X1			; clear registers
    clrf    Y1
    clrf    CTR
    clrf    CTR2
    clrf    COUNTER
    clrf    flag
    clrf    flagadc
  
  
ifstart
    call    delay
    call    delay
    call    delay
    call    delay
    call    delay
    call    delay
    

adcwait	
    bsf	    ADCON0,1		;GO/DONE=1, start a adc conversion
    btfss    0x06,0
    goto    adcwait
    bcf	    0x06,0
    
    movf    COUNTER, W	; move COUNTER to SSP1BUF        
    movwf   SSP1BUF

spiwait
    btfss   0x05,0
    goto    spiwait
    bcf	    0x05,0
    goto    ifstart
    
    
    
delay
    INCFSZ CTR
    GOTO delay
    INCFSZ CTR2
    GOTO delay
    return   

inter_high
    btfss   PIR1, SSPIF
    goto    adcint
    ;movff   COUNTER,SSP1BUF
    bcf	    PIR1,SSPIF
    bsf	    0x05,0
    RETFIE
 adcint    
    btfss   PIR1,ADIF
    RETFIE
    bsf	    0x06,0
    bcf	    PIR1,ADIF
    movff   ADRESH, COUNTER
    RETFIE
    
    
    
inter_low
    nop
    retfie

    END










