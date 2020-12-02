;*************************************************************** 
; Edited:	Aaron Davenport
; Changes-	Converted original OutStr.s to subroutine standard
;			using R0 as input, preserve used registers above R3,
;			and formating
; 07/20/2017
; OutStr -	Output string starting at memory address passed 
;			in R0 to UART0
; Input	 -	R0:	Register with string memory address start, 
;				terminate/end string with 0x04, otherwise
;				subroutine produces unexpected results
; Output -	UART0: Baud = 9600, 8-bit, No Parity, 1-Stop bit
;				   No Flow control		(16 Mhz Clock)
;*************************************************************** 

;*************************************************************** 
; 	EQU Directives
; 	These directives do not allocate memory
;*************************************************************** 
;SYMBOL		DIRECTIVE   VALUE			COMMENT
;	***************** GPIO Registers *****************
RCGCGPIO	EQU 		0x400FE608		;	GPIO clock register
PORTA_DEN	EQU 		0x4000451C		;	Digital Enable
PORTA_PCTL	EQU 		0x4000452C		;	Alternate function select
PORTA_AFSEL	EQU 		0x40004420		;	Enable Alt functions
PORTA_AMSEL	EQU 		0x40004528		;	Enable analog
PORTA_DR2R	EQU			0x40004500		;	Drive current select
	
;	***************** UART Registers *****************
RCGCUART	EQU			0x400FE618		;	UART clock register
UART0_DR	EQU			0x4000C000		;	UART0 data / base address
UART0_CTL	EQU			0x4000C030		;	UART0 control register
UART0_IBRD	EQU			0x4000C024		;	Baud rate divisor Integer part
UART0_FBRD	EQU			0x4000C028		;	Baud rate divisor Fractional part
UART0_LCRH	EQU			0x4000C02C		;	UART serial parameters
UART0_CC	EQU 		0x4000CFC8		;	UART clock config
UART0_FR	EQU 		0x4000C018		;	UART status

;	***************** PLL Registers *****************
SYSCTL_RCC2	EQU			0x400FE070		;	PLL control
									
;***************************************************************
; 	OutStr Subroutine                         
;***************************************************************
;LABEL      DIRECTIVE	VALUE				COMMENT
			AREA    	|.text|, READONLY, CODE, ALIGN=2
			THUMB
			EXPORT		OutStr				;	Make available to other programs
OutStr		PROC
			PUSH		{R4-R7}
			
;	***************** Disable PLL ***************** 
			LDR			R5,=SYSCTL_RCC2
			LDR			R4,[R5]
			PUSH		{R4}				;	Store current state
			ORR			R4,R4,#0x00002000	;	Power-Down PLL 2
			STR			R4,[R5] 
 
;	***************** Enable UART clock ***************** 
			LDR			R5,=RCGCUART
			LDR			R4,[R5]
			ORR			R4,R4,#0x01			;	Set bit 0 to enable UART0 clock
			STR			R4, [R5]
			NOP								;	Let clock stabilize
			NOP
			NOP  

;	***************** Setup GPIO ***************** 
;	Enable GPIO clock to use debug USB as com port (PA0, PA1)
			LDR			R5,=RCGCGPIO
			LDR			R4,[R5]
			ORR			R4,R4,#0x01			;	Set bit 0 to enable port A clock
			STR			R4,[R5]
			NOP								;	Let clock stabilize
			NOP
			NOP 
	
; 	Make PA0, PA1 digital
			LDR			R5,=PORTA_DEN
			LDR			R4,[R5]
			ORR			R4,R4,#0x03			;	Set bits 1,0 to enable digital on PA0, PA1
			STR			R4,[R5]
	
; 	Disable analog on PA0, PA1
			LDR			R5,=PORTA_AMSEL
			LDR			R4,[R5]
			BIC			R4,R4,#0x03			;	Clear bits 1,0 to disable analog on PA0, PA1
			STR			R4,[R5]

; 	Enable alternate functions selected
			LDR			R5,=PORTA_AFSEL
			LDR			R4,[R5]
			ORR			R4,R4,#0x03			;	Set bits 1,0 to enable alt functions on PA0, PA1
			STR			R4,[R5]				;	TX LINE IS LOW UNTIL AFTER THIS CODE
	
;	Delay for voltage on serial to stabalize
			LDR			R4,=0x15			;	At 0x10 there are still errors, voltage not stable
del			SUBS		R4,R4,#1			;	this needs to run once if serial is used, not every time
			BNE			del
	
; 	Select alternate function to be used (UART on PA0, PA1)
			LDR			R5,=PORTA_PCTL
			LDR			R4,[R5]
			ORR			R4,R4,#0x11			;	Set bits 4,0 to select UART Rx, Tx
			STR			R4,[R5]
	
;	***************** Setup UART ***************** 
; 	Disable UART0 while setting up
			LDR			R5,=UART0_CTL
			LDR			R4,[R5]
			BIC			R4,R4,#0x01			;	Clear bit 0 to disable UART0 while
			STR			R4,[R5]				;	Setting up
	
;	Set baud rate to 9600.  
;	Divisor = 16MHz/(16*9600)= 104.16666
			LDR			R5,=UART0_IBRD
			MOV			R4,#104				;	Set integer part to 104
			STR			R4,[R5]
	
;	0.16666*64+0.5 = 11.16666 => Integer = 11
			LDR			R5,=UART0_FBRD
			MOV			R4,#11				;	Set fractional part
			STR			R4,[R5]
	
;	Set serial parameters
			LDR			R5,=UART0_LCRH
			MOV			R4,#0x70			;	No stick parity, 8bit, FIFO enabled, 
			STR			R4,[R5]				;	One stop bit, Disable parity, Normal use
	
; 	Enable UART, TX, RX
			LDR			R5,=UART0_CTL
			LDR			R4,[R5]
			MOV			R6,#0x00000301		;	Set bits 9,8,0
			ORR			R4,R4,R6
			STR			R4,[R5]	
			NOP								;	Let UART settle
			NOP
			NOP	
	
;	***************** Output *****************
; 	Preload R4 with UART data address
			LDR			R7,=UART0_DR
loop
			LDRB		R6,[R0],#1			;	Load character, post inc address
			CMP			R6,#0x04			;	has end character been reached?
			BEQ			done				;	if so, end

;	Check if UART is ready to send (buffer is empty)
			LDR		 	R5,=UART0_FR		;	Load UART status register address
waitR
			LDR			R4,[R5]
			ANDS		R4,R4,#0x20         ;	Check if TXFF = 1
			BNE 		waitR	            ;	If so, UART is full, so wait / check again
			STR			R6,[R7]				;	Else, send character

; 	Check if UART is done transmitting
waitD
			LDR			R4,[R5]
			ANDS		R4,R4,#0x08         ;	Check if BUSY = 1
			BNE 		waitD	            ;	If so, UART is busy, so wait / check again
			B   		loop				;	Else, get next character

done
;	Disable UART, TX, RX
			LDR			R1,=UART0_CTL
			MOV			R2,#0x00000000		;	Clear bits 8,0
			STR			R2,[R1]

; 	Restore PLL
			LDR			R5,=SYSCTL_RCC2
			POP			{R4}				;	Restore PLL state
			STR			R4,[R5]

			POP			{R4-R7}
			BX			LR					;	Return
			ENDP

;***************************************************************
; End of the subroutine section
;***************************************************************
;LABEL      DIRECTIVE   VALUE           	COMMENT
			ALIGN
            END