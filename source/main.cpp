/* @BAKE
    flex -o cddpp.yy.cpp --header=cddpp.yy.hpp --debug cddpp.l
    g++ -o cddpp main.cpp cli.cpp cddpp.yy.cpp -ldictate -ggdb
   @STOP
 */
#include <stdio.h>
#include <dictate.hpp>
#include "cddpp.yy.hpp"
#include "cli.hpp"

extern size_t n_skipped_lines;

extern int init_cddpp_l(void);
extern void make_overview(FILE * f);
extern void make_toc(FILE * f);
extern void render(const char * f, const char * of, const char * tf);

signed main(int argc, char * argv[]) {
    if (parse_arguments(argc, argv)) { return 1; }

    init_cddpp_l();

    yyin = fopen(input_file, "r");
    yylex();

    fclose(yyin);

    render(output_file, overview_file, toc_file);

    fdictate(stderr, n_skipped_lines, " lines were skipped.\n");

    return 0;
}
