/**
    Main file -- Autonomous Library Reshelving (IndiGolog component)

    Planning & Reasoning project, Sapienza A.A. 2025/26
    Vano Mazashvili (matricola 1993251)

    Loads the standalone indigolog_plain interpreter and the library BAT,
    then offers main/0 (interactive controller picker) and main/1 (direct).

    Run from the IndiGolog repo root so config.pl's dir/2 can resolve paths:

        swipl config.pl <path-to>/library/main.pl

    Then:
        ?- main(basic).            % run the basic search controller
        ?- main(reactive).         % run the reactive controller
        ?- main.                   % pick interactively

    (Same launch convention as examples/elevator_simple/main_01.pl.)
**/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSULT NECESSARY FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% top-level interpreter (dir/2 and interpreter paths come from config.pl)
:- dir(indigolog_plain, F), consult(F).

% Consult the application (the BAT). Assumes library.pl sits next to main.pl.
:- [library].


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN PREDICATES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set_exog_mode_for/1: choose the exogenous-event behaviour per controller.
%   basic    -> none (offline, no console prompts; just prints the plan)
%   reactive -> interactive (type urgent_request(b2). etc. at the prompt)
set_exog_mode_for(basic)    :- retractall(exog_mode(_)), assert(exog_mode(none)).
% reactive: use the QUEUED mode with a default scripted scenario, for a clean
% reproducible no-prompt trace. (Call main_reactive_interactive/0 instead to
% drive it live by typing events.)
set_exog_mode_for(reactive) :-
    retractall(exog_mode(_)), assert(exog_mode(queued)),
    seed_exog([battery_drained(r1)]).
set_exog_mode_for(_)        :- true.   % any other controller: leave default

% main/0: list available controllers and run the chosen one.
main :-
    findall(C, proc(control(C), _), L),
    repeat,
    format('Controllers available: ~w\n', [L]),
    write('Select controller: '),
    read(S), nl,
    member(S, L),
    format('Executing controller: *~w*\n', [S]), !,
    set_exog_mode_for(S),
    indigolog(control(S)).

% main/1: run a named controller directly.
main(C) :- set_exog_mode_for(C), indigolog(control(C)).

% run the reactive controller in INTERACTIVE mode (type events at prompts).
main_reactive_interactive :-
    retractall(exog_mode(_)), assert(exog_mode(interactive)),
    indigolog(control(reactive)).

% run the reactive controller with a CUSTOM scripted scenario.
%   e.g. main_reactive_scenario([urgent_request(b3), battery_drained(r1)]).
main_reactive_scenario(Events) :-
    retractall(exog_mode(_)), assert(exog_mode(queued)),
    seed_exog(Events),
    indigolog(control(reactive)).