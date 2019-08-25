;***************************************
;Init_I2C.s source file to implement 
;initialization
;***************************************

;Definition of the labels standing for the
;address of the registers

SYSCTL_RCGCGPIO_R		EQU		0x400FE608 ; GPIO Run Mode Clock Gating Control
GPIO_PORTB_AFSEL_R  	EQU		0x40005420 ; GPIO PortB Alternate Function	
GPIO_PORTB_AMSEL_R		EQU		0x40005528 ; GPIO PortB Analog Mode
GPIO_PORTB_PCTL_R		EQU		0x4000552C ; GPIO PortB Control
GPIO_PORTB_CR_R			EQU		0x40005524 ; GPIO PortB Commit
GPIO_PORTB_ODR_R		EQU		0x4000550C ; GPIO PortB Open Drain
GPIO_PORTB_DEN_R		EQU		0x4000551C ; GPIO PortB Digital Enable
	
SYSCTL_RCGCI2C_R		EQU		0x400FE620 ; I2C Run Mode Clock Gating Control
I2C0_MCR_R				EQU		0x40020020 ; I2C0 Master Configuration
I2C0_MTPR_R				EQU		0x4002000C ; I2C0 Master Timer Period
I2C0_MSA_R				EQU		0x40020000 ; I2C0 Master Slave Address
I2C0_MDR_R				EQU		0x40020008 ; I2C0 Master Data
I2C0_MCS_R				EQU		0x40020004 ; I2C0 Master Control/Status
TPR						EQU		0x02       ;SCL_PERIOD = 2 × (1 + TIMER_PRD) × (SCL_LP + SCL_HP) × CLK_PRD
										   ;For 20 MHz Clock Frequency:
										   ;CLK_PRD = 50 ns
										   ;TIMER_PRD = 2
										   ;SCL_LP=6
										   ;SCL_HP=4
										   ;yields a SCL frequency of:
								           ;1/SCL_PERIOD = 333 Khz
;***************************************
;Initialization Area
;***************************************

						AREA init_i2c , READONLY , CODE , ALIGN=2
						THUMB
						EXPORT	Init_I2C

;configure I2C0
;I2C0 wiring: PB2(SCL) and PB3(SDA)
;Initializes I2C0 width desired speed which is 333 kbps							
							
Init_I2C            
						PUSH	{LR}
						PUSH	{R0}
						PUSH	{R1}
						PUSH	{R2}
						
						LDR		R1,=SYSCTL_RCGCGPIO_R
						LDR		R0,[R1]
						ORR		R0,R0,#0x02 ; enable PORTE, PORTF and PORTB clock
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
						NOP					 ; let clock stabilize
						
;enable alternate functions for PB2 and PB3
						LDR		R1,=GPIO_PORTB_AFSEL_R
						LDR		R0,[R1]
						ORR		R0,R0,#0x0C
						STR		R0,[R1]
						
;disable analog functions for PB2 and PB3
						LDR		R1,=GPIO_PORTB_AMSEL_R
						LDR		R0,[R1]
						BIC		R0,R0,#0x0C
						STR		R0,[R1]
						
;set PCTL to use I2C as alternate function
						LDR		R1,=GPIO_PORTB_PCTL_R
						LDR		R0,[R1]
						ORR		R0,R0,#0x00003300
						STR		R0,[R1]
						
;allow changes
						LDR		R1,=GPIO_PORTB_CR_R
						LDR		R0,[R1]
						ORR		R0,R0,#0x0C
						STR		R0,[R1]
						
;enable I2C0 SDA pin PB3 for open-drain operation
						LDR		R1,=GPIO_PORTB_ODR_R
						LDR		R0,[R1]
						ORR		R0,R0,#0x08
						STR		R0,[R1]
						
;enable digital	for PB2 and PB3
						LDR		R1,=GPIO_PORTB_DEN_R
						LDR		R0,[R1]
						ORR		R0,R0,#0x0C
						STR		R0,[R1]
						
;Initialize I2C master
						LDR		R1,=I2C0_MCR_R
						LDR		R0,[R1]
						ORR		R0,R0,#0x10
						STR		R0,[R1]

;set the speed to 333 kbps
						LDR		R1,=I2C0_MTPR_R
						LDR		R0,[R1]
						LDR		R2,=TPR
						ORR		R0,R0,R2
						STR		R0,[R1]
						
						POP		{R2}
						POP		{R1}
						POP		{R0}
						POP	    {LR}
						
						BX 		LR           ; return
						