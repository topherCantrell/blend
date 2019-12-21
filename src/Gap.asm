; DoubleGap by Christopher Cantrell 2006
; ccantrell@knology.net

; TO DO
; - Expert switches are backwards
; - Debounce switches

; build-command java Blend gap.asm g2.asm
; build-command tasm -b -65 g2.asm g2.bin

; This file uses the "BLEND" program for assembly pre-processing
processor 6502

#include "Stella.asm" ; Equates to give names to hardware memory locations

; The EditorTab comments are read by the SNAP editor, which makes 
; assembly editing a ... SNAP!

;<EditorTab name="RAM">
;
; RAM usage
;
TMP0      .EQU   0x80 ; Temporary storage
TMP1      .EQU   0x81 ; Temporary storage
TMP2      .EQU   0x82 ; Temporary storage
PLAYR0Y   .EQU   0x83 ; Player 0's Y location (normal or pro)
PLAYR1Y   .EQU   0x84 ; Player 1's Y location (normal, pro, or off)
MUS_TMP0  .EQU   0x85 ; Game-over mode sound FX storage (frame delay)
MUS_TMP1  .EQU   0x86 ; Game-over mode sound FX storage (frequency)
SCANCNT   .EQU   0x87 ; Scanline counter during screen drawing
MODE      .EQU   0x88 ; Game mode: 0=GameOver 1=Play 2=Select
WALL_INC  .EQU   0x89 ; How much to add to wall's Y position
WALLCNT   .EQU   0x8A ; Number of walls passed (score)
WALLDELY  .EQU   0x8B ; Wall movement frame skip counter
WALLDELYR .EQU   0x8C ; Number of frames to skip between wall increments
ENTROPYA  .EQU   0x8D ; Incremeneted with every frame
ENTROPYB  .EQU   0x8E ; SWCHA adds in
ENTROPYC  .EQU   0x8F ; Left/Right movements added to other entropies
DEBOUNCE  .EQU   0x90 ; Last state of the Reset/Select switches
WALLDRELA .EQU   0x91 ; PF0 pattern for wall
WALLDRELB .EQU   0x92 ; PF1 pattern for wall
WALLDRELC .EQU   0x93 ; PF2 pattern for wall
WALLSTART .EQU   0x94 ; Wall's Y position (scanline)
WALLHEI   .EQU   0x95 ; Height of wall
GAPBITS   .EQU   0x96 ; Wall's gap pattern (used to make WALLDRELx)
SCORE_PF1 .EQU   0x97 ; 6-bytes. PF1 pattern for each row of the score
SCORE_PF2 .EQU   0x9D ; 6-bytes. PF2 pattern for each row of the score
MUSADEL   .EQU   0xA3 ; Music A delay count
MUSAIND   .EQU   0xA4 ; Music A pointer
MUSAVOL   .EQU   0xA5 ; Music A volume
MUSBDEL   .EQU   0xA6 ; Music B delay count
MUSBIND   .EQU   0xA7 ; Music B pointer
MUSBVOL   .EQU   0xA8 ; Music B volume

; Remember, stack builds down from $FF ... leave some space
;
; 80 - A8 ... that's 41 bytes of RAM used

;</EditorTab>

  .org 0xF000

;<EditorTab name="main">

main() {
  I_Flag = 1        ; Turn off interrupts
  D_Flag = 0        ; Clear the "decimal" flag
  X = 0xFF          ; Set the stack pointer ...
  S = X             ; ... to the end of RAM
  INIT()            ; Initialize game environment
  INIT_SELMODE()    ; Start out in SELECT-MODE
  VIDEO_KERNEL()    ; There should be no return from the KERNEL
}

;</EditorTab>
  
;<EditorTab name="kernel">

