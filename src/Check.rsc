module Check

import AST;
import Resolve;
import Message; // see standard library

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc qdef, loc iddef, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` )
TEnv collect(AForm f) {
  return {<question.src, id.src, id.name, label, type_converter(abstract_type)> | /question:question(str label, AId id, AType abstract_type) := f} +
  		 {<expr_question.src, id.src, id.name, label, type_converter(abstract_type)> | /expr_question:expr_question(str label, AId id, AType abstract_type, _):= f}; 
}

Type type_converter(AType abstract_type){
	switch(abstract_type){
		case intType(): return tint();
		case boolType(): return tbool();
		case strType(): return tstr();
		default: return tunknown();
	}
}

//loc def, str name, str label, Type \type |remove later!|
set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  set[str] defined = {};
  rel[str name, Type t] defined_types = {};
  set[str] used_labels = {};
  
  for(/AQuestion question := f){
  	msgs += check(question, tenv, useDef);
  }
  
  for(<loc qdef, _, str name, str label, Type t> <- tenv) {
  	if(name in defined && <name, t> notin defined_types){
  		msgs += {error("Ambiguous use of name in multiple questions", qdef)}; 
  	} else {
  		defined += {name};
  		defined_types += {<name, t>};
  	} 
  	
  	if(label in used_labels){
  		msgs += {warning("Ambiguous use of label in multiple questions", qdef)};
  	} else {
  		used_labels += {label};
  	}
  }
  return msgs;
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(AQuestion q, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  switch(q) {
    case expr_question(str _, AId _, AType t, AExpr expr): {
      if(check(expr, tenv, useDef) == {} && type_converter(t) != typeOf(expr, tenv, useDef)) {
        msgs += {error("The Type of the question doesn\'t match the Type of the expression", q.src)};
      } else {
        msgs += check(expr, tenv, useDef);
      }
    }
    case if_question(AExpr guard, list[AQuestion] _): {
      if(check(guard, tenv, useDef) == {} && typeOf(guard, tenv, useDef) != tbool()) {
        msgs += {error("The guard of the if statement is not of boolean Type", q.src)};
      } else {
        msgs += check(guard, tenv, useDef);
      }
    }
    case if_else_question(AExpr guard, list[AQuestion] _, list[AQuestion] _): {
      if(check(guard, tenv, useDef) == {} && typeOf(guard, tenv, useDef) != tbool()) {
        msgs += {error("The guard of the if statement is not of boolean Type", q.src)};
      } else {
        msgs += check(guard, tenv, useDef);
      }
    }
  }
  
  return msgs; 
}

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  
  switch (e) {
    case ref(AId x):
      msgs += { error("Undeclared question", x.src) | useDef[x.src] == {} };
    case not(AExpr expression): {
      set[Message] tempError = check(expression, tenv, useDef);
      if(tempError == {}) {
        msgs += {error("Invalid type of argument for NOT", e.src) | typeOf(expression, tenv, useDef) != tbool()};
      }
      msgs += tempError;
    }
    case sum(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for SUM", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case sub(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for SUB", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case mul(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for MUL", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case div(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for DIV", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case strict_less(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for \<", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case strict_greater(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for \>", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case less_or_equal(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for \<=", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case greater_or_equal(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for \>=", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case is_equal(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for ==", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case is_not_equal(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for !=", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case and(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for AND", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
    case or(AExpr lhs, AExpr rhs): {
      set[Message] tempErrorLhs = check(lhs, tenv, useDef);
      set[Message] tempErrorRhs = check(rhs, tenv, useDef);
      if(tempErrorLhs == {} && tempErrorRhs == {}) {
        msgs += {error("Invalid type of arguments for OR", e.src) | (typeOf(lhs, tenv, useDef) != tint() || typeOf(rhs, tenv, useDef) != tint())};
      }
      msgs += tempErrorLhs + tempErrorRhs;
    }
  }
  
  return msgs; 
}

Type typeOf(AExpr e, TEnv tenv, UseDef useDef) {
  switch (e) {
    case ref(id(_, src = loc u)): {
      if (<u, loc d> <- useDef, <_, d, _, _, Type t> <- tenv) {
        return t;
      }
    }
    case boolean(bool _): return tbool();
    case integer(int _): return tint();
    case string(str _): return tstr();
    case not(AExpr _): return tbool();
    case sum(AExpr _, AExpr _): return tint();
    case sub(AExpr _, AExpr _): return tint();
    case mul(AExpr _, AExpr _): return tint();
    case div(AExpr _, AExpr _): return tint();
    case strict_less(AExpr _, AExpr _): return tbool();
    case strict_greater(AExpr _, AExpr _): return tbool();
    case less_or_equal(AExpr _, AExpr _): return tbool();
    case greater_or_equal(AExpr _, AExpr _): return tbool();
    case is_equal(AExpr _, AExpr _): return tbool();
    case is_not_equal(AExpr _, AExpr _): return tbool();
    case and(AExpr _, AExpr _): return tbool();
    case or(AExpr _, AExpr _): return tbool();
  }
  return tunknown(); 
}

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(id(_, src = loc u)), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

