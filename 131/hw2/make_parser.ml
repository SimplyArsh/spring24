type ('nt, 't) symbol =
  | N of 'nt
  | T of 't

type ('nt, 't) parse_tree =
  | Node of 'nt * ('nt, 't) parse_tree list
  | Leaf of 't

  let p_acc frag tree =
  match frag with
  | [] -> Some tree
  | _ -> None

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
  | [] -> acc frag (Node(ss, tchild)) (* tree and acceptor*)
  | (T t)::rt ->
    (* pattern matching the fragment
     - if the terminals match, then invoke mam
       on the remaining tail (this automatically
     builds up the acceptor for the parent functions)*)
    ( match frag with
      | [] -> None
      | (fh::ft) ->
        match (t = fh) with
        | true -> mam pf ss rt acc ft (tchild @ [Leaf t])
        | false -> None
    )
  | (N nt)::rt ->
    (* Call mom on the non-terminal
        - expand nt with production function
        - get the acceptor for the remaining tail
          from an invocation of mam on the said tail
        - pass the expanded nt and the acceptor into
        the mom call *)
    let res_acc frag2 tree2 = 
      mam pf ss rt acc frag2 (tchild @ [tree2]) in
    mom pf nt (pf nt) res_acc frag []

let make_parser (ss, pf) frag =
  mom pf ss (pf ss) p_acc frag []


type awksub_nts =
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



let small_awk_frag = ["$"; "1"; "++"; "-"; "2"]

let test6 =
  ((make_parser awkish_grammar small_awk_frag)
    = Some (Node (Expr,
      [Node (Term,
      [Node (Lvalue,
              [Leaf "$";
        Node (Expr,
              [Node (Term,
                [Node (Num,
                [Leaf "1"])])])]);
        Node (Incrop, [Leaf "++"])]);
      Node (Binop,
      [Leaf "-"]);
      Node (Expr,
      [Node (Term,
              [Node (Num,
              [Leaf "2"])])])])))
