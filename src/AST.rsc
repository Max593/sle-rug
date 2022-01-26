module AST

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ;

// for questions we split the simple if(guard) question from the more complex one with the else.
data AQuestion(loc src = |tmp:///|)
  = question(str q, AId id, AType t)
  | expr_question(str q, AId id, AType t, AExpr expr)
  | if_question(AExpr guard, list[AQuestion] primary)
  | if_else_question(AExpr guard, list[AQuestion] primary, list[AQuestion] secondary) 
  | block_question(list[AQuestion] questions) 
  ; 

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | boolean(bool boolean)
  | string(str string)
  | integer(int integer)
  | not(AExpr expression)
  | sum(AExpr lhs, AExpr rhs)
  | sub(AExpr lhs, AExpr rhs)
  | mul(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | strict_less(AExpr lhs, AExpr rhs)
  | strict_greater(AExpr lhs, AExpr rhs)
  | less_or_equal(AExpr lhs, AExpr rhs)
  | greater_or_equal(AExpr lhs, AExpr rhs)
  | is_equal(AExpr lhs, AExpr rhs)
  | is_not_equal(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  ;

data AId(loc src = |tmp:///|)
  = id(str name);

data AType(loc src = |tmp:///|)
  = intType()
  | boolType()
  | strType()
  ;
