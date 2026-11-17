    mov ax, 18
    call read_sector  
    mov si, [ptr_file_buffer]
    mov di, [ptr_has_files]
    mov cx, 10
    rep movsb
    xor bp, bp
.load_loop:
    cmp bp, 10
    jae .done
    mov ax, bp
    shl ax, 9
    mov bx, [ptr_file_data]
    add bx, ax
    mov ax, bp
    add ax, 19
    call read_sector
    inc bp
    jmp .load_loop
.done:
    mov di, dirty_flags
    mov cx, 10
    xor al, al
    rep stosb
    popa
    ret

syncdaemon_save:
    pusha
    xor bp, bp
.save_loop:
    cmp bp, 10
    jae .done
    cmp byte [dirty_flags + bp], 0
    je .next
    mov ax, bp  
    shl ax, 9
    mov bx, [ptr_file_data]
    add bx, ax
    mov ax, bp
    add ax, 19
    call write_sector
    mov byte [dirty_flags + bp], 0
.next:
    inc bp
    jmp .save_loop
.done:
    mov si, [ptr_has_files]
    mov di, [ptr_file_buffer]
    mov cx, 10
    rep movsb
    mov bx, [ptr_file_buffer]
    mov cl, 18
    call write_sector
    popa
    ret

mark_dirty:
    mov byte [dirty_flags + bp], 1
    ret

times 512 - ($ - $$) db 0
