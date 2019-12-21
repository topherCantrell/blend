                                           ;  DoubleGap by Christopher Cantrell 2006
                                           ;  ccantrell@knology.net
                                           
                                           ;  TO DO
                                           ;  - Expert switches are backwards
                                           ;  - Debounce switches
                                           
                                           ;  build-command java Blend gap.asm g2.asm
                                           ;  build-command tasm -b -65 g2.asm g2.bin
                                           
                                           ;  This file uses the "BLEND" program for assembly pre-processing
                                           ;  processor 6502
                                           
#include         "Stella.asm"                  ; OLine=14  Equates to give names to hardware memory locations
                                           
                                           ;  The EditorTab comments are read by the SNAP editor, which makes 
                                           ;  assembly editing a ... SNAP!
                                           
                                           ; <EditorTab name="RAM">
                                           
                                           ;  RAM usage
                                           
TMP0             .EQU     128              
TMP1             .EQU     129              
TMP2             .EQU     130              
PLAYR0Y          .EQU     131              
PLAYR1Y          .EQU     132              
MUS_TMP0         .EQU     133              
MUS_TMP1         .EQU     134              
SCANCNT          .EQU     135              
MODE             .EQU     136              
WALL_INC         .EQU     137              
WALLCNT          .EQU     138              
WALLDELY         .EQU     139              
WALLDELYR        .EQU     140              
ENTROPYA         .EQU     141              
ENTROPYB         .EQU     142              
ENTROPYC         .EQU     143              
DEBOUNCE         .EQU     144              
WALLDRELA        .EQU     145              
WALLDRELB        .EQU     146              
WALLDRELC        .EQU     147              
WALLSTART        .EQU     148              
WALLHEI          .EQU     149              
GAPBITS          .EQU     150              
SCORE_PF1        .EQU     151              
SCORE_PF2        .EQU     157              
MUSADEL          .EQU     163              
MUSAIND          .EQU     164              
MUSAVOL          .EQU     165              
MUSBDEL          .EQU     166              
MUSBIND          .EQU     167              
MUSBVOL          .EQU     168              
                                           
                                           ;  Remember, stack builds down from $FF ... leave some space
                                           
                                           ;  80 - A8 ... that's 41 bytes of RAM used
                                           
                                           ; </EditorTab>
                                           
                 .org     61440            
                                           
                                           ; <EditorTab name="main">
                                           
main:                                      ;  --SubroutineContextBegins--
                 SEI                       ; OLine=66  Turn off interrupts
                 CLD                       ; OLine=67  Clear the "decimal" flag
                 LDX      #255             
                 TXS                       ; OLine=69  ... to the end of RAM
                 JSR      INIT             ; OLine=70  Initialize game environment
                 JSR      INIT_SELMODE     ; OLine=71  Start out in SELECT-MODE
                 JSR      VIDEO_KERNEL     ; OLine=72  There should be no return from the KERNEL
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ; </EditorTab>
                                           
                                           ; <EditorTab name="kernel">
                                           
VIDEO_KERNEL:                              ;  --SubroutineContextBegins--
                                           ;   (start here at the END of every frame)
                                           
FLOW_A_1_OUTPUT_BEGIN:                           
                                           
                 LDA      #2               ; OLine=84  D1 bit ON
                 STA      WSYNC            ; OLine=85  Wait for the end of the current line
                 STA      VBLANK           ; OLine=86  Turn the electron beam off
                 STA      WSYNC            ; OLine=87  Wait for all ...
                 STA      WSYNC            ; OLine=88  ... the electrons ...
                 STA      WSYNC            ; OLine=89  ... to drain out.
                 STA      VSYNC            ; OLine=90  Trigger the vertical sync signal
                 STA      WSYNC            ; OLine=91  Hold the vsync signal for ...
                 STA      WSYNC            ; OLine=92  ... three ...
                 STA      WSYNC            ; OLine=93  ... scanlines
                 STA      HMOVE            ; OLine=94  Tell hardware to move all game objects
                 LDA      #0               ; OLine=95  D1 bit OFF
                 STA      VSYNC            ; OLine=96  Release the vertical sync signal
                 LDA      #43              ; OLine=97  Set timer to 43*64 = 2752 machine ...
                 STA      TIM64T           ; OLine=98  ... cycles 2752/(228/3) = 36 scanlines
                                           
                                           ;  ***** LENGTHY GAME LOGIC PROCESSING BEGINS HERE *****
                                           
                                           ;  Do one of 3 routines while the beam travels back to the top
                                           ;  0 = Game Over processing
                                           ;  1 = Playing-Game processing
                                           ;  2 = Selecting-Game processing
                                           
                 INC      ENTROPYA         ; OLine=107  Counting video frames as part of the random number
                 LDA      MODE             ; OLine=108  What are we doing between frames?
                                           
                 CMP      #0               
                 BEQ      FLOW_A_2_OUTPUT_TRUE 
                 CMP      #1               
                 BEQ      FLOW_A_3_OUTPUT_TRUE 
                 JSR      SELMODE          ; OLine=115  Selecting game processing
                 JMP      FLOW_A_2_OUTPUT_END 
FLOW_A_3_OUTPUT_TRUE:                           
                 JSR      PLAYMODE         ; OLine=113  Playing-game processing
                 JMP      FLOW_A_2_OUTPUT_END 
FLOW_A_2_OUTPUT_TRUE:                           
                 JSR      GOMODE           ; OLine=111  Game-over processing
FLOW_A_2_OUTPUT_END:                           
                                           
                                           ;  ***** LENGTHY GAME LOGIC PROCESSING ENDS HERE *****
                                           
                 LDA      INTIM            ; OLine=121  Wait for the visible area of the screen
                 CMP      #0               
                 BNE      FLOW_A_2_OUTPUT_END 
                                           
                 STA      WSYNC            ; OLine=124  37th scanline
                 LDA      #0               ; OLine=125  Turn the ...
                 STA      VBLANK           ; OLine=126  ... electron beam back on
                                           
                 LDA      #0               ; OLine=128  Zero out ...
                 STA      SCANCNT          ; OLine=129  ... scanline count ...
                 STA      TMP0             ; OLine=130  ... and all ...
                 STA      TMP1             ; OLine=131  ... returns ...
                 STA      TMP2             ; OLine=132  ... expected ...
                 TAX                       ; OLine=133  ... to come from ...
                 TAY                       ; OLine=134  ... BUILDROW
                                           
                 STA      CXCLR            ; OLine=136  Clear collision detection
                                           
                                           ;  BEGIN VISIBLE PART OF FRAME
                                           
FLOW_A_5_OUTPUT_BEGIN:                           
                                           
                 LDA      TMP0             ; OLine=142  Get A ready (PF0 value)
                 STA      WSYNC            ; OLine=143  Wait for very start of row
                 STX      GRP0             ; OLine=144  Player 0 -- in X
                 STY      GRP1             ; OLine=145  Player 1 -- in Y
                 STA      PF0              ; OLine=146  PF0      -- in TMP0 (already in A)
                 LDA      TMP1             ; OLine=147  PF1      -- in TMP1
                 STA      PF1              ; OLine=148  ...
                 LDA      TMP2             ; OLine=149  PP2      -- in TMP2
                 STA      PF2              ; OLine=150  ...
                                           
                 JSR      BUILDROW         ; OLine=152  This MUST take through to the next line
                                           
                 INC      SCANCNT          ; OLine=154  Next scan line
                 LDA      SCANCNT          ; OLine=155  Do 109*2 = 218 lines
                                           
                 CMP      #109             
                 BNE      FLOW_A_5_OUTPUT_BEGIN 
                                           
                                           ;  END VISIBLE PART OF FRAME
                                           
                 LDA      #0               ; OLine=161  Turning off visuals
                 STA      WSYNC            ; OLine=162  Next scanline
                 STA      PF0              ; OLine=163  Play field 0 off
                 STA      GRP0             ; OLine=164  Player 0 off
                 STA      GRP1             ; OLine=165  Player 1 off
                 STA      PF1              ; OLine=166  Play field 1 off
                 STA      PF2              ; OLine=167  Play field 2 off
                 STA      WSYNC            ; OLine=168  Next scanline
                                           
                 JMP      FLOW_A_1_OUTPUT_BEGIN 
                                           
                                           
                                           ;  ======================================
                                           
