#!/bin/bash

FILE="limbaj"

echo "compiling $FILE"
rm -f lex.yy.c
rm -f $FILE.tab.c
rm -f $FILE
bison -d $FILE.y -Wcounterexamples
lex $FILE.l
g++ lex.yy.c  $FILE.tab.c -o $FILE
