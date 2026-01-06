#!/bin/bash
echo "compiling $1"
rm -f src/lex.yy.c
rm -f src/$1.tab.c
rm -f src/$1
bison -d src/$1.y -Wcounterexamples
lex src/$1.l
g++ -std=c++23 src/lex.yy.c  src/$1.tab.c src/ast.cpp -o $1

FILE="limbaj"

echo "compiling $FILE"
rm -f lex.yy.c
rm -f $FILE.tab.c
rm -f $FILE
bison -d src/$FILE.y -Wcounterexamples
lex src/$FILE.l
g++ lex.yy.c  $FILE.tab.c -o $FILE
