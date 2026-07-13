# Autonomous Library Reshelving

Planning and Reasoning, A.A. 2025/26 (Prof. Andrea Marrella)
Vano Mazashvili, matricola 1993251
mazashvili.1993251@studenti.uniroma1.it

Mobile robots reshelve books in a library: returned books pile up on a central return cart, and battery-powered robots carry each one to the shelf matching its category (fiction, science or history), recharging at docks. I modelled this domain three times for the assignment: classical STRIPS in PDDL (Fast-Downward), numeric PDDL with battery as a 0-100 fluent (ENHSP), and a situation calculus Basic Action Theory on IndiGolog with two controllers.

## Repo structure

```
pddl/
  strips/           STRIPS domain + 3 problem instances
  numeric/          numeric domain (battery fluent, action costs) + 3 problems
indigolog/
  library.pl        BAT: fluents, actions, causal laws, exogenous events,
                    reasoning helpers (legal_seq/1, holds_after/2), controllers
  main.pl           entry points: main(basic). / main(reactive).
results/
  strips-comparison.md    A* with blind / h^max / h^add / h^FF on P1-P3
  numeric-comparison.md   aibr / sat-hadd / sat-hff / opt-hmax / opt-hrmax
  plans/                  Fast-Downward plans
  plans-numeric/          ENHSP plans
  indigolog-traces/       controller session traces
slides/             presentation (PowerPoint + Beamer sources, PDF)
```

## Part 1: PDDL

### STRIPS

```
./fast-downward.py pddl/strips/domain.pddl pddl/strips/problemN.pddl \
    --search "astar(hadd())"        # also: blind(), hmax(), ff()
```

On problem 3, h^add returns a 46-step plan while blind, h^max and h^FF all find the actual optimum at 44 steps, a good example of h^add not being admissible. h^max and h^FF were also slower in wall-clock time than blind despite expanding fewer nodes, since the per-node heuristic cost outweighs the savings on this grid. Full tables in `results/strips-comparison.md`.

### Numeric

Battery is a fluent between 0 and 100 (navigate -10, shelve -30, recharge resets to 100), action costs 1/2/3, metric minimize total-cost.

```
java -jar enhsp.jar -o pddl/numeric/domain_numeric.pddl -f pddl/numeric/problemN.pddl \
    -planner sat-hadd               # also: sat-hff, opt-hmax, opt-hrmax
```

On problem 3, opt-hmax and opt-hrmax time out past 120s trying to prove optimality, while sat-hadd solves it in 0.27s without that guarantee, showing how much pricier optimality gets once you're reasoning over quantities instead of just plan length. Full tables in `results/numeric-comparison.md`.

## Part 2: IndiGolog

Runs on the plain IndiGolog interpreter in SWI-Prolog:

```
$ swipl config.pl <path-to>/indigolog/main.pl
?- main(basic).       % offline search controller - 19-action plan
?- main(reactive).    % prioritized_interrupts + exogenous events
```

Reasoning tasks: legality (`legal_seq/1`), projection (`holds_after/2`), plus the basic and reactive controllers. Three exogenous events, each with its own reaction:

- `battery_drained(R)`: divert to the dock, recharge, resume
- `urgent_request(B)`: pre-empt, urgent book served first
- `new_return(B)`: book reappears at the cart, gets reshelved

Traces in `results/indigolog-traces/`.

## Design notes

- Navigate has no battery precondition in STRIPS/IndiGolog. Gating movement on charge lets a robot strand itself somewhere with a low battery and no way to reach a dock, so movement is always allowed. Numeric is the exception since the planner reasons about quantities and can plan a recharge ahead, so battery >= 10 is safe there.
- Battery depletion differs: STRIPS auto-drops it on every shelve, IndiGolog only drops it via the exogenous battery_drained event, so the reactive controller is reacting to an outside event, not to its own actions.
- IndiGolog uses one robot vs up to two in PDDL. Multi-robot coordination is already covered there, so IndiGolog stays focused on reasoning tasks and control constructs.
