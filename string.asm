;asmttpd - Web server for Linux written in amd64 assembly.
;Copyright (C) 2014  Nathan Torchia <nemasu@gmail.com>
;
;This file is part of asmttpd.
;
;asmttpd is free software: you can redistribute it and/or modify
;it under the terms of the GNU General Public License as published by
;the Free Software Foundation, either version 2 of the License, or
;(at your option) any later version.
;
;asmttpd is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.
;
;You should have received a copy of the GNU General Public License
;along with asmttpd.  If not, see <http://www.gnu.org/licenses/>.
string_itoa:; rdi - buffer, rsi - int
	stackpush
	push rcx
	push rbx

	xchg rdi, rsi
	call get_number_of_digits
	xchg rdi, rsi
	mov rcx, rax ;
	
	;add null
	mov al, 0x0
	mov [rdi+rcx], al
	dec rcx

	mov rax, rsi ; value to print
	xor rdx, rdx ; zero other half
	mov rbx, 10
	
	string_itoa_start:
	xor rdx, rdx ; zero other half
	div rbx      ; divide by 10

	add rdx, 0x30
	mov [rdi+rcx], dl
	dec rcx
	cmp rax, 9
	ja string_itoa_start

	cmp rcx, 0
	jl string_itoa_done
	add rax, 0x30 ;last digit
	mov [rdi+rcx], al

	string_itoa_done:
	pop rbx
	pop rcx
	stackpop
	ret

string_atoi: ; rdi = string, rax = int
	stackpush
	
	mov r8, 0 ; ;return

	call get_string_length
	mov r10, rax ; length 
	cmp rax, 0
	je string_atoi_ret_empty

	mov r9, 1 ; multiplier
	
	dec r10
	string_atoi_loop:
	xor rbx, rbx
	mov bl, BYTE [rdi+r10]
	sub bl, 0x30   ;get byte, subtract to get real from ascii value
	mov rax, r9    
	mul rbx         ; multiply value by multiplier
	add r8, rax    ; add result to running total
	dec r10        ; next digit
	mov rax, 10 ; multiply r9 ( multiplier ) by 10
	mul r9
	mov r9, rax
	cmp r10, -1
	jne string_atoi_loop
	jmp string_atoi_ret

	string_atoi_ret_empty:
	mov rax, -1
	stackpop
	ret

	string_atoi_ret:
	mov rax, r8
	stackpop
	ret


    
;braucht 5000-7000 zyklen
; rdi = dest, rsi = source, rdx = bytes to copy
string_copy:
        prefetchnta  [rsi]

        cmp rdx, 8
        jb strcpy_8

        cmp rdx, 16
        jb strcpy_16

        cmp rdx, 32
        jb strcpy_32

        cmp rdx, 64
        jb strcpy_64
        

        prefetchnta  [rsi + 32]


	;mov        rax, rdi;Backup
	mov        rcx, -16
    strcpy_loop:	
        add         rcx, 16
        movups      xmm1, dqword[rsi + rcx]
;u wie unaligned.
        movdqu      dqword[rdi + rcx], xmm1
	
        cmp rcx, rdx
        jb strcpy_loop
        
        ret
        
;movntps fliegt mir um die Ohren, wenn die daten unanligned sind. => #YOLO
    strcpy_64:
        prefetchnta  [rsi + 32]

        movups      xmm1, dqword[rsi]
        movups      xmm2, dqword[rsi + 16]
        movups      xmm3, dqword[rsi + 32]
        movups      xmm4, dqword[rsi + 48]

        pcmpeqb     xmm0, xmm4

        movntps      dqword[rdi], xmm1
        movntps      dqword[rdi + 16], xmm2
        movntps      dqword[rdi + 32], xmm3
        movntps      dqword[rdi + 48], xmm0
        
        ret

    strcpy_32:
        movups      xmm1, dqword[rsi]
        movups      xmm2, dqword[rsi + 16]

        pcmpeqb     xmm0, xmm2

        movntps      dqword[rdi], xmm1
        movntps      dqword[rdi + 16], xmm0
        ret

    strcpy_16:
        movups      xmm1, dqword[rsi]
        pcmpeqb     xmm0, xmm1
        movdqu      dqword[rdi], xmm0
        ret

    strcpy_8:
;TODO Optmimieren
        mov rcx, rdx
        ;inc rcx ; to get null
        cld
        rep movsb 
        ret



string_concat_int: ;rdi = string being added to, rsi = int to add, ret: new length
	stackpush

	call get_string_length
	add rdi, rax
	call string_itoa

	call get_string_length

	stackpop
	ret

