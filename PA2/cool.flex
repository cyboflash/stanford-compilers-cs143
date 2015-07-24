/*
 *  The scanner definition for COOL.
 */

 /*  Definitions
  *
  *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
  *  output, so headers and global definitions are placed here to be visible
  *  to the code in the file.  Don't remove anything that was here initially
  *
  *  This section contains declarations of simple name definitions to
  *  simplify the scanner specification and declarations of start conditions.
  */

%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */ #define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

/* Macros */

/* For debugging  */
#define MYECHO(n)              \
	do {                         \
		printf("\n----------\n");  \
		printf("Rule " #n "\n");   \
		ECHO;                      \
		printf("\n----------\n");  \
	} while(0)

/* Check for the current length of the sting. If it doesn't fit into the buffer then
   generate and error */
#define CHECK_STRING_LENGTH(l)                            \
  do {                                                    \
		if (currStringLen + (l) >= MAX_STR_CONST)             \
		{                                                     \
			cool_yylval.error_msg = "String constant too long"; \
			return ERROR;                                       \
		}                                                     \
	} while(0)

/* Typedefs */

/* Variables */
unsigned int blockCommentNestingLevel = 0;
unsigned int currStringLen = 0;

/* Function prototyptes */

%}

 /*
  * Conditions
  */
%x BLOCK_COMMENT
%x INLINE_COMMENT
%x STRING

 /*
  * Define names for regular expressions here.
  */

  /* (?:pattern) makes pattern case insensitive */
CLASS		(?:class)
ELSE		(?:else)
FI			(?:fi)
IF			(?:if)
IN			(?:in)
INHERITS			(?:inherits)
LET			(?:let)
LOOP			(?:loop)
POOL			(?:pool)
THEN			(?:then)
WHILE			(?:while)
CASE			(?:case)
ESAC			(?:esac)
OF			(?:of)
DARROW	=>
NEW			(?:new)
ISVOID			(?:isvoid)
INT_CONST		[0-9]+
BOOL_CONST	t(?:rue)|f(?:alse)
ASSIGN		=
NOT		(?:not)
LE		<=

WHITESPACE	[\n\f\r\t\v]*
  /*
   LET_STMT
   EOF
   TYPEID
   OBJECTID
   */

%%

 /* Rules
  *
  * This section contains a series of rules of the form:
  * <pattern>	<action>
  * where <pattern> must be unindendted and the <action> must begin on the same line.
  *
  * Any indented text or text enclosed in %{ %} is copied verbatium to the output
  * (with %{ %} removed). The %{ %} must appear unindented on lines by themselves.
  *
  * Any indented or %{ %} text appearing before the first rule may be used to declare
  * variables which are local to the scanning routine and (after the declarations)
  * code which is to be executed whenever the scanning routine is entered.
  * Other indented or %{ %} text in the rule section is still copied to the output,
  * but its meaning is not well-defined and it may well cause compile-time errors
  * (this feature is present for POSIX compliance)
  */


 /*
  *  The multiple-character operators.
  */
	/* {DARROW}	{ return (DARROW); } */
	/*  */
	/* {INT_CONST}		{ return (INT_CONST); } */
	/* {ASSIGN}		{ return (ASSIGN); } */

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
	/* {CLASS}			{ return (CLASS); } */
	/* {ELSE}			{ return (ELSE); } */
	/* {FI}			{ return (FI); } */
	/* {IF}			{ return (IF); } */
	/* {IN}			{ return (IN); } */
	/* {INHERITS}			{ return (INHERITS); } */
	/* {LET}			{ return (LET); } */
	/* {LOOP}			{ return (LOOP); } */
	/* {POOL}			{ return (POOL); } */
	/* {THEN}			{ return (THEN); } */
	/* {WHILE}			{ return (WHILE); } */
	/* {CASE}			{ return (CASE); } */
	/* {ESAC}			{ return (ESAC); } */
	/* {OF}			{ return (OF); } */
	/* {NEW}			{ return (NEW); } */
	/* {ISVOID}			{ return (ISVOID); } */
	/* {NOT}		{ return (NOT); } */
	/* {LE}		{ return (LE); } */

 /*
  *  Boolean constants
	*  Save matched text and return the token
	*/
	/* {BOOL_CONST} { */
	/*	return (BOOL_CONST); */
	/* } */

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for
  *  \n \t \b \f, the result is c.
  *
  */

