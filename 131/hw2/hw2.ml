type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal

(* To warm up, notice that the format of grammars is different 
in this assignment, versus Homework 1. Write a function convert_grammar 
gram1 that returns a Homework 2-style grammar, which is converted from 
the Homework 1-style grammar gram1. Test your implementation of convert_grammar 
on the test grammars given in Homework 1. For example, the top-level definition 
let awksub_grammar_2 = convert_grammar awksub_grammar should bind awksub_grammar_2 
to a Homework 2-style grammar that is equivalent to the Homework 1-style grammar 
awksub_grammar. *)
  
let rec matcher rules mnt =
  match rules with
    | (nt, rhs)::tl -> if nt = mnt
      then rhs else matcher tl mnt
    | [] -> []

let rec acc_update (nnt, nrhs) = function
  | (nt, rhs)::tl -> if nnt = nt then
    (nt, nrhs::rhs)::(acc_update (nnt, nrhs) tl)
    else acc_update (nnt, nrhs) tl
  | [] -> [(nnt, [nrhs])]

let rec reformat acc = function
 | h::t -> let new_acc = acc_update h acc in
   reformat new_acc t
 | [] -> acc

let func_generator rules =
  let rules_rf = reformat [] rules in
  matcher rules_rf 

let convert_grammar g = 
  match g with
  (root, rules) -> (root, func_generator rules)


(* As another warmup, write a function parse_tree_leaves tree that 
traverses the parse tree tree left to right and yields a list of 
the leaves encountered, in order. *)

let rec parse_tree_leaves_ acc tree =
  match tree with
  | Node (nt, ch_list) -> 
        let rec iterate_child = function
        | ch::tl -> 
          (parse_tree_leaves_ acc ch)@(iterate_child tl)
        | [] -> []
        in iterate_child ch_list
  | Leaf lf -> lf::acc

let rec parse_tree_leaves tree =
  parse_tree_leaves_ [] tree

(* Write a function make_matcher gram that returns a matcher for
the grammar gram. When applied to an acceptor accept and a
fragment frag, the matcher must try the grammar rules in order
and return the result of calling accept on the suffix 
corresponding to the first acceptable matching prefix of frag;
this is not necessarily the shortest or the longest acceptable match.
A match is considered to be acceptable if accept succeeds when
given the suffix fragment that immediately follows the matching
prefix. When this happens, the matcher returns whatever the
acceptor returned. If no acceptable match is found, the matcher
returns None. *)

(* ex: [N Expr, T"09", N Term] *)
let rec match_append gram_check rule frag =
  match rule with
  | (T rh)::rtl -> 
    (match frag with
    | fh::ftl -> if fh=rh then
       match_append gram_check rtl ftl else None
    | [] -> None)
  | (N rh)::rtl -> let res_frag = 
    match_or gram_check (gram_check rh) frag in 
    ( match res_frag with
    | None -> None
    | Some x -> match_append gram_check rtl x)
  | [] -> Some (frag)

and match_or gram_check rules frag =
  match rules with
  | rh::rtl -> let mh = 
      match_append gram_check rh frag in
      ( match mh with
      | None -> match_or gram_check rtl frag
      | Some x -> mh
      )
  | [] -> None

let rec root_make_or gram_check rules acc frag =
    match match_or gram_check rules frag with
    | None -> acc frag
    | Some x ->
      let result = acc x in
      (match result with
      | Some res -> Some res
      | None -> 
        (match rules with
        | hd::tl -> root_make_or gram_check tl acc frag
        | [] -> None)
      )

let make_matcher (root, gram_check) acc frag =
  root_make_or gram_check (gram_check root) acc frag

let accept_all string = Some string

let accept_empty_suffix suffix = match suffix with
  | _::_ -> None
  | x -> Some x

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

let match_appender_tested (root, grammar_check) rule frag = 
  match_or grammar_check (grammar_check rule) frag

let test0 =
  ((make_matcher awkish_grammar accept_all ["1"]))

let test1 =
  ((make_matcher awkish_grammar accept_empty_suffix ["$"; "3"; "--"]))

let test2 =
  ((make_matcher awkish_grammar accept_empty_suffix ["2"; "+"; "3"]))

let test3 =
  ((make_matcher awkish_grammar accept_empty_suffix ["("; "2"; "+"; "3"; ")"]))

let test4 =
  ((make_matcher awkish_grammar accept_empty_suffix ["1"; "+"; "$"; "2"; "--"]))