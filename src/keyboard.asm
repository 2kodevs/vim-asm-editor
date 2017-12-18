%include "keyboard.mac"

section .data

; Previous scancode.
key db 0

section .text

extern shift
extern control
extern cursor

; scan()
; Scan for new keypress. Returns new scancode if changed since last call
global scan
scan:
  jmp .scaning
  .blink:
  call cursor
  .scaning:
  in al, 0x64
  test al, 1
  jz .blink
  ; for touchpad problems
  in al, 0x64 
  test al, 32
  jnz .blink

  in al, 0x60

  cmp al, KEY.LeftSHF
  je shiftOn
  cmp al, KEY.RightSHF
  je shiftOn
  mov bl, KEY.LeftSHF
  add bl, 80h
  cmp bl, al
  je shiftOff
  mov bl, KEY.RightSHF
  add bl, 80h
  cmp bl, al
  je shiftOff

  cmp al, 0x1D   ;KEY.Ctrl  
  je controlOn
  mov bl, 0x1D
  add bl, 80h
  cmp bl, al
  je shiftOff

  jmp continue

shiftOn:
  mov bl, 1
  mov [shift], bl
  jmp continue
controlOn:
  mov bl, 1
  mov [control], bl
  jmp continue
shiftOff:
  xor ebx, ebx
  mov [shift], bl
  jmp continue
controlOff:
  xor ebx, ebx
  mov [control], bl 

  ; If scancode has changed, update key and return it.
continue:
  mov bl, al
  cmp al, [key]
  je .release
  mov [key], al
  cmp al, 0xA6
  ja .zero
  cmp al, 0x00
  je .zero
  jmp .ret
  .zero:
  mov [key], al
  xor al, al
  jmp .ret

  .release:
    add al, 80h
    out 0x60, al
    mov al, bl

  .ret:
    ret
