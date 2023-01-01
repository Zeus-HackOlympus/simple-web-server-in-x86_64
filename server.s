.intel_syntax noprefix 
.section .text 
    .global _start 
        .include "./syscalls.inc"
        _start:
        main: 
            call init_socket_bind_listen
        LOOP: 
            call init_accept 
            
            # fork 
            mov rax, 0x39 
            syscall 
            mov fork_pid, rax 
            
            test rax, rax 
            jz child 
            
            mov rdi, [clientfd]
            call close 
            
            jmp LOOP
        
        child:
            mov rdi, [socket_fd] # close socket fd for child process 
            call close 

            # set registers for data read   
            mov rdi, clientfd
            lea rsi, [request]
            mov rdx, 0x400 
            call read 

            call GET
            
            call POST 

            # exit 
            jmp exit 

        init_socket_bind_listen: 
            # set registers for socket 
            xor rax, rax 
            xor rdi, rdi
            xor rsi, rsi 
            xor rdx, rdx 

            mov dil, 0x02 
            mov sil, 0x01 
            xor rdx, rdx 
            # call socket 
            call socket 
            mov socket_fd, rax    # save the socket fd to bss section for later use
            
            # set registers for bind 
            mov rdi, socket_fd
            lea rsi, sockaddr_struct
            mov dl, 0x10 

            call bind
 
            # set registers for listen
            mov rdi, socket_fd
            xor rsi, rsi 
            call listen 
            
            ret 
        
        init_accept: 
            # set reigsters for accept 
            mov rdi, socket_fd 
            xor rsi, rsi 
            xor rdx, rdx 

            call accept
            
            # save accepted fd in bss section for later use 
            mov clientfd, rax 
            ret 

        GET: 
            GET_check_for_get: 
                lea rdi, GET_string
                lea rsi, request 
                mov rcx, 4 
                cld # clear direction flag to compare from "left to right" rather than "right to left" 
                repe cmpsb # cmp bytes one by one at rdi and rsp. Repeat until equal and rcx != 0 (rcx--)   
                jz GET_get_file_name
                xor rax, rax 
                inc rax 
                ret 

            GET_get_file_name: 
                xor rax, rax 
                xor rbx, rbx 
                xor rcx, rcx 
               
                mov rax, ' '
                lea rsi, [file_name] # destination  
                lea rdi, [request] # source 
                add rdi, 4 # skip "GET " part 
                

            GET_extract_filename: 
                mov bl, byte ptr [rdi] 
                cmp bl, al 
                je GET_found
                mov cl, byte ptr [rdi]
                mov [rsi], cl  
                inc rsi 
                inc rdi 
                jmp GET_extract_filename 
            
            GET_found: 
                # set registers for open 
                lea rdi, [file_name] 
                xor rsi, rsi 
                call open 
                
                # save file fd in bss section for future use  
                mov file_fd, rax 
                
                # read file 
                mov rdi, file_fd
                lea rsi, [data]
                mov rdx, 0x400
                call read

                # store read data len 
                mov data_len, rax  

                # close file fd 
                mov rdi, file_fd 
                call close
                
                # set registers for data write  
                mov rdi, clientfd 
                lea rsi, [conn_200_start]
                lea rdx, [conn_200_len]
                # call write 
                call write 

                # write file contents
                mov rdi, clientfd 
                lea rsi, [data] 
                mov rdx, data_len
                call write 

                mov rdi, clientfd 
                call close
                ret
        
        POST: 
            POST_check_for_post:  
                lea rdi, POST_string
                lea rsi, request 
                mov rcx, 4 
                cld # clear direction flag to compare from "left to right" rather than "right to left" 
                repe cmpsb # cmp bytes one by one at rdi and rsp. Repeat until equal and rcx != 0 (rcx--)   
                jz POST_get_file_name
                xor rax, rax 
                inc rax 
                ret 
            
            POST_get_file_name: 
                
                xor rax, rax 
                xor rbx, rbx 
                xor rcx, rcx 
               
                mov rax, ' '
                lea rsi, [file_name] # destination  
                lea rdi, [request] # source 
                add rdi, 5 # skip "POST " part 
                

            POST_extract_filename: 
                mov bl, byte ptr [rdi] 
                cmp bl, al 
                je POST_found
                mov cl, byte ptr [rdi]
                mov [rsi], cl  
                inc rsi 
                inc rdi 
                jmp POST_extract_filename 
            
            POST_found:
                lea rdi, [file_name] 
                mov rsi, 0x41 # O_CREAT | O_WRONLY 
                mov rdx, 0x1ff # mode = 0777
                call open 
                mov file_fd, rax 
                
                xor rax, rax 
                xor rbx, rbx
                
                xor rsi, rsi 
                lea rdi, [request] # request string 
                add rdi, 5 
                lea rsi, [post_header_end_s]

           POST_seed_to_post_data:
                mov rbx, 0x0a0d0a0d #0x0d0a0d0a # "\r\n\r\n" in rbx for cmp
                cmp ebx, dword ptr [rdi] 
                je POST_extract_data
                inc rdi
                jmp POST_seed_to_post_data

            POST_extract_data:
                # source 
                lea r10, [post_header_end_len]
                add rdi, r10 # skip "\r\n\r\n" 
                mov r9, rdi # save rdi state in r9 for future use to calculate size  
                xor rax, rax
                xor rbx, rbx 
                xor rcx, rcx # null byte 
                lea rsi, [data]  # destination 
                            
            POST_extract_data_LOOP: 
                mov bl, byte ptr [rdi] 
                cmp bl, al # if null byte 
                je POST_data_write # break out from loop 
                mov cl, byte ptr [rdi] # put source in 8bit register 
                mov [rsi], cl # copy 1 byte in *destinatoon  
                inc rsi  
                inc rdi 
                jmp POST_extract_data_LOOP 
                
            POST_data_write: 
                sub rdi, r9  # to get length of data 
                mov rdx,  rdi
                mov rdi, file_fd 
                lea rsi, [data] 
                call write 
           
                mov rdi, file_fd
                call close

                mov rdi, clientfd
                lea rsi, [conn_200_start]
                lea rdx, [conn_200_len] 
                call write 
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
    GET_string: 
        .ascii "GET "
    POST_string: 
        .ascii "POST "
    post_header_end_s: 
        .ascii "\r\n\r\n"
    post_header_end_e: 
        .set post_header_end_len, post_header_end_e-post_header_end_s

.section .bss 
    .lcomm socket_fd, 0x04 
    .lcomm clientfd, 0x04
    .lcomm fork_pid, 0x04 
    .lcomm exit_status, 0x04
    .lcomm file_name, 0x14 
    .lcomm file_fd, 0x04  
    .lcomm request, 0x400
    .lcomm data, 0x400 # used for file/post data 
    .lcomm data_len, 0x04 
