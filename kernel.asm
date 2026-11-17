BITS 16
ORG 0x1000

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7E00

    call wipe_screen

    call show_startup_msg
    call show_prompt

show_prompt:
    call print_newline
    mov si, prompt_string
    call print_string

main_loop:

    mov di, command_buffer
    call read_string

    mov si, command_buffer
    mov di, write_cmd
    mov cx, 5
    repe cmpsb
    je handle_write

    mov si, command_buffer
    mov di, makef_cmd
    mov cx, 5
    repe cmpsb
    je handle_makef

    mov si, command_buffer
    mov di, loadf_cmd
    mov cx, 5
    repe cmpsb
    je handle_loadf

    mov si, command_buffer
    mov di, shutdown_cmd
    call string_compare
    je handle_shutdown

    mov si, command_buffer
    mov di, info_cmd
    call string_compare
    je handle_info

    mov si, command_buffer
    mov di, reboot_cmd
    call string_compare
    je handle_reboot

    mov si, command_buffer
    mov di, wipe_cmd
    call string_compare
    je handle_wipe

    mov si, command_buffer
    mov di, mode0_cmd
    call string_compare
    je handle_mode0

    mov si, command_buffer
    mov di, mode3_cmd
    call string_compare
    je handle_mode3

    mov si, command_buffer
    mov di, mode7_cmd
    call string_compare
    je handle_mode7

    mov si, unknown_cmd
    call print_newline
    call print_string
    jmp main_loop

handle_info:
    call print_newline

    int 12h
    mov cx, ax

    mov si, base_mem_msg
    call print_string

    mov ax, cx
    call print_number

    mov si, kb_msg
    call print_string

    call print_newline
    call show_prompt
    jmp main_loop

handle_wipe:
    call wipe_screen
    call show_startup_msg
    call show_prompt
    jmp main_loop

handle_write:
    mov si, command_buffer
    add si, 5
    call print_newline
    call print_string
    call print_newline
    call show_prompt
    jmp main_loop

handle_reboot:
    mov si, reboot_msg
    call print_string
    
    mov al, 0xFE
    out 0x64, al

    jmp 0xFFFF:0x0000

handle_makef:
    call print_newline
    mov si, slot_msg
    call print_string
    mov di, file_buffer
    call read_string
    mov al, [file_buffer]
    sub al, '0' 
    xor ah, ah
    mov bx, ax
    push bx

    call print_newline
    mov si, ask_msg
    call print_string
    call print_newline
    mov di, file_buffer
    call read_string

    pop bx
    mov ax, bx
    mov cx, 512
    mul cx
    mov di, ax 
    add di, file_data
    mov si, file_buffer
    mov cx, 512
    rep movsb
   
    mov si, has_files
    add si, bx
    mov byte[si], 1
    
    mov si, success_msg
    call print_string
    jmp main_loop   

handle_loadf:
    call print_newline
    mov si, slot_msg
    call print_string
    mov di, file_buffer
    call read_string
    mov al, [file_buffer]
    sub al ,'0'
    xor ah, ah
    mov bx, ax
    
    mov si, has_files
    add si, bx
    cmp byte [si], 0
    je .none

    mov ax, bx
    mov cx, 512
    mul cx
    mov si, ax
    add si, file_data
    call print_newline
    call print_string
    call print_newline
    jmp main_loop

.none:
    call print_newline
    mov si, notfound_msg
    call print_string
    jmp main_loop
    
handle_mode0:
    mov ax, 0x0000
    int 0x10
    call handle_wipe
    call show_prompt
    jmp main_loop

handle_mode3:
    mov ax, 0x0003
    int 0x10
    call handle_wipe
    call show_prompt
    jmp main_loop

handle_mode7:
    mov ax, 0x0007
    int 0x10
    call handle_wipe
    call show_prompt
    jmp main_loop

handle_shutdown:
    mov si, shutdown_msg
    call print_string
 
    mov ax, 0x5301
    xor bx, bx
    int 0x15
    jc .qemu_fallback
 
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    jc .qemu_fallback
    
