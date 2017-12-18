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

; Draw text of one array to another
; OUTPUT_LINE(dword source, dword target, dword length)
%macro OUTPUT_LINE 3.nolist
    cld
    mov esi, %1
    mov edi, %2
    mov ecx, %3
    rep movsw
%endmacro

; Paint screen
%macro PRINT 0.nolist
    mov eax, [viewStart]
    add eax, input
    OUTPUT_LINE eax, FBUFFER, COLS*ROWS
%endmacro

; Push text to the right
%macro MOVE_ALL_RIGHT 0.nolist
    cld
    mov esi, input
    add esi, [pointer]
    add esi, [viewStart]
    mov ebx, [lineCounter]
    lodsw
    mov word [esi - 2], NULL
    add ebx, 2
    cmp ebx, 160
    jne %%move
    xor ebx, ebx
    %%move:
        cmp ax, NULL
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

; Push text to the left
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
    push word [edi]
    mov ebx, [lineCounter]
    %%move:
        cmp word [esi], NULL
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
        sub esi, 2
        mov word [esi], NULL
        cmp ecx, 10
        jne %%conti
        cmp ebx, 0
        jne %%conti
        push eax
        push esi
        BACK_TEXT [temp]
        PRINT
        pop esi
        pop eax
        %%conti:
        sub esi, input
        cmp esi, [lastChar]
        jne %%fin
        sub esi, 2
        mov [lastChar], esi
    %%fin:
        pop ax
        cmp ax, NULL
        jne %%impossible
        mov edx, 1
    %%impossible:
%endmacro

; Move cursor to next nonempty char in the given direction
; FORWARD(dword direction)
%macro FORWARD 1.nolist
    xor edx, edx
    UPD_POINTER %1
    cmp edx, 1
    je %%end
    mov edx, %1 
    cmp edx, 2
    jne %%conti
    ; caso 1 : moverse hacia -->
    mov eax, [line] 
    inc eax
    mov ecx, 160
    imul ecx
    add eax, input
    cmp word [eax], NULL
    je %%end
    mov edx, 160
    sub edx, [lineCounter]
    mov [temp], edx
    UPD_POINTER [temp]
    jmp %%end  
    %%conti:             
    ; caso 2 : moverse en cualquier otra direction
    mov edx, %1
    cmp edx, 160
    jne %%ok
    mov eax, [line] 
    inc eax
    mov ecx, 160
    imul ecx
    add eax, input
    cmp word [eax], NULL
    je %%end
    %%ok:
    mov edx, %1
    mov eax, [pointer] 
    add eax, [viewStart] 
    add eax, input 
    add eax, edx
    %%lop:
        cmp word [eax], NULL
        jne %%endLoop
        add edx, -2
        add eax, -2
        jmp %%lop
    %%endLoop:
    
    mov [temp], edx
    UPD_POINTER [temp]
    %%end: 
%endmacro 

; Update all pointers to the new position
; UPD_POINTER(dword advance)
%macro UPD_POINTER 1.nolist
    mov eax, [pointer]
    add eax, [viewStart]
    add eax, input
    add eax, %1
    cmp eax, input
    jb %%real_end
    cmp word [eax], NULL
    je %%real_end
    mov edx, 1    ; para verificar si hubo movimiento
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
            cmp [greaterLine], ebx
            jae %%conti
            mov [greaterLine], ebx
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

; Move down the text forward to the given line
; ADVANCE_TEXT(dword line)
%macro ADVANCE_TEXT 1.nolist
    mov eax, [greaterLine]
    cmp eax, %1
    je %%end
    add eax, 1
    mov [greaterLine], eax
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

; Move up the text forward to the given line
; BACK_TEXT(dword line)
%macro BACK_TEXT 1.nolist
    mov eax, [greaterLine]
    sub eax, 1
    cmp eax, %1
    jbe %%end
    add eax, 1
    mov ebx, 160
    imul ebx
    mov ecx, eax  ; ecx = greaterline x 160
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

