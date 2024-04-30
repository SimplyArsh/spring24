type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

type ('nonterminal, 'terminal) parse_tree =
  | Node of 'nonterminal * ('nonterminal, 'terminal) parse_tree list
  | Leaf of 'terminal

(* Auxilliary functions *)
let rec rev acc = function
  | [] -> acc
  | x :: xs -> rev (x :: acc) xs

let rec filter all_rules sel =
  match all_rules with
  | [] -> []
  | (h , rlist)::t ->
    if h = sel then
    rlist::(filter t sel)
    else filter t sel

(* To warm up, notice that the format of grammars is different 
in this assignment, versus Homework 1. Write a function convert_grammar 
gram1 that returns a Homework 2-style grammar, which is converted from 
the Homework 1-style grammar gram1. Test your implementation of convert_grammar 
on the test grammars given in Homework 1. For example, the top-level definition 
let awksub_grammar_2 = convert_grammar awksub_grammar should bind awksub_grammar_2 
to a Homework 2-style grammar that is equivalent to the Homework 1-style grammar 
awksub_grammar. *)

let convert_grammar (ss, all_rules) =
  (ss, filter all_rules)

(* As another warmup, write a function parse_tree_leaves tree that 
traverses the parse tree tree left to right and yields a list of 
the leaves encountered, in order. *)

let rec ptl acc tree =
  match tree with
  | Node (nt, ch_list) -> 
        let rec child = function
        | ch::tl -> 
          (ptl acc ch)@(child tl)
        | [] -> []
        in child ch_list
  | Leaf lf -> lf::acc

let rec parse_tree_leaves tree =
  ptl [] tree

(* Write a function mm grammar that returns a mom for
the grammar gram. When applied to an accor acc and a
fragment frag, the mom must try the grammar rules in order
and return the result of calling acc on the suffix 
corresponding to the first accable matching prefix of frag;
this is not necessarily the shortest or the longest accable match.
A match is considered to be accable if acc succeeds when
given the suffix fragment that immediately follows the matching
prefix. When this happens, the mom returns whatever the
accor returned. If no accable match is found, the ma
returns None. *)

let match_empty acc frag = acc frag;;
let match_nothing acc frag = None;;

let rec mom pf = function
  (* pattern matching a list of rules *)
  | [] -> match_nothing
  | rh::rt -> 
    fun acc frag ->
      let hm = mam pf rh acc frag 
      and tm = mom pf rt 
      in match hm with
      (* If the acceptor returned is none,
         we need to move onto the next rule
    in th rules list as hm was a dead end *)
        | None -> tm acc frag
        | _ -> hm
and mam pf = function 
(* pattern matching a single rule *)
  | [] -> match_empty
  | (T t)::rt ->
  (* pattern matching the fragment
     - if the terminals match, then invoke mam
       on the remaining tail (this automatically
     builds up the acceptor for the parent functions)*)
     (fun acc -> function
      | [] -> None
      | fh::ft -> 
        if fh = t then mam pf rt acc ft 
        else None
      )
  | (N nt)::rt ->
    (* Call mom on the non-terminal
       - expand nt with production function
       - get the acceptor for the remaining tail
         from an invocation of mam on the said tail
       - pass the expanded nt and the acceptor into
       the mom call *)
    (let rules = pf nt in
     fun acc frag ->
      let new_acc = mam pf rt acc
      in mom pf rules new_acc frag
    );;

let make_matcher (ss, pf) = 
  let rules = pf ss in
  fun acc frag ->
  mom pf rules acc frag;; 

(* Write a function make_parser gram that returns a parser for the grammar gram.
When applied to a fragment frag, the parser returns an optional parse tree.
If frag cannot be parsed entirely (that is, from beginning to end), the parser 
returns None. Otherwise, it returns Some tree where tree is the parse tree 
corresponding to the input fragment. Your parser should try grammar rules 
in the same order as make_matcher. *)

let p_acc = function
  | [] -> fun tree -> Some tree
  | _  -> fun tree -> None

let rec mom pf ss rules acc frag tchild =
  (* pattern matching a list of rules *)
  match rules with
  | [] -> None
  | (rh::rt) ->
    let hm = mam pf ss rh acc frag tchild 
    and tm = mom pf ss rt acc frag tchild in
    match hm with
    (* If the acceptor returned is none,
      we need to move onto the next rule
      in th rules list as hm was a dead end *)
    | None -> tm
    | Some x -> Some x

and mam pf ss rule acc frag tchild =
  match rule with
  (* pattern matching a single rule *)
  | [] -> acc frag (Node(ss, rev [] tchild))
  | (T t)::rt ->
    (* pattern matching the fragment
      - if the terminals match, then invoke mam
        on the remaining tail (this automatically
      builds up the acceptor for the parent functions)*)
    ( match frag with
      | [] -> None
      | (fh::ft) ->
        if t = fh then mam pf ss rt acc ft ((Leaf t)::tchild)
        else None
    )
  | (N nt)::rt ->
    (* Call mom on the non-terminal
        - expand nt with production function
        - get the acceptor for the remaining tail
          from an invocation of mam on the said tail
        - pass the expanded nt and the acceptor into
        the mom call *)
    let res_acc rfrag rnode = 
      mam pf ss rt acc rfrag (rnode::tchild) in
    mom pf nt (pf nt) res_acc frag []

let make_parser (ss, pf) frag =
  mom pf ss (pf ss) p_acc frag []

(* Write one good, nontrivial test case for your make_matcher function. 
It should be in the style of the test cases given below, but should cover 
different problem areas. Your test case should be named make_matcher_test. 
Your test case should test a grammar of your own. *)

type arithmetic_nonterminals =
  | Expr | Term | Factor | Expr_end | Term_end

let arithmetic_grammar =
  (Expr,
    function
    | Expr ->
        [[N Term; N Expr_end]]
    | Expr_end ->
        [[T "+"; N Term; N Expr_end];
        [T "-"; N Term; N Expr_end];
        []]
    | Term ->
        [[N Factor; N Term_end]]
    | Term_end ->
        [[T "*"; N Factor; N Term_end];
        [T "/"; N Factor; N Term_end];
        []]
    | Factor ->
        [[T "("; N Expr; T ")"];
        [T "0"]; [T "1"]; [T "2"]; [T "3"]; [T "4"];
        [T "5"]; [T "6"]; [T "7"]; [T "8"]; [T "9"]])

let expr5 = ["("; "1"; "+"; "("; "2"; "*"; "3"; ")"; "-"; "4"; ")"; "*"; "5"]

let accept_empty_suffix = function
   | _::_ -> None
   | x -> Some x

let test5 = make_matcher arithmetic_grammar accept_empty_suffix expr5

(* Similarly, write a good test case make_parser_test for your make_parser
function using your same test grammar. This test should check that
parse_tree_leaves is in some sense the inverse of make_parser gram, in
that when make_parser gram frag returns Some tree, then parse_tree_leave
tree equals frag. *)

let tree = make_parser arithmetic_grammar expr5
let test6 =
  match tree with
    | Some tree -> parse_tree_leaves tree = expr5
    | _ -> false