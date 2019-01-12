incsrc "../FNAFGimmickDefines/Defines.asm"

;Used routines
;-TeleportSpecificLevel
;-MathMul16_16
;-MathDiv32_16
;-ConvertToDigits
;-MathDiv

!DigitTable = $02	;>used for HexToDec routine
if !sa1 != 0
	!DigitTable = $04
endif

Maincode:
	LDA $9D					;\Don't do anything during a freeze
	ORA $13D4|!addr				;|
	BEQ +
	JMP .Done				;/
	
	+
	;This increments the frame timer.
	.TimeIncrement
	REP #$20
	LDA !Freeram_FNAF_Hours			;\Stop timer once the night is over and finish level
	CMP.w #!Setting_FNAF_HourLength*6	;|
	BCS ..NightEnd				;/
	INC					;\Continue incrementing
	STA !Freeram_FNAF_Hours			;/
	SEP #$20
	BRA .HandlePower
	
	;Teleport the player when the night finishes
	..NightEnd
	LDA #$0105		;>Level to teleport to.
	JSL TeleportSpecificLevel
	SEP #$20
	
	.HandlePower
	LDA !Freeram_FNAF_Power
	ORA !Freeram_FNAF_Power+1
	ORA !Freeram_FNAF_Power+2
	BEQ ..OutOfPower
	
	..CalculatePowerDrain
	
	LDA.b #!Setting_FNAF_PowerDrainSpeed
	STA $00
	LDA.b #!Setting_FNAF_PowerDrainSpeed<<8
	STA $01
	LDA.b #!Setting_FNAF_PowerDrainSpeed<<16
	STA $02
	
	..DrainPower
	LDA !Freeram_FNAF_Power			;\Decrement 24-bit number
	SEC					;|(if unsigned underflow happens, the carry register is cleared).
	SBC $00					;|
	STA !Freeram_FNAF_Power			;|
	LDA !Freeram_FNAF_Power+1		;|
	SBC $01					;|
	STA !Freeram_FNAF_Power+1		;|
	LDA !Freeram_FNAF_Power+2		;|
	SBC $02					;|
	STA !Freeram_FNAF_Power+2		;/
	BCS ..DecrementNormally
	
	..Underflow
	LDA #$00				;\Stop the power level at zero.
	STA !Freeram_FNAF_Power			;|
	STA !Freeram_FNAF_Power+1		;|
	STA !Freeram_FNAF_Power+2		;/
	
	..DecrementNormally
	..OutOfPower
	
	.DisplayHUD
	
	..Time
	...ClearTile
	LDA #$FC						;>blank tile
	if !Setting_FNAF_DisplayTime == 0
		LDX #(2-1)*!StatusBarFormat			;\How many tiles to clear out (numbers and ":")
	elseif or(equal(!Setting_FNAF_DisplayTime, 1), equal(!Setting_FNAF_DisplayTime, 2))
		LDX #(5-1)*!StatusBarFormat			;|
	endif
	
	....Loop
	STA !Setting_FNAF_TimePosition,x			;>Clear tile
	DEX #!StatusBarFormat					;\Keep looping until not tiles left to clear
	BPL ....Loop						;/
		
	if or(equal(!Setting_FNAF_DisplayTime, 0), equal(!Setting_FNAF_DisplayTime, 1))
		;This simply determines what value to display on each hour division
		...DisplayClock
		REP #$20				;
		LDA !Freeram_FNAF_Hours			;
		STA $00					;
		LDA.w #!Setting_FNAF_HourLength		;
		STA $02					;
		SEP #$20				;
		JSL MathDiv				;>Quotient: the hour. Remainder: The minutes (not converted to 0-59 yet, its loop 0 to !Setting_FNAF_HourLength-1)
		
		....Hour
		REP #$20
		LDA $00
		SEP #$20
		BNE .....PastFirstHour
		
		.....TwelveAM
		LDA #$01				;\Write "12" instead of "0" on the first hour
		STA !Setting_FNAF_TimePosition		;|
		LDA #$02				;|
		BRA .....WriteOnesPlace			;/
		
		.....PastFirstHour
		.....WriteOnesPlace
		STA !Setting_FNAF_TimePosition+(1*!StatusBarFormat)
		
		if !Setting_FNAF_DisplayTime == 1
			LDA #$78						;\":"
			STA !Setting_FNAF_TimePosition+(2*!StatusBarFormat)	;/
			
			....Minute
			;Convert remainder X out of !Setting_FNAF_HourLength to
			;Y out of 60 (0-59)
			;
			;Calculated as [Minute = (X*60)/HourLength]
			REP #$20
			LDA $02					;\Take the remainder (unconverted "minutes"; looping from 0 to !Setting_FNAF_HourLength-1)
			STA $00					;/
			LDA.w #60				;\Multiply by 60
			STA $02					;/
			SEP #$20
			JSL MathMul16_16
			REP #$20
			LDA $04					;\Take potentially 32-bit product and place as
			STA $00					;|dividend
			LDA $06					;|
			STA $02					;/
			LDA.w #!Setting_FNAF_HourLength		;\Divide by HourLength
			STA $04					;/
			SEP #$20
			JSL MathDiv32_16
			LDA $00
			JSL HexDec
			STA !Setting_FNAF_TimePosition+(4*!StatusBarFormat)
			TXA
			STA !Setting_FNAF_TimePosition+(3*!StatusBarFormat)
		endif
		
		....WriteAM
		if !Setting_FNAF_DisplayTime == 0
			LDA #$0A
			STA !Setting_FNAF_TimePosition+(2*!StatusBarFormat)
			LDA #$16
			STA !Setting_FNAF_TimePosition+(3*!StatusBarFormat)
		elseif !Setting_FNAF_DisplayTime == 1
			LDA #$0A
			STA !Setting_FNAF_TimePosition+(5*!StatusBarFormat)
			LDA #$16
			STA !Setting_FNAF_TimePosition+(6*!StatusBarFormat)
		endif
	else
		;display time directly as a frame counter
	endif
	..Power
	;Percentage calculated as [Percentage = (!Freeram_FNAF_Power*100)/!Setting_FNAF_StartingPower]
	REP #$20			;\!Freeram_FNAF_Power*100
	LDA !Freeram_FNAF_Power+1	;|
	STA $00				;|
	LDA.w #100			;|
	STA $02				;|
	SEP #$20			;|
	JSL MathMul16_16		;/
	REP #$20				;\Divide by !Setting_FNAF_StartingPower
	LDA $04					;|
	STA $00					;|
	LDA $06					;|
	STA $02					;|
	LDA.w #!Setting_FNAF_StartingPower	;|
	STA $04					;|
	SEP #$20				;|
	JSL MathDiv32_16			;/
	
	if !Setting_FNAF_DisplayPercentageRounding != 0
		REP #$20				;\Round up should the remainder be nonzero
		LDA $04					;|
		BEQ +					;|
		INC $00					;|
		+					;/
		SEP #$20
	endif
	
	JSL ConvertToDigits
	
	LDA !DigitTable+2
	STA !Setting_FNAF_PowerPosition
	LDA !DigitTable+3
	STA !Setting_FNAF_PowerPosition+(1*!StatusBarFormat)
	LDA !DigitTable+4
	STA !Setting_FNAF_PowerPosition+(2*!StatusBarFormat)
	
	.Done
	RTL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Teleport to specific level