; Set default color on the screen
%macro SCREEN_COLOR 0.nolist
    cld
    mov esi, input
    add esi, [viewStart]
    mov ecx, esi
    add ecx, 3838
    .paintAll:
        lodsw
        mov bl, al
        mov ax, DEFCOL
        mov al, bl
        mov [esi - 2], ax
        cmp esi, ecx
        jbe .paintAll
%endmacro

; Move information of the one memory direction to another
; CHANGE_MEM(dword source, dword target)
%macro CHANGE_MEM 2.nolist
    mov esi, %1
    mov edi, %2
    movsd
%endmacro

; Put in "ecx" the length of the string
; LENGTH_OF(dword string)
%macro LENGTH_OF 1.nolist
    xor ecx, ecx
    mov esi, %1
    %%while: 
    lodsw
    cmp ax, NULL
    je %%end
    add ecx, 2
    %%end:
%endmacro

; Not used
%macro CANTOFCHAR 0.nolist
    push esi
    push eax
    push ebx
    xor ecx, ecx
    mov esi, input
    xor ebx, ebx
    xor edx, edx
    cld
    %%while:
        lodsw
        add bx, 2
        cmp ax, NULL
        jne %%continue
        cmp bx, 160
        je %%update
        add esi, 160
        sub esi, ebx
    %%update:
        inc edx
        mov bx, [esi]
        cmp bx, NULL
        je %%end
        xor bx, bx
        jmp %%while
    %%continue:
        add ecx, 2
        jmp %%while
    %%end:
    mov dword [inputLen], ecx
    pop ebx
    pop eax
    pop esi
%endmacro

section .data

; input array
global input
input times 2000000 dw NULL
previousInput times 2000000 dw NULL

; clipboard
trash times 2000000 dw 0

; pi Array (used in KMP)
pi times 2000000 dw 0

; INSERT SCOPE
; pointer that contain the direction of the first char in view
global viewStart
viewStart dd 0

; position of the cursor
global pointer
pointer dd 2188

line dd 0               ; actual line
greaterLine dd 0        ; greater line reached
lineCounter dd 0        ; column pointer
lastChar dd 0           ; position of the last char
cursorColor db 0        ; store the cursor state
temp dd 0

; Undo support
global linealAction
linealAction db 0
; pointers copies
cpVStart dd 0 
cpPointer dd 0 
cpLine dd 0 
cpGLine dd 0 
cpLCounter dd 0 
cpLChar dd 0 
cpCColor dd 0 

; VISUAL SCOPE
posStart dd 0           ; safe the position which what was entered in visual mode
lineStart dd 0          ; safe the line which what was entered in visual mode

global mVisual
mVisual db 0            ; type of visual mode

copieMode db 0          ; type of visual mode copie
textStart dd 0          ; first char of the selected text
len dd 0                ; lenght of the last selected text
realLen dd 0            ; lenght of the last copied text

; defaut texts
text dw "P" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, "y" | DEFCOL, "e" | DEFCOL, "c" | DEFCOL, "t" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "d" | DEFCOL, "e" | DEFCOL, " " | DEFCOL, "P" | DEFCOL, "M" | DEFCOL, "I" | DEFCOL

raul dw "L" | DEFCOL, "a" | DEFCOL, "z" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "R" | DEFCOL, "a" | DEFCOL, "u" | DEFCOL, "l" | DEFCOL, " " | DEFCOL, "I" | DEFCOL, "g" | DEFCOL, "l" | DEFCOL, "e" | DEFCOL, "s" | DEFCOL, "i" | DEFCOL, "a" | DEFCOL, "s" | DEFCOL, " " | DEFCOL, "V" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, "a" | DEFCOL

teno dw "M" | DEFCOL, "i" | DEFCOL, "g" | DEFCOL, "u" | DEFCOL, "e" | DEFCOL, "l" | DEFCOL, " " | DEFCOL, "T" | DEFCOL, "e" | DEFCOL, "n" | DEFCOL, "o" | DEFCOL, "r" | DEFCOL, "i" | DEFCOL, "o" | DEFCOL, " " | DEFCOL, "P" | DEFCOL, "o" | DEFCOL, "t" | DEFCOL, "r" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "y" | DEFCOL

