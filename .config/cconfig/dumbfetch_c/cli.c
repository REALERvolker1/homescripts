#include "cli.h"
#include "utils.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

const struct Options OPTIONS_DEFAULT_PARTIAL = {
    .cache_interaction = CACHE_READ,
};

const char *cache_interaction_to_string(CacheInteraction ci) {
    switch (ci) {
    case CACHE_NONE:
        return "CACHE_NONE";
        break;
    case CACHE_READ:
        return "CACHE_READ";
        break;
    case CACHE_REFRESH:
        return "CACHE_REFRESH";
        break;
    }
}

void debug_print_opts(struct Options *opt) {

    printf("Options { cache_interaction: %s, cache_path: %s }\n",
           cache_interaction_to_string(opt->cache_interaction),
           opt->cache_path);

    return;
}

/*
 * Get the default cache path.
 * This function could get one or all of the environment variables
 * XDG_RUNTIME_DIR, TMPDIR, and XDG_SESSION_ID.
 * The buffer input must be as long as the buffer length of Options.cache_path.
 */
void get_default_cache_path_for_options(struct Options *opt) {
    if (opt->cache_interaction == CACHE_NONE) {
        return;
    }
    // I don't have to care if it is valid because "(null)" makes sense in
    // context
    char *xdg_session_id = getenv("XDG_SESSION_ID");

    const int PARENT_DIR_BUFFER_LEN = 60;
    // CACHE_PATH_SIZE - (sizeof("/dumbfetch_c-999.cache") - 1);

    char parent_dir[PARENT_DIR_BUFFER_LEN];

    // I am using multiple pointers because idk if modifying the pointer through
    // strcpy can modify the env variable.
    char *xdg_runtime_dir = getenv("XDG_RUNTIME_DIR");
    if (xdg_runtime_dir != NULL) {
        strcpy(parent_dir, xdg_runtime_dir);
    } else {
        char *tmp_dir = getenv("TMPDIR");

        if (tmp_dir == NULL) {
            strcpy(parent_dir, "/tmp");
        } else {

            strcpy(parent_dir, tmp_dir);
        }
    }

    sprintf(opt->cache_path, "%s/dumbfetch_c-%s.cache", parent_dir,
            xdg_session_id);

    struct stat stats;
    if (!stat(opt->cache_path, &stats)) {
        if (stats.st_mode == S_IFREG) {
            if (opt->cache_interaction != CACHE_REFRESH) {
                return;
            }
        } else {
            // it wasn't a file but it exists
            opt->cache_interaction = CACHE_NONE;
            return;
        }
    }

    // ensure parent dir exists, the file can just be refreshed alright anyway
    // if it doesn't exist
    if (stat(parent_dir, &stats)) {
        if (mkdir(parent_dir, 0700)) {
            opt->cache_interaction = CACHE_NONE;
            return;
        }
    }

    opt->cache_interaction = CACHE_REFRESH;
}

struct Options argparse(int argc, char **argv) {
    struct Options opt = OPTIONS_DEFAULT_PARTIAL;
    _Bool valid_cache_path_set = false;

    if (argc > 1) {
        _Bool skip_next = false;

        for (int i = 1; i < argc; i++) {
            if (skip_next) {
                skip_next = false;
                continue;
            }

            if (strcmp(argv[i], "--no-cache") == 0) {
                valid_cache_path_set = true;
                opt.cache_interaction = CACHE_NONE;
            } else if (strcmp(argv[i], "--refresh-cache") == 0 ||
                       argv[i][1] == 'r') {
                opt.cache_interaction = CACHE_REFRESH;
            } else if (strcmp(argv[i], "--cache-path") == 0) {
                skip_next = true;
                char *next = argv[i + 1];

                if (next == NULL) {
                    fprintf(stderr, "Fatal Error: Missing cache path!\n");
                    exit(EXIT_FAILURE);
                }

                struct stat path_stat;

                if (!stat(next, &path_stat)) {
                    fprintf(stderr, "Fatal Error: Invalid cache path!\n");
                    exit(EXIT_FAILURE);
                }
                if (path_stat.st_mode != S_IFREG) {
                    fprintf(stderr,
                            "Fatal Error: Invalid cache path, not a file\n");
                    exit(EXIT_FAILURE);
                }

                // good to go
                opt.cache_interaction = CACHE_READ;
                valid_cache_path_set = true;
                strcpy(opt.cache_path, next);
            } else {
                printf(
                    "dumbfetch - A dumb, fast, and minimal fetcher.\n"
                    "\n"
                    "Options:\n"
                    "\n"
                    "  --no-cache              Do not use the cache.\n"
                    "  --refresh-cache         Refresh the cache.\n"
                    "  --cache-path <PATH>     Specify a custom cache file.\n");
                // running it with --help isn't an error because you explicitly
                // asked for this
                exit(strcmp(argv[i], "--help") == 0 ? 0 : 1);
            }
        }
    }

    if (valid_cache_path_set == false) {
        get_default_cache_path_for_options(&opt);
    }

    return opt;
}
