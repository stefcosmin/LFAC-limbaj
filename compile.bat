echo "compiling %1"
del lex.yy.c
del %1.tab.c
del %1.tab.h
del %1.exe
bison -d %1.y
flex %1.l
g++ lex.yy.c  %1.tab.c -o %1
