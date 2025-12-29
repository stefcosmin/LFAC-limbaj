%{
#include <iostream>
#include <cstdlib>
#include <cstring>


#include "src/scope_node.hpp"
#include "src/log.hpp"

using namespace std;

/* Declaratii pentru lex */
extern int yylex();
extern FILE* yyin;
extern char* yytext;
extern int yylineno;

int error_count = 0;

void yyerror(const char* s) {
    cerr << "Eroare de sintaxa: " << s << " la linia " << yylineno << endl;
    cerr<<"Eroare la tokenul:"<<yytext<<endl;
    error_count++;
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
%error-verbose
/* Tokenii primiti de la lex */
%token CLASS IF WHILE RETURN MAIN PRINT
%token <sval> INT FLOAT STRING BOOL VOID 
%token <sval> IDENT
%token INT_LIT FLOAT_LIT STRING_LIT BOOL_LIT
%token ASSIGN
%token LOGICOP RELOP

/* Precedenta operatorilor */
%left LOGICOP
%nonassoc RELOP
%left '+' '-'
%left '*' '/'

%%


program 
    : global_decls { dsp::debug("Entered global scope"); }
      main_block { dsp::debug("Entered main block"); }
    ;

global_decls
    : /* gol */
    | global_decls declaration { dsp::debug("Processing global declaration"); } 
    | global_decls class_decl  { dsp::debug("Processing class declartions"); } 
    | global_decls function_decl { dsp::debug("Processing global function declaration"); } 
    ;

class_decl
    : CLASS IDENT '{' { 
        dsp::debug("Entered class scope");

        auto new_scope = new scope_node(SNType::CLASS, $2);
        current_scope->add_child(new_scope);
        } 
       class_body '}' ';' 
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
    : type IDENT '(' param_list ')' '{' stmt_list '}'
    ;

function_decl
    : type IDENT '(' param_list ')' '{' local_decls stmt_list '}'
    ;

// acts more or less like an alias
local_decls
    : /* gol */
    | opt_declarations ';'
    ;

// acts more or less like an alias
param_list
    : /* nik */
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
    : assignment ';'
    | if_stmt
    | while_stmt
    | func_call_stmt
    | RETURN expr ';'
    ;

opt_declarations 
    : /* nik */
    | declarations

declarations
    : declaration
    | declarations declaration
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

int main(int argc, const char* argv[]) {
    yylineno = 1;
    if(argc < 2){
       std::cout <<"Please provide a path to the file you want to compile"; 
        return 0;
    }
    yyin=fopen(argv[1],"r");
    yyparse();
    scope_node::print(root); 
    
     if (error_count == 0) {
         cout << ">> The program is correct!" << endl;
     } else {
         cout << ">> Returned " << error_count << " errors." << endl;
     }
    
}
