%include "keyboard.mac"
%include "video.mac"

; cambia a letra Mayuscula
%macro TO_UPPER 0.nolist
    cmp byte [capsLockButton], 0
    je %%next
    add bh, 32
    %%next:
%endmacro
section .data

character db "`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "=", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\", "a", "s", "d", "f", "g", "h", "j", "k", "l", 59, 96, "z", "x", "c", "v", "b", "n", "m", ",", ".", "/", " "
uppers db "~", "!", "@", "#", "$", "%", "^", "&", "*", "(", ")", "_", "+", "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "{", "}", "|", "A", "S", "D", "F", "G", "H", "J", "K", "L", 34, "Z", "X", "C", "V", "B", "N", "M", "<", ">", "?", " "
Keys db KEY.Aprox, KEY.1, KEY.2, KEY.3, KEY.4, KEY.5, KEY.6, KEY.7, KEY.8, KEY.9, KEY.0, KEY.Script, KEY.Equal, KEY.Q, KEY.W, KEY.E, KEY.R, KEY.T, KEY.Y, KEY.U, KEY.I, KEY.O, KEY.P, KEY.OpenSquare, KEY.ClosedSquare, KEY.Back_Slash, KEY.A, KEY.S, KEY.D, KEY.F, KEY.G, KEY.H, KEY.J, KEY.K, KEY.L, KEY.Two_Dots, KEY.Quotes, KEY.Z, KEY.X, KEY.C, KEY.V, KEY.B, KEY.N, KEY.M, KEY.Comma, KEY.Dot, KEY.Slash, KEY.Spc

global capsLockButton
capsLockButton db 0

section .text

extern backSpace
extern pointer
extern move

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
    mov bx, 0 | FG.GRAY | BG.BLACK
    jmp f
    not_left:
    cmp al, KEY.RIGHT
    jne not_right
    mov bx, 2
    push bx
    call move
    add esp, 2
    mov bx, 0 | FG.GRAY | BG.BLACK
    jmp f
    not_right:
    cmp al, KEY.UP
    jne not_up
    mov bx, -160
    push bx
    call move
    add esp, 2
    mov bx, 0 | FG.GRAY | BG.BLACK
    jmp f
    not_up:
    cmp al, KEY.DOWN
    jne not_down
    mov bx, 160
    push bx
    call move
    add esp, 2
    mov bx, 0 | FG.GRAY | BG.BLACK
    jmp f
    not_down:
    cmp al, KEY.LeftSHF
    jne not_lshift
    mov bl, [capsLockButton]
    xor bl, 1
    mov [capsLockButton], bl
    mov bx, 0 | FG.GRAY | BG.BLACK
    jmp f
    not_lshift:
    cmp al, KEY.BckSp
    jne not_bsp
    call backSpace
    mov bx, 0 | FG.GRAY | BG.BLACK
    jmp f
    not_bsp:
    cmp al, KEY.Q
    jne not_q
    mov bx, 113 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_q:
    cmp al, KEY.A
    jne not_a
    mov bx, 97 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_a:
    mov bx, 0 | FG.GRAY | BG.BLACK
    cmp al, KEY.W
    jne not_w
    mov bx, 119 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_w:
    cmp al, KEY.E
    jne not_e
    mov bx, 101 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_e:
    cmp al, KEY.R
    jne not_r
    mov bx, 114 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_r:
    cmp al, KEY.T
    jne not_t
    mov bx, 116 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_t:
    cmp al, KEY.Y
    jne not_y
    mov bx, 121 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_y:
    cmp al, KEY.Spc
    jne not_sp
    mov bx, 32 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_sp:
    cmp al, KEY.B
    jne not_b
    mov bx, 98 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_b:
    cmp al, KEY.C
    jne not_c
    mov bx, 99 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_c:
    cmp al, KEY.D
    jne not_d
    mov bx, 100 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_d:
    cmp al, KEY.F
    jne not_f
    mov bx, 102 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_f:
    cmp al, KEY.G
    jne not_g
    mov bx, 103 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_g:
    cmp al, KEY.H
    jne not_h
    mov bx, 104 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_h:
    cmp al, KEY.I
    jne not_i
    mov bx, 105 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_i:
    cmp al, KEY.J
    jne not_j
    mov bx, 106 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_j:
    cmp al, KEY.K
    jne not_k
    mov bx, 107 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_k:
    cmp al, KEY.L
    jne not_l
    mov bx, 108 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_l:
    cmp al, KEY.M
    jne not_m
    mov bx, 109 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_m:
    cmp al, KEY.N
    jne not_n
    mov bx, 110 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_n:
    cmp al, KEY.O
    jne not_o
    mov bx, 111 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_o:
    cmp al, KEY.P
    jne not_p
    mov bx, 112 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_p:
    cmp al, KEY.S
    jne not_s
    mov bx, 115 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_s:
    cmp al, KEY.U
    jne not_u
    mov bx, 117 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_u:
    cmp al, KEY.V
    jne not_v
    mov bx, 118 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_v:
    cmp al, KEY.X
    jne not_x
    mov bx, 120 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_x:
    cmp al, KEY.Z
    jne not_z
    mov bx, 122 | FG.GRAY | BG.BLACK
    TO_UPPER
    jmp f
    not_z:
    f:
    pop ax
    ret
