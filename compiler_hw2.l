/* Definition section */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "y.tab.h"

    int num_line = 0;
    int num_comment_line = 0;
    int flag = 1;
    char buf[256];
%}



/* Define regular expression label */

letter               [a-zA-Z]
digit                [0-9]
all_char             [\40-\176]
space_or_tab         [ \t]+
newline              [\n]
dot                  [.]
quota                ["]
slash                [/]
bslash               [\\]
star                 [*]
any_char_but_newline .
eol                  $


id                   {letter}+({letter}|{digit})*
i_const              {digit}+
f_const              {digit}+{dot}{digit}+
str_first            [^"\\]
str_const            [^"\\]*
esc_quota            {bslash}{quota}
lcom                 {slash}{star}
rcom                 {star}{slash}
non_rcom             [^{rcom}]


/* Rules section */
%x STR C_COMMENT CPP_COMMENT STR_PLUS
%%

"/*"     { printf("%s", yytext); BEGIN C_COMMENT; }
"//"     { printf("%s", yytext); BEGIN CPP_COMMENT; }
{quota}  { printf("%s \t QUOTA\n", yytext); BEGIN STR; }

"+"      { printf("%s \t ADD\n", yytext); }
"-"      { printf("%s \t SUB\n", yytext); }
"int"    { printf("%s \t INT\n", yytext); }
"float"  { printf("%s \t FLOAT\n", yytext); }
"bool"   { printf("%s \t BOOL\n", yytext); }
"string" { printf("%s \t STRING\n", yytext); }
";"      { printf("%s \t SEMICOLON\n", yytext); }
"="      { printf("%s \t ASGN\n", yytext); }
"true"   { printf("%s \t TRUE\n", yytext); }
"false"  { printf("%s \t FALSE\n", yytext); }
"*"      { printf("%s \t MUL\n", yytext); }
"/"      { printf("%s \t DIV\n", yytext); }
"%"      { printf("%s \t MOD\n", yytext); }
"++"     { printf("%s \t INC\n", yytext); }
"--"     { printf("%s \t DEC\n", yytext); }
"+="     { printf("%s \t ADDASGN\n", yytext); }
"-="     { printf("%s \t SUBASGN\n", yytext); }
"*="     { printf("%s \t MULASGN\n", yytext); }
"/="     { printf("%s \t DIVASGN\n", yytext); }
"%="     { printf("%s \t MODASGN\n", yytext); }
"<"      { printf("%s \t LT\n", yytext); }
">"      { printf("%s \t MT\n", yytext); }
"<="     { printf("%s \t LTE\n", yytext); }
">="     { printf("%s \t MTE\n", yytext); }
"=="     { printf("%s \t EQ\n", yytext); }
"!="     { printf("%s \t NE\n", yytext); }
"&&"     { printf("%s \t AND\n", yytext); }
"||"     { printf("%s \t OR\n", yytext); }
"!"      { printf("%s \t NOT\n", yytext); }
"("      { printf("%s \t LB\n", yytext); }
")"      { printf("%s \t RB\n", yytext); }
"{"      { printf("%s \t LCB\n", yytext); }
"}"      { printf("%s \t RCB\n", yytext); }
"if"     { printf("%s \t IF\n", yytext); }
"else"   { printf("%s \t ELSE\n", yytext); }
"print"  { printf("%s \t PRINT\n", yytext); }
"for"    { printf("%s \t FOR\n", yytext); }
"while"  { printf("%s \t WHILE\n", yytext); }
"return" { printf("%s \t RET\n", yytext); }
"["      { printf("%s \t LSB\n", yytext); }
"]"      { printf("%s \t RSB\n", yytext); }
","      { printf("%s \t COMMA\n", yytext); }
"void"   { printf("%s \t VOID\n", yytext); }
"continue" { printf("%s \t CONTINUE\n", yytext); }
"break"    { printf("%s \t BREAK\n", yytext); }


{id}                      { printf("%s \t ID\n", yytext); }
{i_const}                 { printf("%s \t I_CONST\n", yytext); }
{f_const}                 { printf("%s \t F_CONST\n", yytext); }
{space_or_tab}            {;}
\n                        { ++num_line; flag = 1; }

<STR>{str_first}          { printf("%s", yytext); BEGIN STR_PLUS; }
<STR>{esc_quota}          { printf("%s", yytext); BEGIN STR_PLUS; }
<STR>{quota}              { printf("%s \t QUOTA\n", yytext); BEGIN 0; }
<STR_PLUS>{str_const}     { printf("%s", yytext); }
<STR_PLUS>{esc_quota}     { printf("%s", yytext); }
<STR_PLUS>{quota}         { printf(" \t STR_CONST\n%s \t QUOTA\n", yytext); BEGIN 0; }
<C_COMMENT>"*/"           { printf("%s \t C Comment\n", yytext);
                            if (flag) {
                                ++num_comment_line;
                                flag = 0;
                            }
                            BEGIN 0;
                          }
<C_COMMENT>\n             { printf("\n");
                            ++num_comment_line;
                            flag = 1;
                            ++num_line; 
                          }
<CPP_COMMENT>{newline}    { printf(" \t C++ Comment%s", yytext); 
                            if (flag)
                                ++num_comment_line; 
                            ++num_line; 
                            flag = 1;
                            BEGIN 0; 
                          }

%%

/*  C Code section */
int yywrap(void)
{
    return 1;
}

/*
int main(int argc, char *argv[])
{
    yyin = fopen(argv[1], "r");
    yylex();
    printf("\nParse over, the line number is %d.\n\n", num_line);
    printf("comment: %d lines\n\n", num_comment_line);

    return 0;
}
*/
