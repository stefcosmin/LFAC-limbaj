%{
#include <iostream>
#include <cstdlib>
#include <cstring>
using namespace std;

/* Declaratii pentru lex */
extern int yylex();
void yyerror(const char* s) {
    cerr << "Eroare de sintaxa: " << s << endl;
}

%}

/* Tipurile posibile pentru yylval */
%union {
    int ival;
    float fval;
    bool bval;
    char* sval;
}

/* Tokenii primiti de la lex */
%token CLASS IF WHILE RETURN MAIN PRINT
%token INT FLOAT STRING BOOL VOID
%token IDENT
%token INT_LIT FLOAT_LIT STRING_LIT BOOL_LIT
%token ASSIGN
%token ARITHOP LOGICOP RELOP

/* Precedenta operatorilor */
%left LOGICOP
%nonassoc RELOP
%left '+' '-'
%left '*' '/'

%%


program
    : global_decls main_block
    ;

global_decls
    : /* gol */
    | global_decls class_decl
    | global_decls function_decl
    ;

class_decl
    : CLASS IDENT '{' class_body '}' ';'
    ;

class_body
    : /* gol */
    | class_body field_decl
    | class_body method_decl
    ;

field_decl
    : type IDENT ';'
    ;

method_decl
    : type IDENT '(' param_list ')' '{' stmt_list '}'
    ;

function_decl
    : type IDENT '(' param_list ')' '{' stmt_list '}'
    ;

param_list
    : /* gol */
    | param_list_nonempty
    ;

param_list_nonempty
    : param
    | param ',' param_list_nonempty
    ;

param
    : type IDENT
    ;

type
    : INT
    | FLOAT
    | STRING
    | BOOL
    | IDENT
    ;

main_block
    : MAIN '(' ')' '{' stmt_list '}'
    ;

stmt_list
    : /* gol */
    | stmt_list stmt
    ;

stmt
    : declaration       
    | assignment ';'
    | if_stmt
    | while_stmt
    | func_call_stmt
    | RETURN expr ';'
    ;

declaration
    : type IDENT ';'
    ;

assignment
    : lvalue ASSIGN expr
    ;


lvalue
    : IDENT
    | IDENT '.' IDENT
    ;

if_stmt
    : IF '(' expr ')' '{' stmt_list '}'
    ;

while_stmt
    : WHILE '(' expr ')' '{' stmt_list '}'
    ;

/* Expresii descompuse pe nivele pentru a evita conflictele */
expr
    : logic_expr
    ;

logic_expr
    : logic_expr LOGICOP rel_expr
    | rel_expr
    ;

rel_expr
    : rel_expr RELOP add_expr
    | add_expr
    ;

add_expr
    : add_expr '+' mul_expr
    | add_expr '-' mul_expr
    | mul_expr
    ;

mul_expr
    : mul_expr '*' atom
    | mul_expr '/' atom
    | atom
    ;

/* Atomii pot fi literal, lvalue sau apel de functie */
atom
    : '(' expr ')'
    | literal
    | IDENT '(' arg_list ')'             /* apel functie global */
    | IDENT '.' IDENT '(' arg_list ')'   /* apel metoda obiect */
    | PRINT '(' expr ')'                 /* functie predefinita */
    | lvalue                             /* orice alt IDENT -> lvalue */
    ;

/* Apel de functie ca instructiune separata */
func_call_stmt
    : IDENT '(' arg_list ')' ';'
    | IDENT '.' IDENT '(' arg_list ')' ';'
    | PRINT '(' expr ')' ';'
    ;

/* Lista de argumente */
arg_list
    : /* gol */
    | arg_list_nonempty
    ;

arg_list_nonempty
    : expr
    | expr ',' arg_list_nonempty
    ;

/* Literali */
literal
    : INT_LIT
    | FLOAT_LIT
    | STRING_LIT
    | BOOL_LIT
    ;

%%

int main() {
    return yyparse();
}