\n { curr_lineno++; }

  /* Generate an error if the end of the block comment is found,
     without first finding its beginning.
   */
"*)" {
	cool_yylval.error_msg = "Unmatched *)";
	return ERROR;
}

  /****************************************************************************
		Inline comments
	 ***************************************************************************/
"--" {
  BEGIN(INLINE_COMMENT);
}

  /* Stop inline comment once new line is encountered */
<INLINE_COMMENT>\n {
  curr_lineno++;
	BEGIN(INITIAL);
}

  /* Ignore everything in the inline comment except the new line */
<INLINE_COMMENT>[^\n]*	{}


  /****************************************************************************
	  Block comments

	  Block comments can be nested.
	 ***************************************************************************/

<INITIAL,BLOCK_COMMENT>"(*" {
	blockCommentNestingLevel++;
	BEGIN(BLOCK_COMMENT);
}

<BLOCK_COMMENT>"*)" {
	blockCommentNestingLevel--;
  if (0 == blockCommentNestingLevel)
		BEGIN(INITIAL);
}

<BLOCK_COMMENT>{
  [^\n*)(]+ ; /* Eat the comment in chunks */
  ")" ; /* Eat a lonely right paren */
  "(" ; /* Eat a lonely left paren */
  "*" ; /* Eat a lonely star */
  \n curr_lineno++; /* increment the line count */
}

  /*
	   Can't have EOF in the middle of a block comment
	 */
<BLOCK_COMMENT><<EOF>>	{
  /* For some reason when EOF is encountered in a comment the line number in the
     error is incremented by 1. This does not happen when EOF is encountered in
     a string. For now temproary fix is to decrement the line count by 1.
   */
  curr_lineno--;
	cool_yylval.error_msg = "EOF in comment";
  /*
     Need to return to INITIAL, otherwise the program will be stuck
     in the infinite loop. Thiw was determined experimentally.
   */
  BEGIN(INITIAL);
	return ERROR;
}

  /****************************************************************************
		Strings
	 ***************************************************************************/
\" {
	string_buf_ptr = string_buf;
	BEGIN(STRING);
}

<STRING>\" {
  stringtable.add_string(string_buf, MAX_STR_CONST);
	BEGIN(INITIAL);
}

	/* Match <back slash>\n or \n */
<STRING>\\\n|\n {
  curr_lineno++;
}

	/* Match everything except \b, \t, \n, \f, or \0 */
<STRING>(\\[^btnf0]) {
  /* check for the length of the string */
  CHECK_STRING_LENGTH(1);

	/* '\c' should be treated as 'c' */
  *string_buf_ptr = yytext[1];
	/* Move on to the next character */
  string_buf_ptr++;
}

<STRING>\\0 {
	/* String may not have a '\0', NULL character */
  cool_yylval.error_msg = "String contains null character";
  return ERROR;
}

<STRING><<EOF>> {
	/* String may not have an EOF character */
  cool_yylval.error_msg = "String contains EOF character";

  /*
     Need to return to INITIAL, otherwise the program will be stuck
     in the infinite loop. Thiw was determined experimentally.
   */
  BEGIN(INITIAL);
  return ERROR;
}

	/* Match \b, \t, \n and \f */
<STRING>(\\[btnf]) {
  /* check for the length of the string */
  CHECK_STRING_LENGTH(1);

  char c;
  switch(yytext[1])
	{
    case 'b':
      c = '\b';
      break;
    case 't':
      c = '\t';
      break;
    case 'n':
      c = '\n';
      break;
    case 'f':
      c = '\f';
      break;
    default:
			cool_yylval.error_msg = "Unkown error in lexer. " \
                              "This should not have happened, but it did. " \
                              "Because this happened, it means that monkeys can fly.";
			return ERROR;
	}
  *string_buf_ptr = c;
  string_buf_ptr++;
}

	/* Match everything except '\' and '"' */
<STRING>[^\\"]* {
  CHECK_STRING_LENGTH(yyleng);
  strcpy(string_buf_ptr, yytext);
  string_buf_ptr += yyleng;
}

%%
/* User code.
 *
 * Any indented text or text enclosed in %{ %} is copied verbatium to the output
 * (with %{ %} removed). The %{ %} must appear unindented on lines by themselves.
 */
