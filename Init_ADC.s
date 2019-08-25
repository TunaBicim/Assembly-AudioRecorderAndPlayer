;***************************************
;Init_ADC.s source file to implement 
;initialization
;***************************************

;Definition of the labels standing for the
;address of the registers

NUMBER_ADDR			EQU		0x20000400 ; NUMBER_ADDR equals to memory location 0x20000400
	
;ADC REGISTERS
RCGCADC_R			EQU		0x400FE638 ; ADC clock register
								       ; ADC0 base address EQU 0x40038000
ADC0_ACTSS_R		EQU		0x40038000 ; Sample sequencer (ADC0 base address)
ADC0_RIS_R			EQU		0x40038004 ; Interrupt status
ADC0_IM_R			EQU		0x40038008 ; Interrupt select
ADC0_ISC_R			EQU 	0x4003800C ; Interrupt clear
ADC0_EMUX_R			EQU		0x40038014 ; Trigger select
ADC0_PSSI_R			EQU 	0x40038028 ; Initiate sample
ADC0_SSMUX3_R		EQU		0x400380A0 ; Input channel select
ADC0_SSCTL3_R		EQU		0x400380A4 ; Sample sequence control
ADC0_SSFIFO3_R		EQU		0x400380A8 ; Sample sequencer results
ADC0_PC_R			EQU		0X40038FC4 ; Sample rate
	
;GPIO REGISTERS
SYSCTL_RCGCGPIO_R	EQU		0x400FE608 ; GPIO Run Mode Clock Gating Control
								       ; PORT E base address EQU 0x40024000
GPIO_PORTE_DIR_R	EQU 	0x40024400 ; set direction
GPIO_PORTE_AFSEL_R 	EQU 	0x40024420 ; enable alternative functions
GPIO_PORTE_AMSEL_R	EQU		0x40024528 ; enable analog function
GPIO_PORTE_PCTL_R	EQU		0x4002452C ; alternative function selection
GPIO_PORTE_DEN_R	EQU		0x4002451C ; enable digital function
	
;***************************************
;Initialization Area
;***************************************

; This ADC initialization is used to sample microphone output voltage 
; in order to obtain input sound data during recording process.
; PE3(AIN0) pin of TM4C is used

			AREA    	init_adc1, READONLY, CODE, ALIGN=2
			THUMB		
			EXPORT  	Init_ADC1	

Init_ADC1

            PUSH		{LR}
			PUSH		{R0}
			PUSH		{R1}
			
;Setup GPIO to make PE3 input for ADC0
;Set direction of PE3 as input
			LDR			R1,=GPIO_PORTE_DIR_R
			LDR			R0,[R1]
			BIC			R0,R0,#0x08    ; set PE3 direction as input
			STR			R0,[R1]
;Enable alternative functions
			LDR			R1,=GPIO_PORTE_AFSEL_R
			LDR			R0,[R1]
			ORR			R0,R0,#0x08    ; enable alternative functions 
			STR			R0,[R1]
			
;Enable analog function
			LDR			R1,=GPIO_PORTE_AMSEL_R
			LDR			R0,[R1]
			ORR			R0,R0,#0x08    ; enable analog function
			STR			R0,[R1]
			
;Disable digital function
			LDR			R1,=GPIO_PORTE_DEN_R
			LDR			R0,[R1]
			BIC			R0,R0,#0x08    ; disable digital function
			STR			R0,[R1]			
			
;Disable sequencer while ADC setup
			LDR			R1,=ADC0_ACTSS_R
			LDR			R0,[R1]
			BIC			R0,R0,#0x08    ; clear bit 3 to disable Sequencer 3
			STR			R0,[R1]
			
;Select trigger source
			LDR			R1,=ADC0_EMUX_R
			LDR			R0,[R1]
			BIC			R0,R0,#0xF000  ; clear bits 15:12 to select SOFTWARE trigger
			STR			R0,[R1]
			
;Select input channel
			LDR			R1,=ADC0_SSMUX3_R
			LDR			R0,[R1]
			BIC			R0,R0,#0x0F    ; clear bits 3:0 to select AIN0 (PE3)
			STR			R0,[R1]
			
;Configure sample sequence
			LDR			R1,=ADC0_SSCTL3_R
			LDR			R0,[R1]
			ORR			R0,#0x06       ; set bits 2:1 (IE0,END0)
			STR			R0,[R1]

;Set sample rate
			LDR			R1,=ADC0_PC_R
			LDR			R0,[R1]
			ORR			R0,R0,#0x01    ; set bits 3:0 to 1 for 125K sps
			STR			R0,[R1]
			
;Setup is done, enable sequencer
			LDR			R1,=ADC0_ACTSS_R
			LDR			R0,[R1]
			ORR			R0,R0,#0x08    ; set bit 3 to enable sequencer 3
			STR 		R0,[R1]        ; sampling is enabled but not initiated yet
			ORR			R0,R0,#0x01
			STR			R0,[R1]
			
			POP			{R1}
			POP			{R0}
			POP			{LR}
			
			BX			LR			   ; return
				