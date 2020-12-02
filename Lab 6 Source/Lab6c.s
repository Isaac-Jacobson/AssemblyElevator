;*************************************************************** 
; Lab6c.s  
; Programmer:
; Description:  
;***************************************************************	

;*************************************************************** 
; EQU Directives
; These directives do not allocate memory
;***************************************************************
;LABEL		DIRECTIVE	VALUE		COMMENT
DELAY_CLOCKS	EQU		0x4C4B40

;***************************************************************
; Data Section in READWRITE
; Values of the data in this section are not properly initialazed, 
; but labels can be used in the program to change the data values.
;***************************************************************
;LABEL          DIRECTIVE       VALUE                           COMMENT
				
                AREA            |.sdata|, DATA, READWRITE
                THUMB			

;***************************************************************
; Directives - This Data Section is part of the code
; It is in the read only section  so values cannot be changed.
;***************************************************************
;LABEL          DIRECTIVE       VALUE                           COMMENT
                AREA            |.data|, DATA, READONLY
                THUMB
msgOPEN			DCB				"Door is open."
				DCB          	0x0D
				DCB           	0x04		
msgCLOSE		DCB				"Door is closed."
				DCB				0x0D
				DCB				0x04
msgUP			DCB				"Going up."
				DCB				0x0D
				DCB				0x04
msgDOWN			DCB				"Going down."
				DCB				0x0D
				DCB				0x04
msgSTAY			DCB				"Same floor."
				DCB				0x0D
				DCB				0x04
;***************************************************************
; Program section					      
;***************************************************************
;LABEL		DIRECTIVE	VALUE			COMMENT
			AREA    	main, READONLY, CODE
			THUMB
			EXPORT  	__main			; Make available
			EXTERN		InChar

__main
			MOV			R8,#1
loop		BL			OPEN
			BL			InChar
			MOV			R9,R0
			SUB			R9,R9,#0x30
			BL			CLOSE
			CMP			R8,R9
			BLEQ		STAY
			BLGT		DOWN
			BLLT		UP
			B			loop
		

forever		B			forever
;***************************************************************
; Subroutine section                         
;***************************************************************
;LABEL          DIRECTIVE       VALUE                           COMMENT

				AREA    routines, CODE, READONLY
				THUMB
				EXPORT	DELAY
				EXPORT  CLOSE
				EXPORT  OPEN
				EXTERN	OutStr
				EXTERN	OutChar
				EXPORT	UP
				EXPORT  DOWN
				EXPORT  STAY
				EXTERN  Out1BSP
					
DELAY			LDR			R2,=DELAY_CLOCKS	; set delay count
del				SUBS 		R2, R2, #1		; decrement count
				BNE			del		; if not at zero, do again
				BX			LR			; return when done
		
CLOSE			PUSH 		{LR}
				BL			DELAY
				LDR	    	R0,=msgCLOSE
				BL			OutStr
				POP			{LR}
				BX			LR
				
OPEN			PUSH 		{LR}  			; Save existing return address
				BL			DELAY			; Wait 1 sec.
				LDR   		R0,=msgOPEN		; Pointer to message
				BL    		OutStr          ; Send message
				POP 		{LR}			; Restore return address
				BX			LR				; return when done	
			
UP				PUSH		{LR}
				LDR	    	R0,=msgUP
				BL			OutStr
				SUB			R3,R9,R8
loopUp			BL			DELAY
				ADD			R8,R8,#1
				MOV			R0,R8
				BL			Out1BSP
				SUBS		R3,R3,#1
				BNE			loopUp
				POP			{LR}
				BX			LR
				
DOWN			PUSH		{LR}
				LDR	    	R0,=msgDOWN
				BL			OutStr
				SUB			R3,R8,R9
loopDOWN		BL			DELAY
				SUB			R8,R8,#1
				MOV			R0,R8
				BL			Out1BSP
				SUBS		R3,R3,#1
				BNE			loopDOWN
				POP			{LR}
				BX			LR

STAY			PUSH		{LR}
				BL			DELAY
				LDR	    	R0,=msgSTAY
				BL			OutStr
				POP			{LR}
				BX			LR

				ALIGN
				END 


