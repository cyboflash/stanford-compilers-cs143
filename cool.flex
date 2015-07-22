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
unsigned int blockCommentNestingLevel = 0;

%}

 /*
  * Conditions
  */
%x BLOCK_COMMENT
%x BLOCK_COMMENT_END_CHECK
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
BLOCK_COMMENT_START		"(*"
BLOCK_COMMENT_END		"*)"
INLINE_COMMENT_START		"--"
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
{DARROW}	{ return (DARROW); }

{INT_CONST}		{ return (INT_CONST); }
{ASSIGN}		{ return (ASSIGN); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{CLASS}			{ return (CLASS); }
{ELSE}			{ return (ELSE); }
{FI}			{ return (FI); }
{IF}			{ return (IF); }
{IN}			{ return (IN); }
{INHERITS}			{ return (INHERITS); }
{LET}			{ return (LET); }
{LOOP}			{ return (LOOP); }
{POOL}			{ return (POOL); }
{THEN}			{ return (THEN); }
{WHILE}			{ return (WHILE); }
{CASE}			{ return (CASE); }
{ESAC}			{ return (ESAC); }
{OF}			{ return (OF); }
{NEW}			{ return (NEW); }
{ISVOID}			{ return (ISVOID); }
{NOT}		{ return (NOT); }
{LE}		{ return (LE); }

 /*
  *  Boolean constants
	*  Save matched text and return the token
	*/
{BOOL_CONST} {
	return (BOOL_CONST);
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for
  *  \n \t \b \f, the result is c.
  *
  */

  /*
		Inline comments
	*/
{INLINE_COMMENT_START} { BEGIN(INLINE_COMMENT); }

  /* Stop inline comment once new line is encountered */
<INLINE_COMMENT>\n { BEGIN(INITIAL); }

  /* Ignore everything in the inline comment */
<INLINE_COMMENT>[^\n]*	;


 /*
	* Block comments.
	* Block comments can be nested.
	*/

{BLOCK_COMMENT_START} {
	blockCommentNestingLevel++;
  printf("Marker 0\n");
	BEGIN(BLOCK_COMMENT);
}

  /*
	 * Can't have EOF in the middle of a block comment
	 */
<BLOCK_COMMENT,BLOCK_COMMENT_END_CHECK><<EOF>>	{
	return (ERROR);
}

	/*
	 * Ignore anything in the block comment
	 */
<BLOCK_COMMENT>[^*]*	;

	/*
	 * Once a "*" is seen, it could indicate and and of a block comment.
	 */
<BLOCK_COMMENT>"*"+	{
	BEGIN(BLOCK_COMMENT_END_CHECK);
}

<BLOCK_COMMENT_END_CHECK>[^)]*	{
	BEGIN(BLOCK_COMMENT);
}

	/*
	 * Once a ")" is seen, this indicates the end of the block comment.
	 */
<BLOCK_COMMENT_END_CHECK>")"	{
	blockCommentNestingLevel--;
	if(0 == blockCommentNestingLevel)
		BEGIN(INITIAL);
	else
		BEGIN(BLOCK_COMMENT);
}

%%
/* User code.
 *
 * Any indented text or text enclosed in %{ %} is copied verbatium to the output
 * (with %{ %} removed). The %{ %} must appear unindented on lines by themselves.
 */