finalText dw "P" | DEFCOL, "r" | DEFCOL, "e" | DEFCOL, "s" | DEFCOL, "i" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "e" | DEFCOL, " " | DEFCOL, "e" | DEFCOL, "n" | DEFCOL, "t" | DEFCOL, "e" | DEFCOL, "r" | DEFCOL, " " | DEFCOL, "p" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "a" | DEFCOL, " " | DEFCOL, "c" | DEFCOL, "o" | DEFCOL, "n" | DEFCOL, "t" | DEFCOL, "i" | DEFCOL, "n" | DEFCOL, "u" | DEFCOL, "a" | DEFCOL, "r" | DEFCOL, "." | DEFCOL, "." | DEFCOL, "." | DEFCOL

insert dw "-" | DEFCOL, "-" | DEFCOL, "I" | DEFCOL, "N" | DEFCOL, "S" | DEFCOL, "E" | DEFCOL, "R" | DEFCOL, "T" | DEFCOL, "-" | DEFCOL, "-" | DEFCOL

replace dw "-" | DEFCOL, "-" | DEFCOL, "R" | DEFCOL, "E" | DEFCOL, "P" | DEFCOL, "L" | DEFCOL, "A" | DEFCOL, "C" | DEFCOL, "E" | DEFCOL, "-" | DEFCOL, "-" | DEFCOL

visual dw "-" | DEFCOL, "-" | DEFCOL, "V" | DEFCOL, "I" | DEFCOL, "S" | DEFCOL, "U" | DEFCOL, "A" | DEFCOL, "L" | DEFCOL, "-" | DEFCOL, "-" | DEFCOL

visualLine dw "-" | DEFCOL, "-" | DEFCOL, "V" | DEFCOL, "I" | DEFCOL, "S" | DEFCOL, "U" | DEFCOL, "A" | DEFCOL, "L" | DEFCOL, " " | DEFCOL, "L" | DEFCOL, "I" | DEFCOL, "N" | DEFCOL, "E" | DEFCOL, "-" | DEFCOL, "-" | DEFCOL

cmdLine dw "/" | DEFCOL
modesNames dd insert, replace, visual, visualLine, nullLine, cmdLine
lengths dd 10, 11, 10, 15, 0, 1

; empty line
nullLine times 80 dw NULL

; funtions
global writeTools
writeTools dd write, replaceWrite

; KMP's variables
paternLen dd 0
inputLen dd 0
tempKMP dw 0
matches times 2000000 dd 0
startLen dd 0

section .text

extern writeMode 
extern capsLockButton
extern shift
extern control
extern readNumber

; Clear the screen by filling it with char and attributes.
; clear(byte char, byte attrs)
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

; blink cursor
global cursor
cursor:
    mov al, [cursorColor]
    xor al, 1
    mov [cursorColor], al
    mov eax, [pointer]
    mov bx, [FBUFFER + eax]
    mov cl, 4
    rol bh, cl 
    mov [FBUFFER + eax], bx
    ret

; fix the cursor color
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

; Write in replace mode
; replaceWrite(word char)
global replaceWrite
replaceWrite:
    call action
    xor ebx, ebx
    mov bx, [esp + 4]
    xor eax, eax
    mov [cursorColor], al
    mov eax, [pointer]
    add eax, [viewStart]
    cmp word [input + eax], 255 | DEFCOL
    jne .no_enter
    push eax
    push ebx
    MOVE_ALL_RIGHT
    pop ebx
    pop eax
    .no_enter:
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

; Write in default writing mode
; replaceWrite(word char)
global write
write:
    call action
    xor ebx, ebx
    xor eax, eax
    mov [cursorColor], al
    mov eax, [pointer]
    add eax, [viewStart]
    push eax
    MOVE_ALL_RIGHT
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

