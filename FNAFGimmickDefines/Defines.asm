;Freeram stuff (Only use RAM addresses that doesn't reset on level load).
 if !sa1 == 0
  !Freeram_FNAF_Hours	= $7FAD49
 else
  !Freeram_FNAF_Hours	= $4001B9
 endif
 ;^[2 bytes] The timer that represents the hours. Note that this is
 ; actually an incrementing frame counter that only increments during
 ; main level mode (during loading, it briefly freezes). It gets
 ; converted to display the in-game hours.

 if !sa1 == 0
  !Freeram_FNAF_DoorFlag		= $7FAD4B
 else
  !Freeram_FNAF_DoorFlag		= $4001BB
 endif
 ;^[1 byte] left and right door flag, format: ------RL
 ; 0 = open
 ; 1 = close
 
 if !sa1 == 0
  !Freeram_FNAF_Power			= $7FAD4C
 else
  !Freeram_FNAF_Power			= $4001BC
 endif
 ;^[3 bytes] The power value. Note that this is stored as a fixed-point
 ; value with fractions of 256 ($xxxx.xx), and that the reading of this truncate
 ; the fraction at byte 0 (low endian).
 
;Settings
 !Setting_FNAF_DisplayTime		= 1
 ;^0 = display only the hour (12:01 AM would display 12 AM)
 ; 1 = display hours and minutes (XX:XX). Note the minutes rounded down.
 ; 2 = display the frame counter (for debugging purposes)
 
 !Setting_FNAF_HourLength	= 5160
 ;^How long each in-game hour, in frames
 ; Remember, the game runs 60FPS, so to convert real time
 ; to frames:
 ;  -Using units of seconds: [Frames = Seconds*60]
 ;  -Using units of minutes: [Frames = Minutes*3600]
 ;
 ; The maximum frame value here is 65535, (1092.25 seconds or
 ; 18 minutes and 32.25 seconds, real time).
 ;
 ;Formula if you are so used to MM:SS format:
 ;
 ; Frames = (Minutes*3600)+(Seconds*60)

 !Setting_FNAF_StartingPower		= $4000
 ;^The starting value of the power level, also used as
 ; to display as a percentage. This does not include the fixed-point
 ; fraction point (putting $3000 here means $3000.00)

 !Setting_FNAF_PowerDrainSpeed		= $000280
 ;^How many units of power drained per frame; divided by 16 for fixed point
 ;(so $000003 is $0000.03) when no other use is being triggered.
 
 !Setting_FNAF_DisplayPercentageRounding	= 1
 ;^0 = round down (0.99% display as 0%)
 ; 1 = round up (0.01% display as 1%)
 ; 2 = round half-up (0.4% display as 0%, 0.5% display as 1%)

 !Setting_FNAF_SNESMathOnly		= 0
 ;^Info follows:
 ;-Set this to 0 if any of your code AT LEAST calls the FNAF code under the SA-1 processor;
 ; should you ever have one code calls this using SA-1 and the other calls using SNES, or ALL calls
 ; using SA-1.
 ;-Set this to 1 if *all* codes that call FNAF routine are not using SA-1 processor.
 ;
 ;The reason for this is because if the user only uses the FNAF routine on a SA-1
 ;ROM, but never processed the routine by SA-1, using SA-1's math registers is useless as
 ;the SNES's 8-bit math registers ($4202, $4203, $4216-$4217) become available for 8-bit*8-bit = 16-bit.
 ;
 ;Things to note:
 ;
 ;-SNES' math handles 8bit*8bit = 16bit numbers, all unsigned. This will be unavailable to
 ; be used if processing SA-1.
 ;-SA-1's math are 16bit*16bit = 32bit, all *signed*. The register is always available
 ; to use regardless if SNES or SA-1 being used.

;Status bar stuff
 !StatusBarFormat                     = $02
 ;^Number of grouped bytes per 8x8 tile:
 ; $01 = Minimalist/SMB3 [TTTTTTTT, TTTTTTTT]...[YXPCCCTT, YXPCCCTT]
 ; $02 = Super status bar/Overworld border plus [TTTTTTTT YXPCCCTT, TTTTTTTT YXPCCCTT]...

 if !sa1 == 0
  !Setting_FNAF_TimePosition		= $7FA000
 else
  !Setting_FNAF_TimePosition		= $404000
 endif
 ;^Position of the XX AM on the HUD. By default, it is the top-left corner.
 
 if !sa1 == 0
  !Setting_FNAF_PowerPosition		= $7FA010
 else
  !Setting_FNAF_PowerPosition		= $404010
 endif
 ;^Position of the power percentage.