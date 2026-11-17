# Plan: explain the aggregate zones method better

**DRAFT//PRE-DECISIONAL** · 2026-11-17

This repository exists to help readers of the 2.7 GHz aggregate zones working
paper understand its method. Reviewers of that paper left 130 comments. This
plan uses their technical questions to decide what the explainer must teach.

The review comments are pre-decisional and are not in this repository. This
plan carries only the question themes, reworded, with no sources. The sorted
comment list is kept with the working paper.

## What the questions say

Of the 130 comments, 81 are editorial (grammar, acronyms, capitalization,
footnotes, formatting). The other 49 are technical. They fall into 12 groups:

| Group | Technical comments | The question, in plain words |
| --- | --- | --- |
| G. Receiver noise | 9 | What are the terms and units of the noise equation, and which bandwidth and temperature does it assume? |
| H. Protection criteria and time | 8 | What do "long term" and "short term" mean for a radar, where do the thresholds come from, and how is a percentage of time computed and compared? |
| I. Turn-off list and the 50th percentile | 7 | Where exactly is the 50th percentile used? Is the removal order fixed, or does it change with every Monte Carlo trial? What does "greedy" mean? |
| A. Monte Carlo basics | 5 | Which inputs are random, what distributions do they use, what comes out, how many trials run, and can each step have an example? |
| C. Path loss (ITM) | 5 | What do reliability and confidence mean, what is confidence set to, and what are the model's equations and ground inputs? |
| L. Model versions | 3 | Which versions of the cited Recommendations apply? |
| B. EIRP distribution | 2 | Where does the EIRP distribution come from, and should it be scaled to the maximum authorized power? |
| D. Clutter loss | 2 | Is clutter loss assigned or calculated, what is random in it, and when does it apply? |
| E. Polarization loss | 2 | Does the 3 dB apply to dual-polarized receivers and at long range? |
| F. System loss and frequency-dependent rejection | 2 | Can these be applied after the sum, or must they be applied to each base station? |
| J. Two Monte Carlo simulations | 2 | Why are there two, how do they connect, and could one do both jobs? |
| K. Zone shape | 2 | How does a turn-off list become a zone, and why a circle and not a polygon? |

Three findings stand out:

- **The readers' largest gap is the algorithm, not the physics.** Groups I,
  J, K, and A (16 comments) ask how the simulation turns random draws into a
  list and a zone. Two reviewers independently read the removal order as
  changing in every trial; another asked whether it is fixed in advance. The
  paper's text supports both readings.
- **"Percentage" means four different things.** Reviewers ask about the
  percentage of time in the protection criteria, the 50th percentile in the
  ordering, the Monte Carlo percentile that sizes the list, and the uniform
  percentile that feeds each model. The working paper uses one word for all
  four.
- **Many questions ask for a worked example.** One comment asks for an example
  at every step. Most of the others would not have been asked if a small
  numeric example had been on the page.

## What the explainer covers now

| Group | Covered by | Status |
| --- | --- | --- |
| A. Monte Carlo basics | Section 1 (uniform draws, why, rules, number of trials), Examples 1 to 4 | Mostly covered. Missing: one page that lists every random input and every output of the full simulation. |
| B. EIRP distribution | Section 3 (source, fit, modeled alternative) | Covered for shape. Missing: the absolute level and a maximum-power sensitivity case. |
| C. Path loss | Section 4 (reliability, confidence table, distance sweep) | Covered. Missing: a plain-language definition of confidence, and ground constants. |
| D. Clutter loss | Section 2, Section 6 assumptions | Covered. Missing: when clutter doesn't apply. |
| I. Turn-off list | Planned ([turn-off list plan](PLAN_turn_off_list_section.md)) | Not written. Highest priority. |
| J. Two Monte Carlo simulations | Not planned yet | Gap. |
| K. Zone shape | Not planned yet | Gap. |
| H. Protection criteria and time | Section 7 (percentile of trials is not percentage of time) | Gap: the comparison against two criteria. |
| E, F, G, L | None | Gaps. Small, mostly definitions and one sensitivity figure each. |

## Plan

The work is ordered by how many questions each piece answers.

### 1. Write the algorithm sections first (groups I, J, K: 11 comments)

1. **Turn-off list section**, as already planned: order once by the median,
   let each trial pick a cut point, take a percentile of the cut points. Add
   three things the comments call for:
   - A sentence that settles the reading: "The order is fixed before the
     Monte Carlo trials start. A trial never reorders the list."
   - The reason for the 50th percentile, in one line: the median is the single
     most typical value of each input, so it gives one ranking that isn't tied
     to any one trial.
   - A footnote-length definition of "greedy": remove the largest contributor
     first, then the next, and stop when the limit is met.
1. **Two simulations, two questions.** A new section with one diagram:
   - Simulation 1 asks "how many base stations inside this radius must be
     off?" and outputs the turn-off list.
   - Simulation 2 asks "with that list applied, and everything outside the
     radius still on, does the aggregate meet the criterion often enough?" and
     outputs pass or fail for the radius.
   - Then answer the single-simulation proposal with a small experiment: run
     both designs on the same synthetic deployment and compare the radius.
1. **From a list to a zone.** A new section: the search over candidate radii,
   what "pass" means, why the result is a radius around the federal site, and
   what a polygon would change. One map-style figure on synthetic data.

### 2. One page on the four percentages (groups H and A: 13 comments)

A single table and figure that separate:

| Percentage | What it ranges over | Where it is used |
| --- | --- | --- |
| Uniform draw | Nothing physical; a random number | Input to every model |
| Model percentage | Time (ITM), locations (P.2108), operating states (EIRP) | Reading each model's curve |
| 50th percentile | The same, fixed at the median | Ordering the turn-off list |
| Monte Carlo percentile | Trials | Sizing the list; pass or fail |
| Protection criterion percentage | Time that interference may exceed a level | The requirement being met |

Then show, with the single-base-station example, how one set of trials is
compared against two criteria (a higher level allowed for a small percentage,
a lower level for a large percentage).

### 3. A "what is random, what is fixed" page (group A: 5 comments)

One table for the whole simulation: every input, whether it is random or
fixed, its distribution, its source, and the example that shows it. One list
of outputs: the turn-off list, the pass or fail result, the zone radius. One
line on how many trials run and how the count is checked (the sampling-error
rule in Section 1, plus a convergence figure).

### 4. Short definition boxes with one figure each (groups C, D, E, F, G, B, L: 25 comments)

| Topic | Content | Figure |
| --- | --- | --- |
| Receiver noise | Each term of the noise equation with units; −174 dBm/Hz against −114 dBm/MHz; what 290 K assumes | Stacked bar: thermal floor + bandwidth + noise figure |
| System loss and frequency-dependent rejection | When a common value can move outside the sum, shown with arithmetic; when it can't | Two-row example with equal and unequal offsets |
| Polarization loss | What the 3 dB assumes; single against dual polarization | Sensitivity: result with 0 dB and 3 dB |
| ITM confidence | Plain-language definition; the existing reliability-by-confidence table | Existing table, plus one line on the 7 dB shift |
| ITM ground constants | Sensitivity of the 100 km example to permittivity and conductivity | One small table |
| Clutter loss | "Calculated from a random location percentage", and when it is not applied | Existing Figure 2 |
| EIRP level | Shape against level; a maximum-authorized-power case as a sensitivity | Shifted distribution |
| Model versions | A table of each Recommendation, the version used, and the date checked | None |

### 5. One running example through every step (the "example at each step" comment)

Use one small synthetic deployment (about 20 base stations around one radar
site) and carry the same numbers through every section: inputs, one trial,
the ordering, one trial's cut point, the distribution of cut points, the
percentile, the validation run, the radius search. Each section shows the
state of the same 20 stations.

### 6. Hand the wording back to the working paper

For each group, draft the two or three sentences that the working paper
needs so that the question doesn't come up again, and a pointer to the
explainer section for readers who want more. Nick decides what goes into
the working paper.

## Checks

- Each of the 49 technical comments maps to a section, a definition box, or
  a recorded decision not to address it. The map lives with the comment list,
  not here.
- Every new number comes from an example's CSV.
- A fresh reviewer agent, given only the explainer, answers each group's
  question. A wrong or missing answer sends the section back.
- Nick confirms that the algorithm sections match how the production
  simulation is run.

## Ambition ladder

### Depth: settle the questions with experiments, not prose

This dimension fits because several comments propose a different method, and
a small experiment answers a proposal better than an argument.

1. **Fixed order against per-trial order.** "On the 20-station example and a
   200-station synthetic deployment, compute the turn-off list size with the
   fixed median order and with a fresh order in every trial. Report the
   difference in list size and in the passing radius."
   *Needs:* the turn-off list code. *Check:* the per-trial optimum is never
   larger than the fixed-order size.
1. **One simulation against two.** "Implement the single-simulation design
   that a reviewer proposed, run it beside the two-simulation design on the
   same deployments, and report where the radius differs and why."
   *Needs:* rung 1. *Check:* both designs give the same answer when no
   station inside the radius is turned off.
1. **Shared atmosphere.** "Rerun the aggregate with one time draw shared by
   all base stations in a trial, and report the change in the tail of the
   aggregate." *Needs:* the aggregate code. *Check:* the single-station
   distribution is unchanged.

### Altitude: aim at fewer comments on the next revision

This dimension fits because the goal is not a better explainer; it is a
working paper that reviewers understand.

1. **Comment-to-fix matrix.** "For each of the 49 technical comments, draft
   the proposed disposition (accept, accept with change, explain) and the
   exact replacement text for the working paper." *Needs:* Nick's review;
   this is policy judgment. *Check:* a second reviewer agent reads the revised
   text and tries to re-raise each comment.
1. **Pre-brief.** "Build a 10-minute read-ahead that walks the 20-station
   example from inputs to zone, for the reviewers who commented."
   *Needs:* sections 1 to 3 of this plan. *Check:* Nick's read.

### Range: borrow from teaching and from adversaries

This dimension fits because the same questions came from several groups with
different backgrounds.

1. **Three reader trials.** "Give the explainer to three fresh agents that
   read as a radar engineer, a wireless engineer, and a policy analyst. Each
   answers the 12 group questions from the explainer alone." *Needs:* nothing
   new. *Check:* a human from each background spot-checks the answers.
1. **Hand calculation.** "Add a one-page version of the turn-off list that a
   reader can do with five stations and a six-sided die."
   *Needs:* nothing new. *Check:* the hand result matches the code.

## Decisions needed

1. Does the order of work (algorithm sections, then the four percentages,
   then the definition boxes) match what matters most to you?
1. Which depth rung runs first: fixed order against per-trial order, or one
   simulation against two?
1. Should the explainer take on the maximum-authorized-power EIRP case, or
   leave it to the working paper?
