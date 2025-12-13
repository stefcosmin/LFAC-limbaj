%{
#include "limbaj.tab.h"   // Header generat de Bison (contine tokenii)
#include <cstring>        // Pentru strdup
%}

/* Sectiunea de reguli */
%%

/* Cuvinte cheie */
"class"     { return CLASS; }
"int"       { return INT; }
"float"     { return FLOAT; }
"string"    { return STRING; }
"bool"      { return BOOL; }
"void"      { return VOID; }

/* Structuri de control */
"if"        { return IF; }
"while"     { return WHILE; }
"return"    { return RETURN; }

/* Functia main și functia predefinita Print */
"main"      { return MAIN; }
"Print"     { return PRINT; }

/* Literali booleani */
"true"      { yylval.bval = true; return BOOL_LIT; }
"false"     { yylval.bval = false; return BOOL_LIT; }

/* Literali numerici */
[0-9]+"."[0-9]+ { 
    yylval.fval = atof(yytext);  // Conversie la float
    return FLOAT_LIT; 
}

[0-9]+ { 
    yylval.ival = atoi(yytext);  // Conversie la int
    return INT_LIT; 
}

/* Literal string */
\".*\" { 
    yylval.sval = strdup(yytext); 
    return STRING_LIT; 
}

/* Identificatori (nume de variabile, functii, clase) */
[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.sval = strdup(yytext); 
    return IDENT; 
}

/* Operatori relationali */
"==" | "!=" | "<" | ">" | "<=" | ">=" { 
    return RELOP; 
}

/* Operatori logici */
"&&" | "||" { 
    return LOGICOP; 
}

/* Operatori aritmetici */
"+" | "-" | "*" | "/" { 
    return ARITHOP; 
}

/* Operator de atribuire */
"=" { return ASSIGN; }

/* Separatori și simboluri */
";" { return ';'; }
"," { return ','; }
"(" { return '('; }
")" { return ')'; }
"{" { return '{'; }
"}" { return '}'; }
"." { return '.'; }

/* Spatii albe – ignorate */
[ \t\n]+ { /* ignoram */ }

/* Orice alt caracter */
. { return yytext[0]; }

%%
