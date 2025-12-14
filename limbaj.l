%{
#include "limbaj.tab.h"
#include <cstring>   
#include <cstdlib>
#include <cstdio>   
%}

%x comment


%option noyywrap 
%%
"/*" {BEGIN comment;}
<comment>"*/" {BEGIN 0;}
<comment>.|\n ;

"class"     { return CLASS; }
"int"       { return INT; }
"float"     { return FLOAT; }
"string"    { return STRING; }
"bool"      { return BOOL; }
"void"      { return VOID; }


"if"        { return IF; }
"while"     { return WHILE; }
"return"    { return RETURN; }


"main"      { return MAIN; }
"Print"     { return PRINT; }


[0-9]+\.[0-9]+ { 
    yylval.fval = atof(yytext);  // Conversie la float
    return FLOAT_LIT; 
}


"true"      { yylval.bval = true; return BOOL_LIT; }
"false"     { yylval.bval = false; return BOOL_LIT; }



[0-9]+ { 
    yylval.ival = atoi(yytext);  // Conversie la int
    return INT_LIT; 
}


"=="|"!="|"<"|">"|"<="|">=" { 
    return RELOP; //operatori relationali
}


"&&"|"||" { 
    return LOGICOP;  //operatori logici
}


\".*\" { 
    yylval.sval = strdup(yytext);  //literal string
    return STRING_LIT; 
}


[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.sval = strdup(yytext);  //identificatori clase, functii
    return IDENT; 
}


"+"|"-"|"*"|"/" { 
    return ARITHOP; //operatii aritmetice
}


"=" { return ASSIGN; }


";" { return ';'; }
"," { return ','; }
"(" { return '('; }
")" { return ')'; }
"{" { return '{'; }
"}" { return '}'; }
"." { return '.'; }


[ \t\n]+ {  }


. { return yytext[0]; }

%%
