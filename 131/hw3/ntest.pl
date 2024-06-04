%for debugging, from http://www.swi-prolog.org/pldoc/man?predicate=print/1

/*helper - return true if for X | R list of lists all lists are length N*/
len([], _).
len([X | R], N) :- 
	length(X, N),
	len(R, N).

/*transpose of matrix from: https://stackoverflow.com/questions/4280986/how-to-transpose-a-matrix-in-prolog*/
transpose([], []).
transpose([F|Fs], Ts) :-
    transpose(F, [F|Fs], Ts).

transpose([], _, []).
transpose([_|Rs], Ms, [Ts|Tss]) :-
        lists_firsts_rests(Ms, Ts, Ms1),
        transpose(Rs, Ms1, Tss).

lists_firsts_rests([], [], []).
lists_firsts_rests([[F|Os]|Rest], [F|Fs], [Os|Oss]) :-
        lists_firsts_rests(Rest, Fs, Oss).

/*helper - return true if all elements before are less*/
all_less([], _).
all_less([H | Rest], X) :-
	%print(H), nl, print(X), nl,
	H #< X,
	all_less(Rest, X).

verify_one([], _, X) :- X = 0.
verify_one([X | R], Before, Count) :-
	%print(Count), nl,
	%print(Before), print(X), nl, nl,
	append(Before, [X], NewBefore),
	verify_one(R, NewBefore, Count1),
	(all_less(Before, X) -> Count is Count1 + 1; Count1 = Count).

/*helper - take one list of vals to check, check it works assuming it's the
  left side of the board T*/
verify_rc([], []).
verify_rc([X | TRest], [Num | ValsRest]) :-
	verify_one(X, [], Cnt), Cnt = Num,
	verify_rc(TRest, ValsRest).

/*helper - reverse all lists within this list of lists*/
reverse_all([], []).
reverse_all([X | L], [XRev | LRev]) :-
	reverse(X, XRev),
	reverse_all(L, LRev).

/*check the visible building counts matches on every edge*/
verify(T, Tt, Tr, Ttr, Tp, B, L, R) :-
	verify_rc(T, L),
	verify_rc(Tr, R),
	verify_rc(Tt, Tp),
	verify_rc(Ttr, B).

dom(N, X) :-
	fd_domain(X, 1, N).

m_length(N, T) :-
    length(T, N).

ntower(N, T, counts(Tp, B, L, R)) :-
    length(T, N),
    transpose(T, Tt),
    maplist(m_length(N), T),
    maplist(m_length(N), [Tp, B, L, R]),
	maplist(dom(N), T),
    maplist(fd_all_different, T),
    maplist(fd_all_different, Tt),
    maplist(fd_labeling, T),
    maplist(reverse, T, Tr),
    maplist(reverse, Tt, Ttr),
	verify(T, Tt, Tr, Ttr, Tp, B, L, R).