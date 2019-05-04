/* Definition section */
%{
    #include <stdio.h>
    #include <stdlib.h>

    extern int yylineno;
    extern int yylex();
    extern char* yytext;   // Get current token from lex
    extern char buf[256];  // Get current code line from lex

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
%token ID SEMICOLON
%token INC DEC
%token ADDASGN SUBASGN MULASGN DIVASGN MODASGN


/* Token with return, which need to sepcify type */
%token <i_val> I_CONST
%token <f_val> F_CONST
%token <string> STR_CONST
%token <string> INT FLOAT BOOL STRING VOID  /* the name of the types */


/* Nonterminal with return, which need to sepcify type */
%type <f_val> stat declaration compound_stat expression_stat print_func
%type <string> assign_op type 

/* Yacc will start at this nonterminal */
%start program

/* Grammar section */
%%

program
    : program stat
    |
    ;

stat
    : declaration
    | compound_stat
    | expression_stat
    | print_func
    ;

declaration
    : type ID '=' initializer SEMICOLON
    | type ID SEMICOLON
    ;

initializer
    : assign_expr
    ;


compound_stat
    : '{' stat '}'  
    ;

expression_stat
    : ID            
    | const
    | '(' expr ')' 
    ;

const 
    : I_CONST           { printf("type %s value %d", "int", $1); }
    | F_CONST           { printf("type %s value %f", "float", $1); }
    | STR_CONST         { printf("type %s value %s", "string", $1); }
    ;

expr
    : assign_expr
    | expr ',' assign_expr
    ;

assign_expr
    : unary_expr assign_op assign_expr
    ;

assign_op
    : '='
    | ADDASGN       
    | SUBASGN       
    | MULASGN       
    | DIVASGN       
    | MODASGN       
    ;

unary_expr
    : postfix_expr
    | INC unary_expr
    | DEC unary_expr
    | unary_op unary_expr
    ;

postfix_expr
    : expression_stat
    ;

unary_op
    : '+'
    | '-'
    | '!'
    ;

print_func
    : PRINT '(' const ')'
    ;

/* actions can be taken when meet the token or rule */
type
    : INT               { $$ = $1; }
    | FLOAT             { $$ = $1; }
    | BOOL              { $$ = $1; }
    | STRING            { $$ = $1; }
    | VOID              { $$ = $1; }
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
