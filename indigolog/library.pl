/**
  Autonomous Library Reshelving -- IndiGolog BAT
  Planning & Reasoning, Sapienza A.A. 2025/26
  Vano Mazashvili (matricola 1993251)

  Standalone indigolog_plain interpreter. Boolean battery here; numeric
  battery lives in the ENHSP PDDL version.
**/

%%% INTERFACE %%%

execute(A, SR) :- ask_execute(A, SR).

:- dynamic exog_mode/1.
:- dynamic exog_queue/1.
exog_mode(none).
exog_queue([]).

seed_exog(Events) :- retractall(exog_queue(_)), assert(exog_queue(Events)).

exog_occurs(_) :- exog_mode(none), !, fail.
exog_occurs(A) :- exog_mode(queued), !,
    exog_queue([A|Rest]),
    retractall(exog_queue(_)), assert(exog_queue(Rest)).
exog_occurs(A) :- exog_mode(interactive), ask_exog_occurs(A).


%%% SORTS %%%

robot(r1).

book(b1).
book(b2).
book(b3).

category(fiction).
category(science).
category(history).

zone(cart).
zone(z1).
zone(fiction_shelf).
zone(z2).
zone(science_shelf).
zone(history_shelf).
zone(dock).


%%% RIGID RELATIONS %%%

connected(cart, z1).
connected(z1, fiction_shelf).
connected(z1, z2).
connected(z2, science_shelf).
connected(z2, history_shelf).
connected(z2, dock).

path(X, Y) :- connected(X, Y).
path(X, Y) :- connected(Y, X).

station_at(dock).

book_category(b1, fiction).
book_category(b2, science).
book_category(b3, history).

shelf_category(fiction_shelf, fiction).
shelf_category(science_shelf, science).
shelf_category(history_shelf, history).


%%% FLUENTS %%%

prim_fluent(robot_loc(R)) :- robot(R).
prim_fluent(book_loc(B))  :- book(B).
prim_fluent(carrying(R))  :- robot(R).
prim_fluent(shelved(B))   :- book(B).
prim_fluent(battery_low(R)) :- robot(R).
prim_fluent(urgent(B))    :- book(B).


%%% ACTIONS + PRECONDITIONS %%%

% navigate has NO battery precondition: guarding movement on charge would
% strand a robot unrecoverably. Battery is guarded on shelve instead.
prim_action(navigate(R, From, To)) :- robot(R), zone(From), zone(To).
poss(navigate(R, From, To),
     and(robot_loc(R) = From, path(From, To))).

prim_action(pickup(R, B)) :- robot(R), book(B).
poss(pickup(R, B),
     and(carrying(R) = none,
     and(robot_loc(R) = Z,
     and(book_loc(B) = Z,
         shelved(B) = false)))).

prim_action(shelve(R, B)) :- robot(R), book(B).
poss(shelve(R, B),
     and(carrying(R) = B,
     and(robot_loc(R) = Z,
     and(shelf_category(Z, C),
     and(book_category(B, C),
         battery_low(R) = false))))).

prim_action(recharge(R)) :- robot(R).
poss(recharge(R),
     and(robot_loc(R) = Z,
     and(station_at(Z),
         battery_low(R) = true))).


%%% CAUSAL LAWS %%%

% navigate does not deplete battery in this boolean model; the drain is
% exogenous (see battery_drained/1 below).
causes_val(navigate(R, _, To), robot_loc(R), To, true).

causes_val(pickup(R, B), carrying(R), B, true).
causes_val(pickup(_, B), book_loc(B), onboard, true).

causes_val(shelve(R, _), carrying(R), none, true).
causes_val(shelve(R, B), book_loc(B), Z, robot_loc(R) = Z).
causes_val(shelve(_, B), shelved(B), true, true).
% Shelving satisfies any urgent request on that book.
causes_val(shelve(_, B), urgent(B), false, true).

causes_val(recharge(R), battery_low(R), false, true).

% exogenous effects
causes_val(urgent_request(B), urgent(B), true, true).
causes_val(new_return(B), book_loc(B), cart, true).
causes_val(new_return(B), shelved(B), false, true).
causes_val(battery_drained(R), battery_low(R), true, true).


%%% EXOGENOUS ACTIONS %%%

exog_action(urgent_request(B))  :- book(B).
exog_action(new_return(B))      :- book(B).
exog_action(battery_drained(R)) :- robot(R).


