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

/*
In order to recognize which checkbox/textbox needs editing, we do the following:
-numberfields, textfields and checkboxes receive the id of id.name + "." + label
-true guard statements receive the id of guard.src 
-false guard statements receive the id of else.guard.src
*/
void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
  // I found how to use the html bits here. Do not know if this is intended though, as I did not find it in the documentation.
  // https://github.com/usethesource/rascal/blob/main/src/org/rascalmpl/library/lang/html5/DOM.rsc
  return html(
                head(title(f.name)),
  				body(h1("<f.name>"), div([question2html(q)| q <- f.questions]), script(src(f.src[extension="js"].file)))
  			 );
}

//html of question
HTML5Node question2html(question(str label, AId identifier, AType atype)){
	switch(atype){
		case intType(): return div(h5(label), input([\type("number"), id(identifier.name + "." + label[1..-1]), oninput("updateEntry(this.id)")])); 
		case boolType(): return div(h5(label), input([\type("checkbox"), id(identifier.name + "." + label[1..-1]), oninput("updateEntry(this.id)")]));
		case strType(): return div(h5(label), input([\type("text"), id(identifier.name + "." + label[1..-1]), oninput("updateEntry(this.id)")]));
	}
}

//html of expr question
HTML5Node question2html(expr_question(str label, AId identifier, AType \atype, AExpr expr)){
	switch(atype){
		case intType(): return div(h5(label), input([\type("number"), readonly("readonly"), id(identifier.name + "." + label[1..-1])])); 
		case boolType(): return div(h5(label), input([\type("checkbox"), disabled("disabled"), id(identifier.name + "." + label[1..-1])]));
		case strType(): return div(h5(label), input([\type("text"), readonly("readonly"), id(identifier.name + "." + label[1..-1])]));
	}
}

//html of if 
HTML5Node question2html(if_question(AExpr guard, list[AQuestion] questions)){
	return div(fieldset([question2html(question) | question <- questions]), id(guard.src));
}

// html of if else
HTML5Node question2html(if_else_question(AExpr guard, list[AQuestion] true_questions, list[AQuestion] false_questions)){
	return div(div(fieldset([question2html(question) | question <- true_questions]), id(guard.src)),div(fieldset([question2html(question) | question <- false_questions]), id("else.<guard.src>")));
}

// html of block question
HTML5Node question2html(question_block(list[AQuestion] questions)){
	return div(fieldset([question2html(question) | question <- questions]));
}

str form2js(AForm f) {
    str res = "var questions = [];
<genQuestions(f)>
<genInitVals(f)>
<genInitUpdate(f)>
<genUpdate(f)>
    ";

    return res;
}

str genQuestions(AForm f) {
    str res = "";
    for(/AQuestion q <- f.questions) {
        switch(q) {
            case question(str _, AId id, AType t):
                res += "questions[\"<id.name>\"] = <initializeType(t)>;\n";
            case expr_question(str _, AId id, AType t, AExpr _):
                res += "questions[\"<id.name>\"] = <initializeType(t)>;\n";
        }
    }

    return res;
}

str genInitVals(f) {
    str res = "";
    for(/question(str label, AId id, AType t) <- f.questions)
        res += genInitValsRoutine(label, id, t);
    for(/expr_question(str label, AId id, AType t, AExpr _) <- f.questions)
        res += genInitValsRoutine(label, id, t);

    return res;
}

