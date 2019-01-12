incsrc "FNAFGimmickDefines/Defines.asm"
incsrc "../ControllerExecuteOnce_defines/ExecuteOnce.asm"

db $42 ; or db $37
JMP MarioBelow : JMP MarioAbove : JMP MarioSide
JMP SpriteV : JMP SpriteH : JMP MarioCape : JMP MarioFireball
JMP TopCorner : JMP BodyInside : JMP HeadInside
; JMP WallFeet : JMP WallBody ; when using db $37

MarioBelow:
MarioAbove:
MarioSide:
TopCorner:
BodyInside:
HeadInside:
	LDA $16
	AND.b #%00001000
	BEQ Return

	LDA !Freeram_ControllerInteractBlkCooldown	;\Disable itself from unintentional retrigger
	BNE Return					;/
	
	LDA !Freeram_FNAF_DoorFlag
	AND.b #%00000001
	BEQ OpenDoor
	
	;CloseDoor
	LDA #$09
	BRA +
	
	OpenDoor:
	LDA #$0F
	+
	STA $1DFC|!addr
	
	LDA !Freeram_FNAF_DoorFlag
	EOR #%00000001
	STA !Freeram_FNAF_DoorFlag
	
	LDA #$08					;\Cooldown after toggling door
	STA !Freeram_ControllerInteractBlkCooldown	;/

WallFeet:
WallBody:
SpriteV:
SpriteH:

MarioCape:
MarioFireball:
Return:
	RTL

print "<description>"