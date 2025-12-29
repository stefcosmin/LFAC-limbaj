%{
#include <iostream>
#include <cstdlib>
#include <cstring>

#include "src/scope_node.hpp"

using namespace std;

/* Declaratii pentru lex */
extern int yylex();
extern FILE* yyin;
extern char* yytext;
extern int yylineno;

int error_count = 0;

void yyerror(const char* s) {
    cerr << "Eroare de sintaxa: " << s << " la linia " << yylineno << endl;
}

auto root = new scope_node(SNType::DEFAULT, "global");
scope_node* current_scope = root;

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
%token <sval> INT FLOAT STRING BOOL VOID 
%token <sval> IDENT
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
    | global_decls declarations ';'
    | global_decls class_decl
    | global_decls function_decl
    ;

class_decl
    : CLASS IDENT '{' { 
        cout << "ENTER scope: " << $2 << endl;
        auto new_scope = new scope_node(SNType::CLASS, $2, current_scope);
        current_scope->add_child(new_scope);
        current_scope = new_scope;
        } 
       class_body '}' 
       ';' {
        current_scope = current_scope->parent;
        }
    ;

class_body
    : /* gol */
    | class_body field_decl
    | class_body method_decl
    ;

field_decl
    : type IDENT ';' { current_scope->add_variable(var_data($2, "", ""));}
    ;

method_decl
    : type IDENT '(' param_list ')' '{'  {
    auto new_scope = new scope_node(SNType::FUNCTION, $2, current_scope);
    current_scope->add_child(new_scope);
    current_scope = new_scope;
    }
    stmt_list '}' {
        current_scope = current_scope->parent;
    }
    ;

function_decl
    : type IDENT '(' param_list ')' {
// aici e gresit, trebuie $1 pt primul argument
    current_scope->add_function(func_data($2, $2));
    auto new_scope = new scope_node(SNType::FUNCTION, $2, current_scope);
    current_scope->add_child(new_scope);
    current_scope = new_scope;
     }
     '{' local_decls stmt_list '}' {
    current_scope = current_scope->parent;
    }
    
local_decls
    : /* gol */
    | local_decls declarations ';'
    ;

param_list
    : /* gol */
    | param_list_nonempty declarations ';'
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
    : MAIN '(' ')' '{' {
        auto new_scope = new scope_node(SNType::FUNCTION, "main", current_scope);
        current_scope->add_child(new_scope);
        current_scope = new_scope;
    }

    stmt_list '}' {
        current_scope = current_scope->parent;
    }
    ;

stmt_list
    : /* gol */
    | stmt_list stmt
    ;
    
stmt
    : assignment ';'
    | if_stmt
    | while_stmt
    | func_call_stmt
    | RETURN expr ';'
    ;

declarations
    : declarations declaration
    | /* gol */
    ;

declaration
    : type IDENT ';' { 
        current_scope->add_variable(var_data($2, "", ""));
    }   
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

int main(int argc, const char* argv[]) {
    if(argc < 2){
       std::cout <<"Please provide a path to the file you want to compile"; 
        return 0;
    }
     if (error_count == 0) {
         cout << ">> The program is correct!" << endl;
     } else {
         cout << ">> Returned " << error_count << " errors." << endl;
     }
    yyin=fopen(argv[1],"r");
    yyparse();
    scope_node::print(root); 

    delete root; 
}
