module Compile

import AST;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  // I found how to use the html bits here. Do not know if this is intended though, as I did not find it in the documentation.
  // https://github.com/usethesource/rascal/blob/main/src/org/rascalmpl/library/lang/html5/DOM.rsc
  return html(
  				body(h1("<f.name>"), div([question2html(q)| q <- f.questions]))
  			 );
}

HTML5Node question2html(question(str label, AId identifier, AType atype)){
	switch(atype){
		case intType(): return div(h5(label), input([\type("number")])); 
		case boolType(): return div(h5(label), input([\type("checkbox")]));
		case strType(): return div(h5(label), input([\type("text")]));
	}
}

HTML5Node question2html(expr_question(str label, AId identifier, AType \atype, AExpr expr)){
	switch(atype){
		case intType(): return div(h5(label), input([\type("number"), readonly("readonly"), id("bla")])); 
		case boolType(): return div(h5(label), input([\type("checkbox"), readonly("readonly")]));
		case strType(): return div(h5(label), input([\type("text"), readonly("readonly")]));
	}
}

HTML5Node question2html(if_question(AExpr guard, list[AQuestion] questions)){
	return div(fieldset([question2html(question) | question <- questions]));
}

HTML5Node question2html(if_else_question(AExpr guard, list[AQuestion] true_questions, list[AQuestion] false_questions)){
	return div(fieldset([question2html(question) | question <- true_questions]),fieldset([question2html(question) | question <- false_questions]));
}

HTML5Node question2html(question_block(list[AQuestion] questions)){
	return div(fieldset([question2html(question) | question <- questions]));
}

str form2js(AForm f) {
  return "";
}
