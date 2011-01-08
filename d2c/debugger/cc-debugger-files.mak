# Makefile for compiling the .c and .s files
# If you want to compile .dylan files, don't use this makefile.

CCFLAGS = -Wall -Wno-unused-variable -I.  -g -O -fno-inline-functions   -I/home/gwydion/dylan/gwydion-2.5/d2c/runtime -DGD_PLATFORM_LINUX    
LIBTOOL = /bin/sh /home/gwydion/dylan/gwydion-2.5/libtool
GC_LIBS = -lgc -ldl -lpthread
# We only know the ultimate target when we've finished building the rest
# of this makefile.  So we use this fake target...
#
all : all-at-end-of-file

debugger-guts.lo : debugger-guts.c
	$(LIBTOOL) --tag=CC --mode=compile gcc $(CCFLAGS) -c debugger-guts.c -o debugger-guts.lo
debugger-init.lo : debugger-init.c
	$(LIBTOOL) --tag=CC --mode=compile gcc $(CCFLAGS) -c debugger-init.c -o debugger-init.lo
debugger-heap.lo : debugger-heap.c
	$(LIBTOOL) --tag=CC --mode=compile gcc $(CCFLAGS) -c debugger-heap.c -o debugger-heap.lo

libdebugger-dylan.la :  debugger-guts.lo debugger-init.lo debugger-heap.lo
	rm -f libdebugger-dylan.la
	$(LIBTOOL) --tag=CC --mode=link gcc -o libdebugger-dylan.la  debugger-guts.lo debugger-init.lo debugger-heap.lo -rpath /usr/local/lib/dylan/2.5.0pre4/x86-linux-gcc

all-at-end-of-file : libdebugger-dylan.la

clean :
	rm -f  debugger-guts.lo debugger-init.lo debugger-heap.lo libdebugger-dylan.la

realclean :
	rm -f  cc-debugger-files.mak debugger-guts.lo debugger-guts.c debugger-init.lo debugger-init.c debugger-heap.lo debugger-heap.c libdebugger-dylan.la debugger.lib.du
