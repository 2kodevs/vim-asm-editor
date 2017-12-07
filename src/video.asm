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
    add esi, [pointer]
    add esi, [viewStart]
    mov ebx, [lineCounter]
    lodsw
    mov word [esi - 2], 0 | DEFCOL
    add ebx, 2
    cmp ebx, 160
    jne %%move
    xor ebx, ebx
    %%move:
        cmp ax, 0 | DEFCOL
        je %%end
        cmp ax, 255 | DEFCOL
        je %%check
        xchg ax, [esi]
        add esi, 2
        add ebx, 2
        cmp ebx, 160
        jne %%move
        xor ebx, ebx
        jmp %%move
    %%check:
        cmp ebx, 0
        jne %%end
        push eax
        push esi
        ADVANCE_TEXT [line]
        PRINT
        pop esi
        pop eax
    %%end:
        xchg [esi], ax
        mov eax, lastChar
        add eax, input
        cmp eax, esi
        jle %%ret
        mov eax, [lastChar]
        add eax, 2
        mov [lastChar], eax
    %%ret:
%endmacro

; desplaza las letras para su izquierda
%macro MOVE_ALL_LEFT 0.nolist
    mov eax, [pointer]
    add eax, [viewStart]
    cmp eax, 0
    je %%impossible
    cld
    mov ecx, 0
    mov esi, input
    add esi, eax
    mov edi, esi
    sub edi, 2
    mov ebx, [lineCounter]
    %%move:
        cmp word [esi], 0 | DEFCOL
        je %%end
        cmp word [esi], 255 | DEFCOL
        je %%check
        movsw
        add ebx, 2
        cmp ebx, 160
        jne %%move
        xor ebx, ebx
        jmp %%move
    %%check:
        mov ecx, 10
    %%end:
        movsw
        mov word [esi - 2], 0 | DEFCOL
        cmp ecx, 10
        jne %%conti
        cmp ebx, 0
        jne %%conti
        push eax
        push esi
        BACK_TEXT [line]
        PRINT
        pop esi
        pop eax
        %%conti:
        sub esi, input
        cmp esi, [lastChar]
        jne %%impossible
        sub esi, 2
        mov [lastChar], esi
    %%impossible:
%endmacro

; Ajusta todos los punteros
%macro UPD_POINTER 1.nolist
    ;mov eax, [pointer]
    ;add eax, [viewStart]
    ;cmp eax, [lastChar]
    ;jge %%real_end
    %%start:
        ; setea la linea actual
        mov eax, [lineCounter]
        add eax, %1
        mov [lineCounter], eax
        cmp eax, 0
        jl %%previousLine
        cmp eax, 160
        jge %%nextLine
        jmp %%otherPointers
        %%previousLine:
            add eax, 160
            mov [lineCounter], eax
            ; verifica no estar en la linea 0
            mov ebx, [line]
            cmp ebx, 0
            je %%otherPointers
            sub ebx, 1
            mov [line], ebx
            jmp %%otherPointers
        %%nextLine:
            mov ebx, [line]
            add ebx, 1
            mov [line], ebx
            cmp [graderLine], ebx
            jae %%conti
            mov [graderLine], ebx
            %%conti:
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

; despalza todas las lineas del texto una por una hacia abajo
%macro ADVANCE_TEXT 1.nolist
    mov eax, [graderLine]
    cmp eax, %1
    je %%end
    add eax, 1
    mov [graderLine], eax
    sub eax, 1
    mov ebx, 160
    imul ebx
    mov ecx, eax
    mov eax, %1
    imul ebx
    mov ebx, eax
    mov eax, ecx
    add eax, input
    add ebx, input
    mov edx, eax
    add edx, 160
    %%ciclo:
        cmp eax, ebx
        je %%end
        OUTPUT_LINE eax, edx, 80
        OUTPUT_LINE nullLine, eax, 80
        sub eax, 160
        sub edx, 160
        jmp %%ciclo
    %%end:
%endmacro

; despalza todas las lineas del texto una por una hacia arriba
%macro BACK_TEXT 1.nolist
    mov eax, [graderLine]
    sub eax, 1
    cmp eax, %1
    jbe %%end
    add eax, 1
    mov ebx, 160
    imul ebx
    mov ecx, eax  ; ecx = graderline x 160
    mov eax, %1
    add eax, 1
    imul ebx
    mov ebx, ecx
    add eax, input
    add ebx, input
    mov edx, eax
    add edx, 160
    %%ciclo:
        cmp eax, ebx
        je %%end
        OUTPUT_LINE edx, eax, 80
        OUTPUT_LINE nullLine, edx, 80
        add eax, 160
        add edx, 160
        jmp %%ciclo
    %%end:
%endmacro


section .data

; array donde se guarda la entrada
global input
input times 2000000 dw 0 | DEFCOL

; puntero apuntando a la inicial inicial mostrada en los BUFFERS
global viewStart
viewStart dd 0