; show presentation
global start
start:
    OUTPUT_LINE text, FBUFFER + 1660, 15
    OUTPUT_LINE raul, FBUFFER + 1810, 25
    OUTPUT_LINE teno, FBUFFER + 1974, 22
    OUTPUT_LINE finalText, FBUFFER + 2124, 32
    mov edi, input
    mov ecx, 2000000
    mov ax, NULL
    cld
    rep stosw
    mov eax, 0
    mov [viewStart], eax
    mov [line], eax
    mov [lineCounter], eax
    mov [lastChar], eax
    mov [greaterLine], eax
    mov [cursorColor], al
    mov [writeMode], al
    mov [capsLockButton], al
    mov [len], eax
    mov eax, input
    mov word [eax], 255 | DEFCOL
    ret

;  write the name of the actual mode
; putName(dword index)
global putName
putName:
    OUTPUT_LINE nullLine, FBUFFER + 3842, 15
    mov eax, [esp + 4]
    mov cl, 2
    shl eax, cl
    OUTPUT_LINE [modesNames + eax], FBUFFER + 3842, [lengths + eax]
    ret 4
; delete previous char
global backSpace
backSpace:
    push eax
    call action
    call repairCursor
    mov eax, [line]
    dec eax
    mov [temp], eax
    .repeat:
    xor edx, edx
    MOVE_ALL_LEFT
    push edx
    UPD_POINTER -2
    pop edx
    cmp edx, 1
    je .repeat
    PRINT
    pop eax
    ret

; move the cursor
; move(dword direction)
global move
move:
    push eax
    mov al, 1
    mov [linealAction], al
    call repairCursor
    mov eax, [pointer]
    FORWARD [esp + 8]
    PRINT
    pop eax
    ret
; delete next char
global delete
delete:
    push eax
    call action
    call repairCursor
    mov edx, 0
    UPD_POINTER 2
    cmp edx, 0
    je .no
    MOVE_ALL_LEFT
    UPD_POINTER -2
    PRINT
    jmp .ok
    .no:
    mov eax, [pointer]
    add eax, [viewStart]
    add eax, input
    cmp word [eax], 255 | DEFCOL
    jne .ok
    mov ecx, 160
    sub ecx, [lineCounter]
    mov [temp], ecx
    UPD_POINTER [temp]
    call backSpace
    .ok:
    call action
    pop eax
    ret
; put an "Enter" caracter and adjust line
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
        MOVE_ALL_RIGHT
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
    call action
    pop ebx
    pop eax
    ret

; initialize Visual mode
global initializeVisual
initializeVisual:
    mov eax, [pointer]
    add eax, [viewStart]
    add eax, input
    mov [posStart], eax
    mov eax, [line]
    mov [lineStart], eax
    xor eax, eax
    push eax
    call setSelection
    add esp, 4
    ret

; put default color on all the screen
global restoreScreen
restoreScreen:
    SCREEN_COLOR 
    PRINT
    ret

; Paint the selected text
global setSelection
setSelection:
    ; limpia los cambios de coloracion
    SCREEN_COLOR
    cld
    push dword [esp + 4]
    call move
    add esp, 4
    ; verifica el modo
    mov al, [mVisual]
    cmp al, 0
    jne .line
    mov esi, [posStart]  ; posicion inicial
    mov [textStart], esi
    mov ecx, [pointer]
    add ecx, [viewStart]
    add ecx, input
    cmp ecx, [posStart]  ; posicion del cursor
    je .fin
    cmp esi, ecx
    jb .setMark
    xchg ecx, esi
    mov [textStart], esi
    jmp .setMark
    .line:
        mov eax, [lineStart]
        mov ebx, 160
        imul ebx
        mov esi, eax            ; linea inicial
        mov eax, [line]
        imul ebx
        mov edx, [lineStart]    ; linea final
        cmp edx, [line]
        jbe .ready         
        xchg esi, eax
        .ready:
        add eax, 158
        mov ecx, eax
        add esi, input
        add ecx, input
        xor ebx, ebx
        mov [textStart], esi
    .setMark:
        push ebx
        lodsw
        cmp ax, NULL
        je .noPaint
        mov bl, al
        mov ax, VISUALCOL
        mov al, bl
        mov [esi - 2], ax
        .noPaint:
        pop ebx
        inc ebx
        cmp esi, ecx
        jbe .setMark
    .fin:
    mov [len], ebx
    ; ajustar el color del cursor
    mov eax, [pointer]
    add eax, [viewStart]
    add eax, input
    mov bx, [eax]
    mov cl, bl
    mov bx, DEFCOL
    mov bl, cl
    mov [eax], bx
    PRINT
    ret 