BUILDROW:                                  ;  --SubroutineContextBegins--
                                           
                 LDA      SCANCNT          ; OLine=178  Current scanline
                                           
                 CMP      #6               
                 BCC      FLOW_A_6_OUTPUT_TRUE 
                                           
                 AND      #7               ; OLine=225  Lower 3 bits as an index again
                 TAY                       ; OLine=226  Using Y to lookup graphics
                 LDA      GR_PLAYER,Y      ; OLine=227  Get the graphics (if enabled on this row)
                 TAX                       ; OLine=228  Hold it (for return as player 0)
                 TAY                       ; OLine=229  Hold it (for return as player 1)
                 LDA      SCANCNT          ; OLine=230  Scanline count again
                 LSR      A                ; OLine=231  This time ...
                 LSR      A                ; OLine=232  ... we divide ...
                 LSR      A                ; OLine=233  ... by eight (8 rows in picture)
                                           
                 CMP      PLAYR0Y          
                 BEQ      FLOW_A_7_OUTPUT_FALSE 
                 LDX      #0               ; OLine=236  Not time for Player 0 ... no graphics
FLOW_A_7_OUTPUT_FALSE:                           
                                           
                 CMP      PLAYR1Y          
                 BEQ      FLOW_A_8_OUTPUT_FALSE 
                 LDY      #0               ; OLine=240  Not time for Player 0 ... no graphics
FLOW_A_8_OUTPUT_FALSE:                           
                                           
                 LDA      WALLSTART        ; OLine=243  Calculate ...
                 CLC                       ; OLine=244  ... the bottom of ...  
                 ADC      WALLHEI          
                 STA      TMP0             ; OLine=245  ... the wall
                                           
                 LDA      SCANCNT          ; OLine=247  Scanline count
                                           
                 CMP      WALLSTART        
                 BCC      FLOW_A_9_OUTPUT_FALSE 
                 CMP      TMP0             
                 BCS      FLOW_A_9_OUTPUT_FALSE 
                                           ;  The wall is on this row
                 LDA      WALLDRELA        ; OLine=251  Draw wall ...
                 STA      TMP0             ; OLine=252  ... by transfering ...
                 LDA      WALLDRELB        ; OLine=253  ... playfield ...
                 STA      TMP1             ; OLine=254  ... patterns ...
                 LDA      WALLDRELC        ; OLine=255  ... to ...
                 STA      TMP2             ; OLine=256  ... return area
                 RTS                       
FLOW_A_9_OUTPUT_FALSE:                           
                                           ;  The wall is NOT on this row
                 LDA      #0               ; OLine=259  No walls on this row
                 STA      TMP0             ; OLine=260  ... clear ...
                 STA      TMP1             ; OLine=261  ... out ...
                 STA      TMP2             ; OLine=262  ... the playfield
                                           
                 RTS                       
FLOW_A_6_OUTPUT_TRUE:                           
                                           
                 AND      #7               ; OLine=182  Only need the lower 3 bits
                 TAY                       ; OLine=183  Soon to be an index into a list
                                           
                                           ;  At this point, the beam is past the loading of the
                                           ;  playfield for the left half. We want to make sure
                                           ;  that the right half of the playfield is off, so do that
                                           ;  now.
                                           
                 LDX      #0               ; OLine=190  Blank bit pattern
                 STX      TMP0             ; OLine=191  This will always be blank
                 STX      PF1              ; OLine=192  Turn off playfield ...
                 STX      PF2              ; OLine=193  ... for right half of the screen
                                           
                 TAX                       ; OLine=195  Another index
                 LDA      SCORE_PF1,Y      ; OLine=196  Lookup the PF1 graphics for this row
                 STA      TMP1             ; OLine=197  Return it to the caller
                 TAY                       ; OLine=198  We'll need this value again in a second
                 LDA      SCORE_PF2,X      ; OLine=199  Lookup the PF2 graphics for this row
                 STA      TMP2             ; OLine=200  Return it to the caller
                                           
                 STA      WSYNC            ; OLine=202  Now on the next row
                                           
                 STY      PF1              ; OLine=204  Repeat the left-side playfield ...
                 STA      PF2              ; OLine=205  ... onto the new row
                                           
                 LDA      SCORE_PF2,X      ; OLine=207  Kill some time waiting for the ...
                 LDA      SCORE_PF2,X      ; OLine=208  ... beam to pass the left half ...
                 LDA      SCORE_PF2,X      ; OLine=209  ... of the playfield again
                 LDA      SCORE_PF2,X      ; OLine=210  
                 LDA      SCORE_PF2,X      ; OLine=211  
                 LDA      SCORE_PF2,X      ; OLine=212  
                                           
                 LDX      #0               ; OLine=214  Return 0 (off) for player 0 ...
                 LDY      #0               ; OLine=215  ... and player 1
                                           
                                           ;  The beam is past the left half of the field again.
                                           ;  Turn off the playfield.
                                           
                 STX      PF1              ; OLine=220  0 to PF1 ...
                 STX      PF2              ; OLine=221  ... and PF2
                                           
                                           
                 RTS                       ;  --SubroutineContextEnds--
                                           ; </EditorTab>
                                           
                                           ;  ============= END OF VIDEO KERNEL ===================
                                           
                                           
                                           ;  ======================================
                                           ; <EditorTab name="init">
INIT:                                      ;  --SubroutineContextBegins--
                                           
                                           ;  This function is called ONCE at power-up/reset to initialize various
                                           ;  hardware and temporaries.
                                           
                 LDA      #64              
                 STA      COLUPF           ; OLine=281  ... redish
                 LDA      #126             
                 STA      COLUP0           ; OLine=283  ... white
                 LDA      #0               ; OLine=284  Player 1 ...
                 STA      COLUP1           ; OLine=285  ... black
                                           
                 LDA      #5               ; OLine=287  Right half of playfield is reflection of left ...
                 STA      CTRLPF           ; OLine=288  ... and playfield is on top of players
                                           
                 LDX      #4               ; OLine=290  Player 0 position count
                 LDY      #3               ; OLine=291  Player 1 position count
                 STA      WSYNC            ; OLine=292  Get a fresh scanline
                                           
FLOW_A_10_OUTPUT_BEGIN:                           
                 DEX                       ; OLine=295  Kill time while the beam moves 
                 CPX      #0               
                 BNE      FLOW_A_10_OUTPUT_BEGIN 
                 STA      RESP0            ; OLine=297  Mark player 0's X position
                                           
