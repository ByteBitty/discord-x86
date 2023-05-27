; Discord bot made in x86_64 NASM
;
; By Byte1Bit#0632

;%include "io64.inc"

; you should use rax for the syscall number and rdi, rsi, rdx, r10, r8, and r9 for the parameters.
BITS 64

section .data
    sys_socket dq 41
    AF_INET dd 2
    SOCK_DGRAM dd 1
    SOL_TCP dd 6
    socketfd dq 0 ; Pointer to socket file descriptor
    
    sys_connect dq 42
    
    sys_write dq 1
    
    dns_server dd 0x01b2a8c0
    ;sys_read dq 0
    
    sockaddr_in:
        sin_family dw 2
        sin_port dw 0x5000
        sin_addr dd 0xE8879FA2;0x01010101
        sin_zero dq 0
    sockaddr_inLen equ $ - sockaddr_in
    
    msg db "Hello, worl", 0
    msgLen equ $ - msg
    
    request db 'GET /index.html HTTP/1.1', 0Dh, 0Ah, 'Host: 162.159.135.232', 0Dh, 0Ah, 0Dh, 0Ah, 0h ; http requests always end lines with CRLF and end with 2xCRLF (Carriage return + Line feed)
    requestLen equ $ - request
    
section .bss
    buffer resb 1
    bufferLen equ $ - buffer
    sockaddr resb 8

section .text
global main

main:
    mov rbp, rsp; for correct debugging
    xor rax,rax

    mov rax, [sys_socket]
    mov edi, [AF_INET]
    mov esi, [SOCK_DGRAM]
    mov edx, [SOL_TCP]
    syscall ; int socket(int domain, int type, int protocol)
    
    mov [socketfd], rax ; Store socket file descriptor pointer in socketfd
    
    mov rax, [sys_connect]
    mov rdi, [socketfd]
    ;push dword 0 ;sin_zero[8]
    ;push dword 16843009; 0x01010101 ;ip
    ;push word 0x5000 ;port
    ;push word 2 ;family
    mov rsi, sockaddr_in
    mov rdx, sockaddr_inLen
    syscall ; int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
    
    mov rax, [sys_write]
    mov rdi, [socketfd] ; int file_descriptor
    mov rsi, request    ; const void *buffer
    mov rdx, requestLen ; size_t buffer_size
    syscall ;ssize_t write(int fd, const void *buf, size_t count)
    
    _read:
    xor rax,rax ;sys_read
    mov rdi, [socketfd] ; int file_descriptor
    mov rsi, buffer     ; const void *buffer
    mov rdx, bufferLen  ; size_t buffer_size
    syscall
    
    
    cmp rax, 0
    jz _exit
    mov rdx,bufferLen
    call _stdout
    jmp _read
    
    ; Print
    ;mov rsi, request
    ;mov rdx, requestLen
    ;call _stdout
    
    call _exit
    
_stdout: ;(rdi: buffer,rsi: buffer length)
    mov     rax, 1       ; sys_write()
    mov     rdi, 1       ; Set to STDOUT
    syscall  
    ret
    
_read_to_stdout: ;read(rdi: int fd, rsi: const void *buf, stack: size_t count)
    xor rax,rax ;sys_read
    syscall
    
    cmp rax, 0
    jz _exit
    mov rdx,bufferLen
    call _stdout
    jmp _read_to_stdout
    
    ret
    
_exit:
    mov rax, 60         ; sys_exit(int exitcode)
    xor rdi, rdi        ; set exit code to 0
    syscall             ; exit