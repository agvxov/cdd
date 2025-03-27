%{
    #include <string>
    #include <dictate.hpp>
    #include <dedent.h>
    #include <random>

    #define ECHOS(s) do {                            \
        const char * const  ss = s;                  \
        fwrite(ss, strlen(ss), sizeof(char), yyout); \
    } while (0)
    #define ECHOI(i) do {                            \
        char *is = NULL;                             \
        asprintf(&is, "%d", i);                      \
        fwrite(is, strlen(is), sizeof(char), yyout); \
        free(is);                                    \
    } while (0)
    #define ECHOC(c) fputc(c, yyout)

    using namespace std;

    bool bold_on = false;
    bool ital_on = false;

    string code_buffer;
    string language;

    string generateRandomString(size_t length) {
        const string characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        random_device rd;  
        mt19937 gen(rd()); 
        uniform_int_distribution<> dis(0, characters.size() - 1);

        string randomString;
        for (size_t i = 0; i < length; ++i) {
            randomString += characters[dis(gen)];
        }

        return randomString;
    }
%}

ws          [ \t\r\v\f]
wsnl        [ \t\r\v\f\n]
title       [a-zA-Z0-9_]+
link_root   \/\/₩|\/\/\(0x[0-9a-f]+\)➞
heading     ^{ws}*{title}:{ws}*{link_root}
begin_code  \{?@begin=[a-z]+@\n?

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
{heading}           {

                        size_t space_count;
                        for (space_count = 0; yytext[space_count] == ' '; space_count++) { ; }
                        char header_number = '2' + (space_count / 4);

                        size_t significant_end;
                        for (
                            significant_end = space_count;
                            yytext[significant_end] != ':';
                            significant_end++
                        ) { ; }
                        string significant_text = string(yytext, significant_end + 1);

                        ECHOS("<span class=title>");
                        ECHOS(significant_text.c_str());
                        ECHOS("</span>");

                        if (header_number <= '6') {
                            string id = generateRandomString(6);
                            ECHOS("<h");
                            ECHOC(header_number);
                            ECHOS(" id=");
                            ECHOS(id.c_str());
                            ECHOS(" style='visibility: hidden; display: inline;'>");

                            ECHOS(significant_text.c_str());

                            ECHOS("</h");
                            ECHOC(header_number);
                            ECHOC('>');
                        }
                    }
^{ws}*{title}:      {
                        ECHOS("<span class=title>");
                        ECHO;
                        ECHOS("</span>");
                    }
NOTE:               {
                        ECHOS("<span class=NOTE></span>");
                    }
TLDR                {
                        ECHOS("<span class=TLDR></span>");
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
{begin_code}        {
                        BEGIN IN_CODE;
                        size_t br = (yytext[0] == '{');
                        size_t lb = strlen("@begin=");
                        size_t nl = (yytext[yyleng-1] == '\n');
                        size_t offset = br + lb;
                        language = string(yytext+offset, yyleng-(offset+nl));
                    }

^#define\ [_a-z]+   {
                        BEGIN IN_DEFINE;
                        string name = string(yytext + strlen("#define "));
                        string id = generateRandomString(6);
                        ECHOS("<h1 style='visibility: hidden; font-size: 0;' id=");
                        ECHOS(id.c_str());
                        ECHOC('>');
                        ECHOS(name.c_str());
                        ECHOS("</h1>");

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
                        char * code = strdup(code_buffer.c_str());
                        int width = (int)indent_width(code);
                        code = dedent(code);
                        // ---
                        ECHOS("<code class=language-");
                          ECHOS(language.c_str());

                          ECHOS(" style='margin-left: ");
                          ECHOI(width);
                          ECHOS("ch'");
                        ECHOS(">");

                            ECHOS(code);

                        ECHOS("</code>");
                        // ---
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
