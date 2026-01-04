%{
#include <iostream>
#include <cstdlib>
#include <cstring>


#include "src/scope_node.hpp"
#include "src/type_codex.hpp"
#include "src/log.hpp"
using namespace std;

/* Declaratii pentru lex */
extern int yylex();
extern FILE* yyin;
extern char* yytext;
extern int yylineno;

int error_count = 0;

void yyerror(const char* s) {
    cerr << "Syntax error: " << s << " at line " << yylineno << endl;
    cerr<<"Error at token:"<<yytext<<endl;
    error_count++;
}

type_codex cdx;
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
        cdx.add($2, current_scope);
        } 
       class_body '}' ';' { exit_scope(); } 
    ;

class_body
    : /* gol */
    | class_body function_decl
    | class_body declaration
    ;


function_decl
    : type IDENT '(' param_list ')' {
        auto type_id = cdx.type_id($1);
        if(type_id == type_codex::invalid_t)
            invalid_type_err($1);

        current_scope->add_func(func_data(type_id, $2, recent_params));
        enter_scope(SNType::FUNCTION, $2);
        current_scope->add_variables(recent_params);
        recent_params.clear();
    }
    '{' func_body '}' { exit_scope(); }
    ;

func_body
    : /* */
    | func_body declaration
    | func_body stmt
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
    : type IDENT  {  
    auto type_id = cdx.type_id($1);
    if(type_id == type_codex::invalid_t)
        invalid_type_err($1);

    recent_params.emplace_back(var_data(type_id, $2, "")); 
    } 
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

declaration
    : type IDENT ';' {
        auto type_id = cdx.type_id($1);
        if(type_id == type_codex::invalid_t)
            invalid_type_err($1);

        current_scope->add_variable(var_data(type_id, $2, ""));
    }
    | type IDENT ASSIGN expr ';' {
        auto type_id = cdx.type_id($1);
        if(type_id == type_codex::invalid_t)
            invalid_type_err($1);

            current_scope->add_variable(var_data(type_id, $2, "<TODO: CALCULATE VALUE>"));
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
    yylineno = 1;
    if(argc < 2){
       std::cout <<"Please provide a path to the file you want to compile"; 
        return 0;
    }
    yyin=fopen(argv[1],"r");
    yyparse();
    dsp::print(root, cdx); 

     if (error_count == 0) {
         cout << ">> The program is correct!" << endl;
     } else {
         cout << ">> Returned " << error_count << " errors." << endl;
     }
    
}
