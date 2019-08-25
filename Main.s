;***************************************
; EE447 Term Project
;***************************************
;Definition of the labels standing for the
;address of the registers
NUMBER_ADDR			EQU		0x20000400 ; NUMBER_ADDR equals to memory location 0x20000400
	
SYSCTL_RCGCGPIO_R	EQU		0x400FE608 ; GPIO Run Mode Clock Gating Control
	
GPIO_PORTF_DATA_R	EQU     0x400253FC ;

NVIC_ST_CTRL_R		EQU		0xE000E010
NVIC_ST_RELOAD_R	EQU 	0xE000E014
NVIC_ST_CURRENT_R	EQU		0XE000E018

RCGCADC_R			EQU		0x400FE638 ; ADC clock register

ADC0_PSSI_R			EQU 	0x40038028 ; Initiate sample
ADC0_RIS_R			EQU		0x40038004 ; Interrupt status
ADC0_SSFIFO3_R		EQU		0x400380A8 ; Sample sequencer results

SYSCTL_RCGCI2C_R	EQU		0x400FE620 ; I2C Run Mode Clock Gating Control

I2C0_MSA_R			EQU		0x40020000 ; I2C0 Master Slave Address
I2C0_MDR_R			EQU		0x40020008 ; I2C0 Master Data
I2C0_MCS_R			EQU		0x40020004 ; I2C0 Master Control/Status
slave_addr			EQU		0x62       ; 
;***************************************

					AREA main , READONLY , CODE , ALIGN=2
					THUMB
					EXTERN	Init_PLL
					EXTERN	Init_I2C
					EXTERN	Init_ADC1
					EXTERN	Init_ADC2
					EXTERN	Init_PortF
					EXPORT 	__main
					
__main				BL		Init_PLL

					LDR		R1,=SYSCTL_RCGCGPIO_R
					LDR		R0,[R1]
					ORR		R0,R0,#0x32 ; enable PORTE, PORTF and PORTB clock
					STR		R0,[R1]
					NOP
					NOP
					NOP					; let clock stabilize
					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
					
					BL		Init_PortF
					
					LDR     R2,=GPIO_PORTF_DATA_R	
					LDR		R5,[R2]
					MOV		R5,#0x04 ; BLUE LED is ON 
					STR		R5,[R2]
					
					LDR		R1,=RCGCADC_R ; turn on ADC clock
					LDR		R0,[R1]
					ORR		R0,R0,#0x01 ; set bit 0 to enable ADC0 clock
					STR		R0,[R1]
					NOP
					NOP
					NOP
					NOP
					NOP
					NOP			
					NOP
					NOP
					NOP
					NOP				; let clock stabilize
					
					;enable I2C0 clock
					LDR		R1,=SYSCTL_RCGCI2C_R
					LDR		R0,[R1]
					ORR		R0,R0,#0x01
					STR		R0,[R1]
					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
					NOP
					
					BL		Init_I2C
					BL		Init_ADC1
					
                    
START				MOV		R0,#0
					LDR		R1,=24000
					LDR		R3,=NUMBER_ADDR
					
					LDR     R2,=GPIO_PORTF_DATA_R	
					LDR		R5,[R2]
					MOV		R5,#0x04 ; BLUE LED is ON 
					STR		R5,[R2]

check1				LDR		R5,[R2]
					EORS	R5,R5,#0x10 ; 10000 convert PF4(switch1) to positive logic
					LSR     R5,R5,#4
					CMP		R5,#0
					BEQ		check1
					
					BL		delay_10ms
					
released_check1		LDR     R2,=GPIO_PORTF_DATA_R	
					LDR		R5,[R2]
					EORS	R5,R5,#0x10 ;
					LSR     R5,R5,#4
					CMP		R5,#0
					BNE		released_check1
					
					BL		delay_10ms
					
					LDR     R2,=GPIO_PORTF_DATA_R	
					LDR		R5,[R2]
					MOV		R5,#0x02 ; RED LED is ON 
					STR		R5,[R2]		

Count_Samples1		BL		Sample_at_8kHz
					BL		delay_125us
					ADDS	R0,R0,#1
					CMP		R0,R1
					BNE		Count_Samples1
					
pause_playing		BL 		delay_10ms
					LDR     R2,=GPIO_PORTF_DATA_R	
					LDR		R5,[R2]
					MOV		R5,#0x04 ; BLUE LED is ON 
					STR		R5,[R2]
					

check2				LDR     R2,=GPIO_PORTF_DATA_R	
					LDR		R5,[R2]
					EOR		R5,R5,#0x01 ; 0001 convert PF0(switch2) to positive logic
					BICS	R5,R5,#0x1E ;
					CMP		R5,#0
					BEQ		check2
					
					BL		delay_10ms
					
