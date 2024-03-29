#ifndef CLI_H_
#define CLI_H_

// const int CACHE_PATH_SIZE = 62;

typedef enum {
    CACHE_NONE,
    CACHE_READ,
    CACHE_REFRESH,
} CacheInteraction;
const char *cache_interaction_to_string(CacheInteraction cache_interaction);

struct Options {
    CacheInteraction cache_interaction;
    char cache_path[];
};

struct Options argparse(int argc, char **argv);
void debug_print_opts(struct Options *opt);

extern const struct Options OPTIONS_DEFAULT_PARTIAL;

#endif
