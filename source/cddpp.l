%{
    #include <stdlib.h>
    #include <string.h>
    #include <ctype.h>
    #include <string>
    #include <vector>
    #include <dictate.hpp>

    using namespace std;

    typedef struct {
        string name;
        size_t nesting;
    } title_t;

    vector<title_t> titles;

    title_t tmp_title = {
        .name = "",
        .nesting = 0,
    };

    size_t last_absolute_nesting;
    size_t n_skipped_lines = 0;
    size_t prev_indent;
    size_t indent;

    string to_title_case(string s) {
        if (s.empty()) return s;

        s[0] = toupper(s[0]);
        for (size_t i = 1; i < s.size(); i++) {
            s[i] = tolower(s[i]);
        }
        
        return s;
    }
%}

title       [a-zA-Z0-9_]+
ws          [ \t\r\v\f]
wsnl        [ \t\r\v\f\n]
link_root   \/\/(₩)|(0x[0-9a-d]+➞)

%x IN_ABSOLUTE_TITLE
%x IN_NODE
%x IN_INDENT
%x IN_SKIP
%option nodefault
%option noyywrap
%%

<INITIAL>{
#skip                       {
                                BEGIN IN_SKIP;
                            }
^\                          {
                                BEGIN IN_INDENT;
                                yyless(0);
                                prev_indent = indent;
                                indent = 0;
                            }
#define\ {title}:           {
                                BEGIN IN_ABSOLUTE_TITLE;
                                size_t lprefix = strlen("#define ");
                                tmp_title.name = to_title_case(string(yytext + lprefix, yyleng - lprefix - 1));
                            }
{title}:{ws}*{link_root}    { // RELATIVE_TITLE
                                size_t i;
                                for (i = 0; yytext[i] != ':'; i++) { ; }
                                tmp_title.name = to_title_case(string(yytext, i));
                                tmp_title.nesting = last_absolute_nesting + indent;
                                titles.push_back(tmp_title);
                                tmp_title = (title_t) {
                                    .name = "",
                                    .nesting = 0,
                                };
                            }
.|\n                        { ; }
}

<IN_ABSOLUTE_TITLE>{
:                   {
                        ++tmp_title.nesting;
                    }
{ws}*{link_root}    {
                        last_absolute_nesting = tmp_title.nesting;
                        titles.push_back(tmp_title);
                        tmp_title = (title_t) {
                            .name = "",
                            .nesting = 0,
                        };
                        BEGIN INITIAL;
                    }
.|\n                { // false alarm, abort
                        BEGIN INITIAL;
                    }
}

<IN_SKIP>{
#piks       {
                BEGIN INITIAL;
            }
.           { ; }
\n          {
                ++n_skipped_lines;
            }
}

<IN_INDENT>{
\ \ \ \     {
                ++indent;
            }
.|\n        {
                yyless(0);
                BEGIN INITIAL;
            }
}

%%

void make_overview(FILE * f) {
    for (const auto & title : titles) {
        if (title.nesting == 0) {
            fdictate(f, title.name.c_str(), "\n");
        }
    }
}

void make_toc(FILE * f) {
    #define LINK_PADDING 30
    for (size_t i = 0; i < titles.size(); i++) {
        const auto & title = titles[i];
        // indent
        for (size_t h = 0; h < title.nesting; h++) {
            fdictate(f, "    ");
        }
        // name
        fdictate(f, title.name.c_str());
        // trailing
        const size_t trailing = (LINK_PADDING - title.nesting*4 - title.name.size());
        for (size_t h = 0; h < trailing; h++) {
            fdictate(f, '.');
        }
        // number
        fprintf(f, "(0x%012x)➞\n", (int)i); // XXX
    }
    #undef LINK_PADDING
}

void render(const char * f, const char * of, const char * tf) {
    if (not f
    &&  not of
    &&  not tf) {
        return;
    }

    if (of) {
        FILE * h_overview = fopen(of, "w");
        make_overview(h_overview);
        fclose(h_overview);
    }

    if (tf) {
        FILE * h_toc = fopen(tf, "w");
        make_toc(h_toc);
        fclose(h_toc);
    }
}

int init_cddpp_l(void) {
    return 0;
}
