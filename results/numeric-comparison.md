# Numeric PDDL (ENHSP) — Heuristic Comparison

Domain: `pddl/numeric/domain.pddl` — battery modelled as numeric fluent (0-100).
Cost model: navigate=1, shelve=2, recharge=3. Metric: minimize total-cost.

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
| opt-hmax | — | — | — | >120,000 | TIMED OUT |
| opt-hrmax | — | — | — | >120,000 | TIMED OUT |

## Summary

The numeric formulation captures battery dynamics that classical STRIPS could
not express: navigation costs energy, and the planner balances delivery cost
against recharging trips.

**Key findings:**

1. **Satisficing search scales much better than optimal search.** On Problem 3,
   sat-hadd and sat-hff return plans in 0.25s while opt-hmax and opt-hrmax do
   not terminate within 120s. This is the empirical signature of exponential
   blow-up in optimal numeric planning.

2. **Satisficing plans are typically near-optimal but not guaranteed so.**
   On Problem 2, sat-hadd's cost-34 plan is 10% over the optimal cost-31.
   On Problem 1 it happened to find the optimal (cost 15).

3. **Different optimal heuristics agree.** opt-hmax and opt-hrmax produced
   identical results on Problems 1 and 2 (same plans, same expansions),
   confirming that both are admissible and converge to the same optimum.

4. **The default planner (aibr) sometimes returns clearly suboptimal plans.**
   On Problem 1, aibr returned a 16-step / cost-20 plan vs the optimum
   13-step / cost-15. sat-hadd is a strictly better satisficing choice for
   this domain.

5. **dock2 is not used by the planner in Problem 3.** Under uniform navigation
   costs, dock1's central grid position makes it preferred for all recharges.
   A differential travel cost model could force dock2 usage; this is a
   limitation of the current cost-model design and a possible refinement.

## Comparison to STRIPS

STRIPS Fast-Downward on Problem 3 (best heuristic h^FF): 44 steps, 2.36s.
Numeric ENHSP on Problem 3 (best heuristic sat-hadd): 52 steps, 0.27s.

The numeric plan is longer because it models battery management explicitly
with energy-cost weights, requiring more recharges than the STRIPS plan
(which uses a Boolean low/full battery model with single-step recharge).
Conversely, the STRIPS plan understates the true cost of operation since
its unit-action cost ignores the battery economy.

The two models answer different questions: STRIPS answers "what is the
shortest plan?", numeric answers "what is the most energy-efficient plan?".
Both are valid; the comparison highlights why expressive cost models matter.
