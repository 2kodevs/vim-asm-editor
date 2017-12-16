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
extern writeTools           ; array con los tipos de escritura
extern initializeVisual     ; inicializa el modo visual
extern visualActions        ; decide las acciones en modo visual
extern mVisual              ; indicadar del tipo de visual
extern capsLockButton       ; indica si fue presionada mayuscula
extern restoreScreen
extern normalActions
extern reboot
extern shift
extern control

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
        ;mov cl, al
        pressOnKey:
            call cursor
            call scan

            ;cmp al, 0xA6
            ;jbe .check
            ;jmp pressOnKey
            ;.check:
            ;cmp al, 0x00
            ;ja break

            cmp al, KEY.ENTER
            je break
            jmp pressOnKey
        break:
            
        ; limpia la pantalla    Este fill esta fuera de lugar, solo se necesita la primera vez
        FILL_SCREEN DEFCOL
        mov ebx, 0
        mov [pointer], ebx

        ; Enter in normal mode for first time  
        .normalMode:
            call restoreScreen
            call putModeN
            .normalLoop:
                call cursor
                ;call pauseCursor
                call scan

                ;cmp al, 0xA6
                ;jbe .check
                ;jmp .break
                ;.check:
                ;cmp al, 0x00
                ;ja .break
                ;call pauseCursor
                ;.break:

                call normalActions
                cmp al, KEY.I
                je .insertMode
                cmp al, KEY.V
                je .visualMode
                cmp al, KEY.C
                jne .not_C
                push ax
                mov al, [control]
                cmp al, 1
                jne .not_C
                pop ax
                call reboot
                jmp game
                .not_C:
                pop ax
                jmp .normalLoop


        .insertMode:
            call putModeI
            .read:
                call get_input
                mov al, [lastKey]
                cmp al , KEY.Esc ; Rulo tu pon KEY.Esc en ves d 0x10
                je .normalMode
                jmp .read
        
        .visualMode:
            call putModeV
            xor al, al
            mov al, [capsLockButton] ; comprobar si la mayuscula esta presionada
            cmp al, 1                ; .  
            je .next                 ; .  
            mov al, [shift]          ; .  
            .next:
            mov [mVisual], al
            call initializeVisual
            .standard:
                call cursor
                call scan
                cmp al, KEY.Esc ; Rulo tu pon KEY.Esc en ves d 0x10
                je .normalMode
                call visualActions
                jmp .standard

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
    mov [lastKey], al
    push ax
    ; The value of the input is on 'word [esp]'

    ; Your bindings here
    call convert2
    cmp bx, 0 | DEFCOL
    je no
    push bx
    ; look at this bitch
    xor ebx, ebx
    mov bl, [writeMode]
    mov cl, 2
    shl ebx, cl
    call [writeTools + ebx]

    add esp, 2
    no:
    add esp, 2 ; free the stack
    ret

    