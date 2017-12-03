%include "video.mac"

; Frame buffer location
%define FBUFFER 0xB8000

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

; pinta toda la pantalla
%macro PRINT 0.nolist
    mov eax, [viewStart]
    add eax, input
    OUTPUT_LINE eax, FBUFFER, COLS*ROWS
%endmacro

; desplaza las letras para su derecha
%macro MOVE_ALL_RIGTH 0.nolist
    cld
    mov esi, input
    add esi, eax
    lodsw
    %%move:
        xchg ax, [esi]
        cmp ax, 0 | DEFCOL
        je %%end
        cmp ax, 10 | DEFCOL
        je %%end
        add esi, 2
        jmp %%move
    %%end:
        add esi, 2
        mov [esi], ax
        mov eax, lastChar
        add eax, input
        cmp eax, esi
        jnl %%ret
        sub esi, input
        mov [lastChar], esi
    %%ret:
%endmacro

; desplaza las letras para su izquierda
%macro MOVE_ALL_LEFT 0.nolist
    cmp eax, 0
    je %%impossible
    cld
    mov esi, input
    add esi, eax
    mov edi, esi
    sub edi, 2
    %%move:
        movsw
        cmp dword [esi], 0 | DEFCOL
        je %%end
        cmp dword [esi], 10 | DEFCOL
        je %%end
        jmp %%move
    %%end:
        movsw
        sub esi, input
        cmp esi, [lastChar]
        jne %%impossible
        sub esi, 2
        mov [lastChar], esi
    %%impossible:
%endmacro

; Ajusta todos los punteros
%macro UPD_POINTER 1.nolist
    ; setea la linea actual
    mov eax, [lineCounter]
    add eax, %1
    cmp eax, 0
    jl %%previousLine
    cmp eax, 160
    jge %%nextLine
    jmp %%otherPointers
    %%previousLine:
        ; verifica no estar en la linea 0
        mov ebx, [line]
        cmp ebx, 0
        je %%otherPointers
        sub ebx, 1
        mov [line], ebx
        add eax, 160
        mov [lineCounter], eax
        jmp %%otherPointers
    %%nextLine:
        mov ebx, [line]
        add ebx, 1
        mov [line], ebx
        sub eax, 160
        mov [lineCounter], eax
    %%otherPointers:
        mov eax, [pointer]
        mov ebx, [viewStart]
        ; adiciona el incremento del puntero
        add eax, %1
        cmp eax, 0
        jl %%down_adjust
        cmp eax, 3838
        ja %%up_adjust
        jmp %%end
        %%down_adjust:
            cmp ebx, 0
            je %%real_end
            add eax, 160
            sub ebx, 160
            jmp %%end
        %%up_adjust:
            sub eax, 160
            add ebx, 160
            jmp %%end
    %%end:
        mov [pointer], eax
        mov [viewStart], ebx
    %%real_end:
%endmacro

section .data

global input
input times 2000000 dw 0 | DEFCOL

global viewStart
viewStart dd 0

global pointer
pointer dd 2198

line dd 0
lineCounter dd 0

