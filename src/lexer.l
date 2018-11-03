%{
#include <math.h>
#include "parser.h"
#include "htslib/vcf.h"
%}

alpha   [a-zA-Z]
digit   [0-9]
sym     [!-/:-?_\{-~]
id      {alpha}({alpha}|{digit}|{sym})?
real    ({digit}+[.]{digit}*)|({digit}*[.]{digit}+)
integer {digit}+
exp     ({integer}|{real})[eE]-?{integer}

%%

"["   { return OPEN_SQUARE;  }
"]"   { return CLOSE_SQUARE; }
"!="  { return NEQ;          }
"=="  { return EQ;           }
"<="  { return LESSEQ;       }
">="  { return GREATEREQ;    }
"<"   { return LESS;         }
">"   { return GREATER;      }

.INFO {
    yylval.sval = yytext;
    return INFO;
}

.FILTER {
    yylval.sval = yytext;
    return STR;
}

{id}+ {
    yylval.sval = yytext;
    return STR;
}

({real}|{exp}) {
    yylval.fval = atof(yytext);
    return FLOAT;
}

{digit}+ {
    yylval.ival = atoi(yytext);
    return INT;
}

[ \t\r\n]+ /* skip blanks */

. {
    yylval.sval = yytext;
    return UNKNOWN;
}

%%
