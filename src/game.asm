%include "video.mac"
%include "keyboard.mac"

section .data


section .text

extern clear                ; limpia la pantalla
extern scan                 ; lee del teclado
extern calibrate            ; hace algo
extern putc                 ; pone un caracter en una posicion <x, y>
extern cursor               ; hace parpadear el cursor
extern pauseFor             ; detiene el tiempo (no funciona)
extern convert              ; devuelve el caracter
extern start                ; pone la presentacion
extern write                ; escribe directo al bufer
extern putModeI             ; escribe el modo -Insert-
extern pointer              ; puntero del cursor
extern writeScroll          ; escribe al array que proporciona sensacion de scroll

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
    FILL_SCREEN FG.GRAY|BG.BLACK

    ; Calibrate the timing
    call calibrate        

    ; Snakasm main loop
    game.loop:
        
        ; Pequenna presentacion
        call start
         
        ; wait Press
        call scan
        pressOnKey:
            call cursor
            call scan
            cmp al, 0
            je pressOnKey
            
        ; limpia la pantalla    Este fill esta fuera de lugar, solo se necesita la primera vez
        FILL_SCREEN (FG.GRAY|BG.BLACK)
        mov bx, 0
        mov [pointer], bx
        
        cmp al, KEY.I
        je .insertMode
        jmp pressOnKey
        
        .insertMode:
            call putModeI
            .read:
                call get_input
                ; Main loop.

                ; Here is where you will place your game logic.
                ; Develop procedures like paint_map and update_content,
                ; declare it extern and use here.
                jmp .read


draw.red:
    FILL_SCREEN BG.RED
    ret


draw.green:
    FILL_SCREEN BG.GREEN
    ret


get_input:
    ;mov al, 1
    ;push ax
    ;call pauseFor
    ;add esp, 2
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
    call writeScroll
    add esp, 2
    no:
    add esp, 2 ; free the stack
    ret
