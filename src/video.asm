%include "video.mac"

; Frame buffer location
%define FBUFFER 0xB8000

; color inicial
global DEFCOL
%define DEFCOL (FG.GRAY | BG.BLACK)

; FBOFFSET(byte row, byte column)
%macro FBOFFSET 2.nolist
    xor eax, eax
    mov al, COLS
    mul byte %1
    add al, %2
    adc ah, 0
    shl ax, 1
%endmacro

section .data

global pointer
pointer dw 2198
text dw "P" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, "y" | DEFCOL, "e" | DEFCOL, "c" | DEFCOL, "t" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "d" | DEFCOL, "e" | DEFCOL, " " | DEFCOL, "P" | DEFCOL, "M" | DEFCOL, "I" | DEFCOL
raul dw "L" | DEFCOL, "a" | DEFCOL, "z" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "R" | DEFCOL, "a" | DEFCOL, "u" | DEFCOL, "l" | DEFCOL, " " | DEFCOL, "I" | DEFCOL, "g" | DEFCOL, "l" | DEFCOL, "e" | DEFCOL, "s" | DEFCOL, "i" | DEFCOL, "a" | DEFCOL, "s" | DEFCOL, " " | DEFCOL, "V" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, "a" | DEFCOL
teno dw "M" | DEFCOL, "i" | DEFCOL, "g" | DEFCOL, "u" | DEFCOL, "e" | DEFCOL, "l" | DEFCOL, " " | DEFCOL, "T" | DEFCOL, "e" | DEFCOL, "n" | DEFCOL, "o" | DEFCOL, "r" | DEFCOL, "i" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "P" | DEFCOL, "o" | DEFCOL, "t" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "i" | DEFCOL
finalText dw "P" | DEFCOL, "r" | DEFCOL, "e" | DEFCOL, "s" | DEFCOL, "i" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "e" | DEFCOL, " " | DEFCOL, "c" | DEFCOL, "u" | DEFCOL, "a" | DEFCOL, "l" | DEFCOL, "q" | DEFCOL, "u" | DEFCOL, "i" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, " " | DEFCOL, "t" | DEFCOL, "e" | DEFCOL, "c" | DEFCOL, "l" | DEFCOL, "a" | DEFCOL, " " | DEFCOL, "p" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "a" | DEFCOL, " " | DEFCOL, "c" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "t" | DEFCOL, "i" | DEFCOL, "n" | DEFCOL, "u" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "." | DEFCOL, "." | DEFCOL, "." | DEFCOL
insert dw "-" | DEFCOL, "I" | DEFCOL, "n" | DEFCOL, "s" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, "t" | DEFCOL, "-" | DEFCOL

section .text

extern pauseFor
; clear(byte char, byte attrs)
; Clear the screen by filling it with char and attributes.
global clear
clear:
    push ax
    mov ax, [esp + 6] ; char, attrs
    mov edi, FBUFFER
    mov ecx, COLS * ROWS
    cld
    rep stosw
    pop ax
    ret

; hace parpadear el puntero
global cursor
cursor:
    ;call pauseFor
    mov ax, [pointer]
    ;inc ax
    mov bx, [FBUFFER + eax]
    mov cl, 4
    rol bh, cl ; averiguar que esta pasando
    mov [FBUFFER + eax], bx
    ret

repairCursor:
    push ax
    push bx
    mov ax, [pointer]
    mov bx, [FBUFFER + eax]
    mov cl, 4
    mov bh, DEFCOL
    mov [FBUFFER + eax], bx
    pop bx
    pop ax
    ret

; putc(char chr, byte color, byte r, byte c)
;      4         5           6       7
global putc
putc:
    ; calc framebuffer offset 2 * (r * COLS + c)
    FBOFFSET [esp + 6], [esp + 7]

    mov bx, [esp + 4]
    mov [FBUFFER + eax], bx
    ret

; escribe en la posicion del cursor
global write
write:
    mov bx, [esp + 4]
    mov ax, [pointer]
    mov [FBUFFER + eax], bx
    mov bl, [esp + 5]
    mov [FBUFFER + eax + 3], bl
    mov [FBUFFER + eax - 1], bl
    add ax, 2
    mov [pointer], ax
    ret

; Escribe 4 lineas de presentacion
global start
start:
    push esi
    mov bh, 30
    mov bl, 10
    mov esi, text
    mov ecx, 97
    putText:
        cmp ecx, 82
        je next
        lodsw
        push bx
        push ax
        call putc
        pop ax
        pop bx
        inc bh
        dec ecx
        jmp putText
        next:
        mov bh, 25
        mov bl, 11
        mov esi, raul
        nameR:
        cmp ecx, 57
        je next2
        lodsw
        push bx
        push ax
        call putc
        pop ax
        pop bx
        inc bh
        dec ecx
        jmp nameR
        next2:
        mov bh, 30
        mov bl, 12
        mov esi, teno
        nameT:
        cmp ecx, 42
        je next3
        lodsw
        push bx
        push ax
        call putc
        pop ax
        pop bx
        inc bh
        dec ecx
        jmp nameT
        next3:
        mov bh, 17
        mov bl, 13
        mov esi, finalText
        endText:
        cmp ecx, 0
        je ready
        lodsw
        push bx
        push ax
        call putc
        pop ax
        pop bx
        inc bh
        dec ecx
        jmp endText
    ready:
    pop esi
    ret

; Pone el indicador de modo en -Insert-
global putModeI
putModeI:
    push esi
    mov bh, 1
    mov bl, 24
    mov esi, insert
    mov ecx, 8
    insertText:
        cmp ecx, 0
        je end
        lodsw
        push bx
        push ax
        call putc
        pop ax
        pop bx
        inc bh
        dec ecx
        jmp insertText
    end:
    pop esi
    ret

; mueve el pointer y borra el ultimo char
global backSpace
backSpace:
    push ax
    mov ax, [pointer]
    mov bx, DEFCOL | 0
    mov [FBUFFER + eax], bx
    sub ax, 2
    mov [FBUFFER + eax], bx
    mov [pointer], ax
    pop ax
    ret

;desplaza el cursor
global move
move:
    push ax
    mov ax, [pointer]
    mov bl, DEFCOL 
    mov [FBUFFER + eax + 1], bl
    sub ax, 2
    mov [pointer], ax
    pop ax
    ret