released_check2		LDR     R2,=GPIO_PORTF_DATA_R	
					LDR		R5,[R2]
					EOR		R5,R5,#0x01 ; 0001 convert PF0(switch2) to positive logic
					BICS	R5,R5,#0x1E ;
					CMP		R5,#0
					BNE		released_check2
					
					BL		delay_10ms
					
					LDR     R2,=GPIO_PORTF_DATA_R	  
					LDR		R5,[R2]
					MOV		R5,#0x08 ; GREEN LED is ON 
					STR		R5,[R2]
					
					BL		Init_ADC2
					
keep_playing		MOV		R0,#0
					LDR		R1,=24000
					LDR		R4,=NUMBER_ADDR
					
Count_Samples2		BL		I2C0_Send2_Data
					BL		I2C_delay_control
					BL		I2C_delay
					
					LDR     R2,=GPIO_PORTF_DATA_R	
					LDR		R5,[R2]
					EOR		R5,R5,#0x01 ; 0001 convert PF0(switch2) to positive logic
					BICS	R5,R5,#0x1E ;
					CMP		R5,#0
					BNE		playback_release
					
					ADDS	R0,R0,#1
					CMP		R0,R1
					BNE		Count_Samples2
					
					B		keep_playing
					
playback_release	LDR     R2,=GPIO_PORTF_DATA_R	
					LDR		R5,[R2]
					EOR		R5,R5,#0x01 ; 0001 convert PF0(switch2) to positive logic
					BICS	R5,R5,#0x1E ;
					CMP		R5,#0
					BNE 	playback_release
					B		pause_playing
					
					
;***************************************					
Sample_at_8kHz			
					PUSH	{LR}
					PUSH	{R0}
					PUSH	{R1}
					
					LDR		R1,=ADC0_PSSI_R ; sample sequencer initiate address
					LDR		R0,[R1]
					ORR		R0,R0,#0x08 ; set bit 3 for SS3
					STR		R0,[R1]
			
;Check whether sample is complete or not (bit 3 of ADC_RIS_R is set)
control				LDR		R1,=ADC0_RIS_R
					LDR		R0,[R1]
					ANDS	R0,R0,#0x08 ; check whether bit 3 is "1" or not
					BEQ		control

;Branch fails if the flag is set so data can be read and flag is cleared
					LDR		R1,=ADC0_SSFIFO3_R
					LDR		R2,[R1]     ; store 12 bits in register R2
					LSR		R2,R2,#4		
					STR		R2,[R3],#1	; record 8 bits sound data
	
					LDR		R1,=ADC0_RIS_R
					LDR		R0,[R1]
					ORR		R0,R0,#0x08 ; clear the interrupt flag
					STR		R0,[R1]
					
					POP		{R1}
					POP		{R0}
					POP		{LR}
					
					BX		LR

;***************************************
I2C0_Send2_Data			
					PUSH	{LR}
					PUSH	{R0}
					PUSH	{R1}
					PUSH    {R2}
					PUSH	{R3}
					
controller_idle		LDR		R1,=I2C0_MCS_R
					LDR		R0,[R1]
					AND		R0,R0,#0x01
					CMP		R0,#1
					BEQ		controller_idle

					LDR		R1,=I2C0_MSA_R
					LDR		R0,=slave_addr
					LSL		R0,R0,#1
					BICS	R0,R0,#0x01
					STR		R0,[R1]								
									
					LDR		R2,[R4]
					BICS	R2,R2,#0xFFFFFF0F;
					LSR		R2,R2,#4
					
					LDR		R1,=I2C0_MDR_R
					LDR		R0,[R1]
					MOV		R0,R2
					STR		R0,[R1] ; Firstly, most significant 4 bits are send by I2C0
								
;wait_bus_busy1		LDR		R1,=I2C0_MCS_R
					;LDR		R0,[R1]
					;ANDS	R0,R0,#0x40
					;LSR		R0,R0,#6
					;CMP		R0,#1
					;BEQ		wait_bus_busy1				
					
					LDR		R1,=I2C0_MCS_R
					MOV		R0,#0x03
					STR		R0,[R1]

controller_idle1	LDR		R1,=I2C0_MCS_R
					LDR		R0,[R1]
					AND		R0,R0,#0x01
					CMP		R0,#1
					BEQ		controller_idle1
					
;data_ack1			LDR		R1,=I2C0_MCS_R
					;LDR		R0,[R1]
					;ANDS	R0,R0,#0x08
					;LSR		R0,R0,#3
					;CMP		R0,#1
					;BEQ		data_ack1	

