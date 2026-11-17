[org 0x9C00]
    jmp syncdaemon_init  
    jmp syncdaemon_save
    jmp mark_dirty

ptr_has_files dw 0
ptr_file_data dw 0
ptr_file_buffer dw 0
dirty_flags: times 10 db 0

read_sector:
    pusha
    mov ah, 0x02
    mov ch, 0
    mov dh, 0
    mov dl, 0
    mov al, 1
    int 0x13
    popa
    ret

write_sector:
    pusha
    push ax
    mov cx, 18
    xor dx, dx
    div cx
    inc dx
    mov cl, dl
    mov ax, dx
    pop ax
    push ax
    mov cx, 36
    xor dx, dx
    div cx
    mov ch, al
    mov ax, dx
    mov cx, 18
    xor dx, dx
    div cx
    mov dh, al
    pop ax
    mov ah, 0x03
    mov al, 1
    mov dl, 0
    int 0x13
    popa
    ret

syncdaemon_init:
    mov [ptr_has_files], bx
    mov [ptr_file_data], si
    mov [ptr_file_buffer], di
    pusha
    mov bx, [ptr_file_buffer]
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
