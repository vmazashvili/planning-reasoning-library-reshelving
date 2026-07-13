# Autonomous Library Reshelving

**Planning and Reasoning — A.A. 2025/26 (Prof. Andrea Marrella)**
Vano Mazashvili (matricola 1993251) — mazashvili.1993251@studenti.uniroma1.it

Mobile robots maintain a library: returned books accumulate on a central
*return cart*, and battery-powered robots redistribute each book to a shelf
matching its category (fiction, science, history), recharging at docks. The
domain is modelled in three complementary ways: **classical STRIPS PDDL**
(Fast-Downward), **numeric PDDL** (ENHSP, battery as a 0–100 fluent), and a
**situation-calculus Basic Action Theory** executed on the IndiGolog
interpreter with two controllers.

## Repository structure

```
pddl/
  strips/           STRIPS domain + 3 problem instances
  numeric/          numeric domain (battery fluent, action costs) + 3 problems
indigolog/
  library.pl        BAT: fluents, actions, causal laws, exogenous events,
                    reasoning helpers (legal_seq/1, holds_after/2), controllers
  main.pl           entry points: main(basic). / main(reactive).
results/
  strips-comparison.md    A* with blind / h^max / h^add / h^FF on P1–P3
  numeric-comparison.md   aibr / sat-hadd / sat-hff / opt-hmax / opt-hrmax
  plans/                  Fast-Downward plans
  plans-numeric/          ENHSP plans
  indigolog-traces/       controller session traces
slides/             presentation (PowerPoint + Beamer sources, PDF)
```

## Part 1 — PDDL

**STRIPS** (Fast-Downward, A\* with four heuristics):

```
./fast-downward.py pddl/strips/domain.pddl pddl/strips/problemN.pddl \
    --search "astar(hadd())"        # also: blind(), hmax(), ff()
```

Headline result (Problem 3): **h^add returned a 46-step plan vs the 44-step
optimum** found by Blind, h^max and h^FF — a concrete demonstration of
inadmissibility under A\*. h^max and h^FF were also *slower than Blind* in
wall-clock despite fewer expansions (per-node heuristic cost on a grid
topology). Full tables in `results/strips-comparison.md`.

**Numeric** (ENHSP): battery modelled 0–100 (`navigate` −10, `shelve` −30,
`recharge` sets 100), costs 1/2/3, metric `minimize total-cost`.

```
java -jar enhsp.jar -o pddl/numeric/domain_numeric.pddl -f pddl/numeric/problemN.pddl \
    -planner sat-hadd               # also: sat-hff, opt-hmax, opt-hrmax
```

Headline result (Problem 3): **opt-hmax / opt-hrmax time out (>120 s) while
sat-hadd solves in 0.27 s** — the exponential cost of guaranteed optimality in
numeric planning. STRIPS answers "shortest plan", numeric answers "most
energy-efficient plan". Full tables in `results/numeric-comparison.md`.

## Part 2 — IndiGolog

The BAT runs on the plain IndiGolog interpreter (SWI-Prolog):

```
$ swipl config.pl <path-to>/indigolog/main.pl
?- main(basic).       % offline search controller — 19-action plan
?- main(reactive).    % prioritized_interrupts + exogenous events
```

Reasoning tasks: **legality** (`legal_seq/1`), **projection**
(`holds_after/2`), and **controller synthesis** (basic + reactive). Three
exogenous events with genuine behavioural reactions:
`battery_drained(R)` (divert to dock, recharge, resume),
`urgent_request(B)` (pre-empt: the urgent book is served first),
`new_return(B)` (book reappears at the cart and is reshelved).
Session traces in `results/indigolog-traces/`.

## Key design decisions

- **Navigation has no battery precondition** in the STRIPS and IndiGolog
  models: guarding movement on charge creates unrecoverable dead-ends. The
  numeric model is the deliberate exception — it *can* safely require
  `battery ≥ 10` because its planner reasons about quantities and plans
  recharges ahead.
- **Battery depletion differs by design**: STRIPS auto-depletes on `shelve`;
  IndiGolog depletes only via the exogenous `battery_drained` event, so the
  reactive controller responds to a genuinely external trigger.
- **Single robot in IndiGolog** (vs up to two in PDDL): multi-robot
  coordination is demonstrated in the PDDL part; the IndiGolog part focuses on
  reasoning tasks and control constructs, keeping traces legible.