str genInitValsRoutine(str label, AId id, AType t) {
    str res = "";
    switch(t) {
        // Rascal has no fall-through, so statements repeat
        case intType():
            res += "document.getElementById(\"<id.name + "." + label[1..-1]>\").value = questions[\"<id.name>\"];\n";
        case boolType():
            res += "if(questions[\"<id.name>\"]) {
    document.getElementById(\"<id.name + "." + label[1..-1]>\").checked = true;
} else {
    document.getElementById(\"<id.name + "." + label[1..-1]>\").checked = false;
}
";
        case strType():
            res += "document.getElementById(\"<id.name + "." + label[1..-1]>\").value = questions[\"<id.name>\"];\n";
        }

    return res + "\n";
}

str genInitUpdate(AForm f) {
    str res = "";
    for(/question(str label, AId id, AType t) <- f.questions)
        res += genInitUpdateRoutine(label, id, t);
    for(/expr_question(str label, AId id, AType t, AExpr _) <- f.questions)
        res += genInitUpdateRoutine(label, id, t);

    return res;
}

str genInitUpdateRoutine(str label, AId id, AType t) {
    str res = "";
    switch(t) {
        case intType():
            res += "updateEntry(\"<id.name + "." + label[1..-1]>\");\n";
        case boolType():
            res += "updateEntry(\"<id.name + "." + label[1..-1]>\");\n";
        case strType():
            res += "updateEntry(\"<id.name + "." + label[1..-1]>\");\n";
    }
    return res;
}

// Update function for HTML
str genUpdate(AForm f) {
    str res = "
function updateEntry(id) {
    var identifier = id.split(\".\")[0];

    if(document.getElementById(id).type === \"checkbox\" && document.getElementById(id).checked === true)  // Boolean True
        questions[identifier] = true;
    else if(document.getElementById(id).type === \"checkbox\" && document.getElementById(id).checked === false)  // Boolean False
        questions[identifier] = false;
    else if(document.getElementById(id).type === \"number\")  // Integer
        questions[identifier] = parseInt(document.getElementById(id).value);
    else  // String
        questions[identifier] = document.getElementById(id).value;

    <questions2js(f.questions)>
}
";

    return res;
}

// Translates questions into json
str questions2js(list[AQuestion] questions) {
    str res = "";
    for(AQuestion q <- questions) {
        switch(q) {
            case expr_question(str label, AId id, AType t, AExpr expr): {
                res += "questions[\"<id.name>\"] = <expr2js(expr)>;\n";
                switch(t) {
                    case intType():
                        res += "document.getElementById(\"<id.name + "." + label[1..-1]>\").value = questions[\"<id.name>\"];\n";
                    case boolType():
                        res += "if(questions[\"<id.name>\"]) {
    document.getElementById(\"<id.name + "." + label[1..-1]>\").checked = true;
} else {
    document.getElementById(\"<id.name + "." + label[1..-1]>\").checked = false;
}
";
                    case strType():
                        res += "document.getElementById(\"<id.name + "." + label[1..-1]>\").value = questions[\"<id.name>\"];\n";
                }
            }

            case if_question(AExpr guard, list[AQuestion] primary):
                res += "if(<expr2js(guard)>) {
    document.getElementById(\"<guard.src>\").style.display = \"block\";
    <questions2js(primary)>
} else {
    document.getElementById(\"<guard.src>\").style.display = \"none\";
}
";

            // TODO: Double check that else-guard part
            case if_else_question(AExpr guard, list[AQuestion] primary, list[AQuestion] secondary):
                res += "if(<expr2js(guard)>) {
    document.getElementById(\"<guard.src>\").style.display = \"block\";
    document.getElementById(\"else.<guard.src>\").style.display = \"none\";
    <questions2js(primary)>
} else {
    document.getElementById(\"<guard.src>\").style.display = \"none\";
    document.getElementById(\"else.<guard.src>\").style.display = \"block\";
    <questions2js(secondary)>
}
";

            case block_question(list[AQuestion] questions):
                res += questions2js(questions);
        }
    }

    return res;
}

// Translates expressions into json
str expr2js(AExpr expr) {
    str res = "";
    switch(expr) {
        case ref(AId id):
            res += "questions[\"<id.name>\"]";
        case boolean(bool boolean): {
            if(boolean) res += "true";
            else res += "false";
        }
        case string(str string):
            res += "<string>";
        case integer(int integer):
            res += "<integer>";
        case not(AExpr expression):
            res += "!(" + expr2js(expression) + ")";
        case mul(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "*" + "(" + expr2js(rhs) + ")";
        case div(AExpr lsh, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "/" + "(" + expr2js(rhs) + ")";
        case sum(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "+" + "(" + expr2js(rhs) + ")";
        case sub(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "-" + "(" + expr2js(rhs) + ")";
        case strict_less(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "\<" + "(" + expr2js(rhs) + ")";
        case less_or_equal(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "\<=" + "(" + expr2js(rhs) + ")";
        case strict_greater(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "\>" + "(" + expr2js(rhs) + ")";
        case greater_or_equal(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "\>=" + "(" + expr2js(rhs) + ")";
        case is_equal(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "===" + "(" + expr2js(rhs) + ")";
        case is_not_equal(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "!==" + "(" + expr2js(rhs) + ")";
        case and(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "&&" + "(" + expr2js(rhs) + ")";
        case or(AExpr lhs, AExpr rhs):
            res += "(" + expr2js(lhs) + ")" + "||" + "(" + expr2js(rhs) + ")";
    }

    return res;
}

str initializeType(AType \type){
  switch(\type) {
  	case intType(): return "0";
  	case boolType(): return "false";
  	case strType(): return "\"\""; // empty string
  	default: throw("Illegal Type");
  }
}
