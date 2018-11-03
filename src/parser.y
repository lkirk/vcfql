%{
#include <float.h>
#include <math.h>
#include <stdio.h>
#include <stdbool.h>
    extern void yyerror();
    extern int  yylex();
    void print_and_filter();
%}
%define parse.error verbose

%code requires {
#include "htslib/vcf.h"
}
%parse-param {htsFile *bcf}
%parse-param {bcf_hdr_t *hdr}

%union
{
  int    ival;
  double fval;
  char   *sval;
}
%token <ival> INT
%token <sval> STR
%token <fval> FLOAT
%token UNKNOWN
%token INFO
%token OPEN_SQUARE
%token CLOSE_SQUARE
%token EQ NEQ LESSEQ GREATEREQ LESS GREATER

%%

prog:
		| prog line

expressions:	expressions expression
		| expression

line:		'\n'
		| expressions expression '\n'

expression:	INT       { $<ival>$ = $<ival>1; printf("ival: %d\n",   $<ival>$ ); }
		| STR     { $<sval>$ = $<sval>1; printf("sval: %s\n",   $<sval>$ ); }
		| FLOAT   { $<fval>$ = $<fval>1; printf("fval: %.*e\n", DECIMAL_DIG, $<fval>$ ); }
		| UNKNOWN { $<sval>$ = $<sval>1; printf("Unknown token: %s\n", $<sval>$); exit(1); }
		| INFO OPEN_SQUARE info_selector CLOSE_SQUARE

info_selector:	STR { $<sval>$ = $<sval>1; print_and_filter(bcf, hdr, $<sval>$); }
/*				| STR OPEN_SQUARE INT CLOSE_SQUARE {  }*/

%%
int
fcmp(const double x1, const double x2)
{   /* adapted from the GSL */
    int exponent;
    double delta, difference;
    /* Find exponent of largest absolute value */
    {
	double max = (fabs(x1) > fabs(x2)) ? x1 : x2;
	frexp (max, &exponent);
    }
    /* Form a neighborhood of size  2 * delta */
    delta = ldexp(FLT_EPSILON, exponent);

    difference = x1 - x2;
    if (difference > delta)       /* x1 > x2 */
	{
	    return 1;
	}
    else if (difference < -delta) /* x1 < x2 */
	{
	    return -1;
	}
    else                          /* -delta <= difference <= delta */
	{
	    return 0;             /* x1 ~=~ x2 */
	}
}

bool
float_compare(int opcode, const double a, const double b)
{
    int fcmp_result = fcmp(a, b);
    switch(opcode) {
    case GREATEREQ:
	if (fcmp_result == -1)
	    return false;
	return true;
	break;
    case LESSEQ:
	if (fcmp_result == 1)
	    return false;
	return true;
	break;
    case GREATER:
	if (fcmp_result == 1)
	    return true;
	return false;
	break;
    case LESS:
	if (fcmp_result == -1)
	    return true;
	return false;
	break;
    }
    return false;
}

void
print_and_filter(htsFile *bcf, bcf_hdr_t *hdr, const char *key)
{
    bcf1_t *row = bcf_init();
    /* htsFile *out_bcf = bcf_open("-", "w"); */
    /* bcf_read(bcf, hdr, row); */
    bcf_read(bcf, hdr, row);

    /* puts(key); */
    bcf_info_t *info = bcf_get_info(hdr, row, key);

#define GET_ARRAY_VAL(info, i, type_t, out) {	\
	type_t *p = (type_t*)info->vptr;	\
	(*(out)) = p[i];			\
    }

#define PRINT_VALUE(info, type_t) {				\
	if (info->len > 1)					\
	    {							\
		for (int i = 0; i < info->len; i++)		\
		    {						\
			type_t val;				\
			GET_ARRAY_VAL(info, i, type_t, &val);	\
			if (i > 0)				\
			    {					\
				printf(",%f", val);		\
			    }					\
			else					\
			    {					\
				printf("%s[%f", key, val);	\
			    }					\
		    }						\
		puts("]\n");					\
	    }							\
	else							\
	    {							\
	    printf("%s[%f]\n", key, info->v1.f);		\
	    }							\
    }

    if (info)
	{
	/* printf("%s: len=%d vptr_len=%d\n", key, info->len, info->vptr_len); */
	switch(info->type)
	    {
	    case BCF_BT_NULL:
		printf("%s: NULL", key);
		break;
	    case BCF_BT_INT8:
		break;
	    case BCF_BT_INT16:
		break;
	    case BCF_BT_INT32:
		break;
	    case BCF_BT_FLOAT:
		PRINT_VALUE(info, float);
		break;
	    case BCF_BT_CHAR:
		printf("%s: %s\n", key, info->vptr);
	    	break;

	    default:
		fprintf(stderr, "%s is of unknown type\n", key);
		exit(1);
	    }
	/* if (info->len > 1) */
	/*     { */
	/* 	printf("%s: vptr_len %d: <[", key, info->vptr_len); */
	/* 	for(uint8_t i=0;i < info->vptr_len; i++) */
	/* 	    { */
	/* 		printf("%d,", info->vptr[i]); */
	/* 	    } */
	/* 	puts("]>"); */
	/* 	printf("%s: len %d: <[", key, info->len); */
	/* 	for(int i=0;i < info->len - 1; i++) */
	/* 	    { */
	/* 		printf("%s,", t); */
	/* 	    } */
	/* 	printf("%s]>\n", t); */
	/*     } */
	/* else */
	/*     { */
	/* 	printf("%s: vptr_len %d: len %d: <%s>\n", key, info->vptr_len, info->len, t); */
	/*     } */
	}
    else
    	{
    	    printf("%s: nan\n", key);
    	}

    /* else */
    /* 	{ */
    /* 	    puts("key not matched"); */
    /* 	} */
	
	
    /* printf("%d, %d, %d\n", info->key, info->type, info->len); */
}

/* int main() */
/* { */
/*     int someval = 4; */
/*     yyparse(someval); */
/* } */


/* expression: */
/* INT { */
/*     $<ival>$ = $<ival>1; */
/*     printf("ival: %d\n",   $<ival>$ ); */
/* } | */
/* STR { */
/*     $<sval>$ = $<sval>1; */
/*     printf("sval: %s\n",   $<sval>$ ); */
/* } | */
/* FLOAT { */
/*     $<fval>$ = $<fval>1; */
/*     printf("fval: %.*e\n", DECIMAL_DIG, $<fval>$ ); */
/* } | */
/* UNKNOWN { */
/*     $<sval>$ = $<sval>1; */
/*     printf("Unknown token: %s\n", $<sval>$); */
/*     exit(1); */
/* } */
