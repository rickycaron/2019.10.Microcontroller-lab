  ;***********************************************************
; File Header
;***********************************************************

    list p=18F25k50, r=hex, n=0
    #include <p18F25k50.inc>
    
    config SDOMX = RC7
    
    sampleinx	    equ	0x00; used to count x(n)
    filterinx	    equ	0x01; used in one filter calculation
    filtertime	    equ 0x02; used to 
    caltime	    equ 0x03; =9, used to count time
    adcresult	    equ 0x04; used to store the adc result temperaily
    mulh	    equ	0x05; register to store the high part of the multiple
    mull	    equ 0x06; store low part
    flag	    equ 0x07; flag for FIR filter,	    
;***********************************************************
; Reset Vector
;***********************************************************

    ORG     0x1000   ; Reset Vector
    		     ; When debugging:0x000; when loading: 0x1000
    goto    START


;***********************************************************
; Interrupt Vector
;***********************************************************

    ORG     0x1008	; Interrupt Vector  HIGH priority
    goto    inter_high	; When debugging:0x008; when loading: 0x1008
    ORG     0x1018	; Interrupt Vector  HIGH priority
    goto    inter_low	; When debugging:0x008; when loading: 0x1018


;***********************************************************
; Program Code Starts Here
;***********************************************************

    ORG     0x1020	; When debugging:0x020; when loading: 0x1020

START
    clrf    sampleinx
    clrf    filterinx
    clrf    filtertime
    clrf    adcresult
    movlw   0x09
    movwf   caltime
    call    init_chip		; initialize ports and some other registers
    call    init_timer		; initialize timers
    call    init_ADC		; initialize A/D converter
    call    init_PWM		; initialize PWM module
    call    init_FIR		; initialize filter
    bsf	    T0CON, 7		; TMR0ON, Enable Timer0
    bsf	    T2CON, 2		; TMR2ON, Enable Timer2
    bsf	    INTCON, 7		; GIE, Enable interrupt
    
main
   ; bsf	    PIR1,6
    btfss    flag,   0
    bra	    main    ;if flag=1, start the conversion
    ; WRITE THE CODE FOR THE FIR FILTER BETWEEN THE TWO INSTRUCTIONS ABOVE!!!!!!!!!!!!!!!!
    ;movwf   adcresult	;store the adc temprolrly
    clrf    mulh;
    clrf	   mull;
    movlw   0x0A
    movwf   caltime;		initialize the caltime as 10
    ;movlw   0x46		;this is only for simulation in maplab
    ;movwf   adcresult
    movf    adcresult,0
    movwf   INDF0

checktimes    
    decf    caltime,1	; to ensure the multiplication is performed for 9 times
    bnz	    next
    goto    firend
    
next
    movf    POSTINC0,0	;	move the x(n) to working register,FSR0 points to the next value 
    MULWF   POSTINC1	;	W*b(n), FSR1 points to the next
    movf    mull,0	;
    addwf   PRODL,0	; PRODL+mull(W)->(w)
    movwf   mull,1	;move the result(w) to mull
    movf    mulh,0	;move mulh to W
    addwfc  PRODH,0	;add (W)+PRODH+Carrier and store it in (W)
    movwf   mulh	;mov the result back to mulh
    
    MOVLW   0x28
    cpfsgt	FSR0L	;FSR0L>0x28,skip
    bra		checktimes
    bra		refreshfsr
refreshfsr
    LFSR	0,0x020	;refresh FSR0
    LFSR	1,0x030	;refresh FSR1
    bra		checktimes
  
firend
    movf	mulh,0	;take out the final result
    movwf	CCPR2L	;put it into the PWM
    movf	POSTINC0,0; let fsr0 Point to the nex value
    movf	POSTINC1,0; fsr1 points to the next value
    MOVLW   0x28
    cpfsgt	FSR0L	;FSR0L>0x28,skip
    bra		endafterrefresh
    LFSR	0,0x020	;refresh FSR0 after the increment
    LFSR	1,0x030	;refresh FSR1
endafterrefresh
    clrf		 mulh;
    clrf		mull;
    bcf		flag,0	;clear the flag
    ;above is for FIR filter
    goto		main

init_chip
    movlw   0x80
    movwf   OSCTUNE
    movlw   0x70
    movwf   OSCCON
    movlw   0x10
    movwf   OSCCON2
    
    clrf    PORTA 		; Initialize PORTA by clearing output data latches
    movlw   0xFF 		; Value used to initialize data direction
    movwf   TRISA 		; Set PORTA as input
    movlw   0x00 		; Configure comparators for digital input
    movwf   CM1CON0
    clrf    PORTB 		; Initialize PORTB by clearing output data latches
    movlw   0x00 		; Value used to initialize data direction
    movwf   TRISB 		; Set PORTB as output
    clrf    PORTC 		; Initialize PORTC by clearing output data latches
    clrf    TRISC		; define PORTC as outpnput
    clrf    ANSELC
    bcf     UCON,3		; to be sure to disable USB module
    bsf     UCFG,3		; disable internal USB transceiver
    return

