#include <stdlib.h>
#include <stdint.h>

typedef union
{
  double d;
  int64_t i;
  char *c;
} comp_val;

typedef struct
{
  int32_t op;
  char *key;
  int32_t idx;
  comp_val *arg;
} info_filter;

typedef struct
{
  struct ast_node_t *next;
  int32_t node_type;
  union {
    info_filter *info_f;
  } node;
} ast_node_t;

ast_node_t* new_ast_node();
ast_node_t* new_info_filter_node(int32_t op, char *key, double arg);
ast_node_t* new_info_filter_node_indexed(int32_t op, char *key, double arg, int32_t idx);

void free_ast_node(ast_node_t *n);
