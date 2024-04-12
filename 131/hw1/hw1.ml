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

(* 
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
 let rec union la lb = 
  match lb with
  | [] -> la
  | hd::tl -> hd::(union la tl);;

(* 4 *)
let rec set_all_union = function
	| [] -> []
| hd::tl -> union hd (set_all_union tl);;

(* 5 *)
let self_member s = false;;

(* 6 *)
let rec computed_fixed_point eq f x = 
  let next_val = f x in 
  if eq x next_val then x
  else computed_fixed_point eq f next_val;;

(* 7 *)
let computed_periodic_point eq f p x = 
  let rec matcher eq f p x = function
    | [] -> let rec fill_acc eq f p x count a =
              match count with
              | x when x<p -> fill_acc eq f p (f x) (count+1) a@[f x]
              | _ -> a
            in matcher eq f p x (fill_acc eq f p x 0 [])
    | h::t -> if eq h (f x) then x else matcher eq f p (f x) (t@[f x])
  in matcher eq f p x [];;

  let tester = function
  | x when x=0 -> 1
  | x when x=1 -> 2
  | x when x=2 -> 3
  | x when x=3 -> 1
  | _ -> 1;;
  
(* 8 *)
let whileseq s p x =
  let rec whileseq_ s p x acc = 
    if p x then 
      whileseq_ s p (s x) (x::acc) 
    else 
      List.rev acc
  in whileseq_ s p x [];;

  (*
     let computed_periodic_point eq f p x = 
  let rec fill_acc eq f p x count a =
    match count with
    | x when x<p -> fill_acc eq f p (f x) (count+1) a@[f x]
    | _ -> let rec matcher eq f p x = function
             | [] -> 0
             | h::t -> if eq h (f x) then x else matcher eq f p (f x) t
           in matcher eq f p x a
  in fill_acc eq f p x 0 []
  *)
     
 *)
