#include "platform_api_vmcore.h"
#include "platform_api_extension.h"

int errno = 0;

extern int puts(const char *s);

int bh_platform_init()
{
    return 0;
}

void
bh_platform_destroy()
{
}

void *
os_malloc(unsigned size)
{
    return malloc(size);
}

void *
os_realloc(void *ptr, unsigned size)
{
    return realloc(ptr, size);
}

void
os_free(void *ptr)
{
    free(ptr);
}

/* int putchar(int c) */
/* { */
/*     return 0; */
/* } */

/* int puts(const char *s) */
/* { */
/*     return 0; */
/* } */

/* void os_set_print_function(os_print_function_t pf) */
/* { */
/*     print_function = pf; */
/* } */

int os_printf(const char *message, ...)
{
    puts("os_printf");
    abort();
    return -1;
}

int os_vprintf(const char * format, va_list arg)
{
    puts("os_vprintf");
    abort();
    return -1;
}

void* os_mmap(void *hint, unsigned int size, int prot, int flags)
{
    puts("os_mmap");
    abort();
    return NULL;
}

void os_munmap(void *addr, uint32 size)
{
    puts("os_munmap");
    abort();
}

int os_mprotect(void *addr, uint32 size, int prot)
{
    puts("os_mprotect");
    abort();
}

void
os_dcache_flush(void)
{
    puts("os_dcache_flush");
    abort();
}