VIDEO_KERNEL() {
;  (start here at the END of every frame)
;
  while(true) {

      A = 2          ; D1 bit ON
      WSYNC  = A     ; Wait for the end of the current line
      VBLANK = A     ; Turn the electron beam off
      WSYNC  = A     ; Wait for all ...
      WSYNC  = A     ; ... the electrons ...
      WSYNC  = A     ; ... to drain out.
      VSYNC  = A     ; Trigger the vertical sync signal
      WSYNC  = A     ; Hold the vsync signal for ...
      WSYNC  = A     ; ... three ...
      WSYNC  = A     ; ... scanlines
      HMOVE  = A     ; Tell hardware to move all game objects
      A = 0          ; D1 bit OFF
      VSYNC  = A     ; Release the vertical sync signal
      A  = 43        ; Set timer to 43*64 = 2752 machine ...
      TIM64T = A     ; ... cycles 2752/(228/3) = 36 scanlines

      ; ***** LENGTHY GAME LOGIC PROCESSING BEGINS HERE *****

      ; Do one of 3 routines while the beam travels back to the top
      ; 0 = Game Over processing
      ; 1 = Playing-Game processing
      ; 2 = Selecting-Game processing

      ++ENTROPYA        ; Counting video frames as part of the random number
      A = MODE          ; What are we doing between frames?

      if(A==0) {
          GOMODE()      ; Game-over processing
      } else if(A==1) {
          PLAYMODE()    ; Playing-game processing
      } else {
          SELMODE()     ; Selecting game processing
      }
      
      ; ***** LENGTHY GAME LOGIC PROCESSING ENDS HERE *****

      do {
          A = INTIM     ; Wait for the visible area of the screen
      } while(A!=0);

      WSYNC = A         ; 37th scanline
      A = 0             ; Turn the ...
      VBLANK = A        ; ... electron beam back on
            
      A = 0             ; Zero out ...
      SCANCNT = A       ; ... scanline count ...
      TMP0 = A          ; ... and all ...
      TMP1 = A          ; ... returns ...
      TMP2 = A          ; ... expected ...
      X = A             ; ... to come from ...
      Y = A             ; ... BUILDROW

      CXCLR = A         ; Clear collision detection

      ; BEGIN VISIBLE PART OF FRAME

      do {

          A = TMP0      ; Get A ready (PF0 value)
          WSYNC = A     ; Wait for very start of row
          GRP0 = X      ; Player 0 -- in X
          GRP1 = Y      ; Player 1 -- in Y
          PF0 = A       ; PF0      -- in TMP0 (already in A)
          A = TMP1      ; PF1      -- in TMP1
          PF1 = A       ; ...
          A = TMP2      ; PP2      -- in TMP2
          PF2 = A       ; ...

          BUILDROW()    ; This MUST take through to the next line

          ++SCANCNT     ; Next scan line
          A = SCANCNT   ; Do 109*2 = 218 lines

      } while(A!=109)

      ; END VISIBLE PART OF FRAME

      A = 0             ; Turning off visuals
      WSYNC = A         ; Next scanline
      PF0 = A           ; Play field 0 off
      GRP0 = A          ; Player 0 off
      GRP1 = A          ; Player 1 off
      PF1 = A           ; Play field 1 off
      PF2 = A           ; Play field 2 off
      WSYNC = A         ; Next scanline
      
  }

}

; ======================================

BUILDROW() {        
  
  A = SCANCNT    ; Current scanline

  if(A<6) {      ; Top 6 rows are for the score

      A = A & 7          ; Only need the lower 3 bits
      Y = A              ; Soon to be an index into a list

      ; At this point, the beam is past the loading of the
      ; playfield for the left half. We want to make sure
      ; that the right half of the playfield is off, so do that
      ; now.

      X =  0             ; Blank bit pattern
      TMP0 = X           ; This will always be blank
      PF1 = X            ; Turn off playfield ...
      PF2 = X            ; ... for right half of the screen
      
      X = A              ; Another index
      A = SCORE_PF1[Y]   ; Lookup the PF1 graphics for this row
      TMP1 = A           ; Return it to the caller
      Y = A              ; We'll need this value again in a second
      A = SCORE_PF2[X]   ; Lookup the PF2 graphics for this row
      TMP2 = A           ; Return it to the caller
      
      WSYNC = A          ; Now on the next row
      
      PF1 = Y            ; Repeat the left-side playfield ...
      PF2 = A            ; ... onto the new row

      A =  SCORE_PF2[X]  ; Kill some time waiting for the ...
      A =  SCORE_PF2[X]  ; ... beam to pass the left half ...
      A =  SCORE_PF2[X]  ; ... of the playfield again
      A =  SCORE_PF2[X]  ; 
      A =  SCORE_PF2[X]  ; 
      A =  SCORE_PF2[X]  ; 

      X  =  0            ; Return 0 (off) for player 0 ...
      Y  = 0             ; ... and player 1

      ; The beam is past the left half of the field again.
      ; Turn off the playfield.

      PF1 = X            ; 0 to PF1 ...
      PF2 = X            ; ... and PF2

  } else {   ; Rest of the rows are for the game area
      
      A = A &7           ; Lower 3 bits as an index again
      Y = A              ; Using Y to lookup graphics
      A =  GR_PLAYER[Y]  ; Get the graphics (if enabled on this row)
      X = A              ; Hold it (for return as player 0)
      Y = A              ; Hold it (for return as player 1)
      A = SCANCNT        ; Scanline count again
      A>>1               ; This time ...
      A>>1               ; ... we divide ...
      A>>1               ; ... by eight (8 rows in picture)

      if(A!=PLAYR0Y) {
          X = 0          ; Not time for Player 0 ... no graphics
      }

      if(A!=PLAYR1Y) {
          Y = 0          ; Not time for Player 0 ... no graphics
      }

      A =  WALLSTART     ; Calculate ...
      A = A + WALLHEI    ; ... the bottom of ...  
      TMP0 = A           ; ... the wall

      A = SCANCNT        ; Scanline count

      if(A>=WALLSTART && A<TMP0) {
          ; The wall is on this row
          A = WALLDRELA      ; Draw wall ...
          TMP0 = A           ; ... by transfering ...
          A =  WALLDRELB     ; ... playfield ...
          TMP1 = A           ; ... patterns ...
          A =  WALLDRELC     ; ... to ...
          TMP2 = A           ; ... return area
      } else {
          ; The wall is NOT on this row
          A  = 0             ; No walls on this row
          TMP0 = A           ; ... clear ...
          TMP1 = A           ; ... out ...
          TMP2 = A           ; ... the playfield
      }
      
  }
  
}
;</EditorTab>

