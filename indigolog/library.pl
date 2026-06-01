/**
  Autonomous Library Reshelving -- IndiGolog Basic Action Theory (BAT)

  Planning & Reasoning project, Sapienza A.A. 2025/26
  Vano Mazashvili (matricola 1993251)

  Situation-calculus formulation of the library-reshelving domain, written
  for the STANDALONE indigolog_plain interpreter (the same one used by the
  vanilla elevator examples elevator_01.pl / elevator_02.pl).

  ---------------------------------------------------------------------------
  RELATION TO THE PDDL COMPONENT (adaptation, to be justified in slides)
  ---------------------------------------------------------------------------
  The PDDL problems use up to 2 robots; here we model a SINGLE robot (r1).
  Rationale: the IndiGolog component exists to demonstrate the situation-
  calculus reasoning tasks (legality, projection) and high-level control
  constructs (search, nondeterminism, prioritized interrupts / reactivity),
  NOT multi-robot coordination -- which the PDDL P2/P3 instances already show.
  A single agent keeps controller traces short and legible. Per the project
  rules, the two components need not correspond exactly; this divergence is
  declared and justified.

  Battery is kept here as a BOOLEAN fluent (battery_low/recharge), matching
  the STRIPS abstraction. The NUMERIC battery economics live in the ENHSP
  PDDL version, per Prof. Marrella's recommendation (which is scoped to the
  PDDL modeling part only).

  ---------------------------------------------------------------------------
  indigolog_plain CONVENTIONS THIS FILE OBEYS (important for correctness)
  ---------------------------------------------------------------------------
  - Boolean fluents are modelled as fluents taking VALUES (e.g. = true /
    = false, or = none), and tested with value-equality. The interpreter's
    holds/2 has NO clause for a bare relational atom; conditions must be
    written `f(x) = v`, `neg(f(x) = v)`, and/or wrapped in and/or/some.
    (This is exactly why elevator_01 writes `light(N) = on`, never `light(N)`.)
  - causes_val(Action, Fluent, Value, Condition): doing Action when Condition
    holds sets Fluent to Value. There is NO causes_true/causes_false here.
  - initially(Fluent, Value) gives the value of Fluent in S0.
  - History grows MOST-RECENT-FIRST: the head of the list is the last action.
**/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INTERFACE TO THE OUTSIDE WORLD (required by indigolog_plain main loop)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% execute/2 prints the action (ask_execute is provided by the interpreter).
execute(A, SR) :- ask_execute(A, SR).

% exog_occurs/1: behaviour depends on exog_mode/1 (set by main.pl).
%   exog_mode(none)        -> never offer an exogenous action (OFFLINE).
%                             Used by the BASIC controller: runs with no
%                             console prompts, just prints its plan.
%   exog_mode(interactive) -> ask the console each step (the elevator_02
%                             idiom). Used by the REACTIVE controller, where
%                             you type e.g. urgent_request(b2). at the prompt.
:- dynamic exog_mode/1.
exog_mode(none).                 % default: offline (no prompts)

