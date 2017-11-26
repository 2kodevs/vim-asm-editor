%include "keyboard.mac"
%include "video.mac"

section .text

global convert
convert:
    push ax
    mov ax, [esp + 6]
    cmp al, KEY.Q
    jne not_q
    mov bx, 113 | FG.GRAY | BG.BLACK
    jmp f
    not_q:
    cmp al, KEY.A
    jne not_a
    mov bx, 97 | FG.GRAY | BG.BLACK
    jmp f
    not_a:
    mov bx, 0 | FG.GRAY | BG.BLACK
    cmp al, KEY.W
    jne not_w
    mov bx, 119 | FG.GRAY | BG.BLACK
    jmp f
    not_w:
    cmp al, KEY.E
    jne not_e
    mov bx, 101 | FG.GRAY | BG.BLACK
    jmp f
    not_e:
    cmp al, KEY.R
    jne not_r
    mov bx, 114 | FG.GRAY | BG.BLACK
    jmp f
    not_r:
    cmp al, KEY.T
    jne not_t
    mov bx, 116 | FG.GRAY | BG.BLACK
    jmp f
    not_t:
    cmp al, KEY.Y
    jne not_y
    mov bx, 121 | FG.GRAY | BG.BLACK
    jmp f
    not_y:
    cmp al, KEY.Spc
    jne not_sp
    mov bx, 32 | FG.GRAY | BG.BLACK
    jmp f
    not_sp:
    f:
    pop ax
    ret
