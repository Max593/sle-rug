module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id form_id "{" Question* questions "}"; 

// Syntax for question, computed question, block, if-then-else, if-then
syntax Question
  = Str Id ":" Type 
  | Str Id ":" Type "=" Expr
  | "if" "(" Expr ")"  Question ("else"  Question )?  // if else with multiple statements
  | "{" Question* "}"  
  ; 

// Syntax for Expressions in QL
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Bool
  | Str
  | Int
  | bracket "(" Expr ")"
  | "!" Expr
  > left Expr ("*" | "/") Expr
  > left Expr ("+" | "-") Expr
  > left Expr ("\<" | "\<=" | "\>" | "\>=") Expr
  > left Expr ("==" | "!=") Expr
  > left Expr "&&" Expr
  > left Expr "||" Expr  
  ;

// Types accepted by QL
syntax Type
  = "integer" | "boolean" | "string";  
 
// String lexical in QL
lexical Str = "\"" ![\"]*  "\"";

// Int lexical in QL
lexical Int
  = "-"?[1-9][0-9]* 
  | "-"?[0];

// Bool lexical in QL
lexical Bool = "true" | "false";



