_deflate:

    mov rdi, _LZ_Stream2_size
    call sys_mmap_mem
    mov rdi, rax
    
    mov rcx,  msg_bind_error
    mov rdx,  msg_bind_error_len

    mov [rdi + _next_in], rcx
    mov [rdi + _avail_in], rdx

    call init_stream
    mov rdi, rcx
    call fast_lz2_body
    mov rdi, rcx
    ;call fast_lz2_finish
    
    ;mov rax, [rdi + _next_out]


    call exit