FLOW_A_11_OUTPUT_BEGIN:                           
                 DEY                       ; OLine=300  Kill more time
                 CPY      #0               
                 BNE      FLOW_A_11_OUTPUT_BEGIN 
                 STA      RESP1            ; OLine=302  Mark player 1's X position
                                           
                 JSR      EXPERTISE        ; OLine=304  Initialize the players' Y positions base on expert-settings
                                           
                 LDA      #10              ; OLine=306  Wall is ...
                 STA      WALLHEI          ; OLine=307  ... 10 double-scanlines high
                                           
                 LDA      #0               ; OLine=309  Set score to ...
                 STA      WALLCNT          ; OLine=310  ... 0
                 JSR      MAKE_SCORE       ; OLine=311  Blank the score digits
                 LDA      #0               ; OLine=312  Blank bits ...
                 STA      SCORE_PF2+5      ; OLine=313  ... on the end of each ...
                 STA      SCORE_PF1+5      ; OLine=314  ... digit pattern
                                           
                 JSR      ADJUST_DIF       ; OLine=316  Initialize the wall parameters
                 JSR      NEW_GAPS         ; OLine=317  Build the wall's initial gap
                                           
                 LDA      #112             ; OLine=319  Set wall position off bottom ...
                 STA      WALLSTART        ; OLine=320  ... to force a restart on first move
                                           
                 LDA      #0               ; OLine=322  Zero out ...
                 STA      HMP0             ; OLine=323  ... player 0 motion ...
                 STA      HMP1             ; OLine=324  ... and player 1 motion
                                           
                 RTS                       ;  --SubroutineContextEnds--
                                           ; </EditorTab>
                                           
                                           ;  ===================================
                                           ; <EditorTab name="play-mode">
INIT_PLAYMODE:                             ;  --SubroutineContextBegins--
                                           
                                           ;  This function initializes the game play mode
                                           
                 LDA      #192             
                 STA      COLUBK           ; OLine=336  ... greenish
                 LDA      #1               ; OLine=337  Game mode is ...
                 STA      MODE             ; OLine=338  ... SELECT
                 LDA      #255             ; OLine=339  Restart wall score to ...
                 STA      WALLCNT          ; OLine=340  ... 0 on first move
                 LDA      #112             ; OLine=341  Force wall to start ...
                 STA      WALLSTART        ; OLine=342  ... over on first move
                 JSR      INIT_MUSIC       ; OLine=343  Initialize the music
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ;  ======================================
PLAYMODE:                                  ;  --SubroutineContextBegins--
                                           
                                           ;  This function is called once per frame to process the main game play.
                                           
                                           
                 JSR      SEL_RESET_CHK    ; OLine=352  Check to see if Reset/Select has changed
                                           
                 CMP      #0               
                 BEQ      FLOW_A_12_OUTPUT_FALSE 
                 STX      DEBOUNCE         ; OLine=355  Restore the old value ...
                 JSR      INIT_SELMODE     ; OLine=356  ... and let select-mode process the toggle
                 RTS                       ; OLine=357
FLOW_A_12_OUTPUT_FALSE:                           
                                           
                 JSR      PROCESS_MUSIC    ; OLine=360  Process any playing music
                 JSR      MOVE_WALLS       ; OLine=361  Move the walls
                                           
                 CMP      #1               
                 BNE      FLOW_A_13_OUTPUT_FALSE 
                 INC      WALLCNT          ; OLine=364  Bump the score
                 JSR      ADJUST_DIF       ; OLine=365  Change the wall parameters based on score
                 LDA      WALLCNT          ; OLine=366  Change the ...
                 JSR      MAKE_SCORE       ; OLine=367  ... score pattern
                 JSR      NEW_GAPS         ; OLine=368  Calculate the new gap position
FLOW_A_13_OUTPUT_FALSE:                           
                                           
                 LDA      CXP0FB           ; OLine=371  Player 0 collision with playfield
                 STA      TMP0             ; OLine=372  Hold it
                 LDA      CXP1FB           ; OLine=373  Player 1 collision with playfield
                 ORA      TMP0             ; OLine=374  Did either ...
                 AND      #128             
                                           
                 CMP      #0               
                 BEQ      FLOW_A_14_OUTPUT_FALSE 
                 JSR      INIT_GOMODE      ; OLine=378  Go to Game-Over mode
                 RTS                       ; OLine=379
FLOW_A_14_OUTPUT_FALSE:                           
                                           
                 LDA      SWCHA            ; OLine=382  Joystick
                 ADC      ENTROPYB         ; OLine=383  Add to ...  
                 STA      ENTROPYB         ; OLine=384  ... entropy
                                           
                 LDA      SWCHA            ; OLine=386  Joystick
                 AND      #128             
                 CMP      #0               
                 BEQ      FLOW_A_15_OUTPUT_TRUE 
                 LDA      SWCHA            ; OLine=391  Joystick
                 AND      #64              
                 CMP      #0               
                 BEQ      FLOW_A_16_OUTPUT_TRUE 
                 LDA      #0               ; OLine=397  Not moving value
                 JMP      FLOW_A_15_OUTPUT_END 
FLOW_A_16_OUTPUT_TRUE:                           
                 INC      ENTROPYC         ; OLine=394  Yes ... increase entropy
                 LDA      #16              
                 JMP      FLOW_A_15_OUTPUT_END 
FLOW_A_15_OUTPUT_TRUE:                           
                 LDA      #240             
FLOW_A_15_OUTPUT_END:                           
                 STA      HMP0             ; OLine=400  New movement value P0
                                           
                 LDA      SWCHA            ; OLine=402  Joystick
                 AND      #8               
                 CMP      #0               
                 BEQ      FLOW_A_17_OUTPUT_TRUE 
                 LDA      SWCHA            ; OLine=407  Joystick
                 AND      #4               
                 CMP      #0               
                 BEQ      FLOW_A_18_OUTPUT_TRUE 
                 INC      ENTROPYC         ; OLine=412  Increase entropy
                 LDA      #0               ; OLine=413  Not moving value
                 JMP      FLOW_A_17_OUTPUT_END 
FLOW_A_18_OUTPUT_TRUE:                           
                 LDA      #16              
                 JMP      FLOW_A_17_OUTPUT_END 
FLOW_A_17_OUTPUT_TRUE:                           
                 LDA      #240             
FLOW_A_17_OUTPUT_END:                           
                 STA      HMP1             ; OLine=416  New movement value P1
                                           
                 RTS                       ;  --SubroutineContextEnds--
                                           ; </EditorTab>
                                           
                                           ;  ===================================
                                           ; <EditorTab name="select-mode">
INIT_SELMODE:                              ;  --SubroutineContextBegins--
                                           
                                           ;  This function initializes the games SELECT-MODE
                                           ;           
                 LDA      #0               ; OLine=427  Turn off ...
                 STA      AUDV0            ; OLine=428  ... all ...
                 STA      AUDV1            ; OLine=429  ... sound
                 LDA      #200             
                 STA      COLUBK           ; OLine=431  ... greenish bright
                 LDA      #2               ; OLine=432  Now in ...
                 STA      MODE             ; OLine=433  SELECT game mode
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ;  ======================================
SELMODE:                                   ;  --SubroutineContextBegins--
                                           
                                           ;  This function is called once per frame to process the SELECT-MODE.
                                           ;  The wall moves here, but doesn't change or collide with players.
                                           ;  This function selects between 1 and 2 player game.
                                           
                 JSR      MOVE_WALLS       ; OLine=443  Move the walls
                 JSR      SEL_RESET_CHK    ; OLine=444  Check the reset/select switches
                                           
                 CMP      #1               
                 BEQ      FLOW_A_19_OUTPUT_TRUE 
                 CMP      #3               
                 BEQ      FLOW_A_19_OUTPUT_TRUE 
                 CMP      #2               
                 BNE      FLOW_A_19_OUTPUT_END 
                 LDA      PLAYR1Y          ; OLine=449  Select toggled. Get player 1 Y coordinate
                 CMP      #255             
                 BEQ      FLOW_A_21_OUTPUT_TRUE 
                 LDA      #255             ; OLine=453  Offscreen if it is currently on
                 JMP      FLOW_A_21_OUTPUT_END 
