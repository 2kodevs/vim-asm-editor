%include "video.mac"
%include "keyboard.mac"

section .bss
lastKey resb 1 ; Ultima tecla presionada en el insertMode

section .data
global exit
exit db 0      ; indica si es necesario entrar al Modo Normal

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
extern putName              ; escibe el nombre del modo
extern pointer              ; puntero del cursor
extern writeScroll          ; escribe al array que proporciona sensacion de scroll
extern nonReWrite           ; no sobrescribe
extern writeMode            ; tipo de escritura
extern writeTools           ; array con los tipos de escritura
extern initializeVisual     ; inicializa el modo visual
extern visualActions        ; decide las acciones en modo visual
extern normalActions        ; decide las acciones en modo normal
extern mVisual              ; indicadar del tipo de visual
extern capsLockButton       ; indica si esta presionada mayuscula
extern control              ; indica si el control esta presionado
extern shift                ; indica si el control esta presionado
extern reboot               ; reinicia la aplicacion
extern restoreScreen        ; le pone le color default a todo lo escrito
extern safe                 ; guarda el contenido de la pantalla
extern linealAction

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
        
        ; posicionar el cursor en el inicio de la pantalla
        mov ebx, 0
        mov [pointer], ebx

        ; Enter in normal mode for first time  
        .normalMode:
            xor eax, eax
            mov [linealAction], al
            mov [exit], al
            call restoreScreen
            mov eax, 4
            push eax
            call putName
            .normalLoop:
                call cursor
                call scan
                cmp al, 0
                je .normalLoop
                call normalActions
                cmp al, KEY.I
                je .insertMode
                cmp al, KEY.R
                jne .check_others
                mov bl, [capsLockButton] ; comprobar si la mayuscula esta presionada
                xor bl, [shift] 
                cmp bl, 1
                je .replaceMode 
                .check_others:
                cmp al, KEY.V
                je .visualMode
                cmp al, KEY.C
                jne .normalLoop
                mov al, [control]
                cmp al, 1
                jne .normalLoop
                call reboot
                jmp game

        ; enter in insert mode
        .insertMode:
            xor eax, eax
            mov [linealAction], al
            mov [writeMode], al
            push eax
            call putName
            .read:
                call get_input
                mov al, [exit]
                cmp al, 1
                je .normalMode
                jmp .read

        ; enter in replace mode
        .replaceMode:
            xor eax, eax
            mov [linealAction], al
            mov al, 1
            mov [writeMode], al
            jmp .read
        
        ; enter in visual mode
        .visualMode:
            xor eax, eax
            mov al, [capsLockButton] ; comprobar si la mayuscula esta presionada
            xor al, [shift] 
            mov [mVisual], al
            add al, 2
            push eax
            call putName
            call initializeVisual
            .standard:
                call cursor
                call scan
                call visualActions
                mov al, [exit]
                cmp al, 1
                je .normalMode
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

    