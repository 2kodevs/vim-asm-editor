%include "video.mac"

; Frame buffer location
%define FBUFFER 0xB8000

; color inicial
global DEFCOL
%define DEFCOL FG.GRAY | BG.BLACK

; FBOFFSET(byte row, byte column)
%macro FBOFFSET 2.nolist
    xor eax, eax
    mov al, COLS
    mul byte %1
    add al, %2
    adc ah, 0
    shl ax, 1
%endmacro

; Pinta un texto dado, con su buffer y su length
%macro OUTPUT_LINE 3.nolist
    cld
    mov esi, %1
    mov edi, %2
    mov ecx, %3
    rep movsw
%endmacro

; Ajusta todos los punteros
%macro UPD_POINTER 1.nolist
    ;suma el desplazamiento dl cursor
    add ax, %1
    mov [pointer], ax          
    mov bx, [viewStart]
    mov cx, ax
    add cx, bx
    ;compara con el cursor el puntero al inicio del texto
    cmp cx, bx
    jl %%less
    add bx, 3838
    ; lo compara con el fin
    cmp cx, bx
    jle %%end
    mov bx, [viewStart]
    add bx, 160
    mov [viewStart], bx
    sub ax, 160 ; se salio el cursor x debajo
    mov [pointer], ax
    jmp %%end
    %%less:
        ; verifica si se esta en el inicio del texto
        cmp bx, 0
        je %%undo
        sub bx, 160
        mov [viewStart], bx
        add ax, 160 ; necesario xq el pointer se salio por encima
        mov [pointer], ax
        jmp %%end
        %%undo:
            sub ax, %1
            mov [pointer], ax
    %%end:
%endmacro

section .data

global input
input times 3000000 dw 0 | DEFCOL

global viewStart
viewStart dw 0

lastChar dw 0

global pointer
pointer dw 2198

cursorColor db 0
text dw "P" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, "y" | DEFCOL, "e" | DEFCOL, "c" | DEFCOL, "t" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "d" | DEFCOL, "e" | DEFCOL, " " | DEFCOL, "P" | DEFCOL, "M" | DEFCOL, "I" | DEFCOL
raul dw "L" | DEFCOL, "a" | DEFCOL, "z" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "R" | DEFCOL, "a" | DEFCOL, "u" | DEFCOL, "l" | DEFCOL, " " | DEFCOL, "I" | DEFCOL, "g" | DEFCOL, "l" | DEFCOL, "e" | DEFCOL, "s" | DEFCOL, "i" | DEFCOL, "a" | DEFCOL, "s" | DEFCOL, " " | DEFCOL, "V" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, "a" | DEFCOL
teno dw "M" | DEFCOL, "i" | DEFCOL, "g" | DEFCOL, "u" | DEFCOL, "e" | DEFCOL, "l" | DEFCOL, " " | DEFCOL, "T" | DEFCOL, "e" | DEFCOL, "n" | DEFCOL, "o" | DEFCOL, "r" | DEFCOL, "i" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "P" | DEFCOL, "o" | DEFCOL, "t" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "i" | DEFCOL
finalText dw "P" | DEFCOL, "r" | DEFCOL, "e" | DEFCOL, "s" | DEFCOL, "i" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "e" | DEFCOL, " " | DEFCOL, "c" | DEFCOL, "u" | DEFCOL, "a" | DEFCOL, "l" | DEFCOL, "q" | DEFCOL, "u" | DEFCOL, "i" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, " " | DEFCOL, "t" | DEFCOL, "e" | DEFCOL, "c" | DEFCOL, "l" | DEFCOL, "a" | DEFCOL, " " | DEFCOL, "p" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "a" | DEFCOL, " " | DEFCOL, "c" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "t" | DEFCOL, "i" | DEFCOL, "n" | DEFCOL, "u" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "." | DEFCOL, "." | DEFCOL, "." | DEFCOL
insert dw "-" | DEFCOL, "-" | DEFCOL, "I" | DEFCOL, "N" | DEFCOL, "S" | DEFCOL, "E" | DEFCOL, "R" | DEFCOL, "T" | DEFCOL, "-" | DEFCOL, "-" | DEFCOL

section .text

extern pauseFor

; clear(byte char, byte attrs)
; Clear the screen by filling it with char and attributes.
global clear
clear:
    push ax
    mov ax, [esp + 6] ; char, attrs
    mov edi, FBUFFER
    mov ecx, COLS * ROWS ; notar que ROWS lo cambie x 24
    cld
    rep stosw
    pop ax
    ret

; hace parpadear el puntero
global cursor
cursor:
    ;call pauseFor
    mov al, [cursorColor]
    xor al, 1
    mov [cursorColor], al
    mov ax, [pointer]
    mov bx, [FBUFFER + eax]
    mov cl, 4
    rol bh, cl 
    mov [FBUFFER + eax], bx
    ret

; arregla el posible cambio de coloracion provocado por el cursor
repairCursor:
    push ax
    mov al, [cursorColor]
    cmp al, 0
    je .end
    call cursor
    .end:
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
    xor al, al
    mov [cursorColor], al
    mov ax, [pointer]
    mov [FBUFFER + eax], bx
    UPD_POINTER 2
    ret

; escribe en el array donde es guardado el texto y manda a pintar
global writeScroll
writeScroll:
    xor ebx, ebx
    mov bx, [esp + 4]
    xor eax, eax
    mov [cursorColor], al
    mov ax, [pointer]
    add ax, [viewStart]
    ; escribe en el texto + la posicion inicial actual + el cursor
    mov [input + eax], bx
    ; actualiza el valor de la posicion dl ultimo char
    cmp ax, [lastChar]
    jbe .conti
    mov [lastChar], ax
    .conti:
    mov ax, [pointer]
    UPD_POINTER 2
    call printAll
    ret

; pinta todo lo visualizable desde el inicio hasta 
;el ultimo caracter introducido
printAll:
    mov ax, 0 | DEFCOL
    push ax
    call clear
    pop ax
    mov ax, [viewStart]
    mov esi, input
    add esi, eax
    mov edi, FBUFFER
	mov ebx, input
	add bx, [lastChar]
    cld
    mov cx, 0
    .loop:
        cmp cx, 3838
        ja .ret
        cmp esi, ebx
        ja .ret
        movsw
        add cx, 2
        jmp .loop
    .ret:
    ret

; Escribe 4 lineas de presentacion
global start
start:
    OUTPUT_LINE text, FBUFFER + 1660, 15
    OUTPUT_LINE raul, FBUFFER + 1810, 25
    OUTPUT_LINE teno, FBUFFER + 1980, 15
    OUTPUT_LINE finalText, FBUFFER + 2114, 42
    ret

; Pone el indicador de modo en -Insert-
global putModeI
putModeI:
    OUTPUT_LINE insert, FBUFFER + 3842, 10
    ret

; mueve el pointer y borra el ultimo char
global backSpace
backSpace:
    push ax
    call repairCursor
    mov ax, [pointer]
    UPD_POINTER -2
    mov bx, 0 | DEFCOL
    add ax, [viewStart]
    mov [input + eax], bx
    call printAll
    pop ax
    ret

;desplaza el cursor
global move
move:
    push ax
    call repairCursor
    mov ax, [pointer]
    UPD_POINTER [esp + 6]
    call printAll
    pop ax
    ret
