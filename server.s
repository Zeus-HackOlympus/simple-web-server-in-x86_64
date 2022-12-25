.intel_syntax noprefix 
.section .text 
    .global _start 
        .include "./syscalls.inc"
        _start: 
            # socket; bind; listen; accept 
            call init_accept

            # set registers for data read 
            mov rdi, accept_fd
            lea rsi, [request]
            mov rdx, 256 
            # call read 
            call read 
            
            call check_for_get
            
            # set registers for open 
            lea rdi, [file_name] 
            xor rsi, rsi 
            call open 
            
            # save file fd in bss section for future use  
            mov file_fd, rax 
            
            # read file 
            mov rdi, file_fd
            lea rsi, [read_data]
            mov rdx, 1024 
            call read
            
            # store read data len 
            mov read_data_len, rax  

            # close file fd 
            mov rdi, file_fd 
            call close
            
            # set registers for data write  
            mov rdi, accept_fd 
            lea rsi, [conn_200_start]
            
            lea rdx, [conn_200_len]
            # call write 
            call write 

            # write file contents
            mov rdi, accept_fd 
            lea rsi, [read_data] 
            mov rdx, read_data_len
            call write 

            mov rdi, accept_fd 
            call close
            
            # exit 
            jmp exit 

        init_accept: 
            # set registers for socket 
            mov dil, 0x02 
            mov sil, 0x01 
            xor rdx, rdx 
            # call socket 
            call socket 
            
            # save the socket fd to bss section for later use
            mov socket_fd, rax 
            
            # set registers for bind 
            mov rdi, socket_fd
            lea rsi, sockaddr_struct
            mov dl, 0x10 

            # call bind 
            call bind 
            
            # set registers for listen
            mov rdi, socket_fd
            xor rsi, rsi 
            
            # call listen
            call listen 
            
            # set reigsters for accept 
            mov rdi, 3 
            xor rsi, rsi 
            xor rdx, rdx 

            call accept
            
            # save accepted fd in bss section for later use 
            mov accept_fd, rax 
            ret 
        
        check_for_get: 
        #  thanks to chatgpt 
            lea rdi, GET
            lea rsi, request 
            mov rcx, 4 
            cld # clear direction flag to compare from "left to right" rather than "right to left" 
            repe cmpsb # cmp bytes one by one at rdi and rsp. Repeat until equal and rcx != 0 (rcx--)   
            jz get_file_name
            xor rax, rax 
            inc rax 
            ret 

        get_file_name: 
            xor rax, rax 
            xor rbx, rbx 
            xor rcx, rcx 
           
            mov rax, ' '
            lea rsi, [file_name] # destination  
            lea rdi, [request] # source 
            add rdi, 4 # skip "GET " part 
            

        extract_filename: 
            mov bl, byte ptr [rdi] 
            cmp bl, al 
            je found
            mov cl, byte ptr [rdi]
            mov [rsi], cl  
            inc rsi 
            inc rdi 
            jmp extract_filename 
        
        found: 
            xor rax, rax 
            ret
            

.section .data 
    sockaddr_struct: 
        .2byte 0x02 
        .2byte 0x5000  
        .4byte 0x00
        .8byte 0x00 
    conn_200_start: 
        .ascii "HTTP/1.0 200 OK\r\n\r\n" 
    conn_200_end: 
        .set conn_200_len, conn_200_end-conn_200_start 
    GET: 
        .ascii "GET "

.section .bss 
    .lcomm socket_fd, 4 
    .lcomm accept_fd, 4
    .lcomm file_name, 20 
    .lcomm file_fd, 4  
    .lcomm request, 256 
    .lcomm read_data, 1024
    .lcomm read_data_len, 4 
