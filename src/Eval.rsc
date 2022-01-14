module Eval

import AST;
import Resolve;

import List;
/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) { 
  list[VEnv] venv_list = ([(id.name: initializeType(abstract_type)) | /_:question(str _, AId id, AType abstract_type) := f] +
  		      [(id.name: initializeType(abstract_type)) | /_:expr_question(str _, AId id, AType abstract_type, _) := f]);
  VEnv venv = ();
  for(int i <- [0 .. size(venv_list)])
  	venv += venv_list[i];
  return venv;
}


// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for(AQuestion q <- f.questions)
  	venv = eval(q, inp, venv);
  return venv; 
}

VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  switch(q){
    case question(str _, AId id, AType _): if(id.name == inp.question) venv[id.name] = inp.\value;
    case expr_question(str _, AId id, AType _, AExpr expr): venv[id.name] = eval(expr, venv);
    case if_question(AExpr guard, list[AQuestion] questions): {
    	if(eval(guard, venv).b){
    		for(AQuestion question <- questions){
    			venv = eval(question, inp, venv);
    		}
    	}
    }
    case if_else_question(AExpr guard, list[AQuestion] true_questions, list[AQuestion] false_questions): {
    	if(eval(guard, venv).b){
    		for(AQuestion question <- true_questions){
    			venv = eval(question, inp, venv);
    		}
    	} else {
    		for(AQuestion question <- false_questions) {
    			venv = eval(question, inp, venv);
    		}
    	}
    }
    case block_question(list[AQuestion] questions): {
		for(AQuestion question <- questions){
    		venv = eval(question, inp, venv);
    	}    
    }
  }
  return venv; 
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ref(id(str x)): return venv[x];
    case boolean(bool boolean): return vbool(boolean);
    case string(str string): return vstr(string);
    case integer(int integer): return vint(integer);
    case not(AExpr expression): return vbool(!(eval(expression, venv).b));
    case sum(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n + eval(rhs, venv).n);
    case sub(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n - eval(rhs, venv).n);
    case mul(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n * eval(rhs, venv).n);
    case div(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n / eval(rhs, venv).n);
    case strict_less(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
    case strict_greater(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
    case less_or_equal(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
    case greater_or_equal(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) >= eval(rhs, venv));
    case is_equal(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) == eval(rhs, venv));
    case is_not_equal(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) != eval(rhs, venv));
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b || eval(rhs, venv).b);
    default: throw "Unsupported expression <e>";
  }
}

Value initializeType(AType \type){
  switch(\type) {
  	case intType(): return vint(0);
  	case boolType(): return vbool(false);
  	case strType(): return vstr("");
  	default: throw("Illegal Type");
  }
}