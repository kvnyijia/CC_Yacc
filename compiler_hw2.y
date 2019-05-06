/* Definition section */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    extern int yylineno;
    extern int yylex();
    extern char* yytext;   // Get current token from lex
    extern char buf[256];  // Get current code line from lex
    extern char code_line[128];

    void yyerror(char *s);

    /* Symbol table function - you can add new function if needed. */
    int lookup_symbol();
    void create_symbol();
    void insert_symbol();
    void dump_symbol();

%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    double f_val;
    char* string;
}

/* Token without return */  /* terminals */
%token PRINT 
%token IF ELSE FOR
%token SEMICOLON
%token INC DEC
%token ADDASGN SUBASGN MULASGN DIVASGN MODASGN

%token ASGN "="
%token LB "("
%token RB ")"
%token COMMA ","
%token LCB "{"
%token RCB "}"



/* Token with return, which need to sepcify type */
%token <string> I_CONST
%token <string> F_CONST
%token <string> STR_CONST
%token <string> ID 
%token <string> INT FLOAT BOOL STRING VOID  /* the name of the types */

%token <f_val> FAKETMP FAKETMP2 FAKETMP3 FAKETMP4 FAKETMP5



/* Nonterminal with return, which need to sepcify type */
%type <f_val> stat 
%type <f_val> declaration compound_stat expression_stat 
%type <f_val> print_func
%type <f_val> type 
%type <f_val> const
%type <f_val> func_def

/* Yacc will start at this nonterminal */
%start program

/* Grammar section */
%%

program
    : program stat
    | stat
    ;

stat
    : declaration
    | compound_stat
    | expression_stat
    | print_func
    ;


declaration
    : type 
      ID                    { strcat(code_line, $2); }
      "="                   { ; }
      initializer 
      SEMICOLON             { strcat(code_line, ";"); }
    | type ID SEMICOLON
    | type 
      ID                    { strcat(code_line, $2); }
      "("                   { ; }
      parameters 
      ")"                   { ; }
    ;

parameters
    : type 
      ID                    { strcat(code_line, $2); }
    | type 
      ID                    { strcat(code_line, $2); }
      ","                   { ; }
      parameters
    ;

initializer
    : const
    | ID                    { strcat(code_line, $1); }
    ;


compound_stat
    : func_def
    ;

func_def
    : declaration "{" FAKETMP4 "}"
    ;

expression_stat
    : FAKETMP
    | const
    ;

const 
    : I_CONST               { strcat(code_line, $1); }
    | F_CONST               { strcat(code_line, $1); }
    | STR_CONST             { strcat(code_line, $1); }
    ;

print_func
    : PRINT "(" FAKETMP4 ")"    { $$ = $3; }
    ;


/* actions can be taken when meet the token or rule */
type
    : INT                   { strcat(code_line, "int"); }
    | FLOAT                 { strcat(code_line, "float"); }
    | BOOL                  { strcat(code_line, "bool"); }
    | STRING                { strcat(code_line, "string"); }
    | VOID                  { strcat(code_line, "void"); }
    ;

%%

/* C code section */
int main(int argc, char** argv)
{
    yylineno = 0;

    yyparse();
    printf("\nTotal lines: %d \n", yylineno);

    return 0;
}

void yyerror(char *s)
{
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");
}

void create_symbol() 
{

}

void insert_symbol() 
{

}

int lookup_symbol() 
{

}

void dump_symbol() 
{
    printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
           "Index", "Name", "Kind", "Type", "Scope", "Attribute");
}
