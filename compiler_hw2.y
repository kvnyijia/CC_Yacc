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
        int func_forward_def;
        struct sssss *next;
    } symbol_t;

    typedef struct {
        symbol_t *head;
    } table_t;


    extern int yylineno;
    extern int yylex();
    extern char* yytext;                // Get current token from lex
    extern char buf[256];               // Get current code line from lex
    extern char code_line[256];

    void yyerror(char *s);

    /* Symbol table function - you can add new function if needed. */
    void create_symbol();
    void insert_symbol(symbol_t);
    int lookup_symbol(char *str , int up_to_scope);
    void dump_symbol();
    void dump_parameter();
    void push_type(char *str);
    void pop_type();

    table_t *t[32];                     // symbol table
    symbol_t reading, rfunc;
    int scope = 0;                      // record what scope it is now
    int create_table_flag[32] = {0};    // decide whether need to create table
    int table_item_index[32] = {0};
    char error_msg[32];                 // the name of the ID that causes error 
    int error_type_flag = 0;
    int syntax_error_flag = 0;
    char type_stack[10][8];             // a stack to record types
    int stack_index = 0;
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
%token TRUE FALSE

/* Token with return, which need to sepcify type */
%token <string> I_CONST
%token <string> F_CONST
%token <string> STR_CONST
%token <string> ID 
%token <string> INT FLOAT BOOL STRING VOID  /* the name of the types */

/* Nonterminal with return, which need to sepcify type */

// %type <string> const
%type <string> direct_declarator declarator
%type <string> type 


/* Yacc will start at this nonterminal */
%start program

/* Grammar section */
%%

program:
      external program
    | external
    ;

external:
      declaration
    | func_def
    ;

declaration:
      type 
      ID                    { strcpy(reading.name, $2);
                              if (lookup_symbol($2, scope)) { 
                                  error_type_flag = 1; 
                                  strcat(error_msg, "Redeclared variable ");
                                  strcat(error_msg, $2);
                              }
                            } 
      "="                   
      initializer           
      SEMICOLON             { strcpy(reading.kind, "variable");
                              pop_type(); 
                              reading.scope = scope;
                              reading.index = table_item_index[scope]; 
                              if (!error_type_flag) {
                                  table_item_index[scope]++;
                                  insert_symbol(reading);
                              } 
                            }
    | type              
      ID                    { strcpy(reading.name, $2);
                              if (lookup_symbol($2, scope)) { 
                                  error_type_flag = 1; 
                                  strcat(error_msg, "Redeclared variable ");
                                  strcat(error_msg, $2);
                              }
                            } 
      SEMICOLON             { strcpy(reading.kind, "variable");
                              pop_type(); 
                              reading.scope = scope;
                              reading.index = table_item_index[scope]; 
                              if (!error_type_flag) {
                                  table_item_index[scope]++;
                                  insert_symbol(reading); 
                              }
                            }
    | type                  
      declarator            { scope++;
                              dump_parameter();         // because haven't enter the scope yet
                              strcpy(rfunc.name, $2); 
                              if (lookup_symbol($2, scope)) { 
                                  error_type_flag = 1; 
                                  strcat(error_msg, "Redeclared function ");
                                  strcat(error_msg, $2);
                              }

                              strcpy(rfunc.kind, "function");
                              rfunc.func_forward_def = 1; 
                              pop_type();
                              rfunc.scope = scope;
                              rfunc.index = table_item_index[scope]; 
                              if (!error_type_flag) {
                                  table_item_index[scope]++;
                                  insert_symbol(rfunc);
                              }
                              strcpy(rfunc.attribute, ""); 
                            }
      SEMICOLON
    ;

/* actions can be taken when meet the token or rule */
type:
      INT                   { strcpy(reading.type, $1); strcpy(rfunc.type, $1); push_type($1); }
    | FLOAT                 { strcpy(reading.type, $1); strcpy(rfunc.type, $1); push_type($1); }
    | BOOL                  { strcpy(reading.type, $1); strcpy(rfunc.type, $1); push_type($1); }
    | STRING                { strcpy(reading.type, $1); strcpy(rfunc.type, $1); push_type($1); }
    | VOID                  { strcpy(reading.type, $1); strcpy(rfunc.type, $1); push_type($1); }
    ;

initializer:
      assign_expr
    ;

const: 
      I_CONST               
    | F_CONST               
    | STR_CONST             
    | TRUE
    | FALSE
    ;

func_def:
      type 
      declarator            { strcpy(rfunc.name, $2);
                              int result = lookup_symbol($2, scope);
                              if (result == 1) { 
                                  error_type_flag = 1; 
                                  strcat(error_msg, "Redeclared function ");
                                  strcat(error_msg, $2);
                              }
                              pop_type();
                              // the function wasn't declared before
                              // so it needs to be inserted
                              if (result != 2) {
                                  strcpy(rfunc.kind, "function"); 
                                  rfunc.scope = scope;
                                  rfunc.index = table_item_index[scope]; 
                                  table_item_index[scope]++; 
                                  insert_symbol(rfunc); 
                              }
                              strcpy(rfunc.attribute, "");
                            }
      compound_stat         
    ;

declarator:
      direct_declarator
    ;

direct_declarator:
      ID 
      "(" 
      ")"                   
    | ID 
      "("                   
      parameters 
      ")"                   
    ;

