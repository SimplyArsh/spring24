type awksub_nonterminals =
  | Expr | Term | Lvalue | Incrop | Binop | Num

let awkish_grammar =
  (Expr,
   function
     | Expr ->
         [[N Term; N Binop; N Expr];
          [N Term]]
     | Term ->
	 [[N Num];
	  [N Lvalue];
	  [N Incrop; N Lvalue];
	  [N Lvalue; N Incrop];
	  [T"("; N Expr; T")"]]
     | Lvalue ->
	 [[T"$"; N Expr]]
     | Incrop ->
	 [[T"++"];
	  [T"--"]]
     | Binop ->
	 [[T"+"];
	  [T"-"]]
     | Num ->
	 [[T"0"]; [T"1"]; [T"2"]; [T"3"]; [T"4"];
	  [T"5"]; [T"6"]; [T"7"]; [T"8"]; [T"9"]])
  
    let example_tree =
      Node ("S",
        [
          Node ("NP",
            [
              Leaf "The";
              Leaf "cat"
            ]);
          Node ("VP",
            [
              Node ("NP",
              [
                Leaf "the";
                Leaf "mat"
              ]);
              Leaf "sat";
              Leaf "on"
  
            ])
        ])
    let leaves = parse_tree_leaves [] example_tree;;