#include <stdlib.h>
#include <stdint.h>

#include "htslib/vcf.h"
#include "ast.h"

enum node_type {FILTER_INFO, FILTER_FILTER, SUBSET_SAMPLE};

ast_node_t*
new_ast_node()
{
  ast_node_t* new_tree = malloc(sizeof(ast_node_t));
  return new_tree;
}

void
add_node_to_tree()
{
}

ast_node_t*
new_info_filter_node(int32_t op, char *key, double arg)
{
  ast_node_t *n = new_ast_node();
  info_filter *in_f = malloc(sizeof(info_filter));
  comp_val *ca = malloc(sizeof(double));
  ca->d = arg;
  *in_f = (info_filter) {.op = op, .key = key, .idx = -1, .arg = ca};
  n->node.info_f = in_f;
  n->node_type = FILTER_INFO;
  return n;
}

ast_node_t*
new_info_filter_node_indexed(int32_t op, char *key, double arg, int32_t idx)
{
  ast_node_t *n = new_info_filter_node(op, key, arg);
  n->node.info_f->idx = idx;
  return n;
}


	/* switch(info->type) */
	/*     { */
	/*     case BCF_BT_NULL: */
	/* 	printf("%s: NULL", key); */
	/* 	break; */
	/*     case BCF_BT_INT8: */
	/* 	break; */
	/*     case BCF_BT_INT16: */
	/* 	break; */
	/*     case BCF_BT_INT32: */
	/* 	break; */
	/*     case BCF_BT_FLOAT: */
	/* 	PRINT_VALUE(info, float); */
	/* 	break; */
	/*     case BCF_BT_CHAR: */
	/* 	printf("%s: %s\n", key, info->vptr); */
	/*     	break; */

	/*     default: */
	/* 	fprintf(stderr, "%s is of unknown type\n", key); */
	/* 	exit(1); */
	/*     } */

void
free_ast_node(ast_node_t *n)
{
  if(n)
    {
      switch(n->node_type)
	{
	case FILTER_INFO:
	  if(n->node.info_f)
	    {
	      free(n->node.info_f->arg);
	      free(n->node.info_f);
	    }
	}
      free(n);
    }
}

/* filter_and_print_bcf(htsFile *bcf, bcf_hdr_t *hdr, ast_node_t *ast) */
/* { */
/*     bcf1_t *row = bcf_init(); */
/*     bcf_read(bcf, hdr, row); */

/*     /\* puts(key); *\/ */
/*     bcf_info_t *info = bcf_get_info(hdr, row, key); */

/* #define GET_ARRAY_VAL(info, i, type_t, out) {	\ */
/*       type_t *p = (type_t*)info->vptr;		\ */
/*       (*(out)) = p[i];				\ */
/*     } */

/* } */
