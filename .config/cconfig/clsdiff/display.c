// This is mostly ported from https://github.com/coreutils/coreutils/blob/master/src/dircolors.c

#include "display.h"
#include <stddef.h>
#include <inttypes.h>
#include <sys/types.h>
#include <assert.h>
#include <sys/stat.h>
#include <dirent.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>

struct LscColors
{
    const char* c_no;
    const char* c_fi;
    const char* c_rs;
    const char* c_di;
    const char* c_ln;
    const char* c_or;
    const char* c_mi;
    const char* c_pi;
    const char* c_so;
    const char* c_bd;
    const char* c_cd;
    const char* c_do;
    const char* c_ex;
    const char* c_lc;
    const char* c_rc;
    const char* c_ec;
    const char* c_su;
    const char* c_sg;
    const char* c_st;
    const char* c_ow;
    const char* c_tw;
    const char* c_ca;
    const char* c_mh;
    const char* c_cl;
};

// static char const Filetype_letters[] = {'?', 'p', 'c', 'd', 'b', '-', 'l', 's', 'w', 'd'};
// static_assert (ARRAY_CARDINALITY(Filetype_letters) == FILE_TYPE_ARG_DIRECTORY + 1, "Not every file type has a corresponding icon");

/* Map enum filetype to <dirent.h> d_type values.  */
static uint8_t const filetype_d_type[] =
{
    DT_UNKNOWN, DT_FIFO, DT_CHR, DT_DIR, DT_BLK, DT_REG, DT_LNK, DT_SOCK,
    DT_WHT, DT_DIR
};

// unsafe, mutates color string
int lsc_colorize(char* ls_colors_string, )
{

    size_t idx = 0;

    const char* current = ls_colors_string;


    do {
        current = strchr(ls_colors_string, LSC_KV_DELIM);
        if (current == NULL)
        {
            errno = EINVAL;
            break;
        }
    } while ((current = strchr(ls_colors_string, LSC_COLOR_DELIM)));

    return errno;
}
