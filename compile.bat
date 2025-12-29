echo "compiling %1"
del 'lex.yy.c'
del '%1.tab.c'
del '%1.tab.h'
del '%1.exe'
bison -d src/%1.y
flex src/%1.l
g++  -std=c++17 lex.yy.c  %1.tab.c -o %1
