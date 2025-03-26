%{
    #include <stdio.h>
    #include <dictate.hpp>
%}
%x IN_SKIP
%option noyywrap nodefault
%%
<INITIAL>{
\#skip  {
            BEGIN IN_SKIP;
        }
.|\n    {
            ECHO;
        }
}

<IN_SKIP>{
#piks   {
            BEGIN INITIAL;
        }
.|\n    { ; }
}
%%

void usage(void) {
    dictate(
        "cdd-stripper <file>  : strip #skip blocks from CDD documents\n"
    );
}

signed main(int argc, const char * const argv[]) {
    if (argc < 2) {
        usage();
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fdictatef(stderr, "Failed to open '%s'.", argv[1]);
        return 1;
    }

    yylex();

    fclose(yyin);

    return 0;
}