;Usage:
; REP #$20
; LDA <level>
; JSL TeleportSpecificLevel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TeleportSpecificLevel:
	STA $00
	STZ $88
	
	SEP #$30
	PHX

	LDX $95
	PHA
	LDA $5B
	LSR
	PLA
	BCC +
	LDX $97
	
+	LDA $00
	STA $19B8|!addr,x
	LDA $01
	STA $19D8|!addr,x

	LDA #$06
	STA $71
	
	PLX
	RTL

if !sa1 == 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 16bit * 16bit unsigned Multiplication
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Argusment
; $00-$01 : Multiplicand
; $02-$03 : Multiplier
; Return values
; $04-$07 : Product
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MathMul16_16:	REP #$20
		LDY $00
		STY $4202
		LDY $02
		STY $4203
		STZ $06
		LDY $03
		LDA $4216
		STY $4203
		STA $04
		LDA $05
		REP #$11
		ADC $4216
		LDY $01
		STY $4202
		SEP #$10
		CLC
		LDY $03
		ADC $4216
		STY $4203
		STA $05
		LDA $06
		CLC
		ADC $4216
		STA $06
		SEP #$20
		RTL
else
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 16bit * 16bit unsigned Multiplication SA-1 version
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Argusment
; $00-$01 : Multiplicand
; $02-$03 : Multiplier
; Return values
; $04-$07 : Product
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MathMul16_16:	STZ $2250
		REP #$20
		LDA $00
		STA $2251
		ASL A
		LDA $02
		STA $2253
		BCS +
		LDA.w #$0000
