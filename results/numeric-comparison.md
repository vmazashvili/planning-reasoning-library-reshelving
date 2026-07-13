# Numeric PDDL (ENHSP): Heuristic Comparison

Domain: `pddl/numeric/domain.pddl`, battery modelled as a numeric fluent (0-100). Cost model: navigate=1, shelve=2, recharge=3. Metric: minimize total-cost.

## Problem 1 (1 robot, 5 zones, 2 books)

| Configuration | Plan length | Metric (cost) | Expanded | Time (ms) | Optimal? |
|---|---|---|---|---|---|
| aibr (default, satisficing) | 16 | 20 | 50 | 28 | ✗ (suboptimal) |
| sat-hadd | 13 | 15 | 48 | 28 | ✓ (lucky on this instance) |
| opt-hmax | 13 | 15 | 133 | 52 | ✓ (admissible) |
| opt-hrmax | 13 | 15 | 133 | 47 | ✓ (admissible) |

## Problem 2 (2 robots, 8 zones, 4 books)

| Configuration | Plan length | Metric (cost) | Expanded | Time (ms) | Optimal? |
|---|---|---|---|---|---|
| sat-hadd | 30 | 34 | 151 | 93 | ✗ (3 extra steps) |
| sat-hff | 30 | 34 | 151 | 84 | ✗ (same as hadd) |
| opt-hmax | 27 | 31 | 266,200 | 5,594 | ✓ |
| opt-hrmax | 27 | 31 | 266,200 | 5,969 | ✓ |

## Problem 3 (2 robots, 12 zones, 6 books)

| Configuration | Plan length | Metric (cost) | Expanded | Time (ms) | Optimal? |
|---|---|---|---|---|---|
| sat-hadd | 52 | 64 | 510 | 270 | ✗ (satisficing) |
| sat-hff | 52 | 64 | 510 | 242 | ✗ (same as hadd) |
| opt-hmax | - | - | - | >120,000 | TIMED OUT |
| opt-hrmax | - | - | - | >120,000 | TIMED OUT |

## Summary

The numeric model captures battery dynamics that STRIPS just can't express: navigating costs energy, and the planner has to balance delivery cost against recharge trips.

A few things stood out from the results:

- Satisficing search scales way better than optimal search. On problem 3, sat-hadd and sat-hff both return a plan in about 0.25s, while opt-hmax and opt-hrmax don't finish within 120s, which is basically the exponential blow-up of insisting on optimality showing up empirically.
- Satisficing plans are usually close to optimal but not guaranteed to be. On problem 2, sat-hadd's plan costs 34 versus the true optimum of 31 (about 10% over). On problem 1 it actually landed on the optimum exactly, cost 15.
- opt-hmax and opt-hrmax agree everywhere they both finish: identical plans and expansion counts on problems 1 and 2, which makes sense since both are admissible and should converge to the same optimum.
- The default planner (aibr) can give clearly suboptimal plans. On problem 1 it returned a 16-step, cost-20 plan when the real optimum is 13 steps at cost 15, so sat-hadd is just a better choice for this domain.
- dock2 never actually gets used in problem 3. Since navigation costs are uniform, dock1's more central position on the grid makes it the preferred recharge point every time. Giving docks different travel costs would probably force dock2 into use too, that's something worth trying with more time.

## Comparison to STRIPS

For problem 3, Fast-Downward with h^FF finds a 44-step STRIPS plan in 2.36s. ENHSP with sat-hadd finds a 52-step numeric plan in 0.27s.

The numeric plan is longer because it's actually modelling battery management with real energy-cost weights, so it needs more recharge trips than the STRIPS plan, which just uses a boolean low/full battery model with a single-step recharge action. The STRIPS plan is arguably understating the real running cost since its unit-action costs don't account for the battery economy at all.

Basically the two models are answering different questions: STRIPS finds the shortest plan, numeric finds the most energy-efficient one. Both are correct answers to what they're each asking, which is kind of the point of the comparison: the cost model you pick changes what "best plan" even means.
