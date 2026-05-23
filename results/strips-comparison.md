# STRIPS PDDL — Heuristic Comparison

All runs use A* search (`astar(<heuristic>())`) in Fast-Downward, on a Linux
laptop with default settings. Plan cost equals plan length since all actions
have unit cost.

## Problem 1 (1 robot, 5 zones, 2 books, 2 categories, 1 dock)

| Heuristic | Plan length | Cost | Expanded | Evaluated | Time (s) |
|---|---|---|---|---|---|
| Blind  | 13 | 13 |  45 |  48 | 0.003 |
| h^max  | 13 | 13 |  37 |  43 | 0.002 |
| h^add  | 13 | 13 |  16 |  22 | 0.002 |
| h^FF   | 13 | 13 |  26 |  30 | 0.002 |

**Observations:**
- All four heuristics found the same optimal-cost plan (13 steps).
- Expansion ordering confirms theoretical informativeness ordering
  h^max ≤ h^+ ≤ h^FF ≤ h^add (more informative → fewer expansions).
- Wall-clock times too small to be meaningful at this scale.

## Problem 2 (2 robots, 8 zones, 4 books, 3 categories, 1 dock)

| Heuristic | Plan length | Cost | Expanded | Evaluated | Time (s) |
|---|---|---|---|---|---|
| Blind  | 27 | 27 | 17,355 | 17,764 | 0.052 |
| h^max  | 27 | 27 | 15,082 | 16,228 | 0.055 |
| h^add  | 27 | 27 |  3,893 |  8,296 | 0.034 |
| h^FF   | 27 | 27 |  9,496 | 11,796 | 0.052 |

**Observations:**
- All four found 27-step plans; h^add and h^FF found optimal plans here
  despite being inadmissible (lucky on this instance, not a guarantee).
- Expansion reductions vs blind: h^max −13%, h^FF −45%, h^add −78%.
- h^add was fastest in wall-clock time because aggressive pruning more
  than compensated for per-node heuristic cost.
- h^max barely helped: the domain has many parallel paths so its
  critical-path estimate is loose.
- The plan uses both robots cooperatively and includes two recharges
  at the dock.

## Problem 3 (2 robots, 12 zones, 6 books, 4 categories, 2 docks)

| Heuristic | Plan length | Cost | Expanded | Evaluated | Time (s) |
|---|---|---|---|---|---|
| Blind  | 44 | 44 | 473,273 | 477,112 | 1.19 |
| h^max  | 44 | 44 | 447,251 | 459,664 | 2.30 |
| h^add  | **46** | **46** | 106,880 | 206,113 | 1.03 |
| h^FF   | 44 | 44 | 346,822 | 390,554 | 2.36 |

**Observations — the most interesting instance:**

- **h^add returned a sub-optimal plan (46 vs 44 steps).** This is the
  empirical demonstration of h^add's inadmissibility: by overestimating
  costs, A* committed early to a path that turned out not to be optimal.
  Problems 1 and 2 dodged this; Problem 3 did not.
- **h^max is *slower in wall-clock time* than blind** (2.30s vs 1.19s).
  Although it cut 26,000 expansions (~5%), the per-node cost of computing
  the delete-relaxation heuristic outweighed the saved search effort.
  This domain has too many parallel paths for the critical-path estimate
  to be informative enough.
- **h^add was fastest** (1.03s) but at the cost of optimality — classic
  time/quality tradeoff.
- **h^FF was also slower than blind in wall-clock terms**, for the same
  reason as h^max: heuristic computation overhead vs pruning benefit.
  However, h^FF preserved optimality where h^add did not.
- Two charging docks are both used in the plan; both robots cooperate.

## Summary

The theoretical informativeness ordering h^max ≤ h^+ ≤ h^FF ≤ h^add
manifests cleanly in expansion counts across all three problems.
However, **runtime is not monotonic in informativeness** — per-node
heuristic cost matters. Two findings stand out:

1. On Problem 3, **only Blind, h^max, and h^FF returned optimal plans**;
   h^add returned a 46-step plan vs the optimum of 44. This is the
   empirical signature of inadmissibility.
2. On Problem 3, **h^max and h^FF were both slower than Blind** in
   wall-clock time despite fewer expansions, because the domain
   structure (grid topology, many parallel paths) makes the
   delete-relaxation heuristics loose.

**Practical recommendation:** for our library reshelving domain,
h^add is the right choice when speed matters and ~5% suboptimality is
acceptable; h^FF when optimality is required and the domain is
moderate-sized; Blind itself is competitive for problems below
~500K states.
