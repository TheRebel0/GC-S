; ======================================================
; menu.asm - ONE FILE MikeOS-style menu for cOS
; Standalone - has its own print / clear routines
; No need for syscalls.asm or data.asm
;
; HOW TO USE:
;   call menu_show
;   ; returns with [menu_selected] = 0-4
; ======================================================

menu_selected db 0

menu_show:
    call menu_clear

    mov si, menu_box_top
    call menu_print
    call menu_newline

    mov si, menu_box_title
    call menu_print
    call menu_newline

    mov si, menu_box_mid
    call menu_print
    call menu_newline

    xor cx, cx
.menu_draw:
    mov si, menu_box_side
    call menu_print

    cmp cl, [menu_selected]
    jne .normal
    mov si, menu_prefix_sel
    jmp .do_prefix
.normal:
    mov si, menu_prefix_norm
.do_prefix:
    call menu_print

    mov bx, cx
    shl bx, 1
    mov si, [menu_items + bx]
    call menu_print

    mov si, menu_box_end
    call menu_print
    call menu_newline

    inc cx
    cmp cx, 5
    jl .menu_draw

    mov si, menu_box_bottom
    call menu_print
    call menu_newline

    mov si, menu_help
    call menu_print
    call menu_newline

    ; --- wait for key ---
    mov ah, 0
    int 0x16

    cmp ah, 0x48      ; Up arrow
    je .up
    cmp ah, 0x50      ; Down arrow
    je .down
    cmp al, 'w'
    je .up
    cmp al, 'W'
    je .up
    cmp al, 's'
    je .down
    cmp al, 'S'
    je .down
    cmp al, 13        ; Enter
    je .done
    jmp menu_show

.up:
    cmp byte [menu_selected], 0
    je menu_show
    dec byte [menu_selected]
    jmp menu_show
.down:
    cmp byte [menu_selected], 4
    je menu_show
    inc byte [menu_selected]
    jmp menu_show
.done:
    ret

; --- private helpers, menu_ prefix so no clash ---
menu_clear:
    mov ax, 0x0003
    int 0x10
    ret

menu_print:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp menu_print
.done:
    ret

menu_newline:
    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    ret

; --- data ---
menu_box_top    db '+----------------------+', 0
menu_box_title  db '|       ----OS----     |', 0
menu_box_mid    db '+----------------------+', 0
menu_box_side   db '| ', 0
menu_box_end    db ' |', 0
menu_box_bottom db '+----------------------+', 0
menu_help       db 'W/S or Up/Down, Enter to run', 0
menu_prefix_sel db '> ', 0
menu_prefix_norm db '  ', 0

menu_0 db 'HELLO.BIN', 0
menu_1 db 'FBIRD.BIN', 0
menu_2 db 'INVADERS.BIN', 0
menu_3 db 'PILLMAN.BIN', 0
menu_4 db 'EXIT', 0

menu_items dw menu_0, menu_1, menu_2, menu_3, menu_4
