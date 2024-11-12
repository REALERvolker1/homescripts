#ifndef DISPLAY_H
#define DISPLAY_H

#include <stddef.h>
#include <inttypes.h>

// https://github.com/coreutils/coreutils/blob/58a88f30f802dc9b150b86c4763992c0d74b83e7/src/system.h#L791
#ifndef ARRAY_CARDINALITY
# define ARRAY_CARDINALITY(Array) (sizeof (Array) / sizeof *(Array))
#endif

#define LSCOLORS_COLOR_DELIM ':'
#define LSCOLORS_KV_DELIM '='

#define ANSI(s) "\x1b[" s "m"

// 󱀶 󰟥 󰹬 󰉖 󰍛 󰈤 󰌹

typedef enum
{
    FILE_TYPE_UNKNOWN,
    FILE_TYPE_FIFO,
    FILE_TYPE_CHARDEV,
    FILE_TYPE_DIRECTORY,
    FILE_TYPE_BLOCKDEV,
    FILE_TYPE_NORMAL,
    FILE_TYPE_SYMLINK,
    FILE_TYPE_SOCK,
    FILE_TYPE_WHITEOUT,
    FILE_TYPE_ARG_DIRECTORY,
} LscFileType;

#define DISPLAY_ICON_NonExistent "󱪢",
#define DISPLAY_ICON_Directory "",
#define DISPLAY_ICON_File "󰈙",
#define DISPLAY_ICON_SymlinkDirectory "󱧬",
#define DISPLAY_ICON_SymlinkFile "󱅷",
#define DISPLAY_ICON_DotFile "󰘓",
#define DISPLAY_ICON_DotFolder "󱞞",


#endif
