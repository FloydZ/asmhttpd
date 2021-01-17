CMAKE_MINIMUM_REQUIRED(VERSION 3.12)
project (asmhttp LANGUAGES ASM C)
set(CMAKE_VERBOSE_MAKEFILE ON)


include_directories(.)

SET(ASM_SRC main.asm http.asm constants.asm bss.asm data.asm macros.asm benchmark.asm mutex.asm string.asm syscall.asm)

ADD_EXECUTABLE(release ${ASM_SRC})