init_timer
    movlw   0x42	;Timer0 defines sample rate CHANGE THE LITERAL HERE!!!!!!!!!!!OK
    movwf   T0CON	;Timer0 Control Register
               		;bit7 "0": Disable Timer
               		;bit6 "1": 8-bit timer
               		;bit5 "0": Internal clock
               		;bit4 "0": not important in Timer mode
               		;bit3 "0": Timer0 prescale is assigned
               		;bit2-0  : CHOOSE AN APPROPRIATE VALUE FOR THE PRESCALER!!!!!!!!!OK
			;bit2-0:010; prescalser=1:8, TMR0L starts from 0xB4
			;F = Fosc/(4*Prescale*number of counting)
    movlw   0xB4
    movwf   TMR0L
   ; clrf    TMR0L	;clear timer
    movlw   0x20	;Interrupt settings for Timer0
    movwf   INTCON	;Interrupt Control Register
               		;bit7 "0": Global interrupt Enable
               		;bit6 "0": Peripheral Interrupt Enable
               		;bit5 "1": Enables the TMR0 overflow interrupt
               		;bit4 "0": Disables the INT0 external interrupt
               		;bit3 "0": Disables the RB port change interrupt
               		;bit2 "0": TMR0 Overflow Interrupt Flag bit
			;bit1 "0": INT0 External Interrupt Flag bit
			;bit0 "0": RB Port Change Interrupt Flag bit
			
			
    movlw   0x00	;Timer2 is used for PWM
    movwf   T2CON	;Timer2 Control Register
               		;bit7 "0": unimplemented
               		;bit6-3 "0000": Postscale 1:1
               		;bit2 "0": Timer off
               		;bit1-0 "00": Prescale 1:1  
    clrf    TMR2	;clear timer
    return

init_ADC
    movlw   0x00
    movwf   ADCON1	;A/D Control Register 1
			;bit7-6 "00": unimplemented
			;bit5   "0": VSS as voltage reference
			;bit4   "0": VDD as voltage reference
			;bit3-0 "0000": all ports are analog input
    movlw   0x01
    movwf   ADCON0	;A/D Control Register 0
			;bit7 "0": unimplemented
			;bit6-2 "00000": Channel 0 (AN0)
			;bit1   "0": A/D idle, do not start conversion yet
			;bit0   "1": A/D converter module is enabled
    movlw   0x36
    movwf   ADCON2	;A/D Control Register 2
			;bit7   "0": left justified
			;bit6   "0": unimplemented
			;bit5-3 "110": A/D Acquisition Time is 16 Tad
			;bit2-0 "110": A/D Conversion Clock is Fosc/64
    bsf	    INTCON, 6	;PEIE_GIEL bit, enables peripheral interrupts 
    bcf	    PIR1, 6	;ADIF bit = flag bit
    bsf	    PIE1, 6	;ADIE bit, enables the A/D interrupt
    return

init_PWM
    movlw   0xFF
    movwf   PR2		;PWM period = 255
			;Period = [(PR2+1)*4*Tosc*(TMR2 Prescale value)
			;= 256 * 4 * (1/48 MHz) * 1
			;= 21,33 µs (46,8 kHz)
    movlw   0x0F
    movwf   CCP2CON	;Standard CCP2 control register
			;bit7-6 "00": unimplemented
			;bit5-4 "00": 2 LSBs of duty cycle (10-bit)
			;bit3-0 "1111": PWM mode
    movlw   D'128'
    movwf   CCPR2L	;Duty cycle = 128 to start with
    return

init_FIR
    ; buffer of input samples starts at address 0x020
    lfsr    0, 0x020	; FSR0 is used for the input samples
    clrf    0x20	; now follows a buffer of 9 samples
    clrf    0x21	; all cleared
    clrf    0x22
    clrf    0x23
    clrf    0x24
    clrf    0x25
    clrf    0x26
    clrf    0x27
    clrf    0x28
 
    ; table of filter coefficients starts at address 0x030
    lfsr    1, 0x030	; FSR1 is used for the filter coefficients
    movlw   D'1'	; b(0)
    movwf   0x30
    movlw   D'8'	; b(1)
    movwf   0x31
    movlw   D'28'	; b(2)
    movwf   0x32
    movlw   D'56'	; b(3)
    movwf   0x33
    movlw   D'69'	; b(4)
    movwf   0x34
    movlw   D'56'	; b(5)
    movwf   0x35
    movlw   D'28'	; b(6)
    movwf   0x36
    movlw   D'8'	; b(7)
    movwf   0x37
    movlw   D'1'	; b(8)
    movwf   0x38
    
    return
    
inter_high
    btfss   PIR1, 6	; ADIF bit, interrupt is caused by A/D converter
    bra	    inter_tmr0	; check next interrupt source
inter_ADC
    ;movf    ADRESH, W	; read the value of the ADC (only upper 8 bits
    ;movwf   CCPR2L	; and store it in the duty cycle register
    btfss	flag,0	;if flag=1, it means the filter calculation of the adcvalue hasn't finished; it is 0, then a new value can be taken
    goto		startanewfir
    goto		continuefir
startanewfir    
    movff    ADRESH, adcresult; start a new conversion
    bsf		flag,0	;set flag to 1, so in the main the filter will execute
    bcf	      PIR1, 6	; ADIF bit has to be cleared
    retfie
continuefir
    bcf		PIR1,6
    retfie
    
inter_tmr0
    btfss   INTCON, 2	; TMR0IF, interrupt is caused by Timer0
    retfie		; if not, then return
    movlw   D'180'	; this value sets the sample frequency (see formula in init_timer) CHANGE IT!!!!!!!!!!!!!ok
			;TMR0L=180, number of counting =75
    movwf   TMR0L	; initialize timer again
    bsf	    ADCON0, 1	; GODONE bit, starts the A/D conversion
    bcf	    INTCON, 2	; clear interrupt flag
    retfie

inter_low
    nop
    retfie

    END




