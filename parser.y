%{
	#include <math.h>
	#include <stdio.h>
	#include <stdlib.h>
	#include "symbol.cpp"
	int g_addr = 1000;

	extern "C" {
		int yylex();
		void yyerror(char *);
	}
	string str;
	
%}
%token<str> ID NUM REAL
%token PTR DOT SIZEOF
%token TYPEDEF STRUCT
%token<iValue> INT FLOAT VOID
%token IF ELSE WHILE RETURN FOR 
%token PRINTF SCANF
%token STRING
%token PREPROC
%token ARRAY FUNCTION
%token MAIN
%token<str> GT LT LE GE NE EQ
%left GT LT LE GE NE EQ
%left AND OR
%right '='
%left '+' '-'
%left '*' '/'

%type<iValue> Type
%type<str> statement array 
%union {
 		int iValue; /* integer value */
 		float realValue;
 		char *str; /* identifier name */
	}


%%
start:	Function start
	| declare start
	| PREPROC start
	|
	;

declare: Type statement ';' { if(redeclare($2))
					{insert($2,$1,g_addr); g_addr+=4;}
				else
					{printf("Redecleration  %s \n",$2);} }
	| statement ';' 
	| ID ';' {  printf("Undeclared Variable %s\n",$1);}	
	| function_call ';' 	
	| Type function_call '{' statement_list '}'
	| array ';' 
	| Type array ';' { insert($2,ARRAY,g_addr);
							insert($2,$1,g_addr); g_addr+=4; } 
	| StructStmt ';'
	| error	
	;

block:	'{'{printf("Entered New scope\n");} statement_list {printf("Exited New Scope\n");}'}' 	
	;
statement_list:	statement_list Stmt
	|
	;
Stmt: while
	| declare
	| For
	| If
	| print
	| ';'
	| RETURN ';'{printf("Wrong return type\n");}
	| RETURN statement ';'
	;

expression:	
	| expression LE expression 
	| expression GE expression
	| expression NE expression
	| expression EQ expression
	| expression GT expression
	| expression LT expression
	| statement
	| array
	;


statement: ID{store($1);} '=' {store("=");} statement {assign();}
	| ID ',' statement
	| NUM ',' statement
	| ID{store($1);} '+'{store("+");} statement {temp_assign();} 
	| ID{store($1);} '-'{store("-");} statement {temp_assign();} 
	| ID{store($1);} '*'{store("*");} statement {temp_assign();} 
	| ID{store($1);} '/'{store("/");} statement {temp_assign();} 	
	| '(' statement ')'
	|  NUM {$$ = $1; store($1);}
	|   REAL {$$ = $1; store($1);}
	|   ID {$$=$1;store($1);}
	| array
	| array '=' statement {assign();}
	| array '+'{store("+");} statement {temp_assign();} 
	| array '-'{store("-");} statement {temp_assign();} 
	| array '*'{store("*");} statement {temp_assign();} 
	| array '/'{store("/");} statement {temp_assign();} 
	| function_call 
	;


function_call : ID'('')' {func($1);}
	| ID'('statement')' {func($1);}
	;

array : ID'['statement']' {array($1,$3);}
	;

Function: Type ID '(' ArgListOpt ')' block { insert($2,FUNCTION,g_addr); insert($2,$1,g_addr);g_addr+=4; if($1==268) printf("Wrong return type\n"); } 
	;

ArgListOpt: ArgList
	|
	;
ArgList:  ArgList ',' Arg
	| Arg
	;
Arg:	Type ID
	;

Type: INT 
	| FLOAT
	| VOID 
	;

while: WHILE{w_gen1();} '(' expression ')'{w_gen2();} block{w_gen3();} 
	;

For: FOR '(' expression ';'{f_gen1();} expression ';'{f_gen2();} expression ')'{f_gen3();} block {f_gen4();}
	;

If : IF '(' expression ')'{if_gen1();} block{if_gen2();} ELSE block{if_gen3();}	
	;

StructStmt : STRUCT ID '{' Type statement ';' '}' { insert($2,STRUCT,g_addr); g_addr+=4; } 
	;

print : PRINTF '(' expression ')' ';'
	;


%%

#include "lex.yy.c"
#include <ctype.h>


int main(int argc,char *argv[])
{
	FILE *file;
		file = fopen(argv[1], "r");
		if (!file)
		{
			fprintf(stderr, "Could not open %s\n", argv[1]);
			exit(1);
		}
		yyin = file;

	if(!yyparse())
		{
		printf("\nParsing done\n");
		printsym();
		}
	else
		printf("\nParsing failed\n");

	fclose(yyin);
	return 0;
}


void yyerror(char *s)
{
	printf("%d 	:	%s  %s \n",yylineno,s,yytext);
}


