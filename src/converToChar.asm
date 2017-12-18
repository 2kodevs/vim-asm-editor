%include "keyboard.mac"
%include "video.mac"

; cambia a letra Mayuscula
%macro TO_UPPER 0.nolist
    cmp byte [capsLockButton], 1
    je %%next
    cmp byte [shift], 0
    je %%end
    %%next:
    add bh, 32
    %%end:
%endmacro
section .data

numbs dd 0, 9, 8, 7, 6, 5, 4, 3, 2, 1
characters db "`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\", "a", "s", "d", "f", "g", "h", "j", "k", "l", 59, 96, "z", "x", "c", "v", "b", "n", "m", ",", ".", "/", " "
uppers db "~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}", "|", "A", "S", "D", "F", "G", "H", "J", "K", "L", ":", 34, "Z", "X", "C", "V", "B", "N", "M", "<", ">", "?", " "
keys db KEY.Aprox, KEY.1, KEY.2, KEY.3, KEY.4, KEY.5, KEY.6, KEY.7, KEY.8, KEY.9, KEY.0, KEY.Script, KEY.Equal, KEY.Q, KEY.W, KEY.E, KEY.R, KEY.T, KEY.Y, KEY.U, KEY.I, KEY.O, KEY.P, KEY.OpenSquare, KEY.ClosedSquare, KEY.Back_Slash, KEY.A, KEY.S, KEY.D, KEY.F, KEY.G, KEY.H, KEY.J, KEY.K, KEY.L, KEY.Two_Dots, KEY.Quotes, KEY.Z, KEY.X, KEY.C, KEY.V, KEY.B, KEY.N, KEY.M, KEY.Comma, KEY.Dot, KEY.Slash, KEY.Spc

global capsLockButton
capsLockButton db 0

global shift
shift db 0

global control
control db 0

global doubleG
doubleG db 0

global writeMode
writeMode db 0

; 1 if a action was done otherwise 0
global actioned
actioned db 0

global readNumber
readNumber dd 0

global numberController
numberController db 0

section .text

extern backSpace
extern pointer
extern move
extern finishLine
extern setSelection
extern delete
extern mVisual
extern paste
extern yank
extern cYank
extern jumpTop
extern jumpAt
extern jumpBot
extern reboot

; toma decisiones en modo normal
global normalActions
normalActions:
    cmp al, 0xA2
    je .ret
    cmp al, 0x82
    jae .check#
    jmp .next
    .check#:
    cmp al, 0x8B
    jbe .ret
    .next:
    cmp al, KEY.LeftSHF
    je .ret
    cmp al, KEY.G
    jne .not_G
    mov byte [actioned], 0
    mov al, [capsLockButton] ; comprobar si la mayuscula esta presionada
    xor al, [shift]  
    cmp al, 1
    jne .GG
    mov al, [numberController]
    cmp al, 1
    jne .shiftG
    mov eax, [readNumber]   
    push eax
    call jumpAt
    mov byte [readNumber], 0
    mov byte [numberController], 0
    mov byte [doubleG], 0
    jmp .ret
    .shiftG:                
    call jumpBot
    mov byte [doubleG], 0
    jmp .ret
    .GG:
    inc byte [doubleG]
    mov bl, [doubleG]              
    cmp bl, 2
    jne .ret               
    call jumpTop
    mov byte [doubleG], 0
    jmp .ret
    .not_G:
    mov byte [doubleG], 0


    cmp al, KEY.0
    ja .not_number
    cmp al, KEY.1
    jb .not_number
    mov byte [actioned], 1
    mov cl, 1
    mov [numberController], cl
    mov ecx, 11
    mov edi, keys
    cld
    repne scasb
    inc ecx
    mov esi, numbs
    rep lodsd
    xor ebx, ebx
    mov ecx, eax
    mov ebx, [readNumber]
    mov eax, 10
    xor edx, edx
    imul ebx
    add eax, ecx
    mov [readNumber], eax
    jmp .ret
    .not_number:
    mov dword [readNumber], 0
    mov byte [numberController], 0
    cmp al, KEY.LEFT
    jne .not_left
    mov ebx, -2
    push ebx
    call move 
    mov bl, 1
    mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_left:
    cmp al, KEY.RIGHT
    jne .not_right
    mov ebx, 2
    push ebx
    call move
    mov bl, 1
    mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_right:
    cmp al, KEY.UP
    jne .not_up
    mov ebx, -160
    push ebx
    call move
    mov bl, 1
    mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_up:
    cmp al, KEY.DOWN
    jne .not_down
    mov ebx, 160
    push ebx
    call move
    mov bl, 1
    mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_down:
    cmp al, KEY.P
    jne .not_p
    call paste
    mov bl, 1
    mov [actioned], bl
    .not_p:
       
    .ret:
    ; Para interrumpir los comandos de doble letra
    ;mov bl, [actioned]
    ;cmp bl, 1
    ;jne .final
    ;xor bl, bl
    ;mov [doubleG], bl
    ;mov [readNumber], bl
    ;.final:
    ;.ret:
    ret
