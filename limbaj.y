%{
#include <iostream>
using namespace std;

/* Declaratii pentru lex */
int yylex();
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

/* Tokenii primiti de la lex*/
%token CLASS IF WHILE RETURN MAIN PRINT
%token INT FLOAT STRING BOOL VOID
%token IDENT
%token INT_LIT FLOAT_LIT STRING_LIT BOOL_LIT
%token ASSIGN
%token ARITHOP LOGICOP RELOP

%%

/* Programul este format din declaratii globale + blocul main */
program
    : global_decls main_block
    ;

/* Declaratii globale: clase si functii */
global_decls
    : global_decls class_decl
    | global_decls function_decl
    | /* gol */
    ;

/* Declaratie de clasa – permisa doar global */
class_decl
    : CLASS IDENT '{' class_body '}' ';'
    ;

/* Corpul clasei: campuri si metode */
class_body
    : class_body field_decl
    | class_body method_decl
    | /* gol */
    ;

/* Declaratie de camp */
field_decl
    : type IDENT ';'
    ;

/* Metoda a unei clase */
method_decl
    : type IDENT '(' param_list ')' '{' local_decls stmt_list '}'
    ;

/* Functie globala */
function_decl
    : type IDENT '(' param_list ')' '{' local_decls stmt_list '}'
    ;

/* Lista de parametri */
param_list
    : param_list ',' param
    | param
    | /* gol */
    ;

/* Parametru individual */
param
    : type IDENT
    ;

/* Tipuri de date (inclusiv clase) */
type
    : INT
    | FLOAT
    | STRING
    | BOOL
    | IDENT      /* tip definit de utilizator (clasa) */
    ;

/* Declaratii locale – DOAR la începutul functiei */
local_decls
    : local_decls var_decl
    | /* gol */
    ;

/* Declaratie de variabila */
var_decl
    : type IDENT ';'
    ;

/* Blocul main – NU permite declaratii */
main_block
    : MAIN '(' ')' '{' stmt_list '}'
    ;

/* Lista de instructiuni */
stmt_list
    : stmt_list stmt
    | /* gol */
    ;

/* Instructiuni permise */
stmt
    : assignment ';'
    | if_stmt
    | while_stmt
    | func_call ';'
    | RETURN expr ';'
    ;

/* Atribuire */
assignment
    : lvalue ASSIGN expr
    ;

/* Valoare stanga (variabila sau camp de obiect) */
lvalue
    : IDENT
    | IDENT '.' IDENT
    ;

/* Instructiune if */
if_stmt
    : IF '(' expr ')' '{' stmt_list '}'
    ;

/* Instructiune while */
while_stmt
    : WHILE '(' expr ')' '{' stmt_list '}'
    ;

/* Apel de functie */
func_call
    : IDENT '(' arg_list ')'
    | PRINT '(' expr ')'                /* functie predefinita */
    | IDENT '.' IDENT '(' arg_list ')'  /* metoda de obiect */
    ;

/* Lista de argumente */
arg_list
    : arg_list ',' expr
    | expr
    | /* gol */
    ;

/* Expresii */
expr
    : expr ARITHOP expr
    | expr RELOP expr
    | expr LOGICOP expr
    | '(' expr ')'
    | lvalue
    | literal
    | func_call
    ;

/* Literali */
literal
    : INT_LIT
    | FLOAT_LIT
    | STRING_LIT
    | BOOL_LIT
    ;

%%

/* Functia main a parserului */
int main() {
    return yyparse();
}
