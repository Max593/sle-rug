module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;
import Boolean; //needed for fromString

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return form("<f.form_id>", [cst2ast(question) | question <- f.questions], src=f@\loc); 
}

AQuestion cst2ast(Question q) { //named idl instead of id for naming conflicts
  switch (q) {
  	case (Question) `<Str q> <Id idl> : <Type t>`: return question("<q>", id("<idl>", src=idl@\loc), cst2ast(t), src=q@\loc);
  	case (Question) `<Str q> <Id idl> : <Type t> = <Expr expr>`: return expr_question("<q>", id("<idl>", src=idl@\loc), cst2ast(t), cst2ast(expr), src=q@\loc);
  	case (Question) `{<Question* questions>}`: return block_question([cst2ast(question) | Question question <- questions], src=q@\loc);  
  	case (Question) `if (<Expr guard>) {<Question* primary>}`: return if_question(cst2ast(guard), [cst2ast(question)|Question question <- primary], src=q@\loc);
  	case (Question) `if (<Expr guard>) { <Question* primary> } else { <Question* secondary> }`: return if_else_question(cst2ast(guard), [cst2ast(question) | Question question <- primary], [cst2ast(question) | Question question <- secondary], src=q@\loc);
  	default: throw "Incompatible question <q>";
  }
  
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>", src=x@\loc), src=x@\loc);
    case (Expr)`<Bool x>`: return boolean(fromString("<x>"), src=e@\loc);
    case (Expr)`<Str x>`: return string(("<x>"), src = e@\loc);
    case (Expr)`<Int x>`: return integer(toInt("<x>"), src=e@\loc);
    case (Expr)`(<Expr x>)`: return cst2ast(x);
    case (Expr)`!<Expr x>`: return not(cst2ast(x), src=e@\loc);
    case (Expr)`<Expr lhs> * <Expr rhs>`: return mul(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> / <Expr rhs>`: return div(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> + <Expr rhs>`: return sum(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> - <Expr rhs>`: return sub(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \< <Expr rhs>`: return strict_less(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \> <Expr rhs>`: return strict_greater(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \<= <Expr rhs>`: return less_or_equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \>= <Expr rhs>`: return greater_or_equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> == <Expr rhs>`: return is_equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> != <Expr rhs>`: return is_not_equal(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> && <Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> || <Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc); 
    default: throw "Unhandled expression: <e>";
  }
}

AType cst2ast(Type t) {
  switch(t) {
    case (Type)`integer`: return intType(src=t@\loc);
    case (Type)`boolean`: return boolType(src=t@\loc);
    case (Type)`string` : return strType(src=t@\loc);
    default: throw "Incompatible type <t>";
  }
}
