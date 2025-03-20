#pragma once

typedef enum {
    RENDERER_TXT,
    RENDERER_HTML,
} render_backend_t;

extern char * input_file;
extern char * output_file;
extern char * overview_file;
extern char * toc_file;

extern render_backend_t render_backend;

extern void usage(void);
extern int parse_arguments(int argc, char * argv[]);
