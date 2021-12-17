module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  // get all identifiers
  return { <identifier.src, identifier.name> | /ref(AId identifier) := f}; 
}

Def defs(AForm f) {
  // these are the two abstract syntaxes for questions that produce an identifier
  return { <identifier.name, identifier.src> | /question(_, AId identifier, _) := f}
  +{ <identifier.name, identifier.src> | /expr_question(_, AId identifier, _, _) := f} ;  
}