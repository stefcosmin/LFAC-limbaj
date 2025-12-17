#!/bin/bash

FILE="limbaj"

echo "compiling $FILE"
rm -f lex.yy.c
rm -f $FILE.tab.c
rm -f $FILE
bison -d src/$FILE.y -Wcounterexamples
lex src/$FILE.l
g++ lex.yy.c  $FILE.tab.c -o $FILE
