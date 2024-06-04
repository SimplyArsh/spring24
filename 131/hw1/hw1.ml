(* 1 *)
let rec subset la lb = 
  match la with
  | [] -> true
  | hd::tl -> 
     let rec find x l = 
     match l with
     | hd::tl -> if hd = x then true else find x tl
     | [] -> false
   in (find hd lb)
   && subset tl lb;; 

(* 2 *) 
let equal_sets la lb = subset la lb && subset lb la;;

(* 3 *)
(* duplicates not allowed *)
let rec union_no_dup la lb = 
  match lb with
  | [] -> la
  | hd::tl -> if 
        let rec find x l = 
       match l with
       | hd::tl when hd = x -> true
       | _::tl -> find x tl
       | [] -> false
      in (find hd la)
    then union_no_dup la tl
    else hd::(union_no_dup la tl);;
    
 (* duplicates allowed *)
 let rec set_union la lb = 
  la@lb;;


(* 4 *)
let rec set_all_union = function
	| [] -> []
| hd::tl -> set_union hd (set_all_union tl);;


(* 5 *)
let self_member s = false;;

(* 6 *)
let rec computed_fixed_point eq f x = 
    let next_val = f x in 
    if eq x next_val then x
    else computed_fixed_point eq f next_val;;


(* 7 *)
let rec look_p_ahead f p x = match p with
 | 0 -> x
 | _ -> f (look_p_ahead f (p-1) x);;

let rec computed_periodic_point eq f p x = 
  if eq x (look_p_ahead f p x) then x else
    computed_periodic_point eq f p (f x);;

(* 8 *)
let whileseq s p x =
  let rec whileseq_ s p x acc = 
    if p x then 
      whileseq_ s p (s x) (x::acc) 
    else 
      List.rev acc
  in whileseq_ s p x [];;

(* 9 *)
type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal;;

let rec remove_terminals rule = match rule with
  | (N a)::tl -> a::(remove_terminals tl)
  | (T _)::tl -> remove_terminals tl
  | [] -> []

let rec rule_is_term rule terms = 
  let terminals_removed = remove_terminals rule
 in subset terminals_removed terms

let rec find_terms rules terms = match rules with
  | [] -> []
  | (lhs, rhs)::tl -> let is_term = (rule_is_term rhs terms)
              in if is_term then lhs::(find_terms tl terms)
              else find_terms tl terms;;

let rec filter_rules rules terms =
  let new_terms = (find_terms rules terms) in
  if equal_sets new_terms terms then new_terms
  else filter_rules rules new_terms;;

let rec clean_grammar rules terms = match rules with
 | (nt, arr)::tl -> let is_term = rule_is_term arr terms
              in if is_term then ((nt, arr)::clean_grammar tl terms)
              else clean_grammar tl terms
 | _ -> rules;;

let filter_blind_alleys g = match g with
  | (nt, arr) -> let term_rules = filter_rules arr [] 
                   in (nt, clean_grammar arr term_rules)