parameters:
      type 
      ID                    { strcat(rfunc.attribute, reading.type);
                              strcpy(reading.name, $2); 
                              strcpy(reading.kind, "parameter");
                              strcpy(reading.attribute, "");
                              scope++; 
                              reading.scope = scope; 
                              reading.index = table_item_index[scope];
                              table_item_index[scope]++;
                              insert_symbol(reading);
                              scope--; 
                              pop_type();
                            }
    | type 
      ID                    { strcat(rfunc.attribute, reading.type);
                              strcpy(reading.name, $2); 
                              strcpy(reading.kind, "parameter");
                              strcpy(reading.attribute, "");
                              scope++; 
                              reading.scope = scope; 
                              reading.index = table_item_index[scope];
                              table_item_index[scope]++;
                              insert_symbol(reading);
                              scope--;
                              pop_type(); 
                            }
      ","                   { strcat(rfunc.attribute, ", "); }
      parameters
    ;


compound_stat:
      "{"                   
      "}"                   
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

stat:
      compound_stat         
    | expression_stat       
    | print_func            
    | selection_stat        
    | loop_stat             
    | jump_stat             
    ;

expression_stat:
      SEMICOLON             
    | expr SEMICOLON        
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
      ID                    { if (!lookup_symbol($1, 0)) {
                                  error_type_flag = 1; 
                                  strcat(error_msg, "Undeclared variable ");
                                  strcat(error_msg, $1);
                              } 
                            }
    | const
    | "(" expr ")"
    ;

print_func:
      PRINT "(" STR_CONST ")" SEMICOLON
    | PRINT 
      "(" 
      ID ")" SEMICOLON      { if (!lookup_symbol($3, 0)) { 
                                  error_type_flag = 1; 
                                  strcat(error_msg, "Undeclared variable ");
                                  strcat(error_msg, $3);
                              } 
                            }    
    ;

selection_stat:
      IF "(" expr ")" compound_stat ELSE stat
    | IF "(" expr ")" compound_stat 
    ;

loop_stat:
      WHILE                 
      "("                   
      expr
      ")"                   
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
    if (!syntax_error_flag) {
        dump_symbol();                          // dump table[0]
        printf("\nTotal lines: %d \n", yylineno);
    }

    return 0;
}

void yyerror(char *s)
{
    if (strcmp(s, "syntax error") == 0) {
        yylineno++;
        printf("%d: %s\n", yylineno, code_line); 
        syntax_error_flag = 1;
    }
    
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno, code_line);
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
}

/* add a new node at tail */
void insert_symbol(symbol_t x) 
{
    //puts("!!!!!!!!!!!!!!!!!insert_symbol");
    //printf("~~~~~~~~~~~~~~~~~scope=%d\n", scope);
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
    for ( p = t[scope]->head; p->next != NULL; p = p->next ) 
        ;
    nw->next = NULL;
    p->next = nw;

}

/* check whether `str` is in the table or not
 * from the scope currently at down to `up_to_scope`
 * if it isn't, return 0
 * if it is, return 1
 * if it is a function forward defined before, return 2
 */
int lookup_symbol(char *str, int up_to_scope) 
{
    int i;
    symbol_t *p;
    for ( i = scope; i >= up_to_scope ; i-- ) {
        if (t[i] == NULL) {
            continue;
        }
        for ( p = t[i]->head; p != NULL; p = p->next ) {
            //printf("%s and %s\n", str, p->name);
            if (strcmp(str, p->name) == 0) {
                if (p->func_forward_def)
                    return 2;
                return 1;
            }
        }
    }
    return 0;
}

void dump_symbol() 
{
    //puts("!!!!!!!!!!!!!!!!!dump_symbol");
    //printf("~~~~~~~~~~~~scope=%d\n", scope);
    symbol_t *p, *prev;
    if (syntax_error_flag)
        return;

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
        if ( strcmp(p->attribute, "") == 0 ) {
            printf("%-10d%-10s%-12s%-10s%-10d\n",
                    p->index, p->name, p->kind, p->type, p->scope);
        }
        else {
            printf("%-10d%-10s%-12s%-10s%-10d%s\n",
                    p->index, p->name, p->kind, p->type, p->scope, p->attribute);
        }
        prev = p;
        p = p->next;
        free(prev);
    }
    puts("");
    free(t[scope]);
    t[scope] = NULL;
    //if (t[scope]==NULL)
    //    printf("free table[%d]\n", scope);
    create_table_flag[scope] = 0;
    table_item_index[scope] = 0;
    scope--;
}

void dump_parameter() 
{
    //puts("!!!!!!!!!!!!!!!!!dump_parameter");
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

    for ( p = t[scope]->head; p != NULL; ) {
        prev = p;
        p = p->next;
        free(prev);
    }
    
    free(t[scope]);
    t[scope] = NULL;
    create_table_flag[scope] = 0;
    table_item_index[scope] = 0;
    scope--;
}

void push_type(char *str)
{
    //printf("!!!!!!!!!!!!!!!!!push %s\n", str);
    strcpy(type_stack[stack_index], str);
    stack_index++;
}

void pop_type()
{
    stack_index--;
    //printf("!!!!!!!!!!!!!!!!!pop %s\n", type_stack[stack_index]);
    strcpy(rfunc.type, type_stack[stack_index]);
    strcpy(type_stack[stack_index], "");
}