exog_occurs(_) :- exog_mode(none), !, fail.
exog_occurs(A) :- exog_mode(interactive), ask_exog_occurs(A).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DOMAIN OBJECTS  (sorts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
robot(r1).

book(b1).
book(b2).
book(b3).

category(fiction).
category(science).
category(history).

% Zones (the 7-zone scoped topology from the handoff)
zone(cart).
zone(z1).
zone(fiction_shelf).
zone(z2).
zone(science_shelf).
zone(history_shelf).
zone(dock).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RIGID RELATIONS  (static facts -- not fluents, never change)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Connectivity. We declare each edge once in connected/2, then make path/2
% the symmetric closure so navigation works both directions without us
% writing every pair twice.
connected(cart, z1).
connected(z1, fiction_shelf).
connected(z1, z2).
connected(z2, science_shelf).
connected(z2, history_shelf).
connected(z2, dock).

path(X, Y) :- connected(X, Y).
path(X, Y) :- connected(Y, X).

% Charging station location.
station_at(dock).

% Which category each book belongs to.
book_category(b1, fiction).
book_category(b2, science).
book_category(b3, history).

% Which category each shelf zone accepts.
shelf_category(fiction_shelf, fiction).
shelf_category(science_shelf, science).
shelf_category(history_shelf, history).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRIMITIVE FLUENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% robot_loc(R) = Z      : robot R is in zone Z
prim_fluent(robot_loc(R)) :- robot(R).

% book_loc(B) = Z       : book B is in zone Z   (its physical location)
% book_loc(B) = onboard : book B is being carried by a robot
prim_fluent(book_loc(B)) :- book(B).

% carrying(R) = B        : robot R is carrying book B
% carrying(R) = none     : robot R carries nothing
prim_fluent(carrying(R)) :- robot(R).

% shelved(B) = true/false : book B has been correctly shelved
prim_fluent(shelved(B)) :- book(B).

% battery_low(R) = true/false : robot R's battery is low
prim_fluent(battery_low(R)) :- robot(R).

% urgent(B) = true/false  : book B has an urgent reshelving request
% (set by the urgent_request exogenous action; used by reactive controller)
prim_fluent(urgent(B)) :- book(B).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRIMITIVE ACTIONS  +  PRECONDITIONS (poss/2)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% navigate(R, From, To): robot R drives along a path edge.
% NOTE (key domain design decision, carried over from PDDL):
% navigate does NOT require a charged battery. Requiring full battery would
% create unrecoverable dead-ends (robot stranded at a shelf, unable to reach
% a dock). So navigation is always allowed along an existing path; the
% numeric PDDL version is where real battery economics are enforced.
prim_action(navigate(R, From, To)) :- robot(R), zone(From), zone(To).
poss(navigate(R, From, To),
     and(robot_loc(R) = From, path(From, To))).

% pickup(R, B): robot R picks up book B.
% Requires: R is free (carrying none), R is co-located with B, B not onboard,
% and B is not already shelved.
prim_action(pickup(R, B)) :- robot(R), book(B).
poss(pickup(R, B),
     and(carrying(R) = none,
     and(robot_loc(R) = Z,
     and(book_loc(B) = Z,
         shelved(B) = false)))).

% shelve(R, B): robot R shelves the book it is carrying onto a
% category-matching shelf at its current zone.
% Requires: R carries B, R is at a zone Z that is a shelf, and the shelf's
% category matches the book's category, and battery is NOT low (the
% battery-depleting action is the one we guard, matching STRIPS).
prim_action(shelve(R, B)) :- robot(R), book(B).
poss(shelve(R, B),
     and(carrying(R) = B,
     and(robot_loc(R) = Z,
     and(shelf_category(Z, C),
     and(book_category(B, C),
         battery_low(R) = false))))).

% recharge(R): robot R recharges at a charging station.
% Requires: R is at a zone with a station, and battery is currently low.
prim_action(recharge(R)) :- robot(R).
poss(recharge(R),
     and(robot_loc(R) = Z,
     and(station_at(Z),
         battery_low(R) = true))).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CAUSAL LAWS  (successor-state axioms via causes_val/4)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- navigate: robot's location becomes To ---
% NOTE: navigate does NOT deplete the battery. This mirrors the PDDL design
% (navigate has no battery precondition, to avoid unrecoverable stranding).
% In this boolean model the battery only goes low via the exogenous event
% battery_drained(R); the reactive controller handles recharging. The NUMERIC
% PDDL version (ENHSP) is where quantitative battery economics live.
causes_val(navigate(R, _, To), robot_loc(R), To, true).

% --- pickup: robot now carries B; B is onboard (no longer in a zone) ---
causes_val(pickup(R, B), carrying(R), B, true).
causes_val(pickup(_, B), book_loc(B), onboard, true).

% --- shelve: book placed at the shelf zone, robot freed, book marked shelved
causes_val(shelve(R, _), carrying(R), none, true).
causes_val(shelve(R, B), book_loc(B), Z, robot_loc(R) = Z).
causes_val(shelve(_, B), shelved(B), true, true).
% Shelving also clears any urgent flag on that book (request satisfied).
causes_val(shelve(_, B), urgent(B), false, true).

% --- recharge: battery no longer low ---
causes_val(recharge(R), battery_low(R), false, true).

