%include "video.mac"
%include "keyboard.mac"

section .bss
lastKey resb 1 ; last pressed key 

section .data
global exit
exit db 0      ; one if change to Normal Mode is necessary 

section .text

extern clear                ; clean screen
extern scan                 ; read keyboard
extern calibrate            ; wait at least a full second to calibrate timing
extern putc                 ; put one char in a position <x, y>
extern cursor               ; blink cursor
extern insertActions        ; manage commands of insert mode
extern visualActions        ; manage commands of visual mode
extern normalActions        ; manage commands of normal mode
extern start                ; show presentation
extern write                ; write at the buffer
extern putName              ; write the name of the actual mode
extern pointer              ; store the cursor ip
extern writeMode            ; store the type of write that is already in use 
extern writeTools           ; array that contain the write functions
extern initializeVisual     ; initialize Visual mode
extern mVisual              ; store the type of visual mode that is already in use 
extern capsLockButton       ; show is "caps locks"" is pressed
extern control              ; show is "ctrl" is pressed
extern shift                ; show is "shift" is pressed
extern reboot               ; restart the application
extern restoreScreen        ; put default color on all the screen
extern safe                 ; safe the actual screen state
extern doubleG              ; store the number of pressed g's
extern readNumber           ; store the input of numbers
extern linealAction         ; store the state of last action
extern showPosition        ; put actual line and column in the screen

; Bind a key to a procedure
%macro bind 2
  cmp byte [esp], %1
  jne %%next
  call %2
  %%next:
%endmacro

; Fill the screen with the given background color
%macro FILL_SCREEN 1
  push word %1
  call clear
  add esp, 2
%endmacro

global game
game:
    ; Initialize game
    FILL_SCREEN DEFCOL

    ; Calibrate the timing
    call calibrate        

    ; main loop
    game.loop:
        
        call start
         
        pressOnKey:
            call scan
            cmp al, KEY.ENTER
            je break
            jmp pressOnKey
        break:
        
        ; positionate the cursor in the screen's start
        xor ebx, ebx
        mov [pointer], ebx
        call showPosition

        ; Enter in normal mode for first time  
        .normalMode:
            mov al, [exit]
            mov [linealAction], al
            xor eax, eax
            mov [exit], al
            call restoreScreen
            mov eax, 4
            push eax
            call putName
            mov byte [doubleG], 0
            mov byte [readNumber], 0
            .normalLoop:
                call scan
                cmp al, 0
                je .normalLoop
                cmp al, KEY.I
                je .insertMode
                cmp al, KEY.R
                jne .check_others
                mov bl, [capsLockButton] ; check the "mayus" state
                xor bl, [shift] 
                cmp bl, 1
                je .replaceMode 
                .check_others:
                cmp al, KEY.V
                je .visualMode   
                cmp al, KEY.C
                jne .not_C
                mov al, [control]
                cmp al, 1
                jne .normalLoop
                call reboot
                jmp game
                .not_C:    
                call normalActions         
                jmp .normalLoop

        ; enter in insert mode
        .insertMode:
            xor eax, eax
            mov [writeMode], al
            push eax
            call putName
            mov al, 1
            mov [linealAction], al
            .read:
                call get_input
                mov al, [exit]
                cmp al, 1
                je .normalMode
                jmp .read

        ; enter in replace mode
        .replaceMode:
            xor eax, eax
            mov al, 1
            mov [linealAction], al
            mov [writeMode], al
            push eax
            call putName
            jmp .read
        
        ; enter in visual mode
        .visualMode:
            xor eax, eax
            mov al, [capsLockButton]
            xor al, [shift] 
            mov [mVisual], al
            add al, 2
            push eax
            call putName
            call initializeVisual
            .standard:
                call cursor
                call scan
                call visualActions
                mov al, [exit]
                cmp al, 1
                je .normalMode
                jmp .standard
            

draw.red:
    FILL_SCREEN BG.RED
    ret


draw.green:
    FILL_SCREEN BG.GREEN
    ret


get_input:  
    call scan
    mov [lastKey], al
    call insertActions
    cmp bx, NULL
    je no
    push bx
    xor ebx, ebx
    mov bl, [writeMode]
    mov cl, 2
    shl ebx, cl
    call [writeTools + ebx]
    no:
    ret
