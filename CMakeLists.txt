CMAKE_MINIMUM_REQUIRED(VERSION 3.12)
project (asmhttp LANGUAGES ASM_NASM C)
set(CMAKE_VERBOSE_MAKEFILE ON)

find_program(YASM_EXE NAMES yasm)

include_directories(.)


add_custom_target(release ${YASM_EXE} -f elf64 -a x86 ${CMAKE_CURRENT_SOURCE_DIR}/main.asm -o ${CMAKE_CURRENT_SOURCE_DIR}/main.o COMMAND /usr/bin/ld ${CMAKE_CURRENT_SOURCE_DIR}/main.o -o ${CMAKE_CURRENT_SOURCE_DIR}/asmttpd)

SET(ASM_SRC main.asm http.asm constants.asm bss.asm data.asm macros.asm benchmark.asm mutex.asm string.asm syscall.asm)

#ADD_EXECUTABLE(release ${ASM_SRC})
#ADD_EXECUTABLE(benchmark ${ASM_SRC})