FLOW_A_21_OUTPUT_TRUE:                           
                 LDA      #12              ; OLine=451  Onscreen if it is currently off
FLOW_A_21_OUTPUT_END:                           
                 STA      PLAYR1Y          ; OLine=455  Toggled Y coordinate
                 JMP      FLOW_A_19_OUTPUT_END 
FLOW_A_19_OUTPUT_TRUE:                           
                 JSR      INIT_PLAYMODE    ; OLine=447  Reset toggled ... start game
FLOW_A_19_OUTPUT_END:                           
                                           
                 JSR      EXPERTISE        ; OLine=458  Adjust both players for pro settings
                 RTS                       ;  --SubroutineContextEnds--
                                           ; </EditorTab>
                                           
                                           ;  ======================================
                                           ; <EditorTab name="go-mode">
INIT_GOMODE:                               ;  --SubroutineContextBegins--
                                           
                                           ;  This function initializes the GAME-OVER game mode.
                                           ;    
                 STA      HMCLR            ; OLine=468  Stop both players from moving
                 LDA      CXP0FB           ; OLine=469  P0 collision with wall
                 AND      #128             
                                           
                 CMP      #0               
                 BNE      FLOW_A_22_OUTPUT_FALSE 
                 LDA      #2               ; OLine=473  No ... move player 0 ...
                 STA      PLAYR0Y          ; OLine=474  ... up the screen
FLOW_A_22_OUTPUT_FALSE:                           
                                           
                 LDA      CXP1FB           ; OLine=477  P1 collision with wall
                 AND      #128             
                                           
                 CMP      #0               
                 BNE      FLOW_A_24_OUTPUT_FALSE 
                 LDA      PLAYR1Y          ; OLine=481
                 CMP      #255             
                 BEQ      FLOW_A_24_OUTPUT_FALSE 
                 LDA      #2               ; OLine=483  Player 1 is onscreen and didn't collide ...
                 STA      PLAYR1Y          ; OLine=484  ... move up the screen
FLOW_A_24_OUTPUT_FALSE:                           
                                           
                 LDA      #0               ; OLine=488  Going to ...
                 STA      MODE             ; OLine=489  ... game-over mode
                 STA      AUDV0            ; OLine=490  Turn off any ...
                 STA      AUDV1            ; OLine=491  ... sound
                 JSR      INIT_GO_FX       ; OLine=492  Initialize sound effects
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ;  ======================================
GOMODE:                                    ;  --SubroutineContextBegins--
                                           
                                           ;  This function is called every frame to process the game
                                           ;  over sequence. When the sound effect has finished, the
                                           ;  game switches to select mode.
                                           
                 JSR      PROCESS_GO_FX    ; OLine=502  Process the sound effects
                 CMP      #0               
                 BEQ      FLOW_A_25_OUTPUT_FALSE 
                 JSR      INIT_SELMODE     ; OLine=504  When effect is over, go to select mode
FLOW_A_25_OUTPUT_FALSE:                           
                 RTS                       ;  --SubroutineContextEnds--
                                           ; </EditorTab>
                                           
                                           ;  ======================================
                                           ; <EditorMode name="utils">
MOVE_WALLS:                                ;  --SubroutineContextBegins--
                                           
                                           ;  This function moves the wall down the screen and back to position 0
                                           ;  when it reaches (or passes) 112.
                                           
                                           
                 DEC      WALLDELY         ; OLine=517  Time to move the wall
                 LDA      WALLDELY         ; OLine=518
                                           
                 CMP      #0               
                 BNE      FLOW_A_26_OUTPUT_TRUE 
                 LDA      WALLDELYR        ; OLine=523  Reset the ...
                 STA      WALLDELY         ; OLine=524  ... delay count
                 LDA      WALLSTART        ; OLine=525  Current wall position
                 CLC                       ; OLine=526  Increment wall position      
                 ADC      WALL_INC         
                 CMP      #112             
                 BCC      FLOW_A_27_OUTPUT_TRUE 
                 LDA      #0               ; OLine=531  Else restart ...
                 STA      WALLSTART        ; OLine=532  ... wall at top of screen
                 LDA      #1               ; OLine=533  Return flag that wall DID restart
                 RTS                       
FLOW_A_27_OUTPUT_TRUE:                           
                 STA      WALLSTART        ; OLine=528  Store new wall position
                 LDA      #0               ; OLine=529  Return flag that wall did NOT restart
                 RTS                       
FLOW_A_26_OUTPUT_TRUE:                           
                 LDA      #0               ; OLine=521  Return flag that wall did NOT restart
                                           
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ;  ======================================
NEW_GAPS:                                  ;  --SubroutineContextBegins--
                                           
                                           ;  This function builds the PF0, PF1, and PF2 graphics for a wall
                                           ;  with the gap pattern (GAPBITS) placed at random in the 20 bit
                                           ;  area.
                                           
                 LDA      #255             ; OLine=546  Start with ...
                 STA      WALLDRELA        ; OLine=547  ... solid wall in PF0 ...
                 STA      WALLDRELB        ; OLine=548  ... and PF1
                 LDA      GAPBITS          ; OLine=549  Store the gap pattern ...
                 STA      WALLDRELC        ; OLine=550  ... in PF2
                                           
                 LDA      ENTROPYA         ; OLine=552  Get ...
                 ADC      ENTROPYB         ; OLine=553  ... a randomish ...
                 ADC      ENTROPYC         ; OLine=554  ... number ...  
                 STA      ENTROPYC         ; OLine=555
                 AND      #15              ; OLine=556  ... 0 to 15
                                           
                 CMP      #12              
                 BEQ      FLOW_A_28_OUTPUT_FALSE 
                 BCC      FLOW_A_28_OUTPUT_FALSE 
                                           ; A = A - 9
                 SBC      #9               ; OLine=560
FLOW_A_28_OUTPUT_FALSE:                           
                                           
                 CMP      #0               
                 BEQ      FLOW_A_29_OUTPUT_FALSE 
                 SEC                       ; OLine=564  Roll gap ...
                 ROR      WALLDRELC        ; OLine=565  ... left ...
                 ROL      WALLDRELB        ; OLine=566  ... desired ...
                 ROR      WALLDRELA        ; OLine=567  ... times ...
                 SEC                       ; OLine=568
                 SBC      #1               
                 JMP      FLOW_A_28_OUTPUT_FALSE 
FLOW_A_29_OUTPUT_FALSE:                           
                                           
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ;  ======================================
MAKE_SCORE:                                ;  --SubroutineContextBegins--
                                           
                                           ;  This function builds the PF1 and PF2 graphics rows for
                                           ;  the byte value passed in A. The current implementation is
                                           ;  two-digits only ... PF2 is blank.
                                           
                 LDX      #0               ; OLine=580  100's digit
                 LDY      #0               ; OLine=581  10's digit
                                           
FLOW_A_30_OUTPUT_BEGIN:                           
                 CMP      #100             
                 BCC      FLOW_A_30_OUTPUT_FALSE 
                 INX                       ; OLine=584  Count ...
                 SEC                       ; OLine=585  ... value
                 SBC      #100             
                 JMP      FLOW_A_30_OUTPUT_BEGIN 
