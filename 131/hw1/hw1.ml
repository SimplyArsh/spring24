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

let subset_test0 = subset [] [1;2;3]

let subset_test1 = subset [3;1;3] [1;2;3]
let subset_test2 = not (subset [1;3;7] [4;1;3])


(* 2 *) 
let equal_sets la lb = subset la lb && subset lb la;;

let equal_sets_test0 = equal_sets [1;3] [3;1;3]
let equal_sets_test1 = not (equal_sets [1;3;4] [3;1;3])

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
  match lb with
  | [] -> la
  | hd::tl -> hd::(set_union la tl);;

let set_union_test0 = equal_sets (set_union [] [1;2;3]) [1;2;3]
let set_union_test1 = equal_sets (set_union [3;1;3] [1;2;3]) [1;2;3]
let set_union_test2 = equal_sets (set_union [] []) []

(* 4 *)
let rec set_all_union = function
	| [] -> []
| hd::tl -> union hd (set_all_union tl);;

let set_all_union_test0 =
  equal_sets (set_all_union []) []
let set_all_union_test1 =
  equal_sets (set_all_union [[3;1;3]; [4]; [1;2;3]]) [1;2;3;4]
let set_all_union_test2 =
  equal_sets (set_all_union [[5;2]; []; [5;2]; [3;5;7]]) [2;3;5;7]

(* 5 *)
let self_member s = false;;

(* 6 *)
let rec computed_fixed_point eq f x = 
    let next_val = f x in 
    if eq x next_val then x
    else computed_fixed_point eq f next_val;;

let computed_fixed_point_test0 =
  computed_fixed_point (=) (fun x -> x / 2) 1000000000 = 0
let computed_fixed_point_test1 =
  computed_fixed_point (=) (fun x -> x *. 2.) 1. = infinity
let computed_fixed_point_test2 =
  computed_fixed_point (=) sqrt 10. = 1.
let computed_fixed_point_test3 =
  ((computed_fixed_point (fun x y -> abs_float (x -. y) < 1.)
        (fun x -> x /. 2.)
        10.)
    = 1.25)

(* 7 *)
let computed_periodic_point eq f p x = 
  let rec fill_acc eq f p x count a =
    match count with
    | x when x<p -> fill_acc eq f p (f x) (count+1) a@[f x]
    | _ -> let rec matcher eq f p x = function
              | [] -> 0
              | h::t -> if eq h (f x) then x else matcher eq f p (f x) t
            in matcher eq f p x a
  in fill_acc eq f p x 0 []

let computed_periodic_point_test0 =
  computed_periodic_point (=) (fun x -> x / 2) 0 (-1) = -1
let computed_periodic_point_test1 =
  computed_periodic_point (=) (fun x -> x *. x -. 1.) 2 0.5 = -1.

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
  | T of 'terminal



