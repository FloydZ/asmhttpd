# asmttpd - Web server for Linux written in amd64 assembly. \
Copyright (C) 2014  Nathan Torchia <nemasu@gmail.com> \
\
This file is part of asmttpd. \
\
asmttpd is free software: you can redistribute it and/or modify \
it under the terms of the GNU General Public License as published by \
the Free Software Foundation, either version 2 of the License, or \
(at your option) any later version. \
\
asmttpd is distributed in the hope that it will be useful, \
but WITHOUT ANY WARRANTY; without even the implied warranty of \
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the \
GNU General Public License for more details. \
\
You should have received a copy of the GNU General Public License \
along with asmttpd.  If not, see <http://www.gnu.org/licenses/>.

igzip=igzip/reg_sizes.asm igzip/options.inc igzip/options.asm igzip/utils.asm igzip/bitbuf2.asm igzip/data_struct2.asm igzip/lz0a_const.asm igzip/crc_pcl.asm igzip/crc_utils.asm igzip/crc.asm  igzip/init_stream.asm igzip/hash.asm igzip/hufftables_bam.asm igzip/hufftables_sam.asm igzip/hufftables.asm igzip/huffman.asm igzip/igzip0c_body.asm igzip/igzip0c_finish.asm igzip/igzip1c_body.asm igzip/igzip1c_finish.asm deflate.asm

all: main

release: http.asm constants.asm bss.asm data.asm  macros.asm  main.asm  benchmark.asm mutex.asm  string.asm  syscall.asm
	yasm -f elf64 -a x86 main.asm -o main.o
	ld -03 main.o -o asmttpd
	strip -s asmttpd

benchmark: http.asm constants.asm bss.asm data.asm  macros.asm  main.asm  benchmark.asm mutex.asm  string.asm  syscall.asm $(igzip)
	yasm -g dwarf2  -f elf64 -a x86 benchmark.asm -o benchmark.o
	ld benchmark.o -o benchmark



main.o: http.asm constants.asm bss.asm  data.asm  macros.asm  main.asm  benchmark.asm  mutex.asm  string.asm  syscall.asm  $(igzip)
	yasm -g dwarf2 -f elf64 -a x86 main.asm -o main.o
main: main.o
	ld main.o -o asmttpd
clean:
	rm -rf main.o asmttpd