error_ack1			LDR		R1,=I2C0_MCS_R
					LDR		R0,[R1]
					AND		R0,R0,#0x02
					LSR		R0,R0,#1
					CMP		R0,#1
					BEQ		error_ack1

controller_idle1_	LDR		R1,=I2C0_MCS_R
					LDR		R0,[R1]
					AND		R0,R0,#0x01
					CMP		R0,#1
					BEQ		controller_idle1_
					
					LDR		R3,[R4]
					BICS	R3,R3,#0xFFFFFFF0;
					LSL		R3,R3,#4
					
					LDR		R1,=I2C0_MDR_R
					LDR		R0,[R1]
					MOV		R0,R3
					STR		R0,[R1] ; Secondly, least significant 4 bits are send by I2C0
	
;wait_bus_busy2		LDR		R1,=I2C0_MCS_R
					;LDR		R0,[R1]
					;ANDS	R0,R0,#0x40
					;LSR		R0,R0,#6
					;CMP		R0,#1
					;BEQ		wait_bus_busy2;	

					LDR		R1,=I2C0_MCS_R
					MOV		R0,#0x01 ;
					STR		R0,[R1]
					
;data_ack2			LDR		R1,=I2C0_MCS_R
					;LDR		R0,[R1]
					;ANDS	R0,R0,#0x08
					;LSR		R0,R0,#3
					;CMP		R0,#1
					;BEQ		data_ack2
					
controller_idle2	LDR		R1,=I2C0_MCS_R
					LDR		R0,[R1]
					AND		R0,R0,#0x01
					CMP		R0,#1
					BEQ		controller_idle2
					
error_ack2			LDR		R1,=I2C0_MCS_R
					LDR		R0,[R1]
					AND		R0,R0,#0x02
					LSR		R0,R0,#1
					CMP		R0,#1
					BEQ		error_ack2
					
;wait_bus_busy3		LDR		R1,=I2C0_MCS_R
					;LDR		R0,[R1]
					;ANDS	R0,R0,#0x40
					;LSR		R0,R0,#6
					;CMP		R0,#1
					;BEQ		wait_bus_busy3;	

controller_idle2_	LDR		R1,=I2C0_MCS_R
					LDR		R0,[R1]
					AND		R0,R0,#0x01
					CMP		R0,#1
					BEQ		controller_idle2_ 

					LDR		R1,=I2C0_MCS_R
					LDR		R0,[R1]
					MOV		R0,#0x04 ;
					STR		R0,[R1]
					
;data_ack3			LDR		R1,=I2C0_MCS_R
					;LDR		R0,[R1]
					;ANDS	R0,R0,#0x08
					;LSR		R0,R0,#3
					;CMP		R0,#1
					;BEQ		data_ack3
					
controller_idle3	LDR		R1,=I2C0_MCS_R
					LDR		R0,[R1]
					AND		R0,R0,#0x01
					CMP		R0,#1
					BEQ		controller_idle3

;error_ack3			LDR		R1,=I2C0_MCS_R
					;LDR		R0,[R1]
					;ANDS	R0,R0,#0x02
					;LSR		R0,R0,#1
					;CMP		R0,#1
					;BEQ		error_ack3

					ADDS	R4,R4,#1
					
					POP		{R3}
					POP		{R2}
					POP		{R1}
					POP		{R0}
					POP		{LR}
					
	                BX		LR
						
;***************************************

delay_125us     
					PUSH	{LR}
					PUSH	{R0}
					PUSH	{R1}
					
					LDR		R0,=NVIC_ST_CTRL_R     	; System Timer(SysTick) control and status register
					MOV 	R1,#0 
					STR		R1,[R0]            		; stop counter to prevent any interrupt triggered accidentally
					LDR		R0,=NVIC_ST_RELOAD_R   	; System Timer(Systick) 24 bit reload register
					LDR		R1,=2499          		; trigger every 2499 cycles // 2500*(50ns)= 125us
					STR     R1,[R0]            		; write reload value to reload value register
					LDR		R0,=NVIC_ST_CURRENT_R  	; System Timer(SysTick) current value register
					MOV		R1,#0
					STR		R1,[R0]            		; write any value to current value register clears it
					LDR		R0,=NVIC_ST_CTRL_R     	; System Timer(SysTick) control and status register
					MOV		R1,#0x05           		; enable SysTick counter with system clock and no interrupt
					STR		R1,[R0]			   		; start counter
check_1				LDR     R1,[R0]            		; load the value inside the SysTick control and status register to R1 register
					LSRS	R1,R1,#16		   		; look at the COUNT bit which stores the flag value
					CMP		R1,#1			   		; check whether counter reached 0
					BEQ     done_1               	; if counter reached 0 go to label called done
					BNE     check_1              	; else continue to check				