; toma decisiones en modo visual
global visualActions
visualActions:
    cmp al, KEY.LEFT
    jne .not_left
    mov ebx, -2
    push ebx
    call setSelection
   ; mov bl, 1
    ;mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_left:
    cmp al, KEY.RIGHT
    jne .not_right
    mov ebx, 2
    push ebx
    call setSelection
    ;mov bl, 1
    ;mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_right:
    cmp al, KEY.UP
    jne .not_up
    mov ebx, -160
    push ebx
    call setSelection
    ;mov bl, 1
    ;mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_up:
    cmp al, KEY.DOWN
    jne .not_down
    mov ebx, 160
    push ebx
    call setSelection
    ;mov bl, 1
    ;mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_down:
    cmp al, KEY.CapsLock
    jne .not_capslock
    mov bl, [capsLockButton]
    xor bl, 1
    mov [capsLockButton], bl
    mov bl, [mVisual]
    xor bl, 1
    mov [mVisual], bl
    xor ebx, ebx
    push ebx
    call setSelection
    ;mov bl, 1
    ;mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_capslock:
    cmp al, KEY.Y
    jne .not_y
    call yank
    ;mov bl, 1
    ;mov [actioned], bl
    .not_y:
    ;xor bx, bx
    ;mov [actioned], bl
    .ret:
    ; Para interrumpir los comandos de doble letra
    ;mov bl, [actioned]
    ;cmp bl, 1
    ;jne .final
    ;xor bl, bl
    ;mov [doubleG], bl
    ;.final:
    ret
; con inst de cadena, deja en bx el caracter
global convert2
convert2:
    push ax
    xor ebx, ebx
    mov ax, [esp + 6]
    cmp al, KEY.Y
    jne .continue
    mov bx, 1
    cmp bx, [control]
    jne .continue
    call cYank
    mov bx, 0 | DEFCOL
    jmp .ret
    .continue:  
    mov edi, keys
    mov cl, 48
    cld
    repne scasb
    mov bl, 48
    sub bl, cl
    dec bl
    cmp al, [keys + ebx]
    jne .noVisibleChar
    inc bl
    mov cl, bl ; porque bl contiene las repeticiones
    mov dl, [capsLockButton] 
    mov bl, [shift]
    xor bl, dl
    cmp bl , 1
    je .up
    mov esi, characters
    jmp .conti
    .up:
    mov esi, uppers
    .conti:
    rep lodsb
    mov bx, DEFCOL
    mov bl, al
    jmp .ret
    .noVisibleChar:
        cmp al, KEY.numDel
        jne .not_nd
        call delete
        mov bx, 0 | DEFCOL
        jmp .ret
        .not_nd:
        cmp al, KEY.Tab
        jne .not_ps
        mov bl, [writeMode]
        xor bl, 1
        mov [writeMode], bl
        mov bx, 0 | DEFCOL
        jmp .ret
        .not_ps:
        cmp al, KEY.Esc
        jne .not_esc
        mov bx, 0 | DEFCOL
        jmp .ret
        .not_esc:
        cmp al, KEY.ENTER
        jne .not_enter
        call finishLine
        mov bx, 0 | DEFCOL
        jmp .ret
        .not_enter:
        cmp al, KEY.LEFT
        jne .not_left
        mov ebx, -2
        push ebx
        call move
        add esp, 4
        mov bx, 0 | DEFCOL
        jmp .ret
        .not_left:
        cmp al, KEY.RIGHT
        jne .not_right
        mov ebx, 2
        push ebx
        call move
        add esp, 4
        mov bx, 0 | DEFCOL
        jmp .ret
        .not_right:
        cmp al, KEY.UP
        jne .not_up
        mov ebx, -160
        push ebx
        call move
        add esp, 4
        mov bx, 0 | DEFCOL
        jmp .ret
        .not_up:
        cmp al, KEY.DOWN
        jne .not_down
        mov ebx, 160
        push ebx
        call move
        add esp, 4
        mov bx, 0 | DEFCOL
        jmp .ret
        .not_down:
        cmp al, KEY.CapsLock
        jne .not_capslock
        mov bl, [capsLockButton]
        xor bl, 1
        mov [capsLockButton], bl
        mov bx, 0 | DEFCOL
        jmp .ret
        .not_capslock:
        cmp al, KEY.BckSp
        jne .not_bsp
        call backSpace
        mov bx, 0 | DEFCOL
        jmp .ret
        .not_bsp:
        mov bx, 0 | DEFCOL
    .ret:
        pop ax
        ret
        
