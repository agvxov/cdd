%{
    #include <stdlib.h>
    #include <string.h>
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

    class Node {
      public:
        string text;

        string render(void) const {
            return text;
        }
    } tmp_node;

    class AbsoluteTitle : public Node {
      public:
        string banner;
        
        string render(void) const {
            return banner + text;
        }
    } tmp_absolutetitle;

    class Subtitle : public Node {
      public:
        string render(void) const {
            return text + ':';
        }
    } tmp_subtitle;

    #include "tree.hh"
    tree<Node> syntax_tree;
    tree<Node>::iterator current_node;
%}

title       [a-zA-Z0-9_]+
ws          [ \t\r\v\f]
wsnl        [ \t\r\v\f\n]
link_root   \/\/(₩)|(0x[0-9a-d]+➞)

%x IN_ABSOLUTE_TITLE IN_SUBTITLE IN_BANNER
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
                                tmp_title.name = string(yytext + lprefix, yyleng - lprefix - 1);
                            }
{title}:{ws}*{link_root}    { // RELATIVE_TITLE
                                size_t i;
                                for (i = 0; yytext[i] != ':'; i++) { ; }
                                tmp_title.name = string(yytext, i);
                                tmp_title.nesting = last_absolute_nesting + indent;
                                titles.push_back(tmp_title);
                                tmp_title = (title_t) {
                                    .name = "",
                                    .nesting = 0,
                                };
                            }
^{ws}*>                     {
                                BEGIN IN_NODE;
                            }
^{ws}*-                     {
                                BEGIN IN_SUBTITLE;
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
                        BEGIN IN_BANNER;
                    }
.|\n                { // false alarm, abort
                        BEGIN INITIAL;
                    }
}

<IN_BANNER>{
\\\n                {
                        tmp_title;
                    }
\n                  {

                        BEGIN INITIAL;
                    }
}

<IN_SUBTITLE>{
.           {
                tmp_subtitle.text += yytext;
            }
:           {
                BEGIN INITIAL;
                syntax_tree.append_child(current_node, tmp_subtitle);
            }
\n          {
                tmp_subtitle.text += ' ';
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

<IN_NODE>{
.           {
                tmp_node.text += yytext;
            }
\n          {
                BEGIN INITIAL;
                syntax_tree.append_child(current_node, tmp_node);
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
        for (size_t i = 0; i < title.nesting; i++) {
            fdictate(f, "    ");
        }
        // name
        fdictate(f, title.name.c_str());
        // trailing
        const size_t trailing = (LINK_PADDING - title.nesting*4 - title.name.size());
        for (size_t i = 0; i < trailing; i++) {
            fdictate(f, '.');
        }
        // number
        fprintf(f, "(0x%012x)➞\n", (int)i); // XXX
    }
    #undef LINK_PADDING
}

void render(void) {
    for (const auto & it : syntax_tree) {
        dictate(it.render());
    }
}

int init_cddpp_l(void) {
    syntax_tree.clear();
    syntax_tree.set_head((Node) { .text = "" });
    current_node = syntax_tree.begin();
    return 0;
}