; ============= END OF VIDEO KERNEL ===================


; ======================================
;<EditorTab name="init">
INIT() {          
;
; This function is called ONCE at power-up/reset to initialize various
; hardware and temporaries.
;
  A =  0x40         ; Playfield ...
  COLUPF = A        ; ... redish
  A =   0x7E        ; Player 0 ...
  COLUP0 = A        ; ... white
  A =  0            ; Player 1 ...
  COLUP1 = A        ; ... black

  A = 5             ; Right half of playfield is reflection of left ...
  CTRLPF = A        ; ... and playfield is on top of players

  X =  4            ; Player 0 position count
  Y =  3            ; Player 1 position count
  WSYNC = A         ; Get a fresh scanline

  do {
      --X           ; Kill time while the beam moves 
  } while(X!=0);
  RESP0 = A         ; Mark player 0's X position

  do {
      --Y           ; Kill more time
  } while(Y!=0);
  RESP1 = A         ; Mark player 1's X position

  EXPERTISE()       ; Initialize the players' Y positions base on expert-settings
  
  A  = 10           ; Wall is ...
  WALLHEI = A       ; ... 10 double-scanlines high
    
  A  = 0            ; Set score to ...
  WALLCNT = A       ; ... 0
  MAKE_SCORE()      ; Blank the score digits
  A  = 0            ; Blank bits ...
  SCORE_PF2[5] = A  ; ... on the end of each ...
  SCORE_PF1[5] = A  ; ... digit pattern

  ADJUST_DIF()      ; Initialize the wall parameters
  NEW_GAPS()        ; Build the wall's initial gap
  
  A =  112          ; Set wall position off bottom ...
  WALLSTART = A     ; ... to force a restart on first move

  A = 0             ; Zero out ...
  HMP0 = A          ; ... player 0 motion ...
  HMP1 = A          ; ... and player 1 motion
  
}
;</EditorTab>

; ===================================
;<EditorTab name="play-mode">
INIT_PLAYMODE() {
;
; This function initializes the game play mode
;
  A = 0xC0        ; Background color ...
  COLUBK = A      ; ... greenish
  A = 1           ; Game mode is ...
  MODE = A        ; ... SELECT
  A = 255         ; Restart wall score to ...
  WALLCNT = A     ; ... 0 on first move
  A = 112         ; Force wall to start ...
  WALLSTART = A   ; ... over on first move
  INIT_MUSIC()    ; Initialize the music
}

; ======================================
PLAYMODE() {  
;
; This function is called once per frame to process the main game play.
;
  
  SEL_RESET_CHK()     ; Check to see if Reset/Select has changed

  if(A!=0) {          ; A!=0 if reset/select has been toggled
      DEBOUNCE = X    ; Restore the old value ...
      INIT_SELMODE()  ; ... and let select-mode process the toggle
      return
  }
  
  PROCESS_MUSIC()     ; Process any playing music
  MOVE_WALLS()        ; Move the walls

  if(A==1) {          ; A==1 if wall reached bottom
      ++WALLCNT       ; Bump the score
      ADJUST_DIF()    ; Change the wall parameters based on score
      A =  WALLCNT    ; Change the ...
      MAKE_SCORE()    ; ... score pattern
      NEW_GAPS()      ; Calculate the new gap position
  }

  A =  CXP0FB         ; Player 0 collision with playfield
  TMP0 = A            ; Hold it
  A =  CXP1FB         ; Player 1 collision with playfield
  A = A | TMP0        ; Did either ...
  A = A & 0x80        ; ... player collide with wall?

  if(A!=0) {
      INIT_GOMODE()   ; Go to Game-Over mode
      return
  }

  A =  SWCHA                 ; Joystick
  A = A + C_Flag + ENTROPYB  ; Add to ...  
  ENTROPYB = A               ; ... entropy

  A =  SWCHA          ; Joystick
  A = A & 0x80        ; Player 0 left switch
  if(A==0) {          ; A==0 if joystick-left
      A =  0xF0       ; Moving left value
  } else {
      A =  SWCHA      ; Joystick
      A = A & 0x40    ; Player 0 right switch
      if(A==0) {      ; A==0 if joystick-right
          ++ENTROPYC  ; Yes ... increase entropy
          A =  0x10   ; Moving right value
      } else {
          A =   0     ; Not moving value
      }
  }
  HMP0 = A            ; New movement value P0

  A = SWCHA           ; Joystick
  A = A & 0x08        ; Player 1 left switch
  if(A==0) {
      A =  0xF0       ; Moving left value
  } else {
      A = SWCHA       ; Joystick
      A = A & 0x04    ; Player 1 right switch
      if(A==0) {
          A =  0x10   ; Moving right value
      } else {
          ++ENTROPYC  ; Increase entropy
          A = 0       ; Not moving value
      }
  }
  HMP1 = A            ; New movement value P1

}
;</EditorTab>

