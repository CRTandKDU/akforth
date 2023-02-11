all: ak10.exe ak9.exe akforth9.exe lbforth.exe

ak10.exe: ak10.c
	gcc -D DATA_STACK_SIZE=64 -O -Wall -o ak10.exe ak10.c

ak9.exe: ak9.c
	gcc -D DATA_STACK_SIZE=64 -O -Wall -o ak9.exe ak9.c

akforth9.exe: akforth9.c
	gcc -D DATA_STACK_SIZE=64 -O -Wall -o akforth9.exe akforth9.c

lbforth.exe: lbforth.c
	gcc -D DATA_STACK_SIZE=64 -O -Wall -o lbforth.exe lbforth.c

