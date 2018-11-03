#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <cmocka.h>

#include "ast.h"
#include "parser.h"

static void
test_new_info_filter_node()
{
  ast_node_t* n = new_info_filter_node(GREATEREQ, "AF", 0.00001);
  info_filter* in_f = n->node.info_f;

  assert_int_equal(in_f->idx, -1);
  assert_int_equal(in_f->op, GREATEREQ);
  assert_string_equal(in_f->key, "AF");

  free_ast_node(n);
}

static void
test_new_info_filter_node_indexed()
{
  ast_node_t* n = new_info_filter_node_indexed(GREATEREQ, "AF", 0.00001, 1);
  info_filter* in_f = n->node.info_f;

  assert_int_equal(in_f->idx, 1);
  assert_int_equal(in_f->op, GREATEREQ);
  assert_string_equal(in_f->key, "AF");

  free_ast_node(n);
}

int main(void) {
  const struct CMUnitTest tests[] =
    {
     cmocka_unit_test(test_new_info_filter_node),
     cmocka_unit_test(test_new_info_filter_node_indexed),
    };
  return cmocka_run_group_tests(tests, NULL, NULL);
}