.qemu_fallback:
    mov ax, 0x2000
    mov dx, 0x604
    out dx, ax
    mov dx, 0xB004
    out dx, ax

    cli
.hang:
    hlt
    jmp .hang

show_startup_msg:
    mov si, welcome_string
    call print_string
    call print_newline

    mov si, intro_string
    call print_string
    call print_newline
    
    mov si, intro_string_header
    call print_string
    call print_newline

    mov si, intro_string1
    call print_string
    call print_newline

    mov si, wrap_intro_string1
    call print_string
    call print_newline
    call print_newline

    mov si, intro_string2
    call print_string
    call print_newline

print_string:
    mov ah, 0Eh
.repeat:
    lodsb
    cmp al, 0
    je .done
    int 10h
    jmp .repeat
.done:
    ret

print_newline:
    push ax
    mov ah, 0Eh
    mov al, 0Dh
    int 10h
    mov al, 0Ah
    int 10h
    pop ax
    ret

print_number:
    pusha
    xor cx, cx
    mov bx, 10

.next_digit:
    xor dx, dx
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .next_digit

.print_digits:
    pop dx
    add dl, '0'
    mov ah, 0Eh
    mov al, dl
    int 10h
    loop .print_digits
    popa
    ret

read_string:
    pusha
    mov bx, di
.read_loop:
    mov ah, 00h
    int 16h
    cmp al, 0Dh
    je .done
    cmp al, 08h
    je .backspace
    mov [di], al
    mov ah, 0Eh
    int 10h
    inc di
    jmp .read_loop

.backspace:
    cmp di, bx
    je .read_loop
    dec di
    mov byte [di], 0
    mov ah, 0Eh
    mov al, 08h
    int 10h
    mov al, ' '
    int 10h
    mov al, 08h
    int 10h
    jmp .read_loop

.done:
    mov byte [di], 0
    popa
    ret

string_compare:
    pusha
.loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .notequal
    cmp al, 0
    je .equal
    inc si
    inc di
    jmp .loop
.notequal:
    popa
    clc
    ret
.equal:
    popa
    stc
    ret

wipe_screen:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dx, 0x0000
    int 0x10
    ret

welcome_string      db 'GC/S DISK OPERATING SYSTEM', 0
intro_string        db 'BUILD V1.0 2026', 0
intro_string_header db 'COMMANDS:', 0
intro_string1       db 'INFO  WIPE  WRITE  RBOOT MAKEF LOADF', 0
wrap_intro_string1  db 'POWER MODE0 MODE3  MODE7', 0
intro_string2       db 'READY', 0
prompt_string       db '', 0
unknown_cmd         db 'UNKNOWN COMMAND', 0

base_mem_msg        db 'BASE MEM: ', 0
start_mem_msg       db 'MEM: ',0
kb_msg              db ' KB', 0
shutdown_msg        db 'SHUTTING DOWN', 0
reboot_msg          db 'REBOOTING', 0
sector_num: db 0
file_buffer:  times  512 db 0
file_names: times 160 db 0
temp_name: times 16 db 0
notfound_msg db 'NOT FOUND', 13, 10, 0
has_files times 10 db 0
slot_msg db "SLOT:", 0
file_data times 5120 db 0

ask_msg: db "TEXT:", 0
success_msg: db 13, 10, "WROTE TO SECTOR", 13, 10, 0

info_cmd            db 'INFO', 0
wipe_cmd            db 'WIPE', 0
write_cmd           db 'WRITE', 0
shutdown_cmd        db 'POWER', 0
reboot_cmd          db 'RBOOT', 0
makef_cmd           db 'MAKEF', 0
loadf_cmd           db 'LOADF', 0
listf_cmd           db 'LISTF', 0
mode0_cmd           db 'MODE0', 0
mode3_cmd           db 'MODE3', 0
mode7_cmd           db 'MODE7', 0

command_buffer      times 64 db 0