; ===================================
;<EditorTab name="select-mode">
INIT_SELMODE() {
;
; This function initializes the games SELECT-MODE
;          
  A =  0        ; Turn off ...
  AUDV0 = A     ; ... all ...
  AUDV1 = A     ; ... sound
  A = 0xC8      ; Background color ...
  COLUBK = A    ; ... greenish bright
  A = 2         ; Now in ...
  MODE = A      ; SELECT game mode
}

; ======================================
SELMODE() {
;
; This function is called once per frame to process the SELECT-MODE.
; The wall moves here, but doesn't change or collide with players.
; This function selects between 1 and 2 player game.
;
  MOVE_WALLS()         ; Move the walls
  SEL_RESET_CHK()      ; Check the reset/select switches
  
  if(A==1 || A==3) {
      INIT_PLAYMODE()  ; Reset toggled ... start game
  } else if(A==2) {
      A =  PLAYR1Y     ; Select toggled. Get player 1 Y coordinate
      if(A==255) {
          A =  12      ; Onscreen if it is currently off
      } else {
          A =  255     ; Offscreen if it is currently on
      }
      STA  PLAYR1Y     ; Toggled Y coordinate
  }

  EXPERTISE()          ; Adjust both players for pro settings
}
;</EditorTab>

; ======================================
;<EditorTab name="go-mode">
INIT_GOMODE() {
;
; This function initializes the GAME-OVER game mode.
;   
  HMCLR = A             ; Stop both players from moving
  A = CXP0FB            ; P0 collision with wall
  A = A & 0x80          ; Did player 0 collide?

  if(A==0) {
      A  = 2            ; No ... move player 0 ...
      PLAYR0Y = A       ; ... up the screen
  }

  A = CXP1FB            ; P1 collision with wall
  A = A & 0x80          ; Did player 1 collide?

  if(A==0 ) {
      A =  PLAYR1Y
      if(A!=255) { 
          A =  2        ; Player 1 is onscreen and didn't collide ...
          PLAYR1Y = A   ; ... move up the screen
      }
  }

  A =  0         ; Going to ...
  MODE = A       ; ... game-over mode
  AUDV0 = A      ; Turn off any ...
  AUDV1 = A      ; ... sound
  INIT_GO_FX()   ; Initialize sound effects
}

; ======================================
GOMODE() {
;
; This function is called every frame to process the game
; over sequence. When the sound effect has finished, the
; game switches to select mode.
;
  PROCESS_GO_FX()       ; Process the sound effects
  if(A!=0) {
      INIT_SELMODE()    ; When effect is over, go to select mode
  }
}                       ; Keep coming back till the effect is over
;</EditorTab>

; ======================================
;<EditorMode name="utils">
MOVE_WALLS() {
;
; This function moves the wall down the screen and back to position 0
; when it reaches (or passes) 112.
;
;
  --WALLDELY     ; Time to move the wall
  A =  WALLDELY

  if(A!=0) {               ; A!=0 if still delaying wall movement
      A = 0                ; Return flag that wall did NOT restart
  } else {
      A =  WALLDELYR       ; Reset the ...
      WALLDELY = A         ; ... delay count
      A =  WALLSTART       ; Current wall position
      A = A + WALL_INC     ; Increment wall position      
      if(A<112) {          ; A>=112 if wall is off screen
          WALLSTART = A    ; Store new wall position
          A = 0            ; Return flag that wall did NOT restart
      } else {
          A = 0            ; Else restart ...
          WALLSTART = A    ; ... wall at top of screen
          A = 1            ; Return flag that wall DID restart
      }
  }
  
}

; ======================================
NEW_GAPS() {
;
; This function builds the PF0, PF1, and PF2 graphics for a wall
; with the gap pattern (GAPBITS) placed at random in the 20 bit
; area.
;
  A =  255         ; Start with ...
  WALLDRELA = A    ; ... solid wall in PF0 ...
  WALLDRELB = A    ; ... and PF1
  A = GAPBITS      ; Store the gap pattern ...
  WALLDRELC = A    ; ... in PF2
  
  A =  ENTROPYA               ; Get ...
  A = A + C_Flag + ENTROPYB   ; ... a randomish ...
  A = A + C_Flag + ENTROPYC   ; ... number ...  
  ENTROPYC = A
  A = A &15                   ; ... 0 to 15

  if(A>12) {
      ;A = A - 9
      A = A - C_Flag - 9
  }
  
  while(A!=0) {
      C_Flag = 1       ; Roll gap ...
      ROR  WALLDRELC   ; ... left ...
      ROL  WALLDRELB   ; ... desired ...
      ROR  WALLDRELA   ; ... times ...
      A = A - 1
  }

}