FLOW_A_30_OUTPUT_FALSE:                           
                                           
                 CMP      #10              
                 BCC      FLOW_A_31_OUTPUT_FALSE 
                 INY                       ; OLine=589  Count ...
                 SEC                       ; OLine=590  ... value
                 SBC      #10              
                 JMP      FLOW_A_30_OUTPUT_FALSE 
FLOW_A_31_OUTPUT_FALSE:                           
                                           
                 ASL      A                ; OLine=593  One's digit ...
                 ASL      A                ; OLine=594  ... *8 ....
                 ASL      A                ; OLine=595  ... to find picture
                 TAX                       ; OLine=596  One's digit picture to X
                 TYA                       ; OLine=597  Now the 10's digit
                 ASL      A                ; OLine=598  Multiply ...
                 ASL      A                ; OLine=599  ... by 8 ...
                 ASL      A                ; OLine=600  ... to find picture
                 TAY                       ; OLine=601  10's picture in Y
                                           
                 LDA      DIGITS,Y         ; OLine=603  Get the 10's digit
                 AND      #240             
                 STA      SCORE_PF1        ; OLine=605  Store left side
                 LDA      DIGITS,X         ; OLine=606  Get the 1's digit
                 AND      #15              
                 ORA      SCORE_PF1        ; OLine=608  Put left and right half together
                 STA      SCORE_PF1        ; OLine=609  And store image
                                           
                 LDA      DIGITS+1,Y       ; OLine=611  Repeat for 2nd line of picture
                 AND      #240             
                 STA      SCORE_PF1+1      ; OLine=613
                 LDA      DIGITS+1,X       ; OLine=614
                 AND      #15              
                 ORA      SCORE_PF1+1      ; OLine=616
                 STA      SCORE_PF1+1      ; OLine=617
                                           
                 LDA      DIGITS+2,Y       ; OLine=619  Repeat for 3nd line of picture
                 AND      #240             
                 STA      SCORE_PF1+2      ; OLine=621
                 LDA      DIGITS+2,X       ; OLine=622
                 AND      #15              
                 ORA      SCORE_PF1+2      ; OLine=624
                 STA      SCORE_PF1+2      ; OLine=625
                                           
                 LDA      DIGITS+3,Y       ; OLine=627  Repeat for 4th line of picture
                 AND      #240             
                 STA      SCORE_PF1+3      ; OLine=629
                 LDA      DIGITS+3,X       ; OLine=630
                 AND      #15              
                 ORA      SCORE_PF1+3      ; OLine=632
                 STA      SCORE_PF1+3      ; OLine=633
                                           
                 LDA      DIGITS+4,Y       ; OLine=635  Repeat for 5th line of picture
                 AND      #240             
                 STA      SCORE_PF1+4      ; OLine=637
                 LDA      DIGITS+4,X       ; OLine=638
                 AND      #15              
                 ORA      SCORE_PF1+4      ; OLine=640
                 STA      SCORE_PF1+4      ; OLine=641
                                           
                 LDA      #0               ; OLine=643  For now ...
                 STA      SCORE_PF2        ; OLine=644  ... there ...
                 STA      SCORE_PF2+1      ; OLine=645  ... is ...
                 STA      SCORE_PF2+2      ; OLine=646  ... no ...
                 STA      SCORE_PF2+3      ; OLine=647  ... 100s ...
                 STA      SCORE_PF2+4      ; OLine=648  ... digit drawn
                                           
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ;  ======================================
EXPERTISE:                                 ;  --SubroutineContextBegins--
                                           
                                           ;  This function changes the Y position of the players based on the
                                           ;  position of their respective pro/novice switches. The player 1
                                           ;  position is NOT changed if the mode is a single-player game.
                                           
                 LDA      SWCHB            ; OLine=659  Pro/novice settings
                 AND      #128             
                 CMP      #0               
                 BEQ      FLOW_A_32_OUTPUT_TRUE 
                 LDA      #8               ; OLine=664  Pro ... near the top
                 JMP      FLOW_A_32_OUTPUT_END 
FLOW_A_32_OUTPUT_TRUE:                           
                 LDA      #12              ; OLine=662  Novice ... near the bottom
FLOW_A_32_OUTPUT_END:                           
                 STA      PLAYR0Y          ; OLine=666  ... to Player 0
                                           
                 LDX      PLAYR1Y          ; OLine=668
                 CPX      #255             
                 BEQ      FLOW_A_33_OUTPUT_FALSE 
                 LDA      SWCHB            ; OLine=670
                 AND      #64              
                 CMP      #0               
                 BEQ      FLOW_A_34_OUTPUT_TRUE 
                 LDX      #8               ; OLine=675  Pro ... near the top
                 JMP      FLOW_A_34_OUTPUT_END 
FLOW_A_34_OUTPUT_TRUE:                           
                 LDX      #12              ; OLine=673  Novice ... near the bottom
FLOW_A_34_OUTPUT_END:                           
                 STX      PLAYR1Y          ; OLine=677
FLOW_A_33_OUTPUT_FALSE:                           
                                           
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ;  ======================================
ADJUST_DIF:                                ;  --SubroutineContextBegins--
                                           
                                           ;  This function adjusts the wall game difficulty values based on the
                                           ;  current score. The music can also change with the difficulty. A single
                                           ;  table describes the new values and when they take effect.
                                           ;               
                 LDX      #0               ; OLine=689  Starting at index 0
                                           
FLOW_A_35_OUTPUT_BEGIN:                           
                                           
                 LDA      SKILL_VALUES,X   ; OLine=693  Get the score match
                 CMP      #255             
                 BNE      FLOW_A_36_OUTPUT_FALSE 
                 RTS                       ; OLine=695  End of the table ... leave it alone
FLOW_A_36_OUTPUT_FALSE:                           
                 CMP      WALLCNT          
                 BNE      FLOW_A_37_OUTPUT_FALSE 
                 INX                       ; OLine=698  Copy ...
                 LDA      SKILL_VALUES,X   ; OLine=699  ... new ...
                 STA      WALL_INC         ; OLine=700  ... wall increment
                 INX                       ; OLine=701  Copy ...
                 LDA      SKILL_VALUES,X   ; OLine=702  ... new ...
                 STA      WALLDELY         ; OLine=703  ... wall ...
                 STA      WALLDELYR        ; OLine=704  ... delay
                 INX                       ; OLine=705  Copy ...
                 LDA      SKILL_VALUES,X   ; OLine=706  ... new ...
                 STA      GAPBITS          ; OLine=707  ... gap pattern
                 INX                       ; OLine=708  Copy ...
                 LDA      SKILL_VALUES,X   ; OLine=709  ... new ...
                 STA      MUSAIND          ; OLine=710  ... MusicA index
                 INX                       ; OLine=711  Copy ...
                 LDA      SKILL_VALUES,X   ; OLine=712  ... new ...
                 STA      MUSBIND          ; OLine=713  ... MusicB index
                 LDA      #1               ; OLine=714  Force ...
                 STA      MUSADEL          ; OLine=715  ... music to ...
                 STA      MUSBDEL          ; OLine=716  ... start new
                 RTS                       ; OLine=717
FLOW_A_37_OUTPUT_FALSE:                           
                                           
                 INX                       ; OLine=720  Move ...
                 INX                       ; OLine=721  ... X ...
                 INX                       ; OLine=722  ... to ...
                 INX                       ; OLine=723  ... next ...
                 INX                       ; OLine=724  ... row of ...
                 INX                       ; OLine=725  ... table
                 JMP      FLOW_A_35_OUTPUT_BEGIN 
                                           
                                           ;  ======================================
SEL_RESET_CHK:                             ;  --SubroutineContextBegins--
                                           
                                           ;  This function checks for changes to the reset/select
                                           ;  switches and debounces the transitions.
                                           
                                           
                 LDX      DEBOUNCE         ; OLine=736  Hold onto old value
                 LDA      SWCHB            ; OLine=737  New value
                 AND      #3               ; OLine=738  Only need bottom 2 bits
                                           
                 CMP      DEBOUNCE         
                 BEQ      FLOW_A_38_OUTPUT_TRUE 
                 STA      DEBOUNCE         ; OLine=743  Hold new value
                 EOR      #255             
                 AND      #3               ; OLine=745  Only need select/reset
                 RTS                       
FLOW_A_38_OUTPUT_TRUE:                           
                 LDA      #0               ; OLine=741  Return 0 ... nothing changed
                                           
                 RTS                       ;  --SubroutineContextEnds--
                                           ; </EditorTab>
                                           
                                           ;  ======================================
                                           ; <EditorTab name="sound">
INIT_MUSIC:                                ;  --SubroutineContextBegins--
                                           
                                           ;  This function initializes the hardware and temporaries
                                           ;  for 2-channel music
                                           
                 LDA      #6               
                 STA      AUDC0            ; OLine=759  ... to pure ...
                 STA      AUDC1            ; OLine=760  ... tones
                 LDA      #0               ; OLine=761  Turn off ...
                 STA      AUDV0            ; OLine=762  ... all ...
                 STA      AUDV1            ; OLine=763  ... sound
                 STA      MUSAIND          ; OLine=764  Music pointers ...
                 STA      MUSBIND          ; OLine=765  ... to top of data
                 LDA      #1               ; OLine=766  Force ...
                 STA      MUSADEL          ; OLine=767  ... music ...
                 STA      MUSBDEL          ; OLine=768  ... reload
                 LDA      #15              ; OLine=769  Set volume levels ...
                 STA      MUSAVOL          ; OLine=770  ... to ...
                 STA      MUSBVOL          ; OLine=771  ... maximum
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ;  ======================================
PROCESS_MUSIC:                             ;  --SubroutineContextBegins--
                                           
                                           ;  This function is called once per frame to process the
                                           ;  2 channel music. Two tables contain the commands/notes
                                           ;  for individual channels. This function changes the
                                           ;  notes at the right time.
                                           ;            
                 DEC      MUSADEL          ; OLine=782  Last note ended?
                 BNE      FLOW_A_39_OUTPUT_FALSE 
                                           
FLOW_A_40_OUTPUT_BEGIN:                           
                 LDX      MUSAIND          ; OLine=786  Voice-A index
                 LDA      MUSICA,X         ; OLine=787  Get the next music command
                 CMP      #0               
                 BEQ      FLOW_A_41_OUTPUT_TRUE 
                 CMP      #1               
                 BEQ      FLOW_A_42_OUTPUT_TRUE 
                 CMP      #2               
                 BNE      FLOW_A_41_OUTPUT_END 
                 INX                       ; OLine=805  Point to volume value
                 INC      MUSAIND          ; OLine=806  Bump the music pointer
                 LDA      MUSICA,X         ; OLine=807  Get the volume value
                 INC      MUSAIND          ; OLine=808  Bump the music pointer
                 STA      MUSAVOL          ; OLine=809  Store the new volume value
                 LDA      #0               ; OLine=810  Continue processing
                 JMP      FLOW_A_41_OUTPUT_END 
FLOW_A_42_OUTPUT_TRUE:                           
                 INX                       ; OLine=798  Point to the control value
                 INC      MUSAIND          ; OLine=799  Bump the music pointer
                 LDA      MUSICA,X         ; OLine=800  Get the control value
                 INC      MUSAIND          ; OLine=801  Bump the music pointer
                 STA      AUDC0            ; OLine=802  Store the new control value
                 LDA      #0               ; OLine=803  Continue processing
                 JMP      FLOW_A_41_OUTPUT_END 
FLOW_A_41_OUTPUT_TRUE:                           
                 INX                       ; OLine=789  Point to jump value
                 TXA                       ; OLine=790  X to ...
                 TAY                       ; OLine=791  ... Y (pointer to jump value)
                 INX                       ; OLine=792  Point one past jump value
                 TXA                       ; OLine=793  Into A so we can subtract
                 SEC                       ; OLine=794  New index
                 SBC      MUSICA,Y         
                 STA      MUSAIND          ; OLine=795  Store it
                 LDA      #0               ; OLine=796  Continue processing
FLOW_A_41_OUTPUT_END:                           
                 CMP      #0               
                 BEQ      FLOW_A_40_OUTPUT_BEGIN 
                                           
                 LDY      MUSAVOL          ; OLine=814  Get the volume
                 AND      #31              ; OLine=815  Lower 5 bits are frequency
                 CMP      #31              
                 BNE      FLOW_A_44_OUTPUT_FALSE 
                 LDY      #0               ; OLine=817  Frequency of 31 flags silence
FLOW_A_44_OUTPUT_FALSE:                           
                 STA      AUDF0            ; OLine=819  Store the frequency
                 STY      AUDV0            ; OLine=820  Store the volume
                 LDA      MUSICA,X         ; OLine=821  Get the note value again
                 INC      MUSAIND          ; OLine=822  Bump to the next command
                 ROR      A                ; OLine=823  The upper ...
                 ROR      A                ; OLine=824  ... three ...
                 ROR      A                ; OLine=825  ... bits ...
                 ROR      A                ; OLine=826  ... hold ...
                 ROR      A                ; OLine=827  ... the ...
                 AND      #7               ; OLine=828  ... delay
                 CLC                       ; OLine=829  No accidental carry
                 ROL      A                ; OLine=830  Every delay tick ...
                 ROL      A                ; OLine=831  ... is *4 frames
                 STA      MUSADEL          ; OLine=832  Store the note delay
FLOW_A_39_OUTPUT_FALSE:                           
                                           
                 DEC      MUSBDEL          ; OLine=835  Repeat Channel A sequence for Channel B
                 BNE      FLOW_A_45_OUTPUT_FALSE 
                                           
FLOW_A_46_OUTPUT_BEGIN:                           
                 LDX      MUSBIND          ; OLine=839
                 LDA      MUSICB,X         ; OLine=840
                 CMP      #0               
                 BEQ      FLOW_A_47_OUTPUT_TRUE 
                 CMP      #1               
                 BEQ      FLOW_A_48_OUTPUT_TRUE 
                 CMP      #2               
                 BNE      FLOW_A_47_OUTPUT_END 
                 INX                       ; OLine=858
                 INC      MUSBIND          ; OLine=859
                 LDA      MUSICB,X         ; OLine=860
                 INC      MUSBIND          ; OLine=861
                 STA      MUSBVOL          ; OLine=862
                 LDA      #0               ; OLine=863
                 JMP      FLOW_A_47_OUTPUT_END 
FLOW_A_48_OUTPUT_TRUE:                           
                 INX                       ; OLine=851
                 INC      MUSBIND          ; OLine=852
                 LDA      MUSICB,X         ; OLine=853
                 INC      MUSBIND          ; OLine=854
                 STA      AUDC1            ; OLine=855
                 LDA      #0               ; OLine=856
                 JMP      FLOW_A_47_OUTPUT_END 
FLOW_A_47_OUTPUT_TRUE:                           
                 INX                       ; OLine=842
                 TXA                       ; OLine=843
                 TAY                       ; OLine=844
                 INX                       ; OLine=845
                 TXA                       ; OLine=846
                 SEC                       ; OLine=847
                 SBC      MUSICB,Y         
                 STA      MUSBIND          ; OLine=848
                 LDA      #0               ; OLine=849
FLOW_A_47_OUTPUT_END:                           
                 CMP      #0               
                 BEQ      FLOW_A_46_OUTPUT_BEGIN 
                                           
                 LDY      MUSBVOL          ; OLine=867
                 AND      #31              ; OLine=868
                 CMP      #31              
                 BNE      FLOW_A_50_OUTPUT_FALSE 
                 LDY      #0               ; OLine=870
FLOW_A_50_OUTPUT_FALSE:                           
                 STA      AUDF1            ; OLine=872
                 STY      AUDV1            ; OLine=873
                 LDA      MUSICB,X         ; OLine=874
                 INC      MUSBIND          ; OLine=875
                 ROR      A                ; OLine=876
                 ROR      A                ; OLine=877
                 ROR      A                ; OLine=878
                 ROR      A                ; OLine=879
                 ROR      A                ; OLine=880
                 AND      #7               ; OLine=881
                 CLC                       ; OLine=882
                 ROL      A                ; OLine=883
                 ROL      A                ; OLine=884
                 STA      MUSBDEL          ; OLine=885
FLOW_A_45_OUTPUT_FALSE:                           
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ;  ======================================
INIT_GO_FX:                                ;  --SubroutineContextBegins--
                                           
                                           ;  This function initializes the hardware and temporaries
                                           ;  to play the soundeffect of a player hitting the wall
                                           
                 LDA      #5               ; OLine=895  Set counter for frame delay ...
                 STA      MUS_TMP1         ; OLine=896  ... between frequency change
                 LDA      #3               ; OLine=897  Tone type ...
                 STA      AUDC0            ; OLine=898  ... poly tone
                 LDA      #15              ; OLine=899  Volume A ...
                 STA      AUDV0            ; OLine=900  ... to max
                 LDA      #0               ; OLine=901  Volume B ...
                 STA      AUDV1            ; OLine=902  ... silence
                 LDA      #240             ; OLine=903  Initial ...
                 STA      MUS_TMP0         ; OLine=904  ... sound ...
                 STA      AUDF0            ; OLine=905  ... frequency
                 RTS                       ;  --SubroutineContextEnds--
                                           
                                           ;  ======================================
PROCESS_GO_FX:                             ;  --SubroutineContextBegins--
                                           
                                           ;  This function is called once per scanline to play the
                                           ;  soundeffects of a player hitting the wall.
                                           ;         
                 DEC      MUS_TMP1         ; OLine=914  Time to change the frequency?
                 BNE      FLOW_A_52_OUTPUT_FALSE 
                 LDA      #5               ; OLine=916  Reload ...
                 STA      MUS_TMP1         ; OLine=917  ... the frame count
                 INC      MUS_TMP0         ; OLine=918  Increment ...
                 LDA      MUS_TMP0         ; OLine=919  ... the frequency divisor
                 STA      AUDF0            ; OLine=920  Change the frequency
                 CMP      #0               
                 BNE      FLOW_A_52_OUTPUT_FALSE 
                 LDA      #1               ; OLine=922  All done ... return 1
                 RTS                       ; OLine=923
FLOW_A_52_OUTPUT_FALSE:                           
                 LDA      #0               ; OLine=926
                                           
                 RTS                       ;  --SubroutineContextEnds--
                                           ; </EditorTab>
                                           
                                           ; </EditorTab name="data">
                                           ;  ======================================
                                           ;  Music commands for Channel A and Channel B
                                           
                                           ;  A word on music and wall timing ...
                                           
                                           ;  Wall moves between scanlines 0 and 111 (112 total)
                                           
                                           ;  Wall-increment   frames-to-top
                                           ;       3             336
                                           ;       2             224
                                           ;       1             112
                                           ;      0.5             56  ; Ah ... but we are getting one less
                                           
                                           ;  Each tick is multiplied by 4 to yield 4 frames per tick
                                           ;  32 ticks/song = 32*4 = 128 frames / song
                                           
                                           ;  We want songs to start with wall at top ...
                                           
                                           ;  Find the least-common-multiple
                                           ;  336 and 128 : 2688 8 walls, 21 musics
                                           ;  224 and 128 :  896 4 walls,  7 musics
                                           ;  112 and 128 :  896 8 walls,  7 musics
                                           ;   56 and 128 :  896 16 walls, 7 musics
                                           
                                           ;  Wall moving every other gives us 112*2=224 scanlines
                                           ;  Song and wall are at start every 4
                                           ;  1 scanline, every 8
                                           ;  Wall delay=3 gives us 128*3=336 scanlines 2
                                           
                                           ;  MUSIC EQUATES
                                           
MUSCMD_JUMP      .equ     0                ; OLine=963
MUSCMD_CONTROL   .equ     1                ; OLine=964
MUSCMD_VOLUME    .equ     2                ; OLine=965
MUS_REST         .equ     31               ; OLine=966
MUS_DEL_1        .equ     32*1             ; OLine=967
MUS_DEL_2        .equ     32*2             ; OLine=968
MUS_DEL_3        .equ     32*3             ; OLine=969
MUS_DEL_4        .equ     32*4             ; OLine=970
                                           
                                           
                                           
MUSICA                                     ; OLine=974
                                           
MA_SONG_1                                  ; OLine=976
                                           
                 .BYTE    MUSCMD_CONTROL, 12 
                 .BYTE    MUSCMD_VOLUME,  15 ; OLine=979  Volume (full)
                                           
MA1_01                                     ; OLine=981
                 .BYTE    MUS_DEL_3  +  15 ; OLine=982
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=983
                 .BYTE    MUS_DEL_3  +  15 ; OLine=984
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=985
                 .BYTE    MUS_DEL_1  +  7  ; OLine=986
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=987
                 .BYTE    MUS_DEL_1  +  7  ; OLine=988
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=989
                 .BYTE    MUS_DEL_2  +  MUS_REST ; OLine=990
                 .BYTE    MUS_DEL_1  +  8  ; OLine=991
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=992
                 .BYTE    MUS_DEL_4  +  MUS_REST ; OLine=993
                 .BYTE    MUS_DEL_2  +  17 ; OLine=994
                 .BYTE    MUS_DEL_2  +  MUS_REST ; OLine=995
                 .BYTE    MUS_DEL_2  +  17 ; OLine=996
                 .BYTE    MUS_DEL_2  +  MUS_REST ; OLine=997
                 .BYTE    MUS_DEL_3  +  16 ; OLine=998
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=999
                 .BYTE    MUSCMD_JUMP, (MA1_END - MA1_01) ; OLine=1000  Repeat back to top
MA1_END                                    ; OLine=1001
                                           
MA_SONG_2                                  ; OLine=1003
                                           
                 .BYTE    MUSCMD_CONTROL, 12 
                 .BYTE    MUSCMD_VOLUME,  15 ; OLine=1006
                                           
