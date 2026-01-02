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



void exit_scope() {
    current_scope = current_scope->parent;
}

void enter_scope(SNType type, const char* name){
    auto new_scope = new scope_node(type, name, current_scope);
    current_scope->add_child(new_scope);
    current_scope = new_scope;
}


std::vector<var_data> recent_params;


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
%type <sval> type
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
    | global_decls class_decl  { dsp::debug("Processing class declartion"); } 
    | global_decls function_decl { dsp::debug("Processing global function declaration"); } 
    ;

class_decl
    : CLASS IDENT '{' { 
        dsp::debug("Entered class scope");
        enter_scope(SNType::CLASS, $2);
        } 
       class_body '}' ';' { exit_scope(); } 
    ;

class_body
    : /* gol */
    | class_body method_decl
    | class_body field_decl
    ;

field_decl
    : type IDENT ';' { current_scope->add_variable(var_data($1, $2, ""));}
    ;

method_decl
    : type IDENT '(' param_list ')' { 
        current_scope->add_func(func_data($1, $2, recent_params));
        enter_scope(SNType::FUNCTION, $2);
        recent_params.clear();
    } 
    '{' method_body '}' { exit_scope(); }
    ;

method_body 
    : /* */
    | method_body declaration
    | method_body stmt
    ;

function_decl
    : type IDENT '(' param_list ')' 
    '{' func_body '}'
    ;

func_body
    : /* */
    | func_body declaration
    | func_body stmt
    ;


// acts more or less like an alias
local_decls
    : /* gol */
    | declarations
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
    : type IDENT  { recent_params.emplace_back(var_data($1, $2, "")); } 
    ;

type
    : INT     { $$ = strdup("int"); }
    | FLOAT   { $$ = strdup("float"); }
    | STRING  { $$ = strdup("string"); }
    | BOOL    { $$ = strdup("bool"); }
    | VOID    { $$ = strdup("void"); } 
    | IDENT   { $$ = strdup($1); }   /* tip definit de utilizator */
    ;

main_block
    : MAIN '(' ')' '{' { enter_scope(SNType::FUNCTION, "MAIN"); }
    func_body '}' { exit_scope();} 
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
    : declaration
    | declarations declaration
    ;

declaration
    : type IDENT ';' {current_scope->add_variable(var_data($1, $2, ""));}
    | type IDENT ASSIGN expr ';' {current_scope->add_variable(var_data($1, $2, "<TODO: CALCULATE VALUE>"));}
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
