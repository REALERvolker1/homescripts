/**
* @author REALERvolker1
* @date Long ago...
* @brief Example description
*/

#ifndef PRELUDE_H
#define PRELUDE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stddef.h>
#include <stdbool.h>
#include <inttypes.h>
#include <assert.h>

// for OS programming

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sys/stat.h>
#include <time.h>
#include <fcntl.h>


struct pl_buffer {
    void * buffer;
    uintptr_t alloc_size;
};

#ifdef __cplusplus
}

#endif // __cplusplus

#endif // PRELUDE_H
