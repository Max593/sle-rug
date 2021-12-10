module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Str Id ":" Type 
  | Str Id ":" Type "=" Expr
  | "if" "(" Expr ")" "{" Question* "}" ("else" "{" Question* "}")?  // if else with multiple statements
  | "{" Question* "}"  // not sure this is needed although the TODO mentions it
  ; 

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)
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
  
syntax Type
  = "integer" | "boolean";  
  
lexical Str = "\"" ![\"]*  "\"";

lexical Int
  = "-"?[1-9][0-9]* 
  | "-"?[0];

lexical Bool = "true" | "false";



