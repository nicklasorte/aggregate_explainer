# Plan: the turn-off list section

**DRAFT//PRE-DECISIONAL** · Plan for a new section of
[working_paper.md](working_paper.md) · 2026-11-17

## What the section must get across

A reader who finishes this section can say three sentences:

1. **The median sets the order.** Base stations are ranked once, by the power
   each delivers to the radar at the 50 % values of path loss and clutter
   loss. That ranking is the order in which stations are turned off.
1. **Monte Carlo sets the count.** Each Monte Carlo iteration redraws every
   station's power, then asks: going down the fixed ranking, how many stations
   must be off before the aggregate is under the radar's threshold? Each
   iteration returns one number, a list size.
1. **A percentile picks the final count.** With 1,000 iterations there are
   1,000 list sizes. Sort them and take the chosen percentile, for example the
   80th. The turn-off list is the top of the ranking down to that count.

The order never changes between iterations. Only the cut point moves.

## What the code does (traced)

Source: `part2_neigh_calc_rev19_mc_chunk_pop.m` and the functions it calls, in
[General_Movelist](https://github.com/nicklasorte/General_Movelist) (commit
read on 2026-11-17).

| Step | What happens | Where |
| --- | --- | --- |
| 0 | For one search distance, keep only base stations within that distance of the protection point. | `parfor_chunk_movelist_dual_man_azi_rev30_app`: `keep_idx=find(bs_distance<=single_search_dist)` |
| 1 | Find the 50 % column of the path loss and clutter tables. | `mid_idx=nearestpoint_app(app,50,move_list_reliability)` |
| 2 | Median received power per station: EIRP − median path loss − median clutter loss + base station azimuth gain. | `temp_pr_dbm=sim_array_list_bs(:,4)-mid_pathloss_dB-mid_clutter_loss+bs_azi_gain` |
| 3 | Rank the stations. `tf_opt=0`: sort median power, largest first. `tf_opt=1`: the near-optimal order, which also accounts for the radar antenna azimuths. | `sort(temp_pr_dbm,'descend')` or `near_opt_sort_idx_man_azi_rev6` |
| 4 | Reorder the full tables (all 47 percentages) into that ranking. | `sort_full_Pr_dBm`, `sort_clutter_loss` |
| 5 | For each iteration, draw three uniform numbers per station and interpolate path loss, EIRP offset, and clutter loss. Received power = path-loss-based power + EIRP offset − clutter loss. | `vector_mc_seed_pr_eirp_clutter_rev1` |
| 6 | Add the radar antenna gain for every radar azimuth, convert to watts, and sum over stations for each azimuth. Take the largest azimuth. | `subchunk_ml_man_azi_rev11`, `pre_sort_binary_movelist_rev3_multi_azi_app` |
| 7 | If the aggregate is over the threshold, binary-search the smallest *n* such that turning off ranks 1 to *n* brings every azimuth under the threshold. That *n* is this iteration's list size. If already under, *n* = 0. | `pre_sort_binary_movelist_rev3_multi_azi_app` |
| 8 | Collect *n* from every iteration (`array_turn_off_size`, `mc_size` values). | `parfor_randchunk_ml_rev1_mc_same` |
| 9 | Take the percentile and round up. | `turn_off_size95=ceil(prctile(sort(array_turn_off_size),mc_percentile))` |
| 10 | Add one station as margin, capped at the number of stations. | `conservative_turn_off=min(turn_off_size95+1,num_tx_full)` |
| 11 | The turn-off list is ranks 1 to that count. | `move_sort_sim_array_list_bs=sort_sim_array_list_bs(move_list_turn_off_idx,:)` |
| 12 | With the list applied, a separate Monte Carlo aggregate check confirms the remaining stations meet the threshold; the outer loop then binary-searches the neighborhood distance. | `agg_check_parfor_chunk_man_azi_rev10_app`, `calc_next_search_dist` |

Points to verify with Nick before writing, because the code leaves them open:

- **Variable name.** `turn_off_size95` holds whatever `mc_percentile` is (80 in
  rev25), not the 95th. The paper should use a neutral name.
- **Second threshold.** When a second threshold and percentile are set, the
  code takes the larger of the two counts. Include or leave out of the
  explainer?
- **Seeds.** Step 5 seeds the three draws with `rng(seed+k)`, `rng(seed+k+1)`,
  `rng(seed+k+2)`. `check_mc_seed_independence_rev1.m` in the same repository
  tests whether this reuses draws across iterations. The explainer code uses
  independent substreams. Decide whether the paper mentions this.

Decided (2026-11-17):

- **Ranking to teach.** Teach the simple descending sort by median received
  power (`tf_opt=0`). Then one paragraph on the near-optimal order
  (`tf_opt=1`), which production uses, and why it exists.
- **EIRP units.** dBm.

## Section outline

Working title: **From many links to one list: order by the median, size by
Monte Carlo**

1. **The question the list answers** (one paragraph). Which stations, and how
   many, must be off so the radar stays under its threshold?
1. **Step 1: rank once, at the median.** Worked table of 10 stations with
   median received power, sorted. Say plainly: this order is fixed.
1. **Step 2: one iteration.** Redraw all 10 stations. Show that the redrawn
   powers are no longer in sorted order, and that the list still follows the
   median ranking. Walk down the ranking until the aggregate is under the
   threshold. Result: one number.
1. **Step 3: repeat 1,000 times.** Each iteration gives its own number.
   Histogram of the 1,000 list sizes.
1. **Step 4: pick the percentile.** Sort the sizes; mark the 80th percentile;
   show the `ceil` and the plus-one margin. Plain-language reading: "In 80 %
   of the simulated conditions, turning off this many stations is enough."
1. **The near-optimal order, in one paragraph.** Production ranks stations
   with `near_opt_sort_idx_man_azi_rev6` instead of the plain sort, because
   the radar sees stations through its antenna pattern across azimuths, and a
   station that is strong at one azimuth may matter less than several weaker
   ones at the azimuth that sets the aggregate. The mechanics in this section
   don't change: one fixed order, a cut point per iteration, a percentile.
1. **Why order by the median and not per iteration?** A list has to be one
   list. If each iteration picked its own stations, the result would be 1,000
   different lists that can't be combined into an operating rule. Fixing the
   order makes the only random quantity a single number, which has a
   percentile.
1. **What the percentile does and doesn't promise.** It is a percentile of
   list size, not directly of aggregate interference. The aggregate check
   (step 12) is the separate confirmation.
1. **Radar-specific inputs** (short): threshold, antenna pattern, azimuth scan.
   Values from public or cleared sources only; `TODO` until Nick supplies them.

## Figures

| Figure | Shows | Reader takeaway |
| --- | --- | --- |
| A. Ranking bar chart | Median received power for a small set of stations, sorted, with rank labels. | The order comes from one deterministic calculation. |
| B. One iteration | Same stations in the same rank order; bars now the redrawn powers; a running aggregate line crossing the threshold; a vertical cut at *n*. | Powers move, the order doesn't, the cut point is the output. |
| C. Small multiples | Six iterations side by side with their cut points. | The cut point moves from iteration to iteration. |
| D. List-size distribution | Sorted list sizes for 1,000 iterations (the plot the production code already saves as `MoveList_*.png`), with the 80th percentile marked, plus a histogram. | One number per iteration; the percentile picks the final size. |
| E. Flow diagram | Inputs (three uniform draws per station) → received power → aggregate → binary search → list size → percentile → list. | The whole pipeline on one page. |

All figures carry `DRAFT//PRE-DECISIONAL` and are written by the example
function with `exportgraphics`.

## MATLAB to write

| File | Purpose |
| --- | --- |
| `src/turn_off_order_rev1.m` | Median received power and descending sort (steps 1 to 3, `tf_opt=0`). |
| `src/turn_off_size_one_iteration_rev1.m` | Given powers in rank order (stations by azimuths, watts) and a threshold, return the smallest *n*. Vectorized with `cumsum` from the bottom of the ranking; checked against a port of the production binary search. |
| `src/mc_turn_off_sizes_rev1.m` | Loop over iterations: draw, interpolate with `sim_grid_draws_rev1`, call the function above. Uses `RandStream` substreams, one per iteration. |
| `examples/example_04_turn_off_list_rev1.m` | Synthetic deployment around one radar point; builds figures A to D and a results CSV. |
| `tests/` additions | See checks. |

Synthetic scenario for the example (all values to confirm): a few hundred
stations placed at random within 100 km of one point, flat terrain so
`itm_p2p_rev1` needs no terrain download, clutter from
`p2108_terrestrial_clutter_loss_vector_rev2`, EIRP offsets from the Example 2
table, an omnidirectional radar antenna in the first pass. Threshold, median
EIRP, and heights are placeholders marked `TODO` until Nick provides the
2.7 GHz radar values.

## Checks before the section is written into the paper

- **Hand case.** Three stations, known powers, known threshold: list size by
  hand equals the function's answer.
- **Match production.** On identical inputs, `turn_off_size_one_iteration_rev1`
  returns the same *n* as `pre_sort_binary_movelist_rev3_multi_azi_app` for at
  least 1,000 random cases, including *n* = 0 and "turn everything off."
- **Monotonicity.** Turning off *n* + 1 stations never gives a higher aggregate
  than turning off *n*.
- **Percentile arithmetic.** `ceil(prctile(...))` on a known vector equals the
  hand-sorted value.
- **Reproducibility.** Same seed, same figure D; serial and `parfor` runs give
  identical list sizes.
- **Every number in the section** matches the example's CSV.
- **Human review.** Nick confirms the description matches how the production
  simulation is used, and supplies or approves the radar parameters.

## Ambition ladder

The base plan covers the three sentences. These rungs go further. Each is a
ready-to-paste request.

### Depth: do it the way a simulation methodologist would

Fits because the section makes claims about a statistical procedure, and
claims like that can be tested.

1. **Convergence.** "Rerun example 04 with 100, 300, 1,000, 3,000, and 10,000
   iterations and 20 seeds each. Plot the 80th-percentile list size against
   iteration count with its seed-to-seed range, and state how many iterations
   are needed for the list size to be stable to within one station."
   *Needs:* nothing new. *Check:* bootstrap confidence interval on the
   percentile agrees with the seed-to-seed spread.
1. **Does the median ordering cost anything?** "For each iteration, also
   compute the smallest list that iteration could have used if it were free to
   pick its own stations. Compare the two size distributions and report how
   many extra stations the fixed median order turns off at the 80th
   percentile." *Needs:* nothing new. *Check:* the per-iteration optimum is
   never larger than the fixed-order size.
1. **List-size percentile versus interference percentile.** "With the
   80th-percentile list applied, run the aggregate check and report at which
   percentile the remaining aggregate actually meets the threshold. Show
   whether an 80th-percentile list size delivers 80 % protection, more, or
   less, and why." *Needs:* nothing new. *Check:* independent seed for the
   aggregate check; compare with production `agg_check` on the same inputs.

### Altitude: aim at the decision the list serves

Fits because the percentile is a policy choice, and the section will be read
by people who make that choice.

1. **Percentile sensitivity.** "Add one figure: list size and the resulting
   protection level for percentiles 50, 80, 90, 95, and 99, so a reader can
   see what choosing 80 buys and costs." *Needs:* nothing new. *Check:* same
   as depth rung 3.
1. **Decision page.** "Draft a one-page summary for non-technical readers:
   what the percentile controls, the options, and the trade-off between
   stations turned off and protection, with arguments for and against each
   option." *Needs:* Nick's agreement on which options are real candidates.
   *Check:* human review; this is policy judgment.

### Range: borrow from other fields

Fits because the audience is not all engineers.

1. **Teaching design.** "Restructure the section as a worked example the
   reader can do on paper with five stations and a six-sided die, then show
   the computer doing the same thing 1,000 times." *Needs:* nothing new.
   *Check:* a non-engineer reads it and restates the three sentences.
1. **Red team.** "Have a separate reviewer write the strongest technical
   objection to ordering by the median, and answer it in the paper with the
   result of depth rung 2." *Needs:* depth rung 2 first. *Check:* independent
   agent review.

## Decision needed

Which rung runs first, after the base section: depth 1 (convergence), depth 2
(cost of the median ordering), or depth 3 (list-size percentile versus
protection)?
