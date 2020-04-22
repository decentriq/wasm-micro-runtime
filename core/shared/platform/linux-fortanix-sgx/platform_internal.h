#ifndef PLATFORM_INTERNAL_H
#define PLATFORM_INTERNAL_H

#include <stdarg.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {} korp_thread;
typedef int korp_tid;
typedef struct {} korp_mutex;
typedef struct {} korp_cond;

extern int snprintf(char *str, size_t size, const char *format, ...);
int errno;
  
#ifdef __cplusplus
}
#endif

#endif // PLATFORM_INTERNAL_H