done_1                
					POP     {R1}
					POP     {R0}
					POP		{LR}
					
					BX		LR                 		; return
					
;***************************************						
I2C_delay     
					PUSH	{LR}
					PUSH	{R0}
					PUSH	{R1}
					
					LDR		R0,=NVIC_ST_CTRL_R     	; System Timer(SysTick) control and status register
					MOV 	R1,#0 
					STR		R1,[R0]            		; stop counter to prevent any interrupt triggered accidentally
					LDR		R0,=NVIC_ST_RELOAD_R   	; System Timer(Systick) 24 bit reload register
					MOV     R1,R7	          		; trigger every 2499 cycles // 2500*(50ns)= 125us
					STR     R1,[R0]            		; write reload value to reload value register
					LDR		R0,=NVIC_ST_CURRENT_R  	; System Timer(SysTick) current value register
					MOV		R1,#0
					STR		R1,[R0]            		; write any value to current value register clears it
					LDR		R0,=NVIC_ST_CTRL_R     	; System Timer(SysTick) control and status register
					MOV		R1,#0x05           		; enable SysTick counter with system clock and no interrupt
					STR		R1,[R0]			   		; start counter
check_3				LDR     R1,[R0]            		; load the value inside the SysTick control and status register to R1 register
					LSRS	R1,R1,#16		   		; look at the COUNT bit which stores the flag value
					CMP		R1,#1			   		; check whether counter reached 0
					BEQ     done_3               	; if counter reached 0 go to label called done
					BNE     check_3              	; else continue to check				
done_3                
					POP     {R1}
					POP     {R0}
					POP		{LR}
					
					BX		LR                 		; return
					
;***************************************
delay_10ms       
					PUSH	{LR}
					PUSH	{R0}
					PUSH	{R1}
					
					LDR		R0,=NVIC_ST_CTRL_R     	; System Timer(SysTick) control and status register
					MOV 	R1,#0 
					STR		R1,[R0]            		; stop counter to prevent any interrupt triggered accidentally
					LDR		R0,=NVIC_ST_RELOAD_R   	; System Timer(Systick) 24 bit reload register
					LDR		R1,=199999          	; trigger every 199999 cycles // 200000*(50ns)= 10ms
					STR     R1,[R0]            		; write reload value to reload value register
					LDR		R0,=NVIC_ST_CURRENT_R  	; System Timer(SysTick) current value register
					MOV		R1,#0
					STR		R1,[R0]            		; write any value to current value register clears it
					LDR		R0,=NVIC_ST_CTRL_R     	; System Timer(SysTick) control and status register
					MOV		R1,#0x05           		; enable SysTick counter with system clock and no interrupt
					STR		R1,[R0]			   		; start counter
check_2				LDR     R1,[R0]            		; load the value inside the SysTick control and status register to R1 register
					LSRS	R1,R1,#16		   		; look at the COUNT bit which stores the flag value
					CMP		R1,#1			   		; check whether counter reached 0
					BEQ     done_2               	; if counter reached 0 go to label called done
					BNE     check_2              	; else continue to check				
done_2               
					POP     {R1}
					POP     {R0}
					POP		{LR}
					
					BX		LR                 		; return
					
;***************************************					
I2C_delay_control			
					PUSH	{LR}
					PUSH	{R0}
					PUSH	{R1}
					PUSH	{R2}
					
					LDR    	R2,=10 ; min delay
					
					LDR		R1,=ADC0_PSSI_R ; sample sequencer initiate address
					LDR		R0,[R1]
					ORR		R0,R0,#0x08 ; set bit 3 for SS3
					STR		R0,[R1]
			
;Check whether sample is complete or not (bit 3 of ADC_RIS_R is set)
control_1			LDR		R1,=ADC0_RIS_R
					LDR		R0,[R1]
					ANDS	R0,R0,#0x08 ; check whether bit 3 is "1" or not
					BEQ		control_1

;Branch fails if the flag is set so data can be read and flag is cleared
					LDR		R1,=ADC0_SSFIFO3_R
					LDR		R7,[R1]     ; store 12 bits in register R2
					
					CMP		R7,R2
					BLO		set_min_delay
					B	    set_ris
					
set_min_delay		MOV		R7,R2


set_ris				LDR		R1,=ADC0_RIS_R
					LDR		R0,[R1]
					ORR		R0,R0,#0x08 ; clear the interrupt flag
					STR		R0,[R1]
					
					POP		{R2}
					POP		{R1}
					POP		{R0}
					POP		{LR}
					
					BX		LR

;***************************************
						
;**************************************************************************
; End of the program  section
;**************************************************************************
;LABEL      		DIRECTIVE       VALUE                           COMMENT
					ALIGN
					END