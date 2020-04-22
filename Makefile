all: build/libvmlib.a

clean:
	rm -rf build

build/Makefile:
	mkdir -p build
	cd build && cmake .. -DWAMR_BUILD_PLATFORM=linux-fortanix-sgx -DWAMR_BUILD_TARGET=X86_64 -DWAMR_BUILD_INTERP=1 -DWAMR_BUILD_FAST_INTERP=1 -DWAMR_BUILD_AOT=1 -DWAMR_BUILD_JIT=0 -DWAMR_BUILD_LIBC_BUILTIN=0 -DWAMR_BUILD_LIBC_WASI=0

build/libvmlib.a: build/Makefile
	$(MAKE) -C build
