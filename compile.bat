echo "compiling %1"
del 'lex.yy.c'
del '%1.tab.c'
del '%1.tab.h'
del '%1.tab.cc'
del '%1.tab.hh'
del 'location.hh'
del 'position.hh'
del 'stack.hh'

del '%1.exe'
bison -d src/%1.y
flex src/%1.l
g++  -std=c++23 lex.yy.c  %1.tab.c src/ast.cpp -o %1
