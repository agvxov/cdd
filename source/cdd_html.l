%{
    #include <string>
    #include <dictate.hpp>
    #include <dedent.h>

    #define ECHOS(s) do {                            \
        const char * const  ss = s;                  \
        fwrite(ss, strlen(ss), sizeof(char), yyout); \
    } while (0)
    #define ECHOC(c) fputc(c, yyout)

    using namespace std;

    bool bold_on = false;
    bool ital_on = false;

    string code_buffer;
%}

ws          [ \t\r\v\f]
wsnl        [ \t\r\v\f\n]
title       [a-zA-Z0-9_]+
link_root   \/\/₩|\/\/\(0x[0-9a-f]+\)➞

%s IN_COMMENT IN_MULTILINE_COMMENT IN_CODE IN_DEFINE
%option nodefault
%option noyywrap
%%

\<                  {
                        ECHOS("&lt;");
                    }
\>                  {
                        ECHOS("&gt;");
                    }
ĐĐ                  {
                        if (not bold_on) {
                            ECHOS("<b>");
                        } else {
                            ECHOS("</b>");
                        }
                        bold_on = not bold_on;

                    }
Đ                   {
                        if (not ital_on) {
                            ECHOS("<i>");
                        } else {
                            ECHOS("</i>");
                        }
                        ital_on = not ital_on;
                    }
{link_root}         { ; }

<INITIAL>{
\$\{[^\}]*\}        {
                        ECHOS("<span class=var>");
                        ECHO;
                        ECHOS("</span>");
                    }
^{ws}*{title}:      {
                        ECHOS("<span class=title>");
                        ECHO;
                        ECHOS("</span>");
                    }
NOTE:               {
                        ECHOS("<span class=NOTE></span>");
                    }
^{ws}*YYY:          {
                        ECHOS("<span class='YYY'>See also:<span>");
                    }
^{ws}*>             {
                        char * s = strdup(string(yytext, yyleng-1).c_str());
                        ECHOS(s);
                        ECHOS("&bull; ");
                        free(s);
                    }
^{ws}*-[^-]         {
                        char * s = strdup(string(yytext, yyleng-2).c_str());
                        ECHOS(s);
                        ECHOS("&mdash; ");
                        free(s);
                        yyless(yyleng-1);
                    }
^{ws}*¤             {
                        char * s = strdup(string(yytext, yyleng-strlen("¤")).c_str());
                        ECHOS(s);
                        ECHOS("&#9675; ");
                        free(s);
                    }
Pros                {
                        ECHOS("<span class=pros>");
                        ECHO;
                        ECHOS("</span>");
                    }
Cons                {
                        ECHOS("<span class=cons>");
                        ECHO;
                        ECHOS("</span>");
                    }
\/\/                {
                        BEGIN IN_COMMENT;
                        ECHOS("<span class=comment>");
                        ECHO;
                    }
\/\*                {
                        BEGIN IN_MULTILINE_COMMENT;
                        ECHOS("<span class=comment>");
                        ECHO;
                    }
.|\n                {
                        ECHO;
                    }

\{?@begin=[a-z]+@   {
                        BEGIN IN_CODE;
                        size_t lb = strlen("@begin=");
                        size_t offset = (yytext[0] == '{');
                        string language = string(yytext+lb+offset, yyleng-lb-1-offset);
                        ECHOS("<code class=language-");
                        ECHOS(language.c_str());
                        ECHOS(">");
                    }

^#define            {
                        BEGIN IN_DEFINE;
                        ECHOS("<span class=define>");
                        ECHO;
                    }

}

<IN_COMMENT>{
.               {
                    ECHO;
                }
\n              {
                    ECHOS("</span>");
                    ECHO;
                    BEGIN INITIAL;
                }
}
<IN_MULTILINE_COMMENT>{
\*\/            {
                    ECHO;
                    ECHOS("</span>");
                    BEGIN INITIAL;
                }
.|\n            {
                    ECHO;
                }
}

<IN_CODE>{
.|\n                {
                        code_buffer += yytext;
                    }
@end=[a-z]+@\}?     {
                        char * code = dedent(strdup(code_buffer.c_str()));
                        ECHOS(code);
                        ECHOS("</code>");
                        free(code);
                        code_buffer = "";
                        BEGIN INITIAL;
                    }
}

<IN_DEFINE>{
\\\n        {
                ECHO;
            }
.           {
                ECHO;
            }
\n          {
                BEGIN INITIAL;
                ECHO;
                ECHOS("</span>");
            }
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

    yyin = fopen(argv[1], "r");
    if (!yyin) {
        dictatef("Error opening '%s'.", argv[1]);
        return 1;
    }
    yylex();
    fclose(yyin);

    return 0;
}
#endif
