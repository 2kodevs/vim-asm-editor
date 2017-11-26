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

section .data
pointer dw 0

section .text


; clear(byte char, byte attrs)
; Clear the screen by filling it with char and attributes.
global clear
clear:
  mov ax, [esp + 4] ; char, attrs
  mov edi, FBUFFER
  mov ecx, COLS * ROWS
  cld
  rep stosw
  ret

; hace parpadear el puntero
global cursor
cursor:
    mov ax, [pointer]
    ;dec ax
    mov bx, [FBUFFER + eax]
    mov cl, 4
    rol bl, cl
    mov [FBUFFER + eax], bx
    ret

; putc(char chr, byte color, byte r, byte c)
;      4         5           6       7
global putc
putc:
    ; calc famebuffer offset 2 * (r * COLS + c)
    ;FBOFFSET [esp + 6], [esp + 7]

    mov bx, [esp + 4]
    mov ax, [pointer]
    mov [FBUFFER + eax], bx
    mov bl, [esp + 5]
    mov [FBUFFER + eax + 3], bl
    mov [FBUFFER + eax - 1], bl
    add ax, 2
    mov [pointer], ax
    ret