; ======================================
MAKE_SCORE() {
;
; This function builds the PF1 and PF2 graphics rows for
; the byte value passed in A. The current implementation is
; two-digits only ... PF2 is blank.
;
  X =  0             ; 100's digit
  Y = 0              ; 10's digit

  while(A>=100) {
      ++X            ; Count ...
      A = A - 100    ; ... value
  }

  while(A>=10) {
      ++Y            ; Count ...
      A = A - 10     ; ... value
  }

  A<<1               ; One's digit ...
  A<<1               ; ... *8 ....
  A<<1               ; ... to find picture
  X = A              ; One's digit picture to X
  A = Y              ; Now the 10's digit
  A<<1               ; Multiply ...
  A<<1               ; ... by 8 ...
  A<<1               ; ... to find picture
  Y = A              ; 10's picture in Y
  
  A =  DIGITS[Y]     ; Get the 10's digit
  A = A & 0xF0       ; Only use the left side of the picture
  SCORE_PF1 = A      ; Store left side
  A = DIGITS[X]      ; Get the 1's digit
  A = A & 0x0F       ; Only use the right side of the picture
  A = A | SCORE_PF1  ; Put left and right half together
  SCORE_PF1 = A      ; And store image

  A = DIGITS+1[Y]    ; Repeat for 2nd line of picture
  A = A & 0xF0
  SCORE_PF1[1] = A
  A = DIGITS+1[X]
  A = A & 0x0F
  A = A | SCORE_PF1[1]
  SCORE_PF1[1] = A

  A = DIGITS+2[Y]    ; Repeat for 3nd line of picture
  A = A & 0xF0
  SCORE_PF1[2] = A
  A = DIGITS+2[X]
  A = A & 0x0F
  A = A | SCORE_PF1[2]
  SCORE_PF1[2] = A

  A = DIGITS+3[Y]    ; Repeat for 4th line of picture
  A = A & 0xF0
  SCORE_PF1[3] = A
  A = DIGITS+3[X]
  A = A & 0x0F
  A = A | SCORE_PF1[3]
  SCORE_PF1[3] = A

  A = DIGITS+4[Y]    ; Repeat for 5th line of picture
  A = A & 0xF0
  SCORE_PF1[4] = A
  A = DIGITS+4[X]
  A = A & 0x0F
  A = A | SCORE_PF1[4]
  SCORE_PF1[4] = A

  A = 0              ; For now ...
  SCORE_PF2 = A      ; ... there ...
  SCORE_PF2[1] = A   ; ... is ...
  SCORE_PF2[2] = A   ; ... no ...
  SCORE_PF2[3] = A   ; ... 100s ...
  SCORE_PF2[4] = A   ; ... digit drawn

}

; ======================================
EXPERTISE() {
;
; This function changes the Y position of the players based on the
; position of their respective pro/novice switches. The player 1
; position is NOT changed if the mode is a single-player game.
;
  A =  SWCHB          ; Pro/novice settings
  A = A & 0x80        ; Novice for Player 0?
  if(A==0) {
      A =  12         ; Novice ... near the bottom
  } else {
      A = 8           ; Pro ... near the top
  }
  PLAYR0Y = A         ; ... to Player 0
  
  X = PLAYR1Y
  if(X!=255) {        ; Only move player 1 if it is a 2-player game
      A = SWCHB
      A = A & 0x40
      if(A==0) {
          X = 12      ; Novice ... near the bottom
      } else {
          X = 8       ; Pro ... near the top
      }
      PLAYR1Y = X
  }

}

; ======================================
ADJUST_DIF() {
;
; This function adjusts the wall game difficulty values based on the
; current score. The music can also change with the difficulty. A single
; table describes the new values and when they take effect.
;              
  X = 0  ; Starting at index 0

  while(true) {

      A = SKILL_VALUES[X]       ; Get the score match
      if(A==255) {
          return                ; End of the table ... leave it alone
      }
      if(A==WALLCNT) {
          ++X                   ; Copy ...
          A = SKILL_VALUES[X]   ; ... new ...
          WALL_INC = A          ; ... wall increment
          ++X                   ; Copy ...
          A = SKILL_VALUES[X]   ; ... new ...
          WALLDELY = A          ; ... wall ...
          WALLDELYR = A         ; ... delay
          ++X                   ; Copy ...
          A = SKILL_VALUES[X]   ; ... new ...
          GAPBITS = A           ; ... gap pattern
          ++X                   ; Copy ...
          A = SKILL_VALUES[X]   ; ... new ...
          MUSAIND = A           ; ... MusicA index
          ++X                   ; Copy ...
          A = SKILL_VALUES[X]   ; ... new ...
          MUSBIND = A           ; ... MusicB index
          A = 1                 ; Force ...
          MUSADEL = A           ; ... music to ...
          MUSBDEL = A           ; ... start new
          return
      }
      
      ++X     ; Move ...
      ++X     ; ... X ...
      ++X     ; ... to ...
      ++X     ; ... next ...
      ++X     ; ... row of ...
      ++X     ; ... table
  }
}  

