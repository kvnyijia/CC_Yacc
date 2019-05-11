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

    typedef struct {
        int index;
        char name[32];
        char kind[16];
        char type[8];
        int scope;
        char attribute[32];
        struct symbol_t *next;
    } symbol_t;

    typedef struct {
        symbol_t *head;
    } table_t;

    table_t *t;      /* symbol table */
    symbol_t reading;
    int tmp;
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
%token IF ELSE FOR WHILE
%token RETURN
%token SEMICOLON
%token ADDASGN SUBASGN MULASGN DIVASGN MODASGN
%token OR AND NOT
%token ADD "+" 
%token SUB "-" 
%token MUL "*" 
%token DIV "/" 
%token MOD "%"
%token INC DEC
%token LT "<"
%token MT ">"
%token LTE MTE EQ NE

%token ASGN "="
%token LB "("
%token RB ")"
%token COMMA ","
%token LCB "{"
%token RCB "}"
%token ENDOFFILE

/* Token with return, which need to sepcify type */
%token <string> I_CONST
%token <string> F_CONST
%token <string> STR_CONST
%token <string> ID 
%token <string> INT FLOAT BOOL STRING VOID  /* the name of the types */

/* Nonterminal with return, which need to sepcify type */

// %type <string> const


/* Yacc will start at this nonterminal */
%start program

/* Grammar section */
%%

program
    : program 
      external
//      ENDOFFILE             { puts("this is end!");}
    | external
    ;

external
    : declaration
    | func_def
    ;

stat
    : compound_stat         { ; }
    | expression_stat       { ; }
    | print_func            { ; }
    | selection_stat        { ; }
    | loop_stat             { ; }
    | jump_stat             { ; }
    ;

declaration
    : type                  
      ID                    
      "="                   
      initializer           
      SEMICOLON             
    | type 
      ID 
      SEMICOLON
    ;

/* actions can be taken when meet the token or rule */
type
    : INT                   { ; }
    | FLOAT                 { ; }
    | BOOL                  { ; }
    | STRING                { ; }
    | VOID                  { ; }
    ;

initializer
    : const
    | ID                    { ; }
    ;

const 
    : I_CONST               { ; }
    | F_CONST               { ; }
    | STR_CONST             { ; }
    ;

func_def
    : type declarator compound_stat
    ;

declarator
    : direct_declarator
    ;

direct_declarator
    : ID
    | direct_declarator "(" ")"
    | direct_declarator "(" parameters ")"
    ;

parameters
    : type 
      ID                    { ; }
    | type 
      ID                    { ; }
      ","                   { ; }
      parameters
    ;


compound_stat
    : "{"                   {;}
      "}"                   {;}
    | "{"                   {;}
      block_item_list 
      "}"                   {;}
    ;

block_item_list
    : block_item 
    | block_item_list block_item
    ;

block_item
    : stat
    | declaration
    ;

expression_stat
    : SEMICOLON             {;}
    | expr SEMICOLON        {;}
    ;

expr
    : assign_expr
    | expr "," assign_expr
    ;

assign_expr
    : conditional_expr
    | unary_expression assign_op assign_expr
    ;

assign_op
    : "="
    | MULASGN
    | DIVASGN
    | MODASGN
    | ADDASGN
    | SUBASGN
    ;

conditional_expr
    : logical_or_expr
    ;

logical_or_expr
    : logical_and_expr
    | logical_or_expr OR logical_and_expr
    ;

logical_and_expr
    : equality_expression
    | logical_and_expr AND equality_expression
    ;

equality_expression
    : relational_expression
    | equality_expression EQ relational_expression
    | equality_expression NE relational_expression
    ;

relational_expression
    : additive_expression
    | relational_expression "<" additive_expression
    | relational_expression ">" additive_expression
    | relational_expression LTE additive_expression
    | relational_expression MTE additive_expression
    ;

additive_expression
    : multiplicative_expression
    | additive_expression "+" multiplicative_expression
    | additive_expression "-" multiplicative_expression
    ;


multiplicative_expression
    : cast_expression
    | multiplicative_expression "*" cast_expression
    | multiplicative_expression "/" cast_expression
    | multiplicative_expression "%" cast_expression
    ;

cast_expression
    : unary_expression
    | "(" type ")" cast_expression
    ;

unary_expression
    : postfix_expression
    | INC unary_expression
    | DEC unary_expression
    | unary_operator cast_expression
    ;

unary_operator
    : "+"
    | "-"
    | "!"
    ;

postfix_expression
    : primary_expr
    | postfix_expression INC
    | postfix_expression DEC
    | postfix_expression "(" ")"
    | postfix_expression "(" argument_list_expr ")"
    ;

argument_list_expr
    : assign_expr
    | argument_list_expr "," assign_expr

primary_expr
    : ID
    | const
    | "(" expression_stat ")"
    ;

print_func
    : PRINT "(" STR_CONST ")" SEMICOLON   {;}
    | PRINT "(" ID ")" SEMICOLON         {;}
    ;

selection_stat
    : IF "(" expr ")" stat ELSE stat
    | IF "(" expr ")" stat
    ;

loop_stat
    : WHILE                 {;}
      "("                   {;}
      expr
      ")"                   {;}
      stat
    ;

jump_stat
    : RETURN SEMICOLON
    | RETURN expr SEMICOLON
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
    t = malloc(sizeof(table_t));
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
