let print_terminals frag =
  (* print_endline name; *)
  List.iter (fun x ->print_string (x ^ " ")) frag;
  print_newline ()

(* ex: [N Expr, T"09", N Term] *)
let rec match_append gram_check rule frag =
  (* print_terminals frag "AND"; *) 
  match rule with
  | (T rh)::rtl -> 
    (
      match frag with
      | fh::ftl -> if fh=rh then
        match_append gram_check rtl ftl else None
      | [] -> None
    )
  | (N rh)::rtl -> let res_frag = 
    match_or gram_check (gram_check rh) frag in 
    (
      match res_frag with
      | None -> None
      | Some x -> match_append gram_check rtl x
    )
  | [] -> Some (frag)

and match_or gram_check rules frag =
  (* print_terminals frag "OR"; *)
  match rules with
  | rh::rtl -> let mh = 
    match_append gram_check rh frag in
    (
      match mh with
      | None -> match_or gram_check rtl frag
      | Some x -> Some x
    )
  | [] -> None

let rec root_make_or gram_check rules acc frag =
    match match_or gram_check rules frag with
    | None -> acc frag
    | Some x ->
      let result = acc x in
      (
        match result with
        | Some res -> Some res
        | None -> 
          (
            match rules with
            | hd::tl -> root_make_or gram_check tl acc frag
            | [] -> None
          )
      )

let make_matcher (root, gram_check) acc frag =
  root_make_or gram_check (gram_check root) acc frag

let accept_all string = Some string

let accept_empty_suffix = function
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
(* 
let test0 =
  ((make_matcher awkish_grammar accept_all ["9"]))

let test2 =
  ((make_matcher awkish_grammar accept_all ["9"; "+"; "$"; "1"; "+"]))

let test3 =
  ((make_matcher awkish_grammar accept_empty_suffix ["9"; "+"; "$"; "1"; "+"])) *)

  let test4 =
    (make_matcher awkish_grammar accept_all
        ["("; "$"; "8"; ")"; "-"; "$"; "++"; "$"; "--"; "$"; "9"; "+";
         "("; "$"; "++"; "$"; "2"; "+"; "("; "8"; ")"; "-"; "9"; ")";
         "-"; "("; "$"; "$"; "$"; "$"; "$"; "++"; "$"; "$"; "5"; "++";
         "++"; "--"; ")"; "-"; "++"; "$"; "$"; "("; "$"; "8"; "++"; ")";
         "++"; "+"; "0"])

(* Write a function make_parser gram that returns a parser for the grammar gram. 
When applied to a fragment frag, the parser returns an optional parse tree. 
If frag cannot be parsed entirely (that is, from beginning to end), the parser 
returns None. Otherwise, it returns Some tree where tree is the parse tree corresponding
to the input fragment. Your parser should try grammar rules in the same order 
as make_matcher. *)

(* 
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
  root_make_or gram_check (gram_check root) acc frag *)