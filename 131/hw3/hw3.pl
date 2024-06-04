% change_directory('C:/Users/arshn/ucla/s24/spring24/131/hw3'). [hw3]. ntower_sub(5, T, counts([2,3,2,1,4], [3,1,3,3,2], [4,1,2,5,2], [2,4,2,1,2])).


% ========= PART 1 =============

% ------ UTILS: T_rvanspose, same_length, domain ------

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

m_length(N, X) :- length(X, N).

domain_spec_fd(N, X) :-
	fd_domain(X, 1, N).


% ------------- Tower visibility ------------------

vis_twr_fd(T, C) :-
    vis_twr_fd(T, 0, -1, C).
vis_twr_fd([], C, _, C).
vis_twr_fd([H|T], CC, M, C) :-
    (   H #> M
    ->  NewC is CC + 1,
        vis_twr_fd(T, NewC, H, C)
    ;   vis_twr_fd(T, CC, M, C)
    ).

vis_twr_iter_fd([], []).
vis_twr_iter_fd([T_h|T_t], [C_h|C_t]) :-
    vis_twr_fd(T_h, C_h), vis_twr_iter_fd(T_t, C_t).

% ----------- PART 1: Master Function -----------

ntower(N, T, counts(Tp, R, B, L)) :-
    
    % tranpose + reverse the grid for easier computation
    transpose(T, T_tr),
    maplist(reverse, T, T_rv),
    maplist(reverse, T_tr, T_tr_rv),

    % propogate some constraints and then finally label 
    length(T, N),
    maplist(m_length(N), T),
    maplist(m_length(N), [Tp, R, B, L]),
    maplist(domain_spec_fd(N), T),
    maplist(fd_all_different, T),
    maplist(fd_all_different, T_tr),
    maplist(fd_labeling, T),
    
    % check for tower visibility
    vis_twr_iter_fd(T, L), vis_twr_iter_fd(T_tr, Tp), % check the actual conditions
    vis_twr_iter_fd(T_rv, R), vis_twr_iter_fd(T_tr_rv, B).

% ========== PART 2: No fd :( =================

% ------ UTILS: unique, same_length, domain ------

% unique([]).
% unique([H|T]) :-
%     \+ member(H, T),
%     unique(T).

% domain_spec(N, [H|T]) :-
% 	between(1, N, H),
%     domain_spec(N, T).

% % ----- Tower visibility --------

% vis_twr(T, C) :-
%     vis_twr(T, 0, -1, C).
% vis_twr([], C, _, C).
% vis_twr([H|T], CC, M, C) :-
%     (   H > M
%     ->  NewC is CC + 1,
%         vis_twr(T, NewC, H, C)
%     ;   vis_twr(T, CC, M, C)
%     ).

% vis_twr_iter([], []).
% vis_twr_iter([T_h|T_t], [C_h|C_t]) :-
%     vis_twr(T_h, C_h), vis_twr_iter(T_t, C_t).


% ----------- PART 1: Master Function -----------

% plain_ntower(N, T, counts(Tp, R, B, L)) :-
    
%     % tranpose + reverse the grid for easier computation
%     transpose(T, T_tr),
%     maplist(reverse, T, T_rv),
%     maplist(reverse, T_tr, T_tr_rv),

%     % propogate some constraints and then finally label 
%     length(T, N),
%     maplist(m_length(N), T),
%     maplist(m_length(N), [Tp, R, B, L]),
%     maplist(domain_spec(N), T),
%     maplist(unique, T),
%     maplist(unique, T_tr),
    
%     % check for tower visibility
%     vis_twr_iter(T, L), vis_twr_iter(T_tr, Tp), % check the actual conditions
%     vis_twr_iter(T_rv, R), vis_twr_iter(T_tr_rv, B).