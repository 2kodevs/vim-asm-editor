section .data

; Previous scancode.
key db 0

section .text

; scan()
; Scan for new keypress. Returns new scancode if changed since last call, zero
; otherwise.
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
  mov bl, al

  ; If scancode has changed, update key and return it.
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
