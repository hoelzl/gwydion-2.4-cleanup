### This makefile is machine generated.  Don't expect any edits to survive.
### Generated for target x86-linux-gcc hosted by x86-linux-gcc

SRCROOT=/home/gwydion/dylan/gwydion-2.5
SRCDIR=/home/gwydion/dylan/gwydion-2.5/d2c/debugger
VPATH=$(SRCDIR)
BUILDROOT=/home/gwydion/dylan/gwydion-2.5
top_builddir=/home/gwydion/dylan/gwydion-2.5
BUILDDIR=/home/gwydion/dylan/gwydion-2.5/d2c/debugger
DESTDIR=

.PHONY: default compile install uninstall clean

default: compile

CC = gcc
D2C = /usr/local/bin/d2c
D2CFLAGS = -L/home/gwydion/dylan/gwydion-2.5/d2c/runtime/c-code -L/home/gwydion/dylan/gwydion-2.5/d2c/runtime/dylan -L/home/gwydion/dylan/gwydion-2.5/d2c/runtime/melange -L/home/gwydion/dylan/gwydion-2.5/d2c/runtime/transcendental  -L../../common/collection-extensions -L../../common/command-processor -L../../common/common-dylan -L../../common/io -L../../common/string-extensions -L../../common/table-extensions -L../runtime/random -L../runtime/threads  
CFLAGS =  -Wall -Wno-unused-variable -I.  -g -O -fno-inline-functions  
CPPFLAGS = -I/home/gwydion/dylan/gwydion-2.5/d2c/runtime -DGD_PLATFORM_LINUX  
COPTS = 
MELANGEFLAGS = 
MELANGE = /home/gwydion/dylan/gwydion-2.5/tools/melange/melange
PARSERGEN = /home/gwydion/dylan/gwydion-2.5/tools/parsergen/parsergen
DTRACE = 

export CCFLAGS = $(CFLAGS) $(CPPFLAGS) $(COPTS)

export LIBTOOL = /bin/sh /home/gwydion/dylan/gwydion-2.5/libtool

export GC_LIBS = -lgc -ldl -lpthread

dlfcn.dylan: $(SRCDIR)/dlfcn.intr
	$(MAKE) -C /home/gwydion/dylan/gwydion-2.5/tools/melange 
	$(MELANGE) --d2c $(MELANGEFLAGS) $(CPPFLAGS) -I$(SRCDIR) -I/usr/lib/gcc/i686-redhat-linux/4.5.1/include $(SRCDIR)/dlfcn.intr dlfcn.dylan, && mv dlfcn.dylan, dlfcn.dylan 


${DESTDIR}/usr/local/lib/dylan/2.5.0pre4/x86-linux-gcc/debugger.lib.du: debugger.lib.du
	/usr/bin/install -c debugger.lib.du ${DESTDIR}/usr/local/lib/dylan/2.5.0pre4/x86-linux-gcc/debugger.lib.du


${DESTDIR}/usr/local/lib/dylan/2.5.0pre4/x86-linux-gcc/libdebugger-dylan.la: libdebugger-dylan.la
	/bin/sh /home/gwydion/dylan/gwydion-2.5/libtool --mode=install /usr/bin/install -c libdebugger-dylan.la ${DESTDIR}/usr/local/lib/dylan/2.5.0pre4/x86-linux-gcc/libdebugger-dylan.la

debugger.lib.du: /home/gwydion/dylan/gwydion-2.5/d2c/debugger/debugger.lid $(BUILDROOT)/force.timestamp
	$(D2C) -T x86-linux-gcc -M  $(D2CFLAGS) --rpath=/usr/local/lib/dylan/2.5.0pre4/x86-linux-gcc  /home/gwydion/dylan/gwydion-2.5/d2c/debugger/debugger.lid
	rm -f libdebugger-dylan.a
	ln -s .libs/libdebugger-dylan.a libdebugger-dylan.a

include debugger.dep

compile: dlfcn.dylan debugger.lib.du

install: ${DESTDIR}/usr/local/lib/dylan/2.5.0pre4/x86-linux-gcc/debugger.lib.du ${DESTDIR}/usr/local/lib/dylan/2.5.0pre4/x86-linux-gcc/libdebugger-dylan.la

uninstall: 
	rm -f ${DESTDIR}/usr/local/lib/dylan/2.5.0pre4/x86-linux-gcc/debugger.lib.du

clean: 
	if [ -e cc-debugger-files.mak ]; then make -f cc-debugger-files.mak clean; fi
	-rm -f dlfcn.dylan exports.c exports.lo exports.el exports.o introspection.c introspection.lo introspection.el introspection.o dlfcn.c dlfcn.lo dlfcn.el dlfcn.o debugger-init.c debugger-init.lo debugger-heap.c debugger-heap.lo debugger-guts.c debugger-guts.lo debugger-init.o debugger-heap.o debugger-guts.o debugger.lib.du libdebugger-dylan.la libdebugger-dylan.a  libdebugger-dylan.a
	-rm -rf .libs

GNUmakefile: /home/gwydion/dylan/gwydion-2.5/gen-makefile /home/gwydion/dylan/gwydion-2.5/Defaults /home/gwydion/dylan/gwydion-2.5/d2c/debugger/Makegen
	/home/gwydion/dylan/gwydion-2.5/gen-makefile -p/home/gwydion/dylan/gwydion-2.5/d2c/compiler/platforms.descr .

cc_files: 
	make -f cc-debugger-files.mak