; Copy the selected text
global yank
yank:
    mov cl, [mVisual]
    mov [copieMode], cl
    mov ecx, [len]
    mov [realLen], ecx
    SCREEN_COLOR
    OUTPUT_LINE [textStart], trash, [realLen]
    ret

; Copy the selected text
global paste
paste:
    call safe
    call repairCursor
    UPD_POINTER 2
    mov al, [copieMode]
    cmp al, 0
    je .conti
    ADVANCE_TEXT [line]
    mov eax, [line]
    inc eax
    mov ebx, 160
    xor edx, edx
    imul ebx
    sub ebx, [lineCounter]
    add eax, input
    mov word [eax], 255 | DEFCOL
    mov [temp], ebx
    UPD_POINTER [temp]
    .conti:
    push dword [pointer]
    push dword [viewStart]
    push dword [line]
    push dword [lineCounter]
    mov ecx, [realLen]
    cld
    mov esi, trash
    .copieText:
        cmp ecx, 0
        je .end
        dec ecx
        lodsw
        cmp ax, NULL
        je .copieText
        push esi
        push ecx
        cmp ax, 255 | DEFCOL
        je .Enter
        xor ebx, ebx
        mov bl, [writeMode]
        mov cl, 2
        shl ebx, cl
        push ax
        call [writeTools + ebx]
        add esp, 2
        jmp .pops
        .Enter:
            call finishLine
        .pops:
        pop ecx
        pop esi
        jmp .copieText
    .end:
    mov al, [copieMode]
    cmp al, 0
    je .adjust_pointers
    call backSpace
    .adjust_pointers:
        pop dword [lineCounter]
        pop dword [line]
        pop dword [viewStart]
        pop dword [pointer]   
    mov al, [copieMode]
    cmp al, 0
    je .conti2
    mov eax, [pointer]
    add eax, [viewStart]
    add eax, input
    sub eax, 160
    mov ebx, -2
    .for:
    add ebx, 2
    cmp ebx, 160
    je .conti2
    cmp word [eax], 255 | DEFCOL
    je .conti2
    cmp word [eax], NULL
    jne .for
    mov word [eax], 255 | DEFCOL
    .conti2:
    mov al, 1
    mov [linealAction], al
    ret

; restart the application
global reboot
reboot:
    xor eax, eax
    mov [temp], eax
    mov [posStart], eax
    mov [lineStart], eax
    mov [mVisual], al
    mov [len], eax
    mov [textStart], eax
    mov [realLen], eax
    mov [shift], al
    mov [control], al
    mov eax, 2188
    mov [pointer], eax
    ret

; Ctrl + y
global cYank
cYank:
    push eax
    xor eax, eax
    cmp [line], eax
    je .fin
    mov eax, [viewStart]
    add eax, [pointer]
    add eax, input
    sub eax, 160
    mov bx, [eax]
    cmp bx, NULL
    je .fin
    cmp bx, 255 | DEFCOL
    je .fin
    push bx
    call write
    pop bx
    .fin:
    pop eax
    ret

; new action
action:
    mov al, [linealAction]
    cmp al, 0
    je .ret
    call safe
    .ret:
    ret
; safe screen
global safe
safe:
    OUTPUT_LINE input, previousInput, 2000000
    CHANGE_MEM pointer, cpPointer
    CHANGE_MEM viewStart, cpVStart
    CHANGE_MEM lastChar, cpLChar
    CHANGE_MEM line, cpLine
    CHANGE_MEM lineCounter, cpLCounter
    CHANGE_MEM greaterLine, cpGLine
    CHANGE_MEM cursorColor, cpCColor
    xor al, al
    mov [linealAction], al
    ret
