%code requires {
    #include "src/ast.hpp"
}

%{

#include <iostream>
#include <cstdlib>
#include <cstring>
#include <optional>
#include <vector>
#include "src/ast.hpp"
#include <sstream>
#include <fstream>

#include "src/scope_node.hpp"
#include "src/type_codex.hpp"
#include "src/log.hpp"
using namespace std;

/* Declaratii pentru lex */
extern int yylex();
extern FILE* yyin;
extern char* yytext;
extern int yylineno;

std::vector<ASTNode*> main_asts;
int error_count = 0;
std::stringstream err_stream;

void yyerror(const char* s) {
    err_stream << "[ " << dsp::sprint_colored("ERROR", dsp::Color::RED) << " ] " << s << " at line " << yylineno << '\n';
    // cerr<<"Error at token:"<<yytext<<endl;
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
    ASTNode* ast;
}


// %error-verbose
/* Tokenii primiti de la lex */
%token CLASS IF WHILE RETURN MAIN PRINT
%token <sval> INT FLOAT STRING BOOL VOID 
%token <sval> IDENT
%type <sval> lvalue
%type <sval> type
%token <ival> INT_LIT
%token <fval> FLOAT_LIT
%token <sval> STRING_LIT
%token <bval> BOOL_LIT
%token ASSIGN
%token LOGICOP RELOP


%type <ast> expr logic_expr rel_expr add_expr mul_expr atom assignment stmt literal declaration


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
    | func_body declaration { 
        if ($2) main_asts.push_back($2); // Add this line
    }
    | func_body stmt {
        if ($2) main_asts.push_back($2);
    }
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
    : MAIN '(' ')' '{' { enter_scope(SNType::FUNCTION, "MAIN");}
    func_body '}' { exit_scope();}
    ;

stmt_list
    : /* gol */
    | stmt_list stmt {
          if ($2 != nullptr) {
              main_asts.push_back($2);
          }
      }
    ;


stmt
    : assignment ';'        { $$ = $1; }
    | PRINT '(' expr ')' ';'{
        $$ = new ASTNode(ASTKind::PRINT, "Print",
            std::unique_ptr<ASTNode>($3), nullptr, NType::VOID);
    }
    | if_stmt               { $$ = nullptr; }
    | while_stmt            { $$ = nullptr; }
    | RETURN expr ';'       { $$ = nullptr; }
    | func_call_stmt        { $$ = nullptr; }
    ;


declaration
    : type IDENT ';' {
        auto type_id = cdx.type_id($1);
        if(type_id == type_codex::invalid_t)
            invalid_type_err($1);

        current_scope->add_variable(var_data(type_id, $2, ""));
        $$ = nullptr; // No executable code needed for just "int a;"
    }
    | type IDENT ASSIGN expr ';' {
        auto type_id = cdx.type_id($1);
        if(type_id == type_codex::invalid_t)
            invalid_type_err($1);

        // Add to symbol table
        current_scope->add_variable(var_data(type_id, $2, "0"));
        
        // CREATE THE AST NODE FOR EXECUTION
        $$ = new ASTNode(
            ASTKind::ASSIGN,
            ":=",
            std::make_unique<ASTNode>(ASTKind::LEAF, $2, NType::INVALID), // Left side (Variable name)
            std::unique_ptr<ASTNode>($4), // Right side (Value)
            $4->expr_type
        );
    }
    ;

assignment
    : lvalue ASSIGN expr 
    {
        $$ = new ASTNode(
            ASTKind::ASSIGN,
            ":=",
            std::make_unique<ASTNode>(ASTKind::LEAF, $1, NType::INVALID),
            std::unique_ptr<ASTNode>($3),
            $3->expr_type
        );
    }
    ;



lvalue
    : IDENT {
        if(current_scope->variable_exists_upstream($1) == false) {
            std::string msg = "Attempted to reference a non existent variable '";
            msg += $1;
            msg += "'";
            yyerror(msg.c_str());
        }
    }
    | IDENT '.' IDENT {
        auto var = current_scope->get_variable_upstream($1); 
        if(var.has_value() == false){
            yyerror("Attempted to reference a non existent variable");
        }else{
            auto val = var.value();
            auto type_opt = cdx.get_by_id(val.type_id);
            if(type_opt.has_value() == false) {
            }
            else{ 
                auto type = type_opt.value();
                if(type.details->variable_exists($3) == false) {
                    std::string msg = "Attempted to reference a non existent member variable '";
                    msg += $3;
                    msg += "'";
                    yyerror(msg.c_str());
                }
            }
        } 
    }
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
    {
        $$ = new ASTNode(
            ASTKind::BINARY,
            yytext,
            std::unique_ptr<ASTNode>($1),
            std::unique_ptr<ASTNode>($3),
            NType::BOOL
        );
    }
    | rel_expr { $$ = $1; }
    ;


rel_expr
    : rel_expr RELOP add_expr
    {
        $$ = new ASTNode(
            ASTKind::BINARY,
            yytext,
            std::unique_ptr<ASTNode>($1),
            std::unique_ptr<ASTNode>($3),
            NType::BOOL
        );
    }
    | add_expr { $$ = $1; }
    ;


add_expr
    : add_expr '+' mul_expr
    {
        $$ = new ASTNode(
            ASTKind::BINARY,
            "+",
            std::unique_ptr<ASTNode>($1),
            std::unique_ptr<ASTNode>($3),
            $1->expr_type
        );
    }
    | add_expr '-' mul_expr
    {
        $$ = new ASTNode(
            ASTKind::BINARY,
            "-",
            std::unique_ptr<ASTNode>($1),
            std::unique_ptr<ASTNode>($3),
            $1->expr_type
        );
    }
    | mul_expr { $$ = $1; }
    ;


mul_expr
    : mul_expr '*' atom
    {
        $$ = new ASTNode(
            ASTKind::BINARY,
            "*",
            std::unique_ptr<ASTNode>($1),
            std::unique_ptr<ASTNode>($3),
            $1->expr_type
        );
    }
    | mul_expr '/' atom
    {
        $$ = new ASTNode(
            ASTKind::BINARY,
            "/",
            std::unique_ptr<ASTNode>($1),
            std::unique_ptr<ASTNode>($3),
            $1->expr_type
        );
    }
    | atom { $$ = $1; }
    ;


/* Atomii pot fi literal, lvalue sau apel de functie */
atom
    : '(' expr ')' { $$ = $2; }
    | literal
    | IDENT '(' arg_list ')'  {
    $$ = new ASTNode(ASTKind::LEAF, "OTHER", NType::INVALID);
}           /* apel functie global */
    | IDENT '.' IDENT '(' arg_list ')' {
    $$ = new ASTNode(ASTKind::LEAF, "OTHER", NType::INVALID);
}  /* apel metoda obiect */
    | lvalue  {
        $$ = new ASTNode(ASTKind::LEAF, $1, NType::INVALID);
      }                           /* orice alt IDENT -> lvalue */
    ;

/* Apel de functie ca instructiune separata */
func_call_stmt
    : IDENT '(' arg_list ')' ';' {
        if(current_scope->function_exists_upstream($1) == false) {
            std::string msg = "Attempted to reference a non existent function '";
            msg += $1;
            msg += "'";
            yyerror(msg.c_str());
        } 
    }
    | IDENT '.' IDENT '(' arg_list ')' ';' {
        auto var = current_scope->get_variable_upstream($1); 
        if(var.has_value() == false){
            yyerror("Attempted to reference a non existent variable");
        }else{
            auto val = var.value();
            auto type_opt = cdx.get_by_id(val.type_id);
            if(type_opt.has_value() == false) {
            }
            else{ 
                auto type = type_opt.value();
                if(type.details->function_exists($3) == false) {
                    std::string msg = "Attempted to reference a non existent member variable '";
                    msg += $3;
                    msg += "'";
                    yyerror(msg.c_str());
                }
            }
        } 
    }
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
    : INT_LIT    { $$ = new ASTNode(ASTKind::LEAF, std::to_string($1), NType::INT); }
    | FLOAT_LIT  { $$ = new ASTNode(ASTKind::LEAF, std::to_string($1), NType::FLOAT); }
    | STRING_LIT { $$ = new ASTNode(ASTKind::LEAF, $1, NType::STRING); }
    | BOOL_LIT   { $$ = new ASTNode(ASTKind::LEAF, $1 ? "true" : "false", NType::BOOL); }
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
    dsp::print(root, cdx, std::cout); 

    std::ofstream sym_file("tables.txt");    
    dsp::print_simple(root, cdx, sym_file);
    sym_file.close();

    scope_node* execution_scope = root;
    
    // Assuming scope_node has a public 'children' vector or map.
    // You might need to add a helper function in scope_node.hpp like get_child("MAIN")
    for (auto* child : root->children) { 
        if (child->name == "MAIN") {
            execution_scope = child;
            break;
        }
    }

    if (execution_scope == root) {
        std::cout << "Warning: Could not find MAIN scope. Variables inside main() will not be found.\n";
    }

    // Evaluate using the MAIN scope, not the root scope
    for (auto ast : main_asts) {
        ast->evaluate(execution_scope); 
    }
    

     if (error_count == 0) {
         cout << ">> The program is correct!" << endl;
     } else {
         cout << ">> Returned " << error_count << " errors." << endl;
     }
    std::cout << "\n";
    dsp::print(cdx);
    std::cout << "\n";
    std::cout << err_stream.str();

    pclose(yyin);    
}
