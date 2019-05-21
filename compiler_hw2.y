/* Definition section */
%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>

    typedef struct sssss {
        int index;
        char name[32];
        char kind[16];
        char type[8];
        int scope;
        char attribute[32];
        struct sssss *next;
    } symbol_t;

    typedef struct {
        symbol_t *head;
    } table_t;


    extern int yylineno;
    extern int yylex();
    extern char* yytext;   // Get current token from lex
    extern char buf[256];  // Get current code line from lex
    extern char code_line[128];

    void yyerror(char *s);

    /* Symbol table function - you can add new function if needed. */
    void create_symbol();
    void insert_symbol(symbol_t);
    int lookup_symbol();
    void dump_symbol();

    table_t *t[32];                  // symbol table
    symbol_t reading, rfunc;
    int scope = 0;                   // record what scope it is now
    int create_table_flag[32] = {0}; // decide whether need to create table
    int table_item_index[32] = {0};
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

program:
      program external
    | external
    ;

external:
      declaration
    | func_def
    ;

stat:
      compound_stat         { ; }
    | expression_stat       { ; }
    | print_func            { ; }
    | selection_stat        { ; }
    | loop_stat             { ; }
    | jump_stat             { ; }
    ;

declaration:
      type 
      ID                    { strcpy(reading.name, $2); } 
      "="                   
      initializer           
      SEMICOLON             { strcpy(reading.kind, "variable"); 
                              reading.scope = scope;
                              reading.index = table_item_index[scope];
                              table_item_index[scope]++; 
                              insert_symbol(reading); }
    | type              
      ID                    { strcpy(reading.name, $2);} 
      SEMICOLON             { strcpy(reading.kind, "variable"); 
                              reading.scope = scope;
                              reading.index = table_item_index[scope];
                              table_item_index[scope]++; 
                              insert_symbol(reading); }
    ;

/* actions can be taken when meet the token or rule */
type:
      INT                   { strcpy(reading.type, $1); strcpy(rfunc.type, $1); }
    | FLOAT                 { strcpy(reading.type, $1); strcpy(rfunc.type, $1); }
    | BOOL                  { strcpy(reading.type, $1); strcpy(rfunc.type, $1); }
    | STRING                { strcpy(reading.type, $1); strcpy(rfunc.type, $1); }
    | VOID                  { strcpy(reading.type, $1); strcpy(rfunc.type, $1); }
    ;

initializer:
      const
    | ID                    { ; }
    ;

const: 
      I_CONST               { ; }
    | F_CONST               { ; }
    | STR_CONST             { ; }
    ;

func_def:
      type 
      declarator 
      compound_stat         
    ;

declarator:
      direct_declarator
    ;

direct_declarator:
      ID                    { strcpy(rfunc.name, $1); } 
    | direct_declarator 
      "(" 
       ")"                  { strcpy(rfunc.kind, "function"); 
                              rfunc.scope = scope;
                              rfunc.index = table_item_index[scope]; 
                              table_item_index[scope]++; 
                              insert_symbol(rfunc); }
    | direct_declarator 
      "("                   
      parameters 
      ")"                   { strcpy(rfunc.kind, "function"); 
                              rfunc.scope = scope; 
                              rfunc.index = table_item_index[scope];
                              table_item_index[scope]++;
                              insert_symbol(rfunc); }
    ;

parameters:
      type 
      ID                    { strcpy(reading.name, $2); 
                              strcpy(reading.kind, "parameter");
                              scope++; 
                              reading.scope = scope; 
                              reading.index = table_item_index[scope];
                              table_item_index[scope]++;
                              insert_symbol(reading);
                              scope--; }
    | type 
      ID                    { strcpy(reading.name, $2); 
                              strcpy(reading.kind, "parameter");
                              scope++; 
                              reading.scope = scope; 
                              reading.index = table_item_index[scope];
                              table_item_index[scope]++;
                              insert_symbol(reading);
                              scope--; }
      ","                   
      parameters
    ;


compound_stat:
      "{"                   {;}
      "}"                   {;}
    | "{"                   { scope++; }
      block_item_list 
      "}"                   
    ;

block_item_list:
      block_item 
    | block_item_list block_item
    ;

block_item:
      stat
    | declaration
    ;

expression_stat:
      SEMICOLON             {;}
    | expr SEMICOLON        {;}
    ;

expr:
      assign_expr
    | expr "," assign_expr
    ;

assign_expr:
      conditional_expr
    | unary_expression assign_op assign_expr
    ;