; recover screen
global undo
undo:
    OUTPUT_LINE previousInput, input, 2000000
    CHANGE_MEM cpPointer, pointer 
    CHANGE_MEM cpVStart, viewStart
    CHANGE_MEM cpLChar, lastChar
    CHANGE_MEM cpLine, line
    CHANGE_MEM cpLCounter, lineCounter
    CHANGE_MEM cpGLine, greaterLine
    CHANGE_MEM cpCColor,  cursorColor
    PRINT
    ret


; move to the top of the screen
global jumpTop
jumpTop:
    push eax
    xor eax, eax
    mov [pointer], eax
    mov [viewStart], eax
    mov [lineCounter], eax
    mov [line], eax
    PRINT
    pop eax
    ret   

; move to a specific line of the screen
global jumpAt
jumpAt:
    call supportJump
    mov eax, [line]
    cmp eax, [esp + 4]
    je .end
    jb .less
    .greater:
    UPD_POINTER -160
    mov edx, [line]
    cmp edx, [esp + 4]
    je .end
    jmp .greater
    .less:
        xor edx, edx
        UPD_POINTER 160
        cmp edx, 0
        je .end
        mov edx, [line]
        cmp edx, [esp + 4]
        je .end
        jmp .less
    .end:
    PRINT
    ret 4

supportJump:
    cmp dword [lineCounter], 0
    je .ret
    UPD_POINTER -2
    jmp supportJump
    .ret:
    ret
   

; move to the bottom of the screen
global jumpBot
jumpBot:
   call supportJump
   xor edx, edx
   UPD_POINTER 160
   cmp edx, 0
   jne jumpBot
   PRINT
   ret

; compute prefix function for KMP
prefixFunction:
    push ebp
    mov ebp, esp
    LENGTH_OF [esp + 8]
    mov [paternLen], ecx
    push bx
    push esi
    push edi
    mov esi, [esp + 8] ; a
    mov edi, pi
    mov bx, -1 ; k
    .for:
        .while:
            cmp bx, -1  ; k > -1
            jna .continue
            mov ax, [esi]   ; a[k + 1] != a[i]
            add ax, bx
            inc ax
            cmp ax, [esi + ecx]     
            je .continue
            add bx, [pi] ; k = pi[k]
            jmp .while
        .continue:
        inc bx ; k++
        mov [pi + ecx], bx
        dec ecx
        cmp ecx, 0
        je .ret
        jmp .for
    .ret:
    pop edi
    pop esi
    pop bx
    pop ebp
    ret

;[esp + 4] ip string patern
global KMP
KMP:
    push word [esp + 4]
    call prefixFunction
    push esi
    mov esi, [esp + 4]
    push eax
    push ebx
    push edx
   ; mov edx, [paternLen]
    ;CANTOFCHAR   ; inputLen = input.Length
    xor ebx, ebx
    mov bx, -1   ; k 
    mov ecx, [startLen]
    mov esi, matches
    cld
    .for:
        .while:
           cmp bx, -1   ; k > -1
           jna .continue
           mov ax, [esi]
           add ax, bx
           inc ax
           mov dx, ax
           mov eax, [viewStart]
           add eax, input
           add eax, ecx
           cmp word [eax], dx  ; p[k + 1] != t[i]
           je .continue
           add bx, [pi] ; k = pi[k]
           jmp .while
        .continue:
        inc bx
        cmp ebx, [paternLen]
        jne .continue2
        add bx, [pi] ; k = pi[k]
        ;Action
        sub ecx, [paternLen]
        mov [esi], ecx
        add ecx, [paternLen]
        add esi, 4
        ;
        ;
        .continue2:
        add ecx, 2
        cmp ecx, [inputLen]
        jb .for
    pop edx
    pop ebx
    pop eax
    pop esi
    ret

; set inputLen to the bottom of the input
setInputLen:
    push dword [lineCounter]
    push dword [line]
    call jumpBot
    push dword [line]
    pop dword [inputLen] 
    .while:
        xor edx, edx
        UPD_POINTER 2
        cmp edx, 0
        je .ret
        jmp .while
        .ret:
        xor edx, edx
        mov eax, [inputLen]
        mov ebx, 160
        imul ebx
        add eax, [lineCounter]
        mov [inputLen], eax
        call jumpAt
        UPD_POINTER [esp]
        ret 4
    