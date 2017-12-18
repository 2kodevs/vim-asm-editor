%include "keyboard.mac"
%include "video.mac"

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
extern exit
extern undo
extern putName
extern jumpTop
extern jumpAt
extern jumpBot
extern reboot

; Verify exit code
isExit:
    cmp al, KEY.Esc
    jne .ret
    inc byte [exit]
    .ret:
    ret

; manage commands of normal mode
; normalActions(word keyCode)
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
    mov al, [capsLockButton]
    xor al, [shift]  
    cmp al, 1
    jne .GG
    mov al, [numberController]
    cmp al, 1
    jne .shiftG
    mov eax, [readNumber]  
    dec eax 
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
    call isExit
    cmp al, KEY.numDel
    je .del
    cmp al, KEY.X
    jne .not_nd
    .del:
    call delete
    mov bx, NULL
    jmp .ret
    .not_nd:
    cmp al, KEY.CapsLock
    jne .not_capslock
    mov bl, [capsLockButton]
    xor bl, 1
    mov [capsLockButton], bl
    mov bx, NULL
    jmp .ret
    .not_capslock:
    cmp al, KEY.LEFT
    je .left
    cmp al, KEY.H
    jne .not_left
    .left:
    mov ebx, -2
    push ebx
    call move 
    mov bl, 1
    mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_left:
    cmp al, KEY.RIGHT
    je .rigth
    cmp al, KEY.L
    jne .not_right
    .rigth:
    mov ebx, 2
    push ebx
    call move
    mov bl, 1
    mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_right:
    cmp al, KEY.UP
    je .up
    cmp al, KEY.K
    jne .not_up
    .up:
    mov ebx, -160
    push ebx
    call move
    mov bl, 1
    mov [actioned], bl
    add esp, 4
    jmp .ret
    .not_up:
    cmp al, KEY.DOWN
    je .down
    cmp al, KEY.J
    jne .not_down
    .down:
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
    cmp al, KEY.U
    jne .not_u
    call undo
    .not_u:
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
; manage commands of visual mode
; visualActions(word keyCode)
global visualActions
visualActions:
    call isExit
    cmp al, KEY.LEFT
    je .left
    cmp al, KEY.H
    jne .not_left
    .left:
    mov ebx, -2
    push ebx
    call setSelection
    add esp, 4
    jmp .ret
    .not_left:
    cmp al, KEY.RIGHT
    je .rigth
    cmp al, KEY.L
    jne .not_right
    .rigth:
    mov ebx, 2
    push ebx
    call setSelection
    add esp, 4
    jmp .ret
    .not_right:
    cmp al, KEY.UP
    je .up
    cmp al, KEY.K
    jne .not_up
    .up:
    mov ebx, -160
    push ebx
    call setSelection
    add esp, 4
    jmp .ret
    .not_up:
    cmp al, KEY.DOWN
    je .down
    cmp al, KEY.J
    jne .not_down
    .down:
    mov ebx, 160
    push ebx
    call setSelection
    add esp, 4
    jmp .ret
    .not_down:
    cmp al, KEY.CapsLock
    jne .not_capslock
    mov bl, [capsLockButton]
    xor bl, 1
    mov [capsLockButton], bl
    .not_capslock:
    cmp al, KEY.V
    jne .not_v
    xor ebx, ebx
    mov bl, [capsLockButton]
    xor bl, [shift]
    cmp bl, [mVisual]
    jne .change
    inc byte [exit]
    jmp .ret
    .change:
        mov [mVisual], bl
        add bl, 2
        push ebx
        call putName
        xor ebx, ebx
        push ebx
        call setSelection
        pop ebx
        jmp .ret
    .not_v:
    cmp al, KEY.Y
    jne .not_y
    inc byte [exit]
    call yank
    .not_y:
    .ret:
    ret
; manage commands of insert mode
; insertActions(word keyCode)
global insertActions
insertActions:
    call isExit
    push ax
    xor ebx, ebx
    mov ax, [esp + 6]
    cmp al, KEY.Y
    jne .continue
    mov bx, 1
    cmp bx, [control]
    jne .continue
    call cYank
    mov bx, NULL
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
    mov cl, bl 
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
        mov bx, NULL
        jmp .ret
        .not_nd:
        cmp al, KEY.Esc
        jne .not_esc
        mov bx, NULL
        jmp .ret
        .not_esc:
        cmp al, KEY.ENTER
        jne .not_enter
        call finishLine
        mov bx, NULL
        jmp .ret
        .not_enter:
        cmp al, KEY.LEFT
        jne .not_left
        mov ebx, -2
        push ebx
        call move
        add esp, 4
        mov bx, NULL
        jmp .ret
        .not_left:
        cmp al, KEY.RIGHT
        jne .not_right
        mov ebx, 2
        push ebx
        call move
        add esp, 4
        mov bx, NULL
        jmp .ret
        .not_right:
        cmp al, KEY.UP
        jne .not_up
        mov ebx, -160
        push ebx
        call move
        add esp, 4
        mov bx, NULL
        jmp .ret
        .not_up:
        cmp al, KEY.DOWN
        jne .not_down
        mov ebx, 160
        push ebx
        call move
        add esp, 4
        mov bx, NULL
        jmp .ret
        .not_down:
        cmp al, KEY.CapsLock
        jne .not_capslock
        mov bl, [capsLockButton]
        xor bl, 1
        mov [capsLockButton], bl
        mov bx, NULL
        jmp .ret
        .not_capslock:
        cmp al, KEY.BckSp
        jne .not_bsp
        call backSpace
        mov bx, NULL
        jmp .ret
        .not_bsp:
        mov bx, NULL
    .ret:
        pop ax
        ret
        