% --- exogenous effects ---
% urgent_request(B): an urgent reshelving request arrives for book B.
causes_val(urgent_request(B), urgent(B), true, true).
% new_return(B): a returned book reappears at the cart and is no longer
% considered shelved (it must be reshelved again).
causes_val(new_return(B), book_loc(B), cart, true).
causes_val(new_return(B), shelved(B), false, true).
% battery_drained(R): robot R's battery becomes low (exogenous event the
% reactive controller must handle by diverting to a dock and recharging).
causes_val(battery_drained(R), battery_low(R), true, true).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXOGENOUS ACTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
exog_action(urgent_request(B)) :- book(B).
exog_action(new_return(B))     :- book(B).
exog_action(battery_drained(R))  :- robot(R).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIAL STATE  (S0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Robot starts at the cart, free, fully charged.
initially(robot_loc(r1), cart).
initially(carrying(r1), none).
initially(battery_low(r1), false).

% All three books start at the return cart, unshelved, not urgent.
initially(book_loc(b1), cart).
initially(book_loc(b2), cart).
initially(book_loc(b3), cart).

initially(shelved(B), false) :- book(B).
initially(urgent(B), false)  :- book(B).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ABBREVIATIONS  (derived conditions used by controllers)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% A book still needs shelving.
proc(needs_shelving(B), shelved(B) = false).
% There exists some book still needing shelving.
proc(some_unshelved, some(b, and(book(b), shelved(b) = false))).
% There exists some book with an urgent request still unshelved.
proc(some_urgent, some(b, and(urgent(b) = true, shelved(b) = false))).
% Robot is at a station zone.
proc(at_station(R), some(z, and(robot_loc(R) = z, station_at(z)))).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPLEX ACTIONS  (procedures)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% -------------------------------------------------------------------------
% Routing: go_to(R, Dest) -- navigate r1 across the zone GRAPH to Dest.
% -------------------------------------------------------------------------
% Unlike the elevator (a 1-D line of floors served by up/down), our zones
% form a small graph, so reaching a shelf may take several hops. We let the
% IndiGolog SEARCH operator discover the route: go_to nondeterministically
% steps to a navigable neighbour and recurses until the robot is at Dest.
%
% A HOP COUNTER (Max) bounds the recursion so depth-first findpath cannot
% loop forever on cycles like z1 -> z2 -> z1 -> ...  This is the same
% bounding trick elevator_01's minimize_motion uses. 7 = number of zones,
% an upper bound on any simple path in this topology.
% Entry point: start routing with the current zone marked visited, so the
% search never steps back onto where it started.
proc(go_to(R, Dest),
     pi(here, [ ?(robot_loc(R) = here), go_to(R, Dest, [here]) ])).

% already there: stop (zero further moves).
proc(go_to(R, Dest, _Visited), ?(robot_loc(R) = Dest)).

% otherwise: step to an UNVISITED neighbour and recurse, adding it to the
% visited set. The visited set forbids revisiting any zone, so every route is
% a SIMPLE (acyclic) path -- this eliminates the back-and-forth thrashing that
% an unconstrained search produces (it would otherwise commit to the first
% goal-reaching path it finds, wandering included). On this small graph a
% simple path is optimal or near-optimal.
proc(go_to(R, Dest, Visited),
     [ ?(neg(robot_loc(R) = Dest)),
       pi(next, [ ?(and(robot_loc(R) = Here,
                    and(path(Here, next),
                        neg(member(next, Visited))))),
                  navigate(R, _, next),
                  go_to(R, Dest, [next|Visited]) ]) ]).

% ensure_charged(R): if battery is low and we are at a station, recharge.
% (Used by the REACTIVE controller's battery response; the basic controller
%  never needs it because navigation no longer depletes the battery.)
proc(ensure_charged(R),
     if(battery_low(R) = true,
        if(at_station(R), recharge(R), []),
        [])).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONTROLLER 1 -- BASIC SEARCH CONTROLLER
%
% Goal: shelve ALL books. Demonstrates nondeterministic action choice (the
% pi argument picks), iteration (the while loop), and the IndiGolog lookahead
% SEARCH operator, which finds a complete executable plan offline before
% committing to the first action.
%
% The program is GOAL-DIRECTED and BOUNDED (each loop iteration shelves one
% book; go_to is hop-bounded), so the search tree is finite and shallow --
% this is the elevator_01 `smart`/minimize_motion shape, adapted to a graph.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% serve_book(R, B): route to B's category-matching shelf, then shelve it.
% (B must already be on board, i.e. picked up at the cart.)
proc(serve_book(R, B),
     pi(shelf, [ ?(and(shelf_category(shelf, C), book_category(B, C))),
                 go_to(R, shelf),
                 shelve(R, B) ])).

% collect_book(R, B): drive to wherever B currently sits and pick it up.
proc(collect_book(R, B),
     pi(z, [ ?(book_loc(B) = z),
             go_to(R, z),
             pickup(R, B) ])).

% handle_book(R, B): full cycle for one book -- collect then shelve.
proc(handle_book(R, B),
     [ collect_book(R, B), serve_book(R, B) ]).

% pick SOME still-unshelved book and fully handle it.
proc(handle_some_book,
     pi(b, [ ?(and(book(b), shelved(b) = false)), handle_book(r1, b) ])).

% goal test: nothing left unshelved.
proc(all_shelved, ?(neg(some_unshelved))).

% The program to search over: while some book is unshelved, handle one.
% Terminates after at most |books| iterations.
proc(shelve_all_prog,
     [ while(some_unshelved, handle_some_book), all_shelved ]).

% CONTROLLER: wrap the program in search for offline plan generation.
proc(control(basic), search(shelve_all_prog)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONTROLLER 2 -- REACTIVE CONTROLLER (prioritized_interrupts)
%
% Demonstrates reactivity to THREE exogenous events:
%   urgent_request(B)  : an urgent reshelving request for book B
%   new_return(B)      : a returned book reappears at the cart (must reshelve)
%   battery_drained(R) : robot R's battery goes low (must divert + recharge)
%
% Priority order (highest first):
%   1. battery low & at a station  -> recharge (cheap, opportunistic)
%   2. battery low (not at station)-> drive to the dock (then rule 1 fires)
%   3. some urgent unshelved book  -> plan & shelve everything (urgent first)
%   4. some unshelved book         -> plan & shelve everything
%   5. otherwise                   -> idle: wait for the next exogenous event
%
% Rules 3 and 4 both call search(shelve_all_prog); listing urgent strictly
% above non-urgent makes the controller PRE-EMPT to service an urgent request
% as soon as one arrives. The lowest-priority idle interrupt keeps the
% controller alive between events.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

proc(control(reactive),
     prioritized_interrupts(
       [ % 1. opportunistic recharge when already at a dock
         interrupt(and(battery_low(r1) = true, at_station(r1)), recharge(r1)),
         % 2. battery low but not at a dock: head to the dock
         interrupt(battery_low(r1) = true, go_to(r1, dock)),
         % 3. urgent requests pre-empt: plan to shelve everything
         interrupt(some_urgent, search(shelve_all_prog)),
         % 4. otherwise clear any remaining unshelved books
         interrupt(some_unshelved, search(shelve_all_prog)),
         % 5. nothing to do: wait for the next exogenous event. The body
         %    test fails (no actionable condition yet), so this interrupt
         %    yields control back to the main loop, which calls exog_occurs
         %    to read the next event. When the queue/console supplies an
         %    event, a higher-priority interrupt fires on the next pass.
         interrupt(true, ?(some(b, and(book(b), shelved(b) = false)))) ])).

% NOTE on termination: when every book is shelved AND no exogenous event is
% pending, all interrupt triggers are false, the prioritized_interrupts block
% reaches stop_interrupts, and the controller terminates cleanly. With the
% interactive exog model, press 'end_indi'-style: just answer 'true.' at the
% final prompt and the controller falls through to completion.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REASONING-TASK HELPERS  (legality & projection convenience predicates)
%
% These are thin wrappers around the interpreter's holds/2 and poss/2 so the
% three required reasoning tasks read cleanly at the top level.
%
% IMPORTANT history-order reminder: histories are MOST-RECENT-FIRST.
% A sequence [a1, a2, ..., aN] executed in order corresponds to the history
% list [aN, ..., a2, a1].  The helper legal_seq/1 takes the actions in
% EXECUTION order (a1 first) and threads them through, so you don't have to
% reverse by hand.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TASK 1 -- LEGALITY
% legal_seq(+Actions): true if the list Actions (in EXECUTION order) is
% executable from S0, i.e. each action's precondition holds in the history
% built so far. Builds the history newest-first as it goes.
legal_seq(Actions) :- legal_seq(Actions, []).
legal_seq([], _).
legal_seq([A|As], H) :-
    prim_action(A),
    poss(A, P),
    holds(P, H),
    legal_seq(As, [A|H]).

% Convenience: build the resulting history (newest-first) from a legal
% execution-order sequence, for use in projection queries.
do_seq([], H, H).
do_seq([A|As], H, Hf) :- do_seq(As, [A|H], Hf).

% TASK 2 -- PROJECTION
% holds_after(+Actions, +Condition): true if Condition holds in the history
% produced by executing Actions (execution order) from S0.
% (Does NOT check legality; compose with legal_seq if you want both.)
holds_after(Actions, Condition) :-
    do_seq(Actions, [], H),
    holds(Condition, H).

% TASK 3 (controller execution) is run directly via:
%     indigolog(control(basic)).      or
%     indigolog(control(reactive)).