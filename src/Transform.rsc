module Transform

import Syntax;
import Resolve;
import AST;
// needed to get resolve tree and to use @\loc
import CST2AST;
import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int; 
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 *
 */
 
AForm flatten(AForm f) {
  f.questions = flatten(f.questions, boolean(true));
  return f; 
}
// flattening of question -> if(true) question
// flattening of expr question -> if(true) expr question
// flattening of if question -> merge the guards together
// flattening of if else question -> create two different ifstatements, one with merged guards and one with the not() of the first guard
// flattening of block is just recursive
list[AQuestion] flatten(list[AQuestion] questions, AExpr current_guard){
	list[AQuestion] flattened_questions = [];
	for(AQuestion primitive_question <- questions){
		switch(primitive_question){
			case question(str label, AId identifier, AType \type): flattened_questions += if_question(current_guard, [question(label, identifier, \type)]);
			case expr_question(str label, AId identifier, AType \type, AExpr expr): flattened_questions += if_question(current_guard, [expr_question(label, identifier, \type, expr)]);
			case if_question(AExpr guard, list[AQuestion] primary): flattened_questions += flatten(primary, and(guard, current_guard));
			case if_else_question(AExpr guard, list[AQuestion] primary, list[AQuestion] secondary): {
				flattened_questions += flatten(primary, and(guard, current_guard));
				flattened_questions += flatten(secondary, and(not(guard), current_guard));
			}
			case block_question(list[AQuestion] block_questions): flattened_questions += flatten(block_questions, current_guard);
		}
	}
	return flattened_questions;
}

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
 start[Form] rename(start[Form] f, loc useOrDef, str newName) {
   // taken from lecture lab
   RefGraph r = resolve(cst2ast(f));
   set[loc] toRename = {};
   if(useOrDef in r.defs<1>){
   	toRename += {useOrDef};
   	toRename += {u | <loc u, useOrDef> <- r.useDef}; // all the usages have to be changed
   } else if (useOrDef in r.uses<0>){
   	if(<useOrDef, loc d> <- r.useDef){
   		toRename += {d}; // change def
   		toRename += {u | <loc u, d> <- r.useDef}; // other usages have to be changed as well!
   	}
   }
   return visit(f){
   	case Id id => [Id]newName
   			when id@\loc in toRename
   } 
 } 
 
 
 