; puntero que indica la posicion del cursor en los BUFFERS
global pointer
pointer dd 2198


line dd 0               ;linea actual
graderLine dd 0         ;mayor linea alcanzada
lineCounter dd 0        ;indicador de columna
lastChar dd 0           ;posicion del ultimo caracter
cursorColor db 0        ;indicador de estado del cursor

; textos predefinidos
text dw "P" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, "y" | DEFCOL, "e" | DEFCOL, "c" | DEFCOL, "t" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "d" | DEFCOL, "e" | DEFCOL, " " | DEFCOL, "P" | DEFCOL, "M" | DEFCOL, "I" | DEFCOL

raul dw "L" | DEFCOL, "a" | DEFCOL, "z" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "R" | DEFCOL, "a" | DEFCOL, "u" | DEFCOL, "l" | DEFCOL, " " | DEFCOL, "I" | DEFCOL, "g" | DEFCOL, "l" | DEFCOL, "e" | DEFCOL, "s" | DEFCOL, "i" | DEFCOL, "a" | DEFCOL, "s" | DEFCOL, " " | DEFCOL, "V" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, "a" | DEFCOL

teno dw "M" | DEFCOL, "i" | DEFCOL, "g" | DEFCOL, "u" | DEFCOL, "e" | DEFCOL, "l" | DEFCOL, " " | DEFCOL, "T" | DEFCOL, "e" | DEFCOL, "n" | DEFCOL, "o" | DEFCOL, "r" | DEFCOL, "i" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "P" | DEFCOL, "o" | DEFCOL, "t" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "i" | DEFCOL

finalText dw "P" | DEFCOL, "r" | DEFCOL, "e" | DEFCOL, "s" | DEFCOL, "i" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "e" | DEFCOL, " " | DEFCOL, "c" | DEFCOL, "u" | DEFCOL, "a" | DEFCOL, "l" | DEFCOL, "q" | DEFCOL, "u" | DEFCOL, "i" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, " " | DEFCOL, "t" | DEFCOL, "e" | DEFCOL, "c" | DEFCOL, "l" | DEFCOL, "a" | DEFCOL, " " | DEFCOL, "p" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "a" | DEFCOL, " " | DEFCOL, "c" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "t" | DEFCOL, "i" | DEFCOL, "n" | DEFCOL, "u" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "." | DEFCOL, "." | DEFCOL, "." | DEFCOL

insert dw "-" | DEFCOL, "-" | DEFCOL, "I" | DEFCOL, "N" | DEFCOL, "S" | DEFCOL, "E" | DEFCOL, "R" | DEFCOL, "T" | DEFCOL, "-" | DEFCOL, "-" | DEFCOL

visual dw "-" | DEFCOL, "-" | DEFCOL, "V" | DEFCOL, "I" | DEFCOL, "S" | DEFCOL, "U" | DEFCOL, "A" | DEFCOL, "L" | DEFCOL, "-" | DEFCOL, "-" | DEFCOL

normal times 10 dw 0 | DEFCOL
; linea vacia
nullLine times 80 dw 0 | DEFCOL

section .text

;extern pauseCursorForASecond
extern pauseCursor
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
    ;call pauseCursor ; Funciona delay actual:150 si quieres descomenta esta linea pero ponle 1 ms en timing
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
    xor eax, eax
    mov [cursorColor], al
    mov eax, [pointer]
    add eax, [viewStart]
    push eax
    MOVE_ALL_RIGTH
    pop eax
    mov bx, [esp + 4]
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
    mov edi, input
    mov ecx, 2000000
    mov ax, 0 | DEFCOL
    rep stosw
    ret

; Pone el indicador de modo en -Insert-
global putModeI
putModeI:
    OUTPUT_LINE insert, FBUFFER + 3842, 10
    ret

; Turn Visual mode
global putModeV
putModeV:
    OUTPUT_LINE visual, FBUFFER + 3842, 10
    ret

global putModeN
putModeN:
    OUTPUT_LINE normal, FBUFFER + 3842, 10
    ret

; Mueve el pointer y borra el ultimo char
global backSpace
backSpace:
    push eax
    call repairCursor
    mov bl, [writeMode]
    cmp bl, 1
    je .reWrite
    MOVE_ALL_LEFT
    UPD_POINTER -2
    jmp .conti
    .reWrite:
    UPD_POINTER -2
    add eax, [viewStart]
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

;pone el enter camina el cursor hasta la siguiente fila y pone el texto correctamente 
global finishLine
finishLine:
    push eax
    push ebx
    call repairCursor
    mov eax, [pointer]
    add eax, [viewStart]
    push eax
    mov edx, [line]
    .unFinish:
        push edx
        MOVE_ALL_RIGTH
        UPD_POINTER 2
        pop edx
        mov eax, [line]
        cmp edx, eax
        je .unFinish
    pop eax
    add eax, input
    mov bx, 255 | DEFCOL
    mov [eax], bx
    PRINT
    pop ebx
    pop eax
    ret