lastChar dd 0
cursorColor db 0
text dw "P" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, "y" | DEFCOL, "e" | DEFCOL, "c" | DEFCOL, "t" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "d" | DEFCOL, "e" | DEFCOL, " " | DEFCOL, "P" | DEFCOL, "M" | DEFCOL, "I" | DEFCOL
raul dw "L" | DEFCOL, "a" | DEFCOL, "z" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "R" | DEFCOL, "a" | DEFCOL, "u" | DEFCOL, "l" | DEFCOL, " " | DEFCOL, "I" | DEFCOL, "g" | DEFCOL, "l" | DEFCOL, "e" | DEFCOL, "s" | DEFCOL, "i" | DEFCOL, "a" | DEFCOL, "s" | DEFCOL, " " | DEFCOL, "V" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, "a" | DEFCOL
teno dw "M" | DEFCOL, "i" | DEFCOL, "g" | DEFCOL, "u" | DEFCOL, "e" | DEFCOL, "l" | DEFCOL, " " | DEFCOL, "T" | DEFCOL, "e" | DEFCOL, "n" | DEFCOL, "o" | DEFCOL, "r" | DEFCOL, "i" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "P" | DEFCOL, "o" | DEFCOL, "t" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "i" | DEFCOL
finalText dw "P" | DEFCOL, "r" | DEFCOL, "e" | DEFCOL, "s" | DEFCOL, "i" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "e" | DEFCOL, " " | DEFCOL, "c" | DEFCOL, "u" | DEFCOL, "a" | DEFCOL, "l" | DEFCOL, "q" | DEFCOL, "u" | DEFCOL, "i" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, " " | DEFCOL, "t" | DEFCOL, "e" | DEFCOL, "c" | DEFCOL, "l" | DEFCOL, "a" | DEFCOL, " " | DEFCOL, "p" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "a" | DEFCOL, " " | DEFCOL, "c" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "t" | DEFCOL, "i" | DEFCOL, "n" | DEFCOL, "u" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "." | DEFCOL, "." | DEFCOL, "." | DEFCOL
insert dw "-" | DEFCOL, "-" | DEFCOL, "I" | DEFCOL, "N" | DEFCOL, "S" | DEFCOL, "E" | DEFCOL, "R" | DEFCOL, "T" | DEFCOL, "-" | DEFCOL, "-" | DEFCOL

section .text

extern pauseFor
extern writeMode 

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
    mov eax, [pointer]
    mov bx, [FBUFFER + eax]
    mov cl, 4
    rol bh, cl 
    mov [FBUFFER + eax], bx
    ret

; arregla el posible cambio de coloracion provocado por el cursor
repairCursor:
    push eax
    mov al, [cursorColor]
    cmp al, 0
    je .end
    call cursor
    .end:
    pop eax
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
    mov eax, [pointer]
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
    mov eax, [pointer]
    add eax, [viewStart]
    ; escribe en el texto + la posicion inicial actual + el cursor
    mov [input + eax], bx
    ; actualiza el valor de la posicion dl ultimo char
    cmp eax, [lastChar]
    jbe .conti
    mov [lastChar], eax
    .conti:
    mov eax, [pointer]
    UPD_POINTER 2
    PRINT
    ret

; escribe en el array donde es guardado el texto y manda a pintar
global nonReWrite
nonReWrite:
    xor ebx, ebx
    mov bx, [esp + 4]
    xor eax, eax
    mov [cursorColor], al
    mov eax, [pointer]
    add eax, [viewStart]
    push eax
    MOVE_ALL_RIGTH
    pop eax
    ; escribe en el texto + la posicion inicial actual + el cursor
    mov [input + eax], bx
    ; actualiza el valor de la posicion dl ultimo char
    cmp eax, [lastChar]
    jbe .conti
    mov [lastChar], eax
    .conti:
    mov eax, [pointer]
    UPD_POINTER 2
    PRINT
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
    push eax
    call repairCursor
    mov eax, [pointer]
    mov bl, [writeMode]
    cmp bl, 1
    je .reWrite
    MOVE_ALL_LEFT
    UPD_POINTER -2
    jmp .conti
    .reWrite:
    UPD_POINTER -2
    mov bx, 0 | DEFCOL
    add eax, [viewStart]
    mov [input + eax], bx
    .conti:
    PRINT
    pop eax
    ret

;desplaza el cursor
global move
move:
    push eax
    call repairCursor
    mov eax, [pointer]
    UPD_POINTER [esp + 8]
    PRINT
    pop eax
    ret

;desplaza el cursor
global finishLine
finishLine:
    push eax
    push ebx
    call repairCursor
    mov ecx, [line]
    .unFinish:
        MOVE_ALL_RIGTH
        UPD_POINTER 2
        mov eax, [line]
        cmp ecx, eax
        je .unFinish
    mov bx, 32 | DEFCOL
    mov eax, [pointer]
    add eax, [viewStart]
    mov [input + eax], bx
    pop ebx
    pop eax
    ret