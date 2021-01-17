%include "constants.asm"
%include "macros.asm"

section .data
	%include "data.asm"

section .bss

	%include "bss.asm"

section .text
	%include "string.asm"
	%include "http.asm"
	%include "syscall.asm"
	%include "debug.asm"

    %include "igzip/init_stream.asm"
    %include "igzip/igzip0c_body.asm"
    %include "igzip/igzip0c_finish.asm"
    %include "igzip/igzip1c_body.asm"
    %include "igzip/igzip1c_finish.asm"
    %include "deflate.asm"
global  _start

_start:   
    mov rdi, 8000
    call sys_mmap_mem
    mov rdi, rax
    push rdi


   ; mov rsi, testcopy
    ;mov rdx, testcopy_len

    ;call string_copy
    
    ;mov rsi, testlong
    ;mov rdx, 20

    
    ;mov rdi, rdx
    ;call print_rdi

    push rdx


    xor rax, rax
    rdtsc
    pop rdx
    push rax
    

    call _deflate

    rdtsc
    pop rdx
    sub rax,rdx 

    mov rdi, rax
    call print_rdi 

    pop rdi
    call print_line

    jmp exit


exit:
	
	mov rdi, [listen_socket]
	call sys_close

	xor rdi, rdi 
	mov rax, SYS_EXIT_GROUP
	syscall