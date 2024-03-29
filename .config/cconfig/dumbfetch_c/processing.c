#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/statvfs.h>

#define loop for (;;)

void get_uptime(char *buffer) {
    FILE *fh = fopen("/proc/uptime", "r");
    if (fh == NULL) {
        return;
    }
    // could buffer overflow. also just kinda uses the buffer assigned
    fread_unlocked(buffer, sizeof(char), sizeof(buffer), fh);
    fclose(fh);

    int i;
    for (i = 1; i < sizeof(buffer); i++) {
        if (buffer[i] == '.') {
            break;
        }
    }
    // peak quality C code
    char time_buffer[i];
    strncpy(time_buffer, buffer, i);

    char *end_char = &time_buffer[i];
    unsigned long long total_uptime = strtoull(time_buffer, &end_char, 10);

    unsigned long hours = total_uptime / 3600;
    char minutes = (total_uptime % 3600) / 60;

    if (hours > 0) {
        sprintf(buffer, "%ldh %dm", hours, minutes);
    } else {
        sprintf(buffer, "%dm", minutes);
    }
}

void get_nvidia(char *buffer) {
    FILE *fh = fopen("/sys/module/nvidia/version", "r");
    if (fh == NULL) {
        return;
    }
    fread_unlocked(buffer, sizeof(char), sizeof(buffer), fh);
    fclose(fh);

    buffer[strcspn(buffer, "\n")] = 0;
}

const char *VALID_FS_TYPES[] = {"ext4", "btrfs", "xfs", "ntfs", "bcachefs"};
const int VALID_FS_TYPES_SIZE = 5; // keep in sync with VALID_FS_TYPES
void get_disk_space(char *buffer) {
    char mounts_buffer[2048] = {0};

    FILE *fh = fopen("/proc/mounts", "r");
    if (fh == NULL) {
        return;
    }

    fread_unlocked(mounts_buffer, sizeof(char), sizeof(mounts_buffer), fh);
    fclose(fh);

    char *token;
    char *buffer_pointer = mounts_buffer;

    char internal_mountpoint_buffer[28] = {0};
    // TODO: Make this nonessential
    char internal_mountpoint_fmt_buffer[32] = {0};

    struct statvfs stat_buffer;

    while ((token = strsep(&buffer_pointer, "\n"))) {
        // entries that start with a / are real disks
        if (token[0] != '/') {
            continue;
        }
        // first entry doesn't matter
        strsep(&token, " ");

        {
            char *mountpoint = strsep(&token, " ");
            if (mountpoint == NULL) {
                continue;
            }
            strcpy(internal_mountpoint_buffer, mountpoint);
        }
        {
            char *internal_fstype_token = strsep(&token, " ");
            if (internal_fstype_token == NULL) {
                continue;
            }

            int is_invalid = 1;

            for (int fs = 0; fs < VALID_FS_TYPES_SIZE; fs++) {
                if (strcmp(VALID_FS_TYPES[fs], internal_fstype_token) == 0) {
                    is_invalid =
                        statvfs(internal_mountpoint_buffer, &stat_buffer);

                    break;
                }
            }

            if (is_invalid != 0) {
                continue;
            }
        }

        unsigned long percent =
            (stat_buffer.f_bavail * 100) / stat_buffer.f_blocks;
        // somewhere in here I get �L[/] 65% [/bruh] 37%
        sprintf(internal_mountpoint_fmt_buffer, "[%s] %lu%%, ",
                internal_mountpoint_buffer, percent);
        strcat(buffer, internal_mountpoint_fmt_buffer);
    }

    buffer[strcspn(buffer, ", ")] = 0;

    if (strlen(buffer) == 0) {
        strcpy(buffer, "N/A");
    }
}

void get_kernel(char *buffer) {
    char version_buffer[64] = {0};

    {
        FILE *fh = fopen("/proc/version", "r");
        if (fh == NULL) {
            return;
        }

        fread_unlocked(version_buffer, sizeof(char), sizeof(version_buffer),
                       fh);
        fclose(fh);
    }

    // Linux version 6.8.1-273-tkg-bore-llvm
    // I neeed the third element
    int buf_idx = 0, spaces = 0;
    for (int idx = 0; idx < sizeof(version_buffer); idx++) {
        if (version_buffer[idx] == ' ') {
            if (spaces >= 2) {
                break;
            }

            spaces++;
        } else if (spaces == 2) {
            buffer[buf_idx] = version_buffer[idx];
            buf_idx++;
        }
    }
}

void get_term(char *buffer) {
    char *term = getenv("TERM");

    if (term != NULL) {
        strcpy(buffer, term);
    }
}

/// KEEP THIS SYNCED WITH DESKTOP_ICONS[]
const char *DESKTOP_NAMES[] = {
    "i3",   "hyprland", "sway",     "bspwm",    "dwm",           "qtile",
    "lxqt", "mate",     "deepin",   "pantheon", "enlightenment", "fluxbox",
    "xfce", "plasma",   "cinnamon", "gnome",
};
/// KEEP THIS SYNCED WITH DESKTOP_NAMES[]
const char *DESKTOP_ICONS[] = {
    "", "", "", "", "", "", "", "",
    "", "", "", "", "", "", "", "",
};
// Must hardcode this or the program will segfault instantly when I try to have
// (i <= sizeof(DESKTOP_NAMES)) in the loop
const int DESKTOPS_LENGTH =
    sizeof(DESKTOP_NAMES) / sizeof(DESKTOP_NAMES[0]) - 1;

const char *WAYLAND_ICON = "";
const char *X11_ICON = "";
const char *FREEDESKTOP_ICON = "";

const char *get_desktop(char *buffer) {
    {
        char *desktop = getenv("XDG_CURRENT_DESKTOP");
        if (desktop == NULL) {
            // do this so that I can use the same icon logic
            strcpy(buffer, "Other");
        } else {
            strcpy(buffer, desktop);
        }
    }

    for (int i = 0; i <= DESKTOPS_LENGTH; i++) {
        if (!strcasecmp(buffer, DESKTOP_NAMES[i])) {
            // strcpy(icon_ptr, DESKTOP_ICONS[i]);
            // icon_ptr[0] = *DESKTOP_ICONS[i];
            return DESKTOP_ICONS[i];
            // return;
        }
    }

    if (getenv("WAYLAND_DISPLAY") != NULL) {
        // strcpy(icon_ptr, WAYLAND_ICON);
        // icon_ptr[0] = *WAYLAND_ICON;
        return WAYLAND_ICON;
        // return;
    } else if (getenv("DISPLAY") != NULL) {
        // strcpy(icon_ptr, X11_ICON);
        // icon_ptr[0] = *X11_ICON;
        return X11_ICON;
        // return;
    }

    // strcpy(icon_ptr, FREEDESKTOP_ICON);
    // icon_ptr[0] = *FREEDESKTOP_ICON;
    return FREEDESKTOP_ICON;
    // return;
}
