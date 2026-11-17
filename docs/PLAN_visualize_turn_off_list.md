# Plan: show the turn-off list visually

**Status:** plan only. Nothing here is built yet.
**Scope:** Section 8 of `docs/working_paper.md` ("From many base stations to
one turn-off list") and the first half of Section 9 (the validation run).

## Goal

Section 8 explains the turn-off list in about 600 words, one table, and one
two-panel figure. A reader has to hold the method in their head while they
read. This plan replaces that with a sequence of six figures, one for each
step, so that a reader who looks only at the figures and their headlines
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

## The figure sequence

All numbers below come from example 07 as it runs today (seed 1, 1,000
trials). Headlines are drafts; the build fills in the numbers.

### Figure A: the setup and the ranking (step 1)

- **Draft headline:** "The order is set once, by median power: strongest
  first."
- **Form:** two panels.
  - Left: a schematic plan view. One radar at the center, a circle for the
    candidate radius, six numbered dots inside and four lettered dots
    outside. It is a sketch, not a map; say so in the caption.
  - Right: a sorted horizontal bar chart of median received power, rank 1
    (−98 dBm) at the top to rank 6 (−108 dBm), with the four outside base
    stations below a gap, in a lighter gray.
- **Why this form:** a sorted bar is the most accurate way to show a ranking,
  and the plan view ties "inside the radius" to something a reader can
  picture.
- **Proves:** which base stations can go on the list, and in what order.

### Figure B: one trial, step by step (step 2)

- **Draft headline:** "Turn base stations off in order until the total drops
  under the limit: three at the medians."
- **Form:** a descending staircase. The x-axis is the number of base stations
  turned off (0 to 6). The y-axis is the aggregate from the rest, in dBm.
  A purple horizontal line marks the −99 dBm limit. The first step below the
  line is highlighted in light blue and labeled "cut point: 3."
- **Numbers at the medians:** −94.0, −96.1, −98.4, −100.9, −103.9, −108.0 dBm
  for 0 to 5 off. The staircase crosses the limit between 2 and 3.
- **Why this form:** it is the algorithm drawn as a picture. Each step down
  is one base station turned off.
- **Proves:** what "walk down the list until the limit is met" means.

### Figure C: the same staircase in different trials (step 2, repeated)

- **Draft headline:** "Same order in every trial; only the cut point moves:
  2, 4, and 5 in the first three trials."
- **Form:** small multiples. Four panels in a row with a shared y-axis: the
  medians (cut point 3), then trials 1, 2, and 3 (cut points 2, 4, and 5).
  Each panel is the Figure B staircase with that trial's redrawn powers. The
  x-axis labels are the same six rank numbers in the same order in every
  panel.
- **Why this form:** small multiples let the reader compare shape while the
  axis labels show that the order didn't change.
- **Proves:** a trial with a strong draw at rank 2 stops early; a trial where
  ranks 1 and 2 draw low still turns them off first and stops late.
- **Replaces:** the first-three-trials table, which moves to the results CSV.

### Figure D: every trial at once (the fixed order, made visible)

- **Draft headline:** "Every trial turns off the top of the same list."
- **Form:** two tile grids side by side with the same layout. Rows are trials
  (a fixed sample of 60, sorted by cut point). Columns are ranks 1 to 6. A
  filled tile means that base station is off in that trial.
  - Left, fixed order: every row is filled from the left with no gaps, so the
    grid forms a clean staircase edge.
  - Right, free choice: each trial turns off its own strongest draws, so the
    filled tiles scatter across the columns.
- **Why this form:** it is the direct picture of the idea that is hardest to
  put in words. The left grid has no holes; the right grid can't be turned
  into one list.
- **Proves:** why the order is fixed, and what a per-trial order would
  produce instead.
- **Check before building:** confirm that 60 rows are readable at 6.5 inches.
  If not, use 40.

### Figure E: from 1,000 cut points to one list size (steps 3 and 4)

- **Draft headline:** "80% of trials need four or fewer off; with the margin
  of one, the list is five."
- **Form:** a quantile dot plot. One hundred dots, each standing for 10
  trials, stacked by cut point (0 to 6). The 80 dots at or below the 80th
  percentile are light blue; the 20 above it are gray. An arrow labeled
  "+1 margin" runs from 4 to 5. Under the axis, the six ranks appear as a
  strip with the first five filled: the list itself.
- **Why this form:** counting dots makes a percentile concrete in a way a
  histogram doesn't. A reader can see 80 of 100.
- **Proves:** how the percentile turns a spread of cut points into one
  number, and that the list is the top of the Figure A ranking.
- **Replaces:** the left panel of the current Figure 8.
- **Rounding rule:** 1,000 trials into 100 dots needs largest-remainder
  rounding so the dots sum to 100. State the rule in the caption.

### Figure F: the check (Section 9)

- **Draft headline:** "With five off, the total stays under the limit in 89%
  of trials: the radius passes."
- **Form:** two panels.
  - Left: a strip of ten tiles in the Figure A order. Five are marked off;
    rank 6 and outside base stations A to D stay on, in a darker gray. This
    shows who is in the second simulation.
  - Right: an exceedance curve of the validation aggregate, with the limit as
    a vertical purple line, the 80th percentile (−100.1 dBm) marked, and the
    1.1 dB gap to the limit labeled.
- **Why this form:** an exceedance curve answers "how often is the limit
  exceeded" directly, which is the pass or fail question.
- **Proves:** the second simulation adds back the base stations outside the
  radius, and pass or fail is one comparison at one percentile.
- **Replaces:** the right panel of the current Figure 8.

### Optional Figure G: what the fixed order costs

- **Draft headline:** "One list for every trial costs about one more base
  station than a list for each trial."
- **Form:** two rows of the Figure E dot plot on one axis, fixed order above
  and free choice below, with the two 80th percentiles (4 and 3) and the two
  means (3.34 and 2.64) marked.
- **Decision:** build it only if Figure D doesn't already make the point. The
  paragraph in Section 8 can carry the numbers without a figure.

### One-page summary for briefings

A single page that places small versions of Figures A, B, D, E, and F left to
right under the four step names, with one arrow between each. It is for
slides and read-aheads, not for the paper. Build it last, from the same
results, so it can't drift from the paper.

## How the section reads after the change

| Section 8 part | Today | After |
| --- | --- | --- |
| The method in four steps | Numbered list | Numbered list, each step pointing to its figure |
| Setup of the example | One paragraph | Figure A plus two sentences |
| Medians and first three trials | Paragraph and table | Figures B and C |
| Why the order is fixed | Three paragraphs | Figure D plus one paragraph |
| List size | Figure 8, left | Figure E |
| Cost of the fixed order | Paragraph | Paragraph, with optional Figure G |
| Validation (Section 9) | Figure 8, right, and a table | Figure F and the table |

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
   - `plot_cut_point_staircase_rev1` (Figures B and C).
   - `plot_trial_tile_grid_rev1` (Figures D and F, left).
   - `plot_quantile_dots_rev1` (Figures E and G).
   Check built-ins first (`stairs`, `heatmap` or `imagesc`, `swarmchart`,
   `tiledlayout`) against `help` in the live session before writing custom
   drawing code.
1. **Add `example_08_turn_off_list_figures_rev1.m`.** It calls example 07
   `_rev2` once and writes `fig09` to `fig14`. One run feeds every figure, so
   the figures can't disagree with each other.
1. **Build in this order:** B, C, D first. They carry the three ideas in the
   goal. Then E and F, then A, then G if needed, then the summary page.
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

- **Dots or bars for Figure E.** The dot plot is clearer for a first-time
  reader; bars are more familiar to engineers. The plan picks dots. Say if
  you prefer bars.
- **How many figures Section 8 can hold.** Six figures in one section is a
  lot for a Word document. An alternative is to combine B and C, and E and
  F, for four figures.
- **Units label.** The figures use dBm with "per megahertz" in the subhead,
  as the rest of the paper does.

## Later, if wanted

- **An animated version for the README and for slides:** the Figure B
  staircase replayed over 20 trials, with the cut point moving and the dot
  plot of Figure E filling in. Word can't show it, so it would live beside
  the paper, not in it.
- **An interactive page:** sliders for the percentile, the spread, and the
  limit, redrawing Figures B, E, and F. It would let a reviewer test "what if
  the percentile were 95" without running MATLAB.
