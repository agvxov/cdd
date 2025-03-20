#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <dictate.hpp>
#include "cli.hpp"

char * input_file    = NULL;
char * output_file   = NULL;
char * overview_file = NULL;
char * toc_file      = NULL;

render_backend_t render_backend = RENDERER_TXT;

void usage(void) {
    dictate(
        "cddpp <options><file>\n"
        "  -h          : show help message\n"
        "  -i <file>   : specify input file"
        "  -o <file>   : specify output file"
        "  -O <file>   : specify overview file path\n"
        "  -T <file>   : specify table of contents file path\n"
        "  -r txt|html : select renderer backend (default: txt)\n"
    );
}

int parse_arguments(int argc, char *argv[]) {
    int opt;

    if (argc == 1) {
        usage();
        return -1;
    }
    
    while ((opt = getopt(argc, argv, "hi:o:O:T:r:")) != -1) {
        switch (opt) {
            case 'h':
                usage();
                exit(EXIT_SUCCESS);
            case 'i':
                input_file = optarg;
                break;
            case 'o':
                output_file = optarg;
                break;
            case 'O':
                overview_file = optarg;
                break;
            case 'T':
                toc_file = optarg;
                break;
            case 'r':
                if (!strcmp(optarg, "txt")) {
                    render_backend = RENDERER_TXT;
                } else
                if (!strcmp(optarg, "html")) {
                    render_backend = RENDERER_HTML;
                } else {
                    fdictatef(stderr, "Invalid renderer backend: %s\n", optarg);
                    return -1;
                }
                break;
            default:
                return -1;
        }
    }
    return 0;
}