%%% INITIAL STATE %%%

initially(robot_loc(r1), cart).
initially(carrying(r1), none).
initially(battery_low(r1), false).

initially(book_loc(b1), cart).
initially(book_loc(b2), cart).
initially(book_loc(b3), cart).

initially(shelved(B), false) :- book(B).
initially(urgent(B), false)  :- book(B).


%%% ABBREVIATIONS %%%

proc(needs_shelving(B), shelved(B) = false).
proc(some_unshelved, some(b, and(book(b), shelved(b) = false))).
proc(some_urgent, some(b, and(urgent(b) = true, shelved(b) = false))).
proc(at_station(R), some(z, and(robot_loc(R) = z, station_at(z)))).


%%% PROCEDURES %%%

% Routing on the zone graph. The visited-set forces simple paths -- without
% it, an unconstrained search wanders (35 actions instead of 19).
proc(go_to(R, Dest),
     pi(here, [ ?(robot_loc(R) = here), go_to(R, Dest, [here]) ])).

proc(go_to(R, Dest, _Visited), ?(robot_loc(R) = Dest)).

proc(go_to(R, Dest, Visited),
     [ ?(neg(robot_loc(R) = Dest)),
       pi(next, [ ?(and(robot_loc(R) = Here,
                    and(path(Here, next),
                        neg(member(next, Visited))))),
                  navigate(R, _, next),
                  go_to(R, Dest, [next|Visited]) ]) ]).

proc(ensure_charged(R),
     if(battery_low(R) = true,
        if(at_station(R), recharge(R), []),
        [])).


%%% CONTROLLER 1 -- BASIC %%%

proc(serve_book(R, B),
     pi(shelf, [ ?(and(shelf_category(shelf, C), book_category(B, C))),
                 go_to(R, shelf),
                 shelve(R, B) ])).

proc(collect_book(R, B),
     pi(z, [ ?(book_loc(B) = z),
             go_to(R, z),
             pickup(R, B) ])).

proc(handle_book(R, B),
     [ collect_book(R, B), serve_book(R, B) ]).

% Urgent-first selection. shelve clears urgent(B), so the loop drains urgent
% books before non-urgent ones -- urgent_request genuinely pre-empts.
proc(handle_urgent_book,
     pi(b, [ ?(and(urgent(b) = true, shelved(b) = false)), handle_book(r1, b) ])).
proc(handle_any_book,
     pi(b, [ ?(and(book(b), shelved(b) = false)), handle_book(r1, b) ])).
proc(handle_some_book,
     if(some_urgent, handle_urgent_book, handle_any_book)).

proc(all_shelved, ?(neg(some_unshelved))).

proc(shelve_all_prog,
     [ while(some_unshelved, handle_some_book), all_shelved ]).

proc(control(basic), search(shelve_all_prog)).


%%% CONTROLLER 2 -- REACTIVE %%%

proc(control(reactive),
     prioritized_interrupts(
       [ interrupt(and(battery_low(r1) = true, at_station(r1)), recharge(r1)),
         % Wrapped in search: under prioritized_interrupts the body is
         % re-expanded each step, so bare go_to loses its visited-set.
         interrupt(battery_low(r1) = true, search(go_to(r1, dock))),
         interrupt(some_urgent, search(shelve_all_prog)),
         interrupt(some_unshelved, search(shelve_all_prog)),
         % Lowest priority: body always fails, so when no other interrupt
         % can fire the controller terminates cleanly.
         interrupt(true, ?(neg(true))) ])).


%%% REASONING-TASK HELPERS %%%

% Histories are most-recent-first. legal_seq/1 takes actions in execution
% order and threads them through automatically.

% Task 1 -- legality
legal_seq(Actions) :- legal_seq(Actions, []).
legal_seq([], _).
legal_seq([A|As], H) :-
    prim_action(A),
    poss(A, P),
    holds(P, H),
    legal_seq(As, [A|H]).

do_seq([], H, H).
do_seq([A|As], H, Hf) :- do_seq(As, [A|H], Hf).

% Task 2 -- projection
holds_after(Actions, Condition) :-
    do_seq(Actions, [], H),
    holds(Condition, H).

% Task 3 (controller execution) -- run via:
%   indigolog(control(basic)).
%   indigolog(control(reactive)).