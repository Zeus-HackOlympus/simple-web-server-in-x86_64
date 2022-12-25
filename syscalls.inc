socket: 
    # make a socket 
    mov rax, 0x29 
    syscall
    ret 
    # store socket fd in bss section 

bind:
    mov rax,  0x31
    syscall
    ret 

listen:
    mov rax, 0x32
    syscall 
    ret 

accept: 
    mov rax, 0x2b 
    syscall 
    ret 

read: 
    xor rax, rax 
    syscall 
    ret 

write: 
    xor rax, rax 
    inc rax 
    syscall 
    ret 

open: 
    xor rax, rax 
    mov al, 2
    syscall 
    ret 

close:  
    xor rax, rax 
    mov al, 3 
    syscall 
    ret 

exit: 
    # exit with 0 
    xor rdi, rdi 
    xor rax, rax 
    mov al, 60 
    syscall 



