%include "video.mac"
%include "keyboard.mac"

section .text

extern clear
extern scan
extern calibrate
extern putc
extern cursor
extern pauseFor
extern convert

; Bind a key to a procedure
%macro bind 2
  cmp byte [esp], %1
  jne %%next
  call %2
  %%next:
%endmacro

; Fill the screen with the given background color
%macro FILL_SCREEN 1
  push word %1
  call clear
  add esp, 2
%endmacro

global game
game:
  ; Initialize game

  FILL_SCREEN FG.GRAY | BG.YELLOW

  ; Calibrate the timing
  call calibrate

  ; Snakasm main loop
  game.loop:
    .input:
      call get_input
    ; Main loop.

    ; Here is where you will place your game logic.
    ; Develop procedures like paint_map and update_content,
    ; declare it extern and use here.
    jmp game.loop


draw.red:
  FILL_SCREEN BG.RED
  ret


draw.green:
  FILL_SCREEN BG.GREEN
  ret


get_input:
    ;mov eax, 1000
    ;push eax
    ;call pauseFor
    ;add esp, 4
    call cursor
    call scan
    push ax
    ; The value of the input is on 'word [esp]'

    ; Your bindings here
    call convert
    cmp bx, 0 | FG.GRAY | BG.BLACK
    je no
    ;mov bx, 'a' | FG.GRAY | BG.BLACK
    push bx
    call putc
    add esp, 2
    no:
    add esp, 2 ; free the stack
    ret
