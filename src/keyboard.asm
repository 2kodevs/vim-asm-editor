%include "keyboard.mac"

section .data

; Previous scancode.
key db 0

section .text

extern shift
extern control

; scan()
; Scan for new keypress. Returns new scancode if changed since last call
global scan
scan:
  ; Scan.
  ;in al, 0x64
  ;test al, 1
  ;jz scan
  ;in al, 0x64
  ;test al, 32
  ;jnz scan

  in al, 0x60

  cmp al, KEY.LeftSHF
  je shiftOn
  cmp al, KEY.RightSHF
  je shiftOn
  mov bl, KEY.LeftSHF
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
  mov [shift], ebx
  jmp continue
controlOff:
  xor ebx, ebx
  mov [control], ebx 

  ; If scancode has changed, update key and return it.
continue:
  mov bl, al
  cmp al, [key]
  je .release
  mov [key], al
  jmp .ret

  .release:
    add al, 80h
    out 0x60, al
    mov al, bl

  .ret:
    ret
