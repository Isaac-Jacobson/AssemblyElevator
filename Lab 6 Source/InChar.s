;*************************************************************** 
; Edited:	07/20/2017	Aaron Davenport
;		Converted original InChar.s to subroutine standard
;		using R0 as output, preserve used registers above R3,
;		and formating
;		11/30/2017	Marcus Benzel
;		Correct PCTL Setting
;
; InChar -	Capture ACSII input via UART0, storing at memory 
;			address passed in R0
; Input	 -	UART0: Baud = 9600, 8-bit, No Parity, 1-Stop bit
;		  No Flow control  (16 Mhz Clock)
; Output -	R0: Captured ACSII character
;***************************************************************

;*************************************************************** 
; EQU Directives
; These directives do not allocate memory
;*************************************************************** 
;SYMBOL		DIRECTIVE	VALUE			COMMENT
;	***************** GPIO Registers *****************
RCGCGPIO	EQU			0x400FE608		;	GPIO clock register
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

;***************************************************************
; InChar Subroutine                         
;***************************************************************
;LABEL		DIRECTIVE	VALUE				COMMENT
			AREA 		|.text|,READONLY,CODE,ALIGN=2
			THUMB
			EXPORT		InChar				;	Make available to other programs
InChar		PROC
			PUSH		{R4-R6}

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
	

; 	Select alternate function to be used (UART on PA0, PA1)
			LDR			R5,=PORTA_PCTL
			LDR			R4,[R5]
			BIC			R4, #0xFF
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

;	***************** Input *****************
; 	Preload R4 with UART data address
			LDR			R6,=UART0_DR
check                               
; check for incoming character
			LDR			R5,=UART0_FR		;	Load UART status register address
			LDR			R4,[R5]
			ANDS		R4,R4,#0x10			;	Check if char received (RXFE is 0)
			BNE			check				;	If no character, check again 
			LDR			R0,[R6]				;	Else, load received char into R0
	
			POP			{R4-R6}
			BX			LR					;	Return
			ENDP

;***************************************************************
; End of the subroutine section
;***************************************************************
;LABEL      DIRECTIVE   VALUE           	COMMENT
			ALIGN
            END