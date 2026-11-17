BITS 16
[org 0x7c00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c0

    mov bx, 0x1000
    mov ah, 0x02
    mov al, 15
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    int 0x13

    jc fail
    jmp 0x0000:0x1000

fail:
    mov si, err_msg
    call print
    jmp $
    
print:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .loop
.done:
    ret

err_msg db 'Load Failed: Could not find kernel.', 0

    times 510-($-$$) db 0
    dw 0xAA55
