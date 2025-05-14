[BITS 16]
[ORG 0x7C00]

start:
    ; Set up stack
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Set up video mode
    mov ah, 0x00
    mov al, 0x03
    int 0x10

    ; debug: mov si, start_msg
    ; debug: call print_string

    ; Check for extended read support
    mov ah, 0x41
    mov bx, 0x55AA
    int 0x13
    jc no_ext_support
    cmp bx, 0xAA55
    jne no_ext_support

    ; debug: mov si, ext_support_msg
    ; debug: call print_string

    ; Read kernel using LBA
    mov ah, 0x42
    mov si, dap
    int 0x13
    jc disk_error

    ; debug: mov si, kernel_loaded_msg
    ; debug: call print_string

    lgdt [gdt_descriptor]

    ; Set up segment registers
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Switch to protected mode
    jmp CODE_SEG:init_pm

no_ext_support:
    mov si, no_ext_msg
    call print_string
    jmp hang

disk_error:
    mov si, disk_error_msg
    call print_string
    jmp hang

[BITS 32]
init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    jmp 0x10000

; Hang loop
hang:
    hlt
    jmp hang

[BITS 16]
print_string:
    mov ah, 0x0E
.next_char:
    lodsb
    cmp al, 0
    je .done
    int 0x10
    jmp .next_char
.done:
    ret

disk_error_msg db "Disk read failed", 0
no_ext_msg db "No extended read support", 0

dap:
    db 0x10
    db 0
    dw 1
    dw 0
    dw 0x1000
    dq 1

align 8
gdt:
    dq 0x0000000000000000
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF

gdt_descriptor:
    dw gdt_descriptor_end - gdt - 1
    dd gdt
gdt_descriptor_end:

CODE_SEG equ 0x08
DATA_SEG equ 0x10

start_msg db "Bootloader started", 0
ext_support_msg db "Extended read supported", 0
kernel_loaded_msg db "Kernel loaded", 0

times 510-($-$$) db 0
dw 0xAA55