;***************************************
;Init_PortF.s source file to implement 
;initialization
;***************************************

;Definition of the labels standing for the
;address of the registers

SYSCTL_RCGCGPIO_R	EQU		0x400FE608 ; GPIO Run Mode Clock Gating Control

GPIO_PORTF_LOCK_R   EQU     0x40025520 ; GPIO PortF Lock
GPIO_PORTF_CR_R		EQU		0x40025524 ; GPIO PortF Commit 
GPIO_PORTF_AMSEL_R  EQU		0x40025528 ; GPIO PortF Analog Mode Select
GPIO_PORTF_PCTL_R	EQU		0x4002552C ; GPIO PortF Port Control
GPIO_PORTF_DIR_R    EQU		0x40025400 ; GPIO PortF Direction
GPIO_PORTF_AFSEL_R  EQU		0x40025420 ; GPIO PortF Alternative Function Select
GPIO_PORTF_PUR_R	EQU		0x40025510 ; GPIO PortF Pull-up
GPIO_PORTF_DEN_R	EQU		0x4002551C ; GPIO PortF Digital Enable
	
;***************************************
;Initialization Area
;***************************************

; This PortF initialization is used to enable PF0(SW2) and PF4(SW1)
; and PF1(Red LED), PF2(Blue LED), PF3(Green LED) pins of the TM4C 
; for the recording and replay purposes

					AREA init_portf , READONLY , CODE , ALIGN=2
					THUMB
					EXPORT	Init_PortF

Init_PortF
					PUSH	{LR}
					PUSH	{R0}
					PUSH	{R1}
					
					;unlock GPIO PortF (only PF0 needs to be unlocked other bits can't be locked)
					LDR		R1,=GPIO_PORTF_LOCK_R
					LDR     R0,=0x4C4F434B       ; This value is written to unlock
					STR		R0,[R1]			   
					
					;allow changes to all PortF pins
					LDR		R1,=GPIO_PORTF_CR_R
					LDR     R0,=0x1F         	
					STR		R0,[R1]
					
					;disable analog function for all PortF pins
					LDR		R1,=GPIO_PORTF_AMSEL_R
					LDR		R0,[R1]
					BIC		R0,R0,#0x1F		   		
					STR		R0,[R1]
					
					;use regular GPIO function for all PortF pins
					LDR		R1,=GPIO_PORTF_PCTL_R
					LDR		R0,[R1]
					BIC		R0,R0,#0x1F			
					STR		R0,[R1]
					
					;set PF4 and PF0 as input - set PF1,PF2,PF3 as output
					LDR		R1,=GPIO_PORTF_DIR_R
					LDR		R0,[R1]
					ORR		R0,R0,#0x0E			 
					STR		R0,[R1]
					
					;disable alternate functions for all PortF pins
					LDR		R1,=GPIO_PORTF_AFSEL_R
					LDR		R0,[R1]
					BIC		R0,R0,#0x1F		   		
					STR		R0,[R1]
					
					;enable pull-up on PF4 and PF0
					LDR		R1,=GPIO_PORTF_PUR_R
					LDR		R0,[R1]
					ORR		R0,R0,#0x11		   		
					STR		R0,[R1]
					
					;enable digital function for all PortF pins
					LDR		R1,=GPIO_PORTF_DEN_R
					LDR		R0,[R1]
					ORR		R0,R0,#0x1F		   		
					STR		R0,[R1]
					
					POP		{R1}
					POP		{R0}
					POP		{LR}
					
					BX		LR                 		; return
