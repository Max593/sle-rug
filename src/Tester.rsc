module Tester

import ParseTree;
import Compile;
import Check;
import Eval;
import Resolve;
import AST;
import CST2AST;
import Syntax;
import IO;

// all test files 
loc binary = |project://QL/examples/binary.myql|;

loc cyclic = |project://QL/examples/cyclic.myql|;

loc empty = |project://QL/examples/empty.myql|;

loc errors = |project://QL/examples/errors.myql|;

loc tax = |project://QL/examples/tax.myql|;

// made this to speed up testing as it was suggested during the lab
void main(){
	AForm f = cst2ast(parse(#start[Form], binary));
	
	UseDef useDef = resolve(f).useDef;
    set[Message] msgs = check(f, collect(f), useDef);
    bool canCompile = true;
 	for(msg <- msgs){
 		if(error(_, _) := msg) canCompile = false; 
 		println(msg);
 	}
 	if(canCompile == false) return;
	//test compile
	compile(f);
	
	//test eval(need to provide input if form changes)
	println(eval(cst2ast(parse(#start[Form], tax)), input("hasMaintLoan", vbool(true)), initialEnv(cst2ast(parse(#start[Form], tax)))));
	
}