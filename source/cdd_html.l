%{
    #include <string>
    #include <dictate.hpp>

    #define ECHOS(s) do {                            \
        const char * const  ss = s;                  \
        fwrite(ss, strlen(ss), sizeof(char), yyout); \
    } while (0)
    #define ECHOC(c) fputc(c, yyout)

    using namespace std;
%}

%option nodefault
%option noyywrap
%%
ĐĐ.*ĐĐ      {
                ECHOS("<b>");
                ECHOS(string(yytext+2, yyleng-4).c_str());
                ECHOS("</b>");
            }
Đ.*Đ        {
                ECHOS("<i>");
                ECHOS(string(yytext+1, yyleng-2).c_str());
                ECHOS("</i>");
            }
.|\n        {
                ECHO;
            }
%%

#ifdef CDD_HTML_MAIN
void usage() {
    dictate("cdd-html <file>");
}

signed main(int argc, char * argv[]) {
    if (argc < 2) {
        usage();
        return 1;
    }

    cdd_html_in = fopen(argv[1], "r");
    if (!cdd_html_in) {
        dictatef("Error opening '%s'.", argv[1]);
        return 1;
    }
    cdd_html_lex();
    fclose(cdd_html_in);

    return 0;
}
#endif