; ======================================
SEL_RESET_CHK() {
;
; This function checks for changes to the reset/select
; switches and debounces the transitions.
;
  
  X =  DEBOUNCE     ; Hold onto old value
  A =  SWCHB        ; New value
  A = A & 3         ; Only need bottom 2 bits

  if(A==DEBOUNCE) {
      A = 0         ; Return 0 ... nothing changed
  } else {
      DEBOUNCE = A  ; Hold new value
      A = A ^ 0xFF  ; Complement the value (active low hardware)
      A = A & 3     ; Only need select/reset
  }
  
}
;</EditorTab>

; ======================================
;<EditorTab name="sound">
INIT_MUSIC() {
;
; This function initializes the hardware and temporaries
; for 2-channel music
;
  A = 0x06     ; Initialize sound ...
  AUDC0 = A    ; ... to pure ...
  AUDC1 = A    ; ... tones
  A = 0        ; Turn off ...
  AUDV0 = A    ; ... all ...
  AUDV1 = A    ; ... sound
  MUSAIND = A  ; Music pointers ...
  MUSBIND = A  ; ... to top of data
  A = 1        ; Force ...
  MUSADEL = A  ; ... music ...
  MUSBDEL = A  ; ... reload
  A = 15       ; Set volume levels ...
  MUSAVOL = A  ; ... to ...
  MUSBVOL = A  ; ... maximum
}

; ======================================
PROCESS_MUSIC() {
;
; This function is called once per frame to process the
; 2 channel music. Two tables contain the commands/notes
; for individual channels. This function changes the
; notes at the right time.
;           
  --MUSADEL               ; Last note ended?
  if(ZERO_SET) {

      do {
          X = MUSAIND            ; Voice-A index
          A = MUSICA[X]          ; Get the next music command
          if(A==0) {             ; A==0 for JUMP command
              ++X                ; Point to jump value
              A = X              ; X to ...
              Y = A              ; ... Y (pointer to jump value)
              ++X                ; Point one past jump value
              A = X              ; Into A so we can subtract
              A = A - MUSICA[Y]  ; New index
              MUSAIND = A        ; Store it
              A = 0              ; Continue processing
          } else if(A==1) {      ; A==1 for CONTROL command
              ++X                ; Point to the control value
              ++MUSAIND          ; Bump the music pointer
              A = MUSICA[X]      ; Get the control value
              ++MUSAIND          ; Bump the music pointer
              AUDC0 = A          ; Store the new control value
              A = 0              ; Continue processing
          } else if(A==2) {      ; A==2 for VOLUME command
              ++X                ; Point to volume value
              ++MUSAIND          ; Bump the music pointer
              A = MUSICA[X]      ; Get the volume value
              ++MUSAIND          ; Bump the music pointer
              MUSAVOL=A          ; Store the new volume value
              A = 0              ; Continue processing
          }
      } while(A==0);

      Y = MUSAVOL     ; Get the volume
      A = A & 31      ; Lower 5 bits are frequency
      if(A==31) {
          Y = 0       ; Frequency of 31 flags silence
      }
      AUDF0 = A       ; Store the frequency
      AUDV0 = Y       ; Store the volume
      A = MUSICA[X]   ; Get the note value again
      ++MUSAIND       ; Bump to the next command
      ROR  A          ; The upper ...
      ROR  A          ; ... three ...
      ROR  A          ; ... bits ...
      ROR  A          ; ... hold ...
      ROR  A          ; ... the ...
      A = A & 7       ; ... delay
      C_Flag = 0      ; No accidental carry
      ROL  A          ; Every delay tick ...
      ROL  A          ; ... is *4 frames
      MUSADEL = A     ; Store the note delay
  }
  
  --MUSBDEL           ; Repeat Channel A sequence for Channel B
  if(ZERO_SET) {
      
      do {
          X = MUSBIND
          A = MUSICB[X]
          if(A==0) {
              ++X  
              A = X     
              Y = A     
              ++X     
              A = X         
              A = A - MUSICB[Y]  
              MUSBIND    = A
              A = 0
          } else if(A==1) {
              ++X           
              ++MUSBIND  
              A = MUSICB[X]
              ++MUSBIND   
              AUDC1 = A
              A = 0
          } else if(A==2) {
              ++X            
              ++MUSBIND   
              A = MUSICB[X]
              ++MUSBIND  
              MUSBVOL = A  
              A = 0
          }
      } while(A==0);

      Y = MUSBVOL
      A = A & 31
      if(A==31) {
          Y = 0
      }
      AUDF1 = A
      AUDV1 = Y
      A = MUSICB[X]
      ++MUSBIND
      ROR  A
      ROR  A
      ROR  A
      ROR  A
      ROR  A
      A = A & 7
      C_Flag = 0
      ROL  A
      ROL  A
      MUSBDEL = A
  }
}

