# Plan: show the turn-off list visually

**Status:** plan, with Python previews of 27 figure options. The paper's
figures aren't built yet.
**Scope:** Section 8 of `docs/working_paper.md` ("From many base stations to
one turn-off list") and the first half of Section 9 (the validation run).

## Goal

Section 8 explains the turn-off list in about 600 words, one table, and one
two-panel figure. A reader has to hold the method in their head while they
read. This plan offers several figure options for each step and recommends a
set of eight, so that a reader who looks only at the figures and their headlines
still gets the method right.

The figures must make three ideas visible, because these are the ideas
readers most often get wrong:

- **The order never changes.** Trials redraw the powers, but they never
  reorder the base stations.
- **Only one number varies from trial to trial:** the cut point.
- **The list is a percentile of the cut points,** plus one, and a second run
  then checks it with every other base station on.

## What exists today

| Item | What it shows | What it doesn't show |
| --- | --- | --- |
| Figure 8, left panel | Share of trials by list size, fixed order (bars) and free choice (line) | Where a list size comes from inside one trial |
| Figure 8, right panel | Histogram of the validation aggregate against the limit | Which base stations make up that aggregate |
| First-three-trials table | Six redrawn powers and the count turned off | The running total as base stations turn off |

Nothing shows the ranking step, a single trial worked through, or the fact
that every trial turns off the top of the same list.

## Design rules for every figure

These follow `CLAUDE.md` and the slide-design and dataviz-resources skills:

- The headline states the takeaway and its number. The number comes from the
  example's results struct, never typed by hand.
- Mid gray for context, light blue for the one highlight, purple only for the
  limit line or a failure. Label marks directly; no legends.
- One idea per figure. If a figure needs two headlines, split it.
- Same base station, same position and label in every figure (rank 1 to 6
  inside the radius, A to D outside it).
- Same power axis in every figure that shows dBm, so the figures can be
  compared by eye.
- 6.5 inches wide, 300 dpi, Times New Roman, text at least 8 pt at final
  size, `DRAFT//PRE-DECISIONAL` at the top right.
- Each figure gets alt text in the paper that states the chart type and the
  takeaway.

## Figure options

Each step has several options. Previews of all 27 are in
[`plan_previews/turn_off_list/`](plan_previews/turn_off_list/), drawn in
Python from the published example 07 run (the exact MATLAB draws, exported to
`toy_offsets_db.csv`), so every number in them matches the paper. They are
design previews: the chosen figures get rebuilt in MATLAB (Build plan). Four
contact sheets show them side by side:

- [Steps 1 and 2: ranking and one trial](plan_previews/turn_off_list/contact_sheet_1_rank_and_one_trial.png)
- [Many trials and the fixed order](plan_previews/turn_off_list/contact_sheet_2_trials_and_fixed_order.png)
- [Steps 3 and 4: the list size](plan_previews/turn_off_list/contact_sheet_3_list_size.png)
- [The check, the cost of the fixed order, and a summary](plan_previews/turn_off_list/contact_sheet_4_check_cost_summary.png)

The tables below give each option's takeaway, what it's good at, and its
risk. **Pick** marks the recommended option for the paper; **Also** marks a
strong second for slides or a backup figure.

### Step 1: the ranking

| ID | Form | Takeaway in the preview | Good at | Risk | Call |
| --- | --- | --- | --- | --- | --- |
| A1 | Sorted horizontal bars, inside in blue, outside in gray | The order is set once, strongest median first | Most accurate read of a ranking; shows who can't be on the list | Plain | **Pick** |
| A2 | Plan-view sketch: radar, circle, numbered dots | Six can go on the list; four outside can't | Ties "inside the radius" to a picture | Readers may read it as a map; needs "not to scale" | **Also** |
| A3 | Waffle of 100 squares by share of median power | Rank 1 alone delivers 39% of the total | Shows why the strongest go first | Linear power is new to some readers | |
| A4 | Share bars with a cumulative line | The first three carry 80% of the power | Links the ranking to the cut point of 3 | Two encodings in one chart | |

### Step 2: one trial, at the medians

| ID | Form | Takeaway in the preview | Good at | Risk | Call |
| --- | --- | --- | --- | --- | --- |
| B1 | Descending staircase against the limit | Turn off in order until under the limit: 3 at the medians | The algorithm drawn as a picture | Decibel steps shrink, which can look odd | **Pick** |
| B2 | Shrinking stacked bars, linear power | Remove blocks until the bar fits under the limit | Makes power addition visible; no decibel math | Femtowatts are an unfamiliar unit | **Also** |
| B3 | Waterfall, linear power | Each station turned off takes its share away | Familiar business chart | Hides that the order is the rule | |
| B4 | Storyboard: one row of tiles per step | One row per step, until the total meets the limit | Reads like the algorithm's steps; no axes | Takes vertical space | |

### Step 2 repeated: many trials

| ID | Form | Takeaway in the preview | Good at | Risk | Call |
| --- | --- | --- | --- | --- | --- |
| C1 | Small multiples: medians plus trials 1-3 | Same order every trial; only the cut point moves: 2, 4, and 5 | Direct comparison of shapes with the same axis labels | Only four trials | **Pick** |
| C2 | 60 staircases overlaid, medians highlighted | The crossing point spreads from 1 to 6 | Shows the spread in one picture | Busy; dots need explaining | **Also** |
| C3 | Strip plot of 1,000 draws for each rank | Powers vary, but the ranks are always taken in the same order | Explains why trials differ: rank 2 beats rank 1 in 38% of trials | Doesn't show the cut | |
| C4 | Heat map of 12 trials with the cut edge | The cut is always a straight edge from the left | Powers and cut together | Color encodes power, which is less accurate | |

### The fixed order, made visible

| ID | Form | Takeaway in the preview | Good at | Risk | Call |
| --- | --- | --- | --- | --- | --- |
| D1 | Two tile grids, fixed order and free choice | Every trial turns off the top of the same list; free choice scatters | The single clearest picture of the fixed order | Needs a sentence on what "free choice" means | **Pick** |
| D2 | Paired bars: share of trials each rank is off | Fixed order turns off rank 1 in 99.9% of trials; free choice, 80% | Simple bars; good for slides | Indirect | |
| D3 | Bars of the most common free-choice lists | Free choice gives 56 different lists; the fixed order gives 7 | Answers "why not let each trial choose?" with a number | Long labels | **Also** |

### Steps 3 and 4: from 1,000 cut points to one list size

| ID | Form | Takeaway in the preview | Good at | Risk | Call |
| --- | --- | --- | --- | --- | --- |
| E1 | Quantile dot plot, 100 dots of 10 trials | The 80th dot lands at 4; plus one, the list is 5 | A reader can count a percentile | Rounding of 1,000 trials into 100 dots needs a caption note | **Pick** |
| E2 | Histogram, bars up to 4 highlighted | 83.7% of trials need 4 or fewer | Familiar to engineers | Percentile isn't visible as a point | **Also** |
| E3 | Cumulative step curve with the 80% line | Read the list size off the curve | Exact percentile reading | Cumulative curves lose non-technical readers | |
| E4 | Running 80th percentile as trials accumulate | The list size settles at 4 after about 23 trials | Answers "are 1,000 trials enough?" | Answers a different question; better in Section 11 | Section 11 |

### The check (Section 9)

| ID | Form | Takeaway in the preview | Good at | Risk | Call |
| --- | --- | --- | --- | --- | --- |
| F1 | Exceedance curve with limit and 20% line | With 5 off, the total meets the limit in 89% of trials | Answers pass or fail directly | Exceedance curves need a sentence of explanation | **Pick** |
| F2 | Histogram, trials over the limit in purple | The 80th percentile is −100.1 dBm, under the limit | Familiar | Percentile and limit are two vertical lines, easy to confuse | |
| F3 | Who stays on, and their shares | Outside stations carry 59% of the median power in the check | Explains why the second simulation exists | Doesn't show pass or fail | **Also** |
| F4 | Two exceedance curves: all on and list applied | Turning off 5 moves the 80th percentile from −89.7 to −100.1 dBm | Shows what the list buys, 10.4 dB | Two curves to read | **Also** |
| F5 | One dot per trial, over the limit in purple | 89% fall under the limit | Every trial visible; no curve to learn | Vertical position is meaningless jitter | |

### What the fixed order costs

| ID | Form | Takeaway in the preview | Good at | Risk | Call |
| --- | --- | --- | --- | --- | --- |
| G1 | Back-to-back histograms, fixed order and free choice | One list for every trial costs about one more base station | Both distributions at once | Downward bars confuse some readers | **Pick** |
| G2 | Bars of extra stations per trial | In 49% of trials the fixed order costs nothing extra | Direct answer to "how much does it cost?" | Needs D1 first to make sense | **Also** |

### Summary

| ID | Form | Use |
| --- | --- | --- |
| H1 | Four small panels, one per step | Slides and read-aheads; the paper's section opener if there's room |

### Recommended set for the paper

Eight figures, in reading order: **A1, B1, C1, D1, E1, F3, F1, G1**. F3 comes
before F1 so the reader knows who is in the check before seeing its result.
The **Also** options go to a backup appendix or to slides.

If eight is too many for Section 8, the shortest set that still carries the
three ideas in the goal is **B1, D1, E1, F1**.

## How the section reads after the change

| Section 8 part | Today | After |
| --- | --- | --- |
| The method in four steps | Numbered list | Numbered list, each step pointing to its figure |
| Setup of the example | One paragraph | A1 plus two sentences |
| Medians and first three trials | Paragraph and table | B1 and C1 |
| Why the order is fixed | Three paragraphs | D1 plus one paragraph |
| List size | Figure 8, left | E1 |
| Cost of the fixed order | Paragraph | G1 and one paragraph |
| Validation (Section 9) | Figure 8, right, and a table | F3, F1, and the table |

The target is that the text shrinks. Where a figure says it, cut the
sentence.

## Build plan

1. **Return the per-trial powers.** Example 07 `_rev1` doesn't return the
   redrawn powers, and the paper cites it, so don't edit it. Add
   `example_07_turn_off_list_toy_rev2.m` that returns the inside and outside
   power matrices and the per-trial off masks for both orders. Keep the seed
   and settings, so every published number stays the same. Add a test that
   `_rev2` reproduces the `_rev1` summary exactly.
1. **Add the plot helpers to `src/`,** each with a test:
   - `plot_cut_point_staircase_rev1` (B1, C1, C2).
   - `plot_trial_tile_grid_rev1` (D1, F3).
   - `plot_quantile_dots_rev1` (E1).
   - `plot_exceedance_rev1` (F1, F4).
   Check built-ins first (`stairs`, `heatmap` or `imagesc`, `swarmchart`,
   `tiledlayout`) against `help` in the live session before writing custom
   drawing code.
1. **Add `example_08_turn_off_list_figures_rev1.m`.** It calls example 07
   `_rev2` once and writes one figure per chosen option, numbered from `fig09`. One run feeds every figure, so
   the figures can't disagree with each other.
1. **Build in this order:** B1, C1, D1 first. They carry the three ideas in
   the goal. Then E1, F3, F1, then A1, then G1, then H1 for slides. Match the
   previews' numbers exactly: `make_previews.py` asserts the same values
   the MATLAB tests check.
1. **Review each figure** before the next: render it, look at it in
   grayscale, and check for label overlap at final size.
1. **Rewrite Section 8 and the start of Section 9** around the figures.
   Renumber later figures. Retire the current Figure 8 from the paper but
   keep its file, because `_rev1` still writes it.
1. **Finish:** update `run_all_examples_rev1.m`, the tests, `README.md`,
   `CHANGELOG.md`, and `CLAUDE.md`; rebuild the Word file; run
   `buildtool check test`; push after CI passes.

## Checks

| Check | How |
| --- | --- |
| The fixed order holds in every trial | Test: every row of the fixed-order off mask is a run of ones followed by zeros |
| The staircase matches hand arithmetic | Test: at the medians, the aggregates are −94.0, −96.1, −98.4, −100.9, −103.9, −108.0 dBm and the cut point is 3 |
| Figures agree with the paper | Test: headline numbers come from the results struct; the paper's numbers match `turn_off_toy_summary.csv` |
| Dot counts are honest | Test: quantile dots sum to 100, and the highlighted count equals the percentile |
| A figure-only reader gets it right | Give the figures, without the text, to a fresh reviewer agent and ask it to state the method. Compare its answer with the four steps |
| Readable and accessible | Grayscale render, 8 pt minimum text, alt text present, no legend |

Human review still applies: the paper leaves the organization, so the
figures need Nick's review before anyone circulates them.

## Open questions

- **Which option for each step.** The tables above give a recommendation;
  any option can be swapped in.
- **How many figures Section 8 can hold:** the recommended eight, or the
  shortest four.
- **Where the Also options go:** a backup appendix in the paper, or slides
  only.

## Not planned

- Interactive pages. All figures are static.
