/* @BAKE
    flex -o cddpp.yy.cpp --header=cddpp.yy.hpp --debug cddpp.l
    g++ -o cddpp main.cpp cddpp.yy.cpp -ldictate -ggdb
   @STOP
 */
#include <stdio.h>
#include <dictate.hpp>
#include "cddpp.yy.hpp"
#include "tree.hh"

extern size_t n_skipped_lines;

extern int init_cddpp_l(void);
extern void make_overview(FILE * f);
extern void make_toc(FILE * f);
extern void render(void);

void usage(void) {
    dictate(
        "cddpp <options><file>\n"
        "  -h          : show help message\n"
        "  -o          : specify output file"
        "  -O <file>   : specify overview file path\n"
        "  -T <file>   : specify table of contents file path\n"
        "  -r txt|html : select renderer backend (default: txt)\n"
    );
}

signed main(int argc, char * argv[]) {
    if (argc < 2) {
        usage();
        return 1;
    }

    section_main();

    init_cddpp_l();

    yyin = fopen(argv[1], "r");
    yylex();

    fclose(yyin);

    section_main("overview.txt", "table_of_contents.txt");

    render();

    fdictate(stderr, n_skipped_lines, " lines were skipped.\n");

    return 0;
}