; ======================================
INIT_GO_FX() {
;
; This function initializes the hardware and temporaries
; to play the soundeffect of a player hitting the wall
;
  A = 5         ; Set counter for frame delay ...
  MUS_TMP1 = A  ; ... between frequency change
  A = 3         ; Tone type ...
  AUDC0 = A     ; ... poly tone
  A = 15        ; Volume A ...
  AUDV0 = A     ; ... to max
  A = 0         ; Volume B ...
  AUDV1 = A     ; ... silence
  A = 240       ; Initial ...
  MUS_TMP0 = A  ; ... sound ...
  AUDF0 = A     ; ... frequency
}

; ======================================
PROCESS_GO_FX() {
;
; This function is called once per scanline to play the
; soundeffects of a player hitting the wall.
;        
  --MUS_TMP1        ; Time to change the frequency?
  if(ZERO_SET) {
      A = 5         ; Reload ...
      MUS_TMP1 = A  ; ... the frame count
      ++MUS_TMP0    ; Increment ...
      A = MUS_TMP0  ; ... the frequency divisor
      AUDF0 = A     ; Change the frequency
      if(A==0) {
          A = 1     ; All done ... return 1
          return
      }
  }
  A = 0
  
}
;</EditorTab>

;</EditorTab name="data">
; ======================================
; Music commands for Channel A and Channel B
  
  ; A word on music and wall timing ...

  ; Wall moves between scanlines 0 and 111 (112 total)

  ; Wall-increment   frames-to-top
  ;      3             336
  ;      2             224
  ;      1             112
  ;     0.5             56  ; Ah ... but we are getting one less
  
  ; Each tick is multiplied by 4 to yield 4 frames per tick
  ; 32 ticks/song = 32*4 = 128 frames / song

  ; We want songs to start with wall at top ...

  ; Find the least-common-multiple
  ; 336 and 128 : 2688 8 walls, 21 musics
  ; 224 and 128 :  896 4 walls,  7 musics
  ; 112 and 128 :  896 8 walls,  7 musics
  ;  56 and 128 :  896 16 walls, 7 musics

  ; Wall moving every other gives us 112*2=224 scanlines
  ; Song and wall are at start every 4
  ; 1 scanline, every 8
  ; Wall delay=3 gives us 128*3=336 scanlines 2

; MUSIC EQUATES
;
MUSCMD_JUMP    .equ 0
MUSCMD_CONTROL .equ 1
MUSCMD_VOLUME  .equ 2
MUS_REST       .equ 31
MUS_DEL_1      .equ 32*1
MUS_DEL_2      .equ 32*2
MUS_DEL_3      .equ 32*3
MUS_DEL_4      .equ 32*4



MUSICA

MA_SONG_1

  .BYTE MUSCMD_CONTROL, 0x0C  ; Control (pure tone)
  .BYTE MUSCMD_VOLUME,  15   ; Volume (full)

MA1_01
  .BYTE MUS_DEL_3  +  15
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_3  +  15
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  7
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  7
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_2  +  MUS_REST
  .BYTE MUS_DEL_1  +  8
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_4  +  MUS_REST
  .BYTE MUS_DEL_2  +  17
  .BYTE MUS_DEL_2  +  MUS_REST
  .BYTE MUS_DEL_2  +  17
  .BYTE MUS_DEL_2  +  MUS_REST
  .BYTE MUS_DEL_3  +  16
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUSCMD_JUMP, (MA1_END - MA1_01)  ; Repeat back to top
MA1_END

MA_SONG_2

  .BYTE MUSCMD_CONTROL, 0x0C
  .BYTE MUSCMD_VOLUME,  15

MA2_01
  .BYTE MUS_DEL_1  +  15
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  15
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_2  +  MUS_REST
  .BYTE MUS_DEL_4  +  7
  .BYTE MUS_DEL_4  +  MUS_REST
  .BYTE MUS_DEL_2  +  15
  .BYTE MUS_DEL_4  +  MUS_REST
  .BYTE MUS_DEL_2  +  12
  .BYTE MUS_DEL_2  +  MUS_REST
  .BYTE MUS_DEL_2  +  15
  .BYTE MUS_DEL_2  +  MUS_REST
  .BYTE MUS_DEL_2  +  17
  .BYTE MUS_DEL_2  +  MUS_REST  
  .BYTE MUSCMD_JUMP, (MA2_END - MA2_01) ; Repeat back to top