assign_op:
      "="
    | MULASGN
    | DIVASGN
    | MODASGN
    | ADDASGN
    | SUBASGN
    ;

conditional_expr:
      logical_or_expr
    ;

logical_or_expr:
      logical_and_expr
    | logical_or_expr OR logical_and_expr
    ;

logical_and_expr:
      equality_expression
    | logical_and_expr AND equality_expression
    ;

equality_expression:
      relational_expression
    | equality_expression EQ relational_expression
    | equality_expression NE relational_expression
    ;

relational_expression:
      additive_expression
    | relational_expression "<" additive_expression
    | relational_expression ">" additive_expression
    | relational_expression LTE additive_expression
    | relational_expression MTE additive_expression
    ;

additive_expression:
      multiplicative_expression
    | additive_expression "+" multiplicative_expression
    | additive_expression "-" multiplicative_expression
    ;


multiplicative_expression:
      cast_expression
    | multiplicative_expression "*" cast_expression
    | multiplicative_expression "/" cast_expression
    | multiplicative_expression "%" cast_expression
    ;

cast_expression:
      unary_expression
    | "(" type ")" cast_expression
    ;

unary_expression:
      postfix_expression
    | INC unary_expression
    | DEC unary_expression
    | unary_operator cast_expression
    ;

unary_operator:
      "+"
    | "-"
    | "!"
    ;

postfix_expression:
      primary_expr
    | postfix_expression INC
    | postfix_expression DEC
    | postfix_expression "(" ")"
    | postfix_expression "(" argument_list_expr ")"
    ;

argument_list_expr:
      assign_expr
    | argument_list_expr "," assign_expr
    ;

primary_expr:
      ID
    | const
    | "(" expr ")"
    ;

print_func:
      PRINT "(" STR_CONST ")" SEMICOLON   {;}
    | PRINT "(" ID ")" SEMICOLON         {;}
    ;

selection_stat:
      IF "(" expr ")" stat ELSE stat
    | IF "(" expr ")" stat
    ;

loop_stat:
      WHILE                 {;}
      "("                   {;}
      expr
      ")"                   {;}
      stat
    ;

jump_stat:
      RETURN SEMICOLON
    | RETURN expr SEMICOLON
    ;

%%

/* C code section */
int main(int argc, char** argv)
{
    for (int i = 0; i < 32; i++)
        t[i] = NULL;
    
    yylineno = 0;

    yyparse();
    dump_symbol();                              // dump table[0]
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
    //puts("!!!!!!!!!!!!!!!!!!!!create_symbol");
    t[scope] = malloc(sizeof(table_t));
    if (t[scope] == NULL)
        return;
    t[scope]->head = NULL;
    create_table_flag[scope] = 1;
    //tin++;
}

/* add new node at tail */
void insert_symbol(symbol_t x) 
{
    //puts("!!!!!!!!!!!!!!!!!insert_symbol");
    //printf("~~~~~~~~~~~~scope=%d\n", scope);
    symbol_t *nw, *p; 
    if (!create_table_flag[scope])
        create_symbol();

    if ( t[scope] == NULL )
        return;
    nw = malloc(sizeof(symbol_t));
    if ( nw == NULL )
        return;
    *nw = x;

    
    if ( t[scope]->head == NULL ) {
        nw->next = NULL;
        t[scope]->head = nw;
        return;
    }
    
    /* move to the tail of the list */
    for ( p = t[scope]->head; p->next != NULL; p = p->next ) ;
    nw->next = NULL;
    p->next = nw;

}

int lookup_symbol() 
{

}

void dump_symbol() 
{
    //puts("!!!!!!!!!!!!!!!!!dump_symbol");
    //printf("~~~~~~~~~~~~scope=%d\n", scope);
    symbol_t *p, *prev;
    if ( t[scope] == NULL ) {
        //puts("!!!!!!!!!!!!!!!!!but actually dump nothing");
        scope--;
        return;
    }
    if ( t[scope]->head == NULL ) {
        free(t[scope]);
        return;
    }
    printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
           "Index", "Name", "Kind", "Type", "Scope", "Attribute");
    for ( p = t[scope]->head; p != NULL; ) {
        printf("%-10d%-10s%-12s%-10s%-10d%-10s\n",
               p->index, p->name, p->kind, p->type, p->scope, p->attribute);
        prev = p;
        p = p->next;
        free(prev);
    }
    puts("");
    free(t[scope]);
    create_table_flag[scope] = 0;
    table_item_index[scope] = 0;
    scope--;
}
