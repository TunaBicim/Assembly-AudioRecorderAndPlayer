;***************************************
;Init_PLL.s source file to implement 
;initialization
;***************************************

;Definition of the labels standing for the
;address of the registers

SYSCTL_RIS_R			EQU		0x400FE050 ; Raw Interrupt Status		
SYSCTL_RIS_PLLRIS		EQU		0x00000040 ; PLL Lock Raw Interrupt Status
SYSCTL_RCC_R			EQU		0x400FE060 ; Run-Mode Clock Configuration
SYSCTL_RCC_XTAL_M		EQU		0x000007C0 ; Crystal Value
SYSCTL_RCC_XTAL_6MHZ	EQU		0x000002C0 ; 6 Mhz Crystal
SYSCTL_RCC_XTAL_8MHZ	EQU		0x00000380 ; 8 Mhz Crystal
SYSCTL_RCC_XTAL_16MHZ	EQU		0x00000540 ; 16 Mhz Crystal
SYSCTL_RCC2_R			EQU		0x400FE070 ; Run-Mode Clock Configuration 2
SYSCTL_RCC2_USERCC2		EQU		0x80000000 ; Use RCC2
SYSCTL_RCC2_DIV400		EQU		0x40000000 ; Divide PLL as 400 MHz vs. 200 Mhz
SYSCTL_RCC2_SYSDIV2_M	EQU		0x1F800000 ; System Clock Divisor 2
SYSCTL_RCC2_SYSDIV2LSB	EQU		0x00400000 ; Additional LSB for SYSDIV2
SYSCTL_RCC2_PWRDN2		EQU		0x00002000 ; Power-Down PLL 2
SYSCTL_RCC2_BYPASS2		EQU		0x00000800 ; PLL Bypass 2
SYSCTL_RCC2_OSCSRC2_M	EQU		0x00000070 ; Oscillator Source 2
SYSCTL_RCC2_OSCSRC2_MO	EQU		0x00000000 ; MOSC
SYSDIV2					EQU		0x13	   ; SYSDIV2 = 19
	
;***************************************
;Initialization Area
;***************************************

;configure system to get its clock from the PLL
;bus frequency is 400MHz/(SYSDIV2+1) = 400MHz/(19+1) = 20 MHz

						AREA init_pll , READONLY , CODE , ALIGN=2
						THUMB
						EXPORT	Init_PLL

Init_PLL				
						PUSH	{LR}
						PUSH	{R0}
						PUSH	{R1}
						PUSH	{R2}
						
;configure system to use RCC2 for advanced features
;such as 400 MHz PLL and non-integer System Clock Divisor						
						LDR		R1,=SYSCTL_RCC2_R
						LDR		R0,[R1]
						LDR		R2,=SYSCTL_RCC2_USERCC2
						ORR		R0,R0,R2
						STR		R0,[R1]
						
;bypass PLL while initializing						
						LDR		R1,=SYSCTL_RCC2_R
						LDR		R0,[R1]
						LDR		R2,=SYSCTL_RCC2_BYPASS2
						ORR		R0,R0,R2
						STR		R0,[R1]

;select the crystal value and oscillator source
						LDR		R1,=SYSCTL_RCC_R
						LDR		R0,[R1]
						LDR		R2,=SYSCTL_RCC_XTAL_M
						BIC		R0,R0,R2
						STR		R0,[R1]

;configure for 16 MHz crystal
						LDR		R1,=SYSCTL_RCC_R
						LDR		R0,[R1]
						LDR		R2,=SYSCTL_RCC_XTAL_16MHZ
						ADDS	R0,R0,R2
						STR		R0,[R1]

;clear oscillator source field
						LDR		R1,=SYSCTL_RCC2_R
						LDR		R0,[R1]
						LDR		R2,=SYSCTL_RCC2_OSCSRC2_M
						BIC		R0,R0,R2
						STR		R0,[R1]
						
;configure for main oscillator
						LDR		R1,=SYSCTL_RCC2_R
						LDR		R0,[R1]
						LDR		R2,=SYSCTL_RCC2_OSCSRC2_MO
						ADDS	R0,R0,R2
						STR		R0,[R1]

;activate PLL by clearing PWRDN
						LDR		R1,=SYSCTL_RCC2_R
						LDR		R0,[R1]
						LDR		R2,=SYSCTL_RCC2_PWRDN2
						BIC		R0,R0,R2
						STR		R0,[R1]

;set the system divider and the system divider least significant bit

;use 400 MHz PLL
						LDR		R1,=SYSCTL_RCC2_R
						LDR		R0,[R1]
						LDR		R2,=SYSCTL_RCC2_DIV400
						ORR		R0,R0,R2
						STR		R0,[R1]


						LDR		R1,=SYSCTL_RCC2_R
						LDR		R0,[R1]
						BIC		R0,R0,#0x1FC00000 ; clear system clock divider field
						LDR		R2,=SYSDIV2
						LSLS	R2,R2,#22		  ; configure for 20 Mhz clock
						ADDS	R0,R0,R2
						STR		R0,[R1]

;wait for the PLL to lock by polling PLLLRIS
						;LDR		R1,=SYSCTL_RIS_R
						;LDR		R0,[R1]
						;LDR		R2,=SYSCTL_RIS_PLLRIS
;wait					BICS	R0,R0,R2
						;CMP		R0,#0
						;BEQ		wait
						;BNE		continue
						
;enable use of PLL by clearing BYPASS
continue				LDR		R1,=SYSCTL_RCC2_R
						LDR		R0,[R1]
						LDR		R2,=SYSCTL_RCC2_BYPASS2
						BIC		R0,R0,R2
						STR		R0,[R1]
						
						POP		{R2}
						POP		{R1}
						POP		{R0}
						POP	    {LR}
						
						BX 		LR        ; return
						