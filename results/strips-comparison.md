# STRIPS PDDL: Heuristic Comparison

All runs use A* (`astar(<heuristic>())`) in Fast-Downward on a Linux laptop, default settings. Since every action has unit cost, plan cost is just plan length.

## Problem 1 (1 robot, 5 zones, 2 books, 2 categories, 1 dock)

| Heuristic | Plan length | Cost | Expanded | Evaluated | Time (s) |
|---|---|---|---|---|---|
| Blind  | 13 | 13 |  45 |  48 | 0.003 |
| h^max  | 13 | 13 |  37 |  43 | 0.002 |
| h^add  | 13 | 13 |  16 |  22 | 0.002 |
| h^FF   | 13 | 13 |  26 |  30 | 0.002 |

All four heuristics find the same 13-step optimal plan. Expansion counts follow the expected informativeness ordering (h^max ≤ h^+ ≤ h^FF ≤ h^add, more informative meaning fewer expansions), though at this scale the wall-clock times are too small to mean much.

## Problem 2 (2 robots, 8 zones, 4 books, 3 categories, 1 dock)

| Heuristic | Plan length | Cost | Expanded | Evaluated | Time (s) |
|---|---|---|---|---|---|
| Blind  | 27 | 27 | 17,355 | 17,764 | 0.052 |
| h^max  | 27 | 27 | 15,082 | 16,228 | 0.055 |
| h^add  | 27 | 27 |  3,893 |  8,296 | 0.034 |
| h^FF   | 27 | 27 |  9,496 | 11,796 | 0.052 |

All four land on the same 27-step plan, so h^add and h^FF happen to be optimal here too, though that's not guaranteed in general. Expansion counts drop a lot with the better heuristics: about 13% fewer than blind for h^max, 45% for h^FF, and 78% for h^add, and h^add also comes out fastest overall since the pruning outweighs its per-node cost. h^max barely helps here because the domain has a lot of parallel paths, which makes its critical-path estimate pretty loose. The plan itself has both robots working together with two dock recharges.

## Problem 3 (2 robots, 12 zones, 6 books, 4 categories, 2 docks)

| Heuristic | Plan length | Cost | Expanded | Evaluated | Time (s) |
|---|---|---|---|---|---|
| Blind  | 44 | 44 | 473,273 | 477,112 | 1.19 |
| h^max  | 44 | 44 | 447,251 | 459,664 | 2.30 |
| h^add  | 46 | 46 | 106,880 | 206,113 | 1.03 |
| h^FF   | 44 | 44 | 346,822 | 390,554 | 2.36 |

This is the interesting one. h^add returns a 46-step plan instead of the 44-step optimum that blind, h^max, and h^FF all find, a solid real example of h^add's inadmissibility (it overestimates costs, so A* locks onto a path early that turns out not to be optimal). h^max and h^FF are both slower than blind in wall-clock time even though they expand fewer nodes, since computing the delete-relaxation heuristic per node costs more here than it saves on this grid. h^add is still the fastest overall, just not optimal, a pretty clean time-versus-quality tradeoff. Both docks get used and both robots cooperate in the plan.

## Summary

Expansion counts follow the expected informativeness ordering everywhere, but runtime doesn't, since per-node heuristic cost matters just as much as how many nodes get pruned. For this domain: h^add if you want speed and can live with occasional suboptimality, h^FF if you need optimality and the problem isn't huge, and blind if you're staying under roughly 500K states.
