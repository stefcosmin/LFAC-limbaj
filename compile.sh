#!/bin/bash
echo "compiling $1"
rm -f src/lex.yy.c
rm -f src/$1.tab.c
rm -f src/$1
bison -d src/$1.y -Wcounterexamples
lex src/$1.l
g++ src/lex.yy.c  src/$1.tab.c -o $1
