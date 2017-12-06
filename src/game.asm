%include "video.mac"
%include "keyboard.mac"

section .bss
lastKey resb 1 ; Ultima tecla presionada en el insertMode

section .text

extern clear                ; limpia la pantalla
extern scan                 ; lee del teclado
extern calibrate            ; hace algo
extern putc                 ; pone un caracter en una posicion <x, y>
extern cursor               ; hace parpadear el cursor
extern pauseCursor          ; detiene el tiempo
extern convert              ; devuelve el caracter
extern convert2             ; devuelve el caracter
extern start                ; pone la presentacion
extern write                ; escribe directo al bufer
extern putModeI             ; escribe el modo -Insert-
extern putModeV             ; Write -Visual- and start visual mode
extern putModeN
extern pointer              ; puntero del cursor
extern writeScroll          ; escribe al array que proporciona sensacion de scroll
extern nonReWrite           ; no sobrescribe
extern writeMode            ; tipo de escritura

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
    FILL_SCREEN DEFCOL

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
            push ax
            call convert2
            pop ax
            cmp bx, 0 | FG.GRAY | BG.BLACK
            je pressOnKey
            
        ; limpia la pantalla    Este fill esta fuera de lugar, solo se necesita la primera vez
        FILL_SCREEN DEFCOL
        mov ebx, 0
        mov [pointer], ebx

        ; Enter in normal mode for first time  
        .normalMode:
            call putModeN
            .normalLoop:
                call cursor
                call scan

                cmp al, KEY.I
                je .insertMode
                cmp al, KEY.V
                je .visualMode

                jmp .normalLoop


        .insertMode:
            call putModeI
            .read:
                call get_input
                mov eax, [lastKey]
                cmp eax , 0x10 ; Rulo tu pon KEY.Esc en ves d 0x10
                je .normalMode
                jmp .read
        
        .visualMode:
            call putModeV
            .oread:
                call cursor
                call scan
                cmp ax, 0x10 ; Rulo tu pon KEY.Esc en ves d 0x10
                je .normalMode
                jmp .oread

draw.red:
    FILL_SCREEN BG.RED
    ret


draw.green:
    FILL_SCREEN BG.GREEN
    ret


get_input:
    ;mov al, 1
    ;push ax
    ;add esp, 2
    call cursor
    call scan
    mov [lastKey], ax
    push ax
    ; The value of the input is on 'word [esp]'

    ; Your bindings here
    call convert2
    cmp bx, 0 | DEFCOL
    je no
    push bx
    mov bl, [writeMode]
    cmp bl, 1
    je .reWrite
    call nonReWrite
    jmp .conti
    .reWrite:
    call writeScroll
    .conti:
    add esp, 2
    no:
    add esp, 2 ; free the stack
    ret