; sin inst de cadena
global convert
convert:
    push ax
    mov ax, [esp + 6]
    cmp al, KEY.LEFT
    jne not_left
    mov bx, -2
    push bx
    call move
    add esp, 2
    mov bx, 0 | DEFCOL
    jmp f
    not_left:
    cmp al, KEY.RIGHT
    jne not_right
    mov bx, 2
    push bx
    call move
    add esp, 2
    mov bx, 0 | DEFCOL
    jmp f
    not_right:
    cmp al, KEY.UP
    jne not_up
    mov bx, -160
    push bx
    call move
    add esp, 2
    mov bx, 0 | DEFCOL
    jmp f
    not_up:
    cmp al, KEY.DOWN
    jne not_down
    mov bx, 160
    push bx
    call move
    add esp, 2
    mov bx, 0 | DEFCOL
    jmp f
    not_down:
    cmp al, KEY.LeftSHF
    jne not_lshift
    mov bl, [capsLockButton]
    xor bl, 1
    mov [capsLockButton], bl
    mov bx, 0 | DEFCOL
    jmp f
    not_lshift:
    cmp al, KEY.BckSp
    jne not_bsp
    call backSpace
    mov bx, 0 | DEFCOL
    jmp f
    not_bsp:
    cmp al, KEY.Q
    jne not_q
    mov bx, 113 | DEFCOL
    TO_UPPER
    jmp f
    not_q:
    cmp al, KEY.A
    jne not_a
    mov bx, 97 | DEFCOL
    TO_UPPER
    jmp f
    not_a:
    mov bx, 0 | DEFCOL
    cmp al, KEY.W
    jne not_w
    mov bx, 119 | DEFCOL
    TO_UPPER
    jmp f
    not_w:
    cmp al, KEY.E
    jne not_e
    mov bx, 101 | DEFCOL
    TO_UPPER
    jmp f
    not_e:
    cmp al, KEY.R
    jne not_r
    mov bx, 114 | DEFCOL
    TO_UPPER
    jmp f
    not_r:
    cmp al, KEY.T
    jne not_t
    mov bx, 116 | DEFCOL
    TO_UPPER
    jmp f
    not_t:
    cmp al, KEY.Y
    jne not_y
    mov bx, 121 | DEFCOL
    TO_UPPER
    jmp f
    not_y:
    cmp al, KEY.Spc
    jne not_sp
    mov bx, 32 | DEFCOL
    TO_UPPER
    jmp f
    not_sp:
    cmp al, KEY.B
    jne not_b
    mov bx, 98 | DEFCOL
    TO_UPPER
    jmp f
    not_b:
    cmp al, KEY.C
    jne not_c
    mov bx, 99 | DEFCOL
    TO_UPPER
    jmp f
    not_c:
    cmp al, KEY.D
    jne not_d
    mov bx, 100 | DEFCOL
    TO_UPPER
    jmp f
    not_d:
    cmp al, KEY.F
    jne not_f
    mov bx, 102 | DEFCOL
    TO_UPPER
    jmp f
    not_f:
    cmp al, KEY.G
    jne not_g
    mov bx, 103 | DEFCOL
    TO_UPPER
    jmp f
    not_g:
    cmp al, KEY.H
    jne not_h
    mov bx, 104 | DEFCOL
    TO_UPPER
    jmp f
    not_h:
    cmp al, KEY.I
    jne not_i
    mov bx, 105 | DEFCOL
    TO_UPPER
    jmp f
    not_i:
    cmp al, KEY.J
    jne not_j
    mov bx, 106 | DEFCOL
    TO_UPPER
    jmp f
    not_j:
    cmp al, KEY.K
    jne not_k
    mov bx, 107 | DEFCOL
    TO_UPPER
    jmp f
    not_k:
    cmp al, KEY.L
    jne not_l
    mov bx, 108 | DEFCOL
    TO_UPPER
    jmp f
    not_l:
    cmp al, KEY.M
    jne not_m
    mov bx, 109 | DEFCOL
    TO_UPPER
    jmp f
    not_m:
    cmp al, KEY.N
    jne not_n
    mov bx, 110 | DEFCOL
    TO_UPPER
    jmp f
    not_n:
    cmp al, KEY.O
    jne not_o
    mov bx, 111 | DEFCOL
    TO_UPPER
    jmp f
    not_o:
    cmp al, KEY.P
    jne not_p
    mov bx, 112 | DEFCOL
    TO_UPPER
    jmp f
    not_p:
    cmp al, KEY.S
    jne not_s
    mov bx, 115 | DEFCOL
    TO_UPPER
    jmp f
    not_s:
    cmp al, KEY.U
    jne not_u
    mov bx, 117 | DEFCOL
    TO_UPPER
    jmp f
    not_u:
    cmp al, KEY.V
    jne not_v
    mov bx, 118 | DEFCOL
    TO_UPPER
    jmp f
    not_v:
    cmp al, KEY.X
    jne not_x
    mov bx, 120 | DEFCOL
    TO_UPPER
    jmp f
    not_x:
    cmp al, KEY.Z
    jne not_z
    mov bx, 122 | DEFCOL
    TO_UPPER
    jmp f
    not_z:
    f:
    pop ax
    ret