string_concat: ;rdi = string being added to, rsi = string to add, ret: new length
	stackpush
	
	call get_string_length
	add rdi, rax ; Go to end of string
	mov r10, rax
	
	;Get length of source ie. bytes to copy
	push rdi
	mov rdi, rsi
	call get_string_length
	inc rax ; null
	mov rcx, rax
	add r10, rax
	pop rdi
	
	rep movsb

	mov rax, r10

	stackpop
	ret


;rdi = haystack, rsi = needle, ret = rax: location of string, else -1 Return value is buggy.
string_contains:
    MovDqU xmm2, dqword[rsi] ; load the first 16 bytes of neddle
    Pxor xmm3, xmm3
    lea rax, [rdi - 16]

    ; find the first possible match of 16-byte fragment in haystack
    strstr_loop:
        add rax, 16
        PcmpIstrI xmm2, dqword[rax], EQUAL_ORDERED
        ja strstr_loop

    jnc strstr_not_found

;    add rax, rdi ; save the possible match start
    mov r10, rsi
    mov r9, rax
    sub r10, r9
    sub r9, 16

    ; compare the strings
    strstr_inner:
        add r9, 16
        MovDqU    xmm1, dqword[r9 + r10]
        ; mask out invalid bytes in the haystack
        PcmpIstrM xmm3, xmm1, EQUAL_EACH + NEGATIVE_POLARITY + BYTE_MASK
        MovDqU xmm4, dqword[r9]
        ;PAnd xmm4, xmm0
        PcmpIstrI xmm1, xmm4, EQUAL_EACH + NEGATIVE_POLARITY
        ja strstr_inner

    jnc strstr_found

    ; continue searching from the next byte
    sub rax, 15
    jmp strstr_loop

    strstr_not_found:
    mov rax, -1

    strstr_found:
    ret

;Removes first instance of string
;ERROR TODO
;This is not workiing with the SSE optimized string_contains func 
string_remove: ;rdi = source, rsi = string to remove, ret = 1 for removed, 0 for not found
	stackpush

	mov r9, 0 ; return flag

	call get_string_length
	mov r8, rax ;  r8: source length
	cmp r8, 0 
	mov rax, 0
	jle string_remove_ret ; source string empty?

	push rdi
	mov rdi, rsi
	call get_string_length
	mov r10, rax ; r10: string to remove length
	pop rdi
	cmp r10, 0
	mov rax, 0
	jle string_remove_ret ; string to remove is blank?

	string_remove_start:
	
	call string_contains
	
	cmp rax,-1
	je string_remove_ret
	
	;Shift source string over
	add rdi, rax
	mov rsi, rdi
	add rsi, r10 ; copying to itself sans found string
	
	cld
	string_remove_do_copy:
	lodsb
	stosb
	cmp al, 0x00
	jne string_remove_do_copy

	mov r9, 1

	string_remove_ret:
	mov rax, r9
	stackpop
	ret

;rdi = haystack, rsi = needle, ret = rax: 0 false, 1 true
;SSE "optimiert" Besser geht es nur wenn man die länge von RSI hardcodet. ==> hat aber nicht funktioniert.
string_ends_with:
	stackpush

	;Get length of haystack, store in r8
	call get_string_length
	mov r8, rax

	;Get length of needle, store in r10
	push rdi
	mov rdi, rsi
	call get_string_length
	mov r10, rax
	pop rdi

	add rdi, r8     ;Now haystack is set to the end
        sub rdi, r10    ;Now haystack is set to the end - len(needle)

	call strcmpeq   ;Cmp the 2 strings

	stackpop
	ret

string_char_at_reverse: ;rdi = haystack, rsi = count from end, rdx = character(not pointer), ret = rax: 0 false, 1 true
	stackpush
	inc rsi ; include null
	call get_string_length
	add rdi, rax ; go to end
	sub rdi, rsi ; subtract count
	mov rax, 0   ; set return to false
	cmp dl, BYTE [rdi] ; compare rdx(dl)
	jne string_char_at_reverse_ret
	mov rax, 1
	string_char_at_reverse_ret:
	stackpop
	ret

print_line: ; rdi = pointer, rsi = length
	stackpush
	call sys_write
	mov rdi, new_line
	mov rsi, 1
	call sys_write
	stackpop
	ret



