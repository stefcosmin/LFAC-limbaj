echo "compiling %1"
<<<<<<< HEAD
del 'src/lex.yy.c'
del 'src/%1.tab.c'
del 'src/%1.tab.h'
del 'src/%1.exe'
bison -d src/%1.y
flex src/%1.l
g++  -std=c++11 lex.yy.c  %1.tab.c -o %1
=======
del lex.yy.c
del %1.tab.c
del %1.tab.h
del %1.exe
bison -d src/%1.y
flex src/%1.l
g++ -std=c++17 lex.yy.c  %1.tab.c -o %1
>>>>>>> 9b43da7edb044eb0cf6dc570afbfbe99c8094485
