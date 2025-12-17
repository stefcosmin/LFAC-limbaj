echo "compiling %1"
del 'src/lex.yy.c'
del 'src/%1.tab.c'
del 'src/%1.tab.h'
del 'src/%1.exe'
bison -d src/%1.y
flex src/%1.l
g++  -std=c++11 lex.yy.c  %1.tab.c -o %1