;RDI Pointer to string
;SSE zwischen 145-220
;Normal zwischen 400 - 480
get_string_length:
        prefetchnta  [rdi]

	mov        rax, -16
	pxor       xmm0, xmm0

    .strlen_loop4:	
        ; Must perform addition before the string comparison;
	; doing it after would interfere with the status flags:

	add        rax, 16
	pcmpistri  xmm0, [rdi + rax], 0x08	; EQUAL_EACH
	jnz        .strlen_loop4

	add        rax, rcx
	ret


;SSE lief in ca 100    
strcmpeq:
        prefetchnta  [rdi]
        prefetchnta  [rsi]
	xor        rax, rax
	xor        rdx, rdx

    .strcmpeq_loop:	
        movdqu     xmm1, [rdi + rdx]
	pcmpistri  xmm1, [rsi + rdx], 0x18	; EQUAL_EACH | NEGATIVE_POLARITY
	jc         .strcmpeq_dif
	jz         .strcmpeq_eql
	add        rdx, 16
	jmp        .strcmpeq_loop

    .strcmpeq_eql:   
        inc        eax
    .strcmpeq_dif:   
        ret



get_number_of_digits: ; of rdi, ret rax
	stackpush
	push rbx
	push rcx
	
	mov rax, rdi
	mov rbx, 10
	mov rcx, 1 ;count
gnod_cont:
	cmp rax, 10
	jb gnod_ret

	xor rdx,rdx
	div rbx

	inc rcx
	jmp gnod_cont
gnod_ret:
	mov rax, rcx
	
	pop rcx
	pop rbx
	stackpop
	ret

;===============================================================================
;Veraltet kommt sse2 oder 4 zu tragen
get_string_length____: ; rdi = pointer, ret rax
	stackpush
	cld
	mov r10, -1
	mov rsi, rdi
    get_string_length_start:
	inc r10 
	lodsb
	cmp al, 0x00
	jne get_string_length_start
	mov rax, r10
	stackpop
	ret



string_ends_with____:;rdi = haystack, rsi = needle, ret = rax: 0 false, 1 true
	stackpush

	;Get length of haystack, store in r8
	call get_string_length
	mov r8, rax

	;Get length of needle, store in r10
	push rdi
	mov rdi, rsi
	call get_string_length
	mov r10, rax
	pop rdi

	add rdi, r8
	add rsi, r10

	xor rax, rax
	xor rdx, rdx
	
    string_ends_with_loop:
	;Start from end, dec r10 till 0
	mov dl, BYTE [rdi]
	cmp dl, BYTE [rsi]
	jne string_ends_with_ret
	dec rdi
	dec rsi
	dec r10
	cmp r10, 0
	jne string_ends_with_loop
	mov rax, 1

	string_ends_with_ret:
	stackpop
	ret


string_contains___: ;rdi = haystack, rsi = needle, ret = rax: location of string, else -1
	stackpush
	
	xor r10, r10 ; total length from beginning
	xor r8, r8 ; count from offset

	string_contains_start:
	mov dl, BYTE [rdi]
	cmp dl, 0x00
	je string_contains_ret_no
	cmp dl, BYTE [rsi]
	je string_contains_check
	inc rdi
	inc r10 ; count from base ( total will be r10 + r8 )
	jmp string_contains_start

	string_contains_check:
	inc r8 ; already checked at pos 0
	cmp BYTE [rsi+r8], 0x00
	je string_contains_ret_ok
	mov dl, [rdi+r8]
	cmp dl ,0x00
	je string_contains_ret_no
	cmp dl, [rsi+r8]
	je string_contains_check
	
	inc rdi
	inc r10
	jmp string_contains_start

	string_contains_ret_ok:
	mov rax, r10
	jmp string_contains_ret

	string_contains_ret_no:
	mov rax, -1

	string_contains_ret:
	stackpop
	ret
;SSE4 ist schneller
strlen_sse2______:

	mov       rax, -16		; 64-bit init to -16
	pxor      xmm0, xmm0		; zero the comparison register

    .strlen_loop:	
        add       rax, 16		; add 16 to the offset
	movdqu    xmm1, [rdi + rax]	; unaligned string read
	pcmpeqb   xmm1, xmm0		; compare string against zeroes
	pmovmskb  ecx, xmm1		; create bitmask from result
	test      ecx, ecx		; set flags based on bitmask
	jz        .strlen_loop			; no bits set means no zeroes found

	bsf       ecx, ecx		; find position of first set bit
	add       rax, rcx		; 64-bit add position to offset
	ret

   

string_copy__________: ; rdi = dest, rsi = source, rdx = bytes to copy
	stackpush
	mov rcx, rdx
	inc rcx ; to get null
	cld
	rep movsb 
	stackpop
	ret