MA2_01                                     ; OLine=1008
                 .BYTE    MUS_DEL_1  +  15 ; OLine=1009
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1010
                 .BYTE    MUS_DEL_1  +  15 ; OLine=1011
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1012
                 .BYTE    MUS_DEL_2  +  MUS_REST ; OLine=1013
                 .BYTE    MUS_DEL_4  +  7  ; OLine=1014
                 .BYTE    MUS_DEL_4  +  MUS_REST ; OLine=1015
                 .BYTE    MUS_DEL_2  +  15 ; OLine=1016
                 .BYTE    MUS_DEL_4  +  MUS_REST ; OLine=1017
                 .BYTE    MUS_DEL_2  +  12 ; OLine=1018
                 .BYTE    MUS_DEL_2  +  MUS_REST ; OLine=1019
                 .BYTE    MUS_DEL_2  +  15 ; OLine=1020
                 .BYTE    MUS_DEL_2  +  MUS_REST ; OLine=1021
                 .BYTE    MUS_DEL_2  +  17 ; OLine=1022
                 .BYTE    MUS_DEL_2  +  MUS_REST ; OLine=1023
                 .BYTE    MUSCMD_JUMP, (MA2_END - MA2_01) ; OLine=1024  Repeat back to top
MA2_END                                    ; OLine=1025
                                           
                                           
                                           
MUSICB                                     ; OLine=1029
                                           
MB_SONG_1                                  ; OLine=1031
                                           
                 .BYTE    MUSCMD_CONTROL, 8 
                 .BYTE    MUSCMD_VOLUME,  8 ; OLine=1034  Volume (half)
                                           
MB1_01                                     ; OLine=1036
                 .BYTE    MUS_DEL_1  +  10 ; OLine=1037
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1038
                 .BYTE    MUS_DEL_1  +  20 ; OLine=1039
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1040
                 .BYTE    MUS_DEL_1  +  30 ; OLine=1041
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1042
                 .BYTE    MUS_DEL_1  +  15 ; OLine=1043
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1044
                 .BYTE    MUS_DEL_1  +  10 ; OLine=1045
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1046
                 .BYTE    MUS_DEL_1  +  20 ; OLine=1047
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1048
                 .BYTE    MUS_DEL_1  +  30 ; OLine=1049
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1050
                 .BYTE    MUS_DEL_1  +  15 ; OLine=1051
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1052
                 .BYTE    MUSCMD_JUMP, (MB1_END - MB1_01) ; OLine=1053  Repeat back to top
MB1_END                                    ; OLine=1054
                                           
MB_SONG_2                                  ; OLine=1056
                                           
                 .BYTE    MUSCMD_CONTROL, 8 
                 .BYTE    MUSCMD_VOLUME,  8 ; OLine=1059
                                           
MB2_01                                     ; OLine=1061
                 .BYTE    MUS_DEL_1  +  1  ; OLine=1062
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1063
                 .BYTE    MUS_DEL_1  +  1  ; OLine=1064
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1065
                 .BYTE    MUS_DEL_1  +  1  ; OLine=1066
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1067
                 .BYTE    MUS_DEL_1  +  1  ; OLine=1068
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1069
                 .BYTE    MUS_DEL_1  +  30 ; OLine=1070
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1071
                 .BYTE    MUS_DEL_1  +  30 ; OLine=1072
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1073
                 .BYTE    MUS_DEL_1  +  30 ; OLine=1074
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1075
                 .BYTE    MUS_DEL_1  +  30 ; OLine=1076
                 .BYTE    MUS_DEL_1  +  MUS_REST ; OLine=1077
                 .BYTE    MUSCMD_JUMP, (MB2_END - MB2_01) ; OLine=1078  Repeat back to top
MB2_END                                    ; OLine=1079
                                           
                                           
                                           ;  ======================================
SKILL_VALUES                               ; OLine=1083
                                           
                                           ;  This table describes how to change the various
                                           ;  difficulty parameters as the game progresses.
                                           ;  For instance, the second entry in the table 
                                           ;  says that when the score is 4, change the values of
                                           ;  wall-increment to 1, frame-delay to 2, gap-pattern to 0,
                                           ;  MusicA to 24, and MusicB to 22.
                                           
                                           ;  A 255 on the end of the table indicates the end 
                                           
                                           ;  Wall  Inc  Delay     Gap   MA                 MB
                 .BYTE    0,    1,   3,     0  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB ; OLine=1095
                 .BYTE    4,    1,   2,     0  ,MA_SONG_2-MUSICA , MB_SONG_2-MUSICB ; OLine=1096
                 .BYTE    8,    1,   1,     0  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB ; OLine=1097
                 .BYTE    16,    1,   1,     1  ,MA_SONG_2-MUSICA , MB_SONG_2-MUSICB ; OLine=1098
                 .BYTE    24,    1,   1,     3  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB ; OLine=1099
                 .BYTE    32,    1,   1,     7  ,MA_SONG_2-MUSICA , MB_SONG_2-MUSICB ; OLine=1100
                 .BYTE    40,    1,   1,    15  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB ; OLine=1101
                 .BYTE    48,    2,   1,     0  ,MA_SONG_2-MUSICA , MB_SONG_2-MUSICB ; OLine=1102
                 .BYTE    64,    2,   1,     1  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB ; OLine=1103
                 .BYTE    80,    2,   1,     3  ,MA_SONG_2-MUSICA , MB_SONG_2-MUSICB ; OLine=1104
                 .BYTE    96 ,   2,   1,     7  ,MA_SONG_1-MUSICA , MB_SONG_1-MUSICB ; OLine=1105
                 .BYTE    255              ; OLine=1106
                                           
                                           ;  ======================================
                                           ;  Image for players
GR_PLAYER:                                 ; OLine=1110
                                           ; <Graphic widthBits="8" heightBits="8" bitDepth="1" name="player">     
                 .BYTE    16               
                 .BYTE    16               
                 .BYTE    40               
                 .BYTE    40               
                 .BYTE    84               
                 .BYTE    84               
                 .BYTE    170              
                 .BYTE    124              
                                           ; </Graphic>
                                           
                                           ;  ======================================
                                           ;  Images for numbers
DIGITS:                                    ; OLine=1124
                                           ;  We only need 5 rows, but the extra space on the end makes each digit 8 rows,
                                           ;  which makes it the multiplication easier.
                                           ; <Graphic widthBits="8" heightBits="8" bitDepth="1" images="10" name="digits">
                 .BYTE    14 ,10 ,10 ,10 ,14, 0,0,0 
                 .BYTE    34 ,34 ,34 ,34 ,34, 0,0,0 
                 .BYTE    238 ,34 ,238 ,136 ,238, 0,0,0 
                 .BYTE    238 ,34 ,102 ,34 ,238, 0,0,0 
                 .BYTE    170 ,170 ,238 ,34 ,34, 0,0,0 
                 .BYTE    238 ,136 ,238 ,34 ,238, 0,0,0 
                 .BYTE    238 ,136 ,238 ,170 ,238, 0,0,0 
                 .BYTE    238 ,34 ,34 ,34 ,34, 0,0,0 
                 .BYTE    238 ,170 ,238 ,170 ,238, 0,0,0 
                 .BYTE    238 ,170 ,238 ,34 ,238, 0,0,0 
                                           ; </Graphic>
                                           
                                           ; </EditorTab>
                                           
                                           ; <EditorTab name="vectors">
                                           ;  ====================================== 
                                           ;  6502 Hardware vectors at the end of memory
.org             63482                     
                 .WORD    0                
                 .WORD    main             ; OLine=1147  Reset vector (top of program)
                 .WORD    0                
                                           
                                           ; </EditorTab>
                                           
                                           
                                           
.end                                       ; OLine=1154