MA2_END



MUSICB

MB_SONG_1

  .BYTE MUSCMD_CONTROL, 0x08  ; Control (white noise)
  .BYTE MUSCMD_VOLUME,  8    ; Volume (half)

MB1_01     
  .BYTE MUS_DEL_1  +  10
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  20
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  30
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  15
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  10
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  20
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  30
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  15
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUSCMD_JUMP, (MB1_END - MB1_01) ; Repeat back to top
MB1_END

MB_SONG_2

  .BYTE MUSCMD_CONTROL, 0x08
  .BYTE MUSCMD_VOLUME,  8

MB2_01    
  .BYTE MUS_DEL_1  +  1
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  1
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  1
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  1
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  30
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  30
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  30
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUS_DEL_1  +  30
  .BYTE MUS_DEL_1  +  MUS_REST
  .BYTE MUSCMD_JUMP, (MB2_END - MB2_01) ; Repeat back to top
MB2_END


; ======================================
SKILL_VALUES
;
; This table describes how to change the various
; difficulty parameters as the game progresses.
; For instance, the second entry in the table 
; says that when the score is 4, change the values of
; wall-increment to 1, frame-delay to 2, gap-pattern to 0,
; MusicA to 24, and MusicB to 22.
;
; A 255 on the end of the table indicates the end 
;
  ; Wall  Inc  Delay     Gap   MA                 MB
  .BYTE  0,    1,   3,     0  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB
  .BYTE  4,    1,   2,     0  ,MA_SONG_2-MUSICA , MB_SONG_2-MUSICB
  .BYTE  8,    1,   1,     0  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB
  .BYTE 16,    1,   1,     1  ,MA_SONG_2-MUSICA , MB_SONG_2-MUSICB
  .BYTE 24,    1,   1,     3  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB
  .BYTE 32,    1,   1,     7  ,MA_SONG_2-MUSICA , MB_SONG_2-MUSICB
  .BYTE 40,    1,   1,    15  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB
  .BYTE 48,    2,   1,     0  ,MA_SONG_2-MUSICA , MB_SONG_2-MUSICB
  .BYTE 64,    2,   1,     1  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB
  .BYTE 80,    2,   1,     3  ,MA_SONG_2-MUSICA , MB_SONG_2-MUSICB
  .BYTE 96 ,   2,   1,     7  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB
  .BYTE 255

; ======================================
; Image for players
GR_PLAYER:
;<Graphic widthBits="8" heightBits="8" bitDepth="1" name="player">     
  .BYTE 0x10 ; ...*....
  .BYTE 0x10 ; ...*....
  .BYTE 0x28 ; ..*.*...
  .BYTE 0x28 ; ..*.*...
  .BYTE 0x54 ; .*.*.*..
  .BYTE 0x54 ; .*.*.*..
  .BYTE 0xAA ; *.*.*.*.
  .BYTE 0x7C ; .*****..
;</Graphic>

; ======================================
; Images for numbers
DIGITS: 
; We only need 5 rows, but the extra space on the end makes each digit 8 rows,
; which makes it the multiplication easier.
;<Graphic widthBits="8" heightBits="8" bitDepth="1" images="10" name="digits">
  .BYTE  0x0E ,0x0A ,0x0A ,0x0A ,0x0E, 0,0,0 ; 00
  .BYTE  0x22 ,0x22 ,0x22 ,0x22 ,0x22, 0,0,0 ; 11
  .BYTE  0xEE ,0x22 ,0xEE ,0x88 ,0xEE, 0,0,0 ; 22
  .BYTE  0xEE ,0x22 ,0x66 ,0x22 ,0xEE, 0,0,0 ; 33
  .BYTE  0xAA ,0xAA ,0xEE ,0x22 ,0x22, 0,0,0 ; 44
  .BYTE  0xEE ,0x88 ,0xEE ,0x22 ,0xEE, 0,0,0 ; 55
  .BYTE  0xEE ,0x88 ,0xEE ,0xAA ,0xEE, 0,0,0 ; 66
  .BYTE  0xEE ,0x22 ,0x22 ,0x22 ,0x22, 0,0,0 ; 77
  .BYTE  0xEE ,0xAA ,0xEE ,0xAA ,0xEE, 0,0,0 ; 88
  .BYTE  0xEE ,0xAA ,0xEE ,0x22 ,0xEE, 0,0,0 ; 99
;</Graphic>

;</EditorTab>

;<EditorTab name="vectors">
; ====================================== 
; 6502 Hardware vectors at the end of memory
.org 0xF7FA  ; Ghosting to 0xFFFA for 2K part
  .WORD  0x0000   ; NMI vector (not used)
  .WORD  main     ; Reset vector (top of program)
  .WORD  0x0000   ; IRQ and BRK vector (not used)

;</EditorTab>



.end