+		BIT $02
		BPL +
		CLC
		ADC $00
+		CLC
		ADC $2308
		STA $06
		LDA $2306
		STA $04
		SEP #$20
		RTL
endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Unsigned 32bit / 16bit Division
; By Akaginite (ID:8691), fixed the overflow
; bitshift by GreenHammerBro (ID:18802)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Arguments
; $00-$03 : Dividend
; $04-$05 : Divisor
; Return values
; $00-$03 : Quotient
; $04-$05 : Remainder
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MathDiv32_16:	REP #$20
		ASL $00
		ROL $02
		LDY #$1F
		LDA.w #$0000
-		ROL A
		BCS +
		CMP $04
		BCC ++
+		SBC $04
		SEC
++		ROL $00
		ROL $02
		DEY
		BPL -
		STA $04
		SEP #$20
		RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;16-bit hex to 4 (or 5)-digit decimal subroutine
;Input:
;$00-$01 = the value you want to display
;Output:
;!DigitTable to !DigitTable+4 = a digit 0-9 per byte table (used for
; 1-digit per 8x8 tile):
; +$00 = ten thousands
; +$01 = thousands
; +$02 = hundreds
; +$03 = tens
; +$04 = ones
;
;!DigitTable is address $02 for normal ROM and $04 for SA-1.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	
ConvertToDigits:
	if !sa1 == 0
		PHX
		PHY

		LDX #$04	;>5 bytes to write 5 digits.

		.Loop
		REP #$20	;\Dividend (in 16-bit)
		LDA $00		;|
		STA $4204	;|
		SEP #$20	;/
		LDA.b #10	;\base 10 Divisor
		STA $4206	;/
		JSR .Wait	;>wait
		REP #$20	;\quotient so that next loop would output
		LDA $4214	;|the next digit properly, so basically the value
		STA $00		;|in question gets divided by 10 repeatedly. [Value/(10^x)]
		SEP #$20	;/
		LDA $4216	;>Remainder (mod 10 to stay within 0-9 per digit)
		STA $02,x	;>Store tile

		DEX
		BPL .Loop

		PLY
		PLX
		RTL

		.Wait
		JSR ..Done		;>Waste cycles until the calculation is done
		..Done
		RTS
	else
		PHX
		PHY

		LDX #$04

		.Loop
		REP #$20		;>16-bit XY
		LDA.w #10		;>Base 10
		STA $02			;>Divisor (10)
		SEP #$20		;>8-bit XY
		JSL MathDiv		;>divide
		LDA $02			;>Remainder (mod 10 to stay within 0-9 per digit)
		STA.b !DigitTable,x	;>Store tile

		DEX
		BPL .Loop

		PLY
		PLX
		RTL
	endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 16bit / 16bit Division
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Arguments
; $00-$01 : Dividend
; $02-$03 : Divisor
; Return values
; $00-$01 : Quotient
; $02-$03 : Remainder
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MathDiv:	REP #$20
		ASL $00
		LDY #$0F
		LDA.w #$0000
-		ROL A
		CMP $02
		BCC +
		SBC $02
+		ROL $00
		DEY
		BPL -
		STA $02
		SEP #$20
		RTL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Small hexdec routine (works best with 0-99).
;Input:
; A = 8-bit value to convert
;Output:
; A = ones place
; X = tens (glitches out if above 99).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HexDec:
	LDX #$00
.Loops
	CMP #$0A
	BCC .Return
	SBC #$0A
	INX
	BRA .Loops
.Return
	RTL