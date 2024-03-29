#include "cli.h"
#include "processing.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

struct Properties {
    char disk_space[64];

    char kernel[32];

    char uptime[16];
    char nvidia[16];
    char term[16];
    char xdg_desktop[16];
};

void generate_padding(char *buffer, int length, int max_length) {
    int pad_length = max_length - length;
    for (int i = 0; i <= pad_length; i++) {
        buffer[i] = ' ';
    }
}

void get_cache(struct Options *opts, struct Properties *props) {
    switch (opts->cache_interaction) {
    case CACHE_NONE:
        get_nvidia(props->nvidia);
        get_disk_space(props->disk_space);
        get_kernel(props->kernel);
        break;
    case CACHE_REFRESH:
        get_nvidia(props->nvidia);
        get_disk_space(props->disk_space);
        get_kernel(props->kernel);

        {
            FILE *fh = fopen(opts->cache_path, "w");
            if (fh == NULL) {
                return;
            }

            fprintf(fh, "%s\n%s\n%s\n", props->nvidia, props->disk_space,
                    props->kernel);
            fclose(fh);
        }
        break;
    case CACHE_READ: {
        FILE *fh = fopen(opts->cache_path, "r");
        if (fh == NULL) {
            return;
        }
        const int BUF_SIZE = sizeof(props->nvidia) + sizeof(props->disk_space) +
                             sizeof(props->kernel);
        char buffer[BUF_SIZE];
        fread_unlocked(buffer, sizeof(char), BUF_SIZE, fh);

        fclose(fh);

        char *buffer_ptr = buffer;
        char *nvidia = strsep(&buffer_ptr, "\n");
        if (nvidia == NULL) {
            printf("Could not read nvidia from cache\n");
            get_nvidia(props->nvidia);
        } else {
            strncpy(props->nvidia, nvidia, sizeof(props->nvidia));
        }

        char *disk_space = strsep(&buffer_ptr, "\n");
        if (disk_space == NULL) {
            printf("Could not read disks from cache\n");
            get_disk_space(props->disk_space);
        } else {
            strncpy(props->disk_space, disk_space, sizeof(props->disk_space));
        }

        char *kernel = strsep(&buffer_ptr, "\n");
        if (kernel == NULL) {
            printf("Could not read kernel from cache\n");
            get_kernel(props->kernel);
        } else {
            strncpy(props->kernel, kernel, sizeof(props->kernel));
        }
    } break;
    }
}

/// TODO: Disks prints a ��──
int main(int argc, char *argv[], char **envp) {
    struct Options options = argparse(argc, argv);
    // debug_print_opts(&options);
    struct Properties props = {
        .disk_space = {0},
        .kernel = "Unknown",
        .uptime = "0s",
        .nvidia = "Not Found",
        .term = "Undefined",
        .xdg_desktop = "Other",
    };
    // can't assign a default value to disk_space
    get_cache(&options, &props);

    get_uptime(props.uptime);
    get_term(props.term);
    const char *desktop_icon = get_desktop(props.xdg_desktop);

    // get the max length, pad strings, etc.
    // Future me finds this method rather amusing.
    int max_length = 0;

    int uptime_ln = strlen(props.uptime);
    int nvidia_ln = strlen(props.nvidia);
    int disk_space_ln = strlen(props.disk_space);
    int kernel_ln = strlen(props.kernel);
    int term_ln = strlen(props.term);
    int xdg_desktop_ln = strlen(props.xdg_desktop);

    // This is why I can't split it into a function
    if (uptime_ln > max_length) {
        max_length = uptime_ln;
    }
    if (nvidia_ln > max_length) {
        max_length = nvidia_ln;
    }
    if (disk_space_ln > max_length) {
        max_length = disk_space_ln;
    }
    if (kernel_ln > max_length) {
        max_length = kernel_ln;
    }
    if (term_ln > max_length) {
        max_length = term_ln;
    }
    if (xdg_desktop_ln > max_length) {
        max_length = xdg_desktop_ln;
    }

    // if I move this declaration underneath all those generate_padding
    // functions, it breaks xdg_desktop_pad
    char top_expand[64] = {0};

    for (int i = 0; i <= max_length; i++) {
        // multibyte char
        strcat(top_expand, "─");
    }

    char uptime_pad[64] = {0};
    char nvidia_pad[64] = {0};
    char disk_space_pad[64] = {0};
    char kernel_pad[64] = {0};
    char term_pad[64] = {0};
    char xdg_desktop_pad[64] = {0};

    generate_padding(uptime_pad, uptime_ln, max_length);
    generate_padding(nvidia_pad, nvidia_ln, max_length);
    generate_padding(disk_space_pad, disk_space_ln, max_length);
    generate_padding(kernel_pad, kernel_ln, max_length);
    generate_padding(term_pad, term_ln, max_length);
    generate_padding(xdg_desktop_pad, xdg_desktop_ln, max_length);

    srand(time(NULL));
    int box_color = abs(rand()) % 256;

    // yeah I think I like the bash version of printf better
    printf(
        "\e[0;38;5;%dm╭────────────%s╮\e[0m\n"
        "\e[0;38;5;%dm│\e[0;95m 󰅐 Uptime:  "
        "\e[1m%s%s\e[0;38;5;%dm│\e[0m\n"
        "\e[0;38;5;%dm│\e[0;92m 󰾲 Nvidia:  "
        "\e[1m%s%s\e[0;38;5;%dm│\e[0m\n"
        "\e[0;38;5;%dm│\e[0;93m 󰋊 Disk:    "
        "\e[1m%s%s\e[0;38;5;%dm│\e[0m\n"
        "\e[0;38;5;%dm│\e[0;91m  Kernel:  \e[1m%s%s\e[0;38;5;%dm│\e[0m\n"
        "\e[0;38;5;%dm│\e[0;94m  Term:    \e[1m%s%s\e[0;38;5;%dm│\e[0m\n"
        "\e[0;38;5;%dm│\e[0;96m %s Desk:    \e[1m%s%s\e[0;38;5;%dm│\e[0m\n"
        "\e[0;38;5;%dm╰────────────%s╯\e[0m\n",
        box_color, top_expand, box_color, props.uptime, uptime_pad, box_color,
        box_color, props.nvidia, nvidia_pad, box_color, box_color,
        props.disk_space, disk_space_pad, box_color, box_color, props.kernel,
        kernel_pad, box_color, box_color, props.term, term_pad, box_color,
        box_color, desktop_icon, props.xdg_desktop, xdg_desktop_pad, box_color,
        box_color, top_expand);

    // for (;;) {
    // }

    return 0;
}
