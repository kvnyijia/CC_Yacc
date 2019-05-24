# ComplierConstruction hw2 Yacc

This is a simple parser for the **μC** programming language.

## How to compile and run

```shell
$ lex compiler_hw2.l                # create lex.yy.c

$ yacc -d -v compiler_hw2.y         # create y.tab.[ch]

$ gcc lex.yy.c y.tab.c -o myparser

$ ./myparser < INPUT_FILE
```

or

```shell
$ make test
```
