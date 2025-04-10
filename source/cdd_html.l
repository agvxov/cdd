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

    #define PRESERVE_LEADING_WHITESPACE\
        char * PLW_c;\
        for (\
            PLW_c = yytext; \
            *PLW_c == ' ' || *PLW_c == '\t';\
            PLW_c++\
        ) {\
            ECHOC(*PLW_c);\
        }
%}

ws              [ \t\r\v\f]
wsnl            [ \t\r\v\f\n]
title           [a-zA-Z0-9_]+
link_root       \/\/₩|\/\/\(0x[0-9a-f]+\)➞
heading         ^{ws}*{title}:{ws}*{link_root}
begin_code      \{?@begin=[a-z]+@\n?
begin_figure    {ws}*\{@begin=figure@\n
href            https?:\/\/[-a-zA-z0-9._%?/=#]+

%s IN_COMMENT IN_MULTILINE_COMMENT IN_DEFINE IN_STRING IN_COLOR
%x IN_CODE IN_FIGURE
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
{ws}*{href}         {
                        PRESERVE_LEADING_WHITESPACE;
                        ECHOS("<a href='");
                        ECHOS(PLW_c);
                        ECHOS("'>");
                        ECHOS(PLW_c);
                        ECHOS("</a>");
                    }
{ws}*NOTE:          {
                        PRESERVE_LEADING_WHITESPACE;
                        ECHOS("<span class=NOTE></span>");
                    }
^{ws}*YYY:          {
                        PRESERVE_LEADING_WHITESPACE;
                        ECHOS("<span class='YYY'></span>");
                    }
^{ws}*XXX:          {
                        PRESERVE_LEADING_WHITESPACE;
                        ECHOS("<span class='XXX'></span>");
                    }
^{ws}*[pP]ros:      {
                        PRESERVE_LEADING_WHITESPACE;
                        ECHOS("<span class=pros></span>");
                    }
^{ws}*[cC]ons:      {
                        PRESERVE_LEADING_WHITESPACE;
                        ECHOS("<span class=cons></span>");
                    }
^{ws}*{title}:      {
                        ECHOS("<span class=title>");
                        ECHO;
                        ECHOS("</span>");
                    }
TLDR                {
                        ECHOS("<span class=TLDR></span>");
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
\"                  {
                        BEGIN IN_STRING;
                        ECHOS("<span class=string-literal>");
                        ECHO;
                    }
{begin_figure}      {
                        BEGIN IN_FIGURE;
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
Red\(               {
                        BEGIN IN_COLOR;
                        for (size_t i = 0; i < strlen("Red("); i++) {
                            ECHOC(' ');
                        }
                        ECHOS("<span class=red>");
                    }
Green\(             {
                        BEGIN IN_COLOR;
                        for (size_t i = 0; i < strlen("Green("); i++) {
                            ECHOC(' ');
                        }
                        ECHOS("<span class=green>");
                    }
Blue\(              {
                        BEGIN IN_COLOR;
                        for (size_t i = 0; i < strlen("Blue("); i++) {
                            ECHOC(' ');
                        }
                        ECHOS("<span class=blue>");
                    }
Yellow\(            {
                        BEGIN IN_COLOR;
                        for (size_t i = 0; i < strlen("Yellow("); i++) {
                            ECHOC(' ');
                        }
                        ECHOS("<span class=yellow>");
                    }
Purple\(            {
                        BEGIN IN_COLOR;
                        for (size_t i = 0; i < strlen("Purple("); i++) {
                            ECHOC(' ');
                        }
                        ECHOS("<span class=purple>");
                    }
.|\n                {
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
\<                      {
                            code_buffer += "&lt;";
                        }
\>                      {
                            code_buffer += "&gt;";
                        }
.|\n                    {
                            code_buffer += yytext;
                        }
{ws}*@end=[a-z]+@\}?    {
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

<IN_FIGURE>{
\<                      {
                            code_buffer += "&lt;";
                        }
\>                      {
                            code_buffer += "&gt;";
                        }
@end=figure@\}\n        {
                            char * figure = strdup(code_buffer.c_str());
                            int width = (int)indent_width(figure);
                            figure = dedent(figure);
                            // ---
                            ECHOS("<div class=figure style='margin-left: ");
                              ECHOI(width);
                              ECHOS("ch'>");
                            ECHOS(figure);
                            ECHOS("</div>");
                            // ---
                            free(figure);
                            code_buffer = "";
                            BEGIN INITIAL;
                        }
.|\n                    {
                            code_buffer += yytext;
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

<IN_STRING>{
\\\"|\\\n   {
                ECHO;
            }
\"|\n       {
                ECHO;
                ECHOS("</span>");
                BEGIN INITIAL;
            }
.           {
                ECHO;
            }
}

<IN_COLOR>{
\)          {
                ECHOC(' ');
                ECHOS("</span>");
                BEGIN INITIAL;
            }
.|\n        {
                ECHO;
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
