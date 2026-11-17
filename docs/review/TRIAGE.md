# Review triage

**DRAFT//PRE-DECISIONAL** · 2026-11-17 · Reviews of commit `d6cd603`

Two independent reviewers that didn't write the code or the paper produced
[code_review.md](code_review.md) (22 findings, no blockers) and
[paper_review.md](paper_review.md) (34 findings, one blocker). This file
records what was done with each finding. Nick's decisions are still needed on
the deferred items.

## Fixed

| Finding | What changed |
| --- | --- |
| B-01 (blocker) | Section 7 now gives the correct narrowing: 3.7 dB (EIRP) and 2.6 dB (clutter loss). |
| A-01 | The paper and code no longer call the spline's two peaks artificial. They follow the table's uneven steps; the table is too coarse to confirm them. |
| A-02, B-20 | The paper states that the fit's upper tail is lighter than the table's (95th percentile 7.7 dB above the median against 8.6 dB), and that this needs a recheck in the aggregate. Figure 3's headline now says the fit matches the table within 0.7 dB. |
| B-02, B-03, B-29 | "Worst-case stack" is now "1%-each stack", with its one-in-a-million joint probability. The paper explains that a percentile of trials isn't a percentage of time. Figure 7 labels the stack's value. |
| B-04, B-12, B-13, B-33, B-34 | Section 6 lists its assumptions: independent inputs, clutter at the base station end only, base station pointed at the receiver, illustrative EIRP level and geometry. |
| B-06, B-07, B-14, B-15, A-07, A-20 | New Section 8 lists the differences from the production simulation, including the seeding pattern, the EIRP level, clutter for urban and suburban stations only, and the antenna pattern. |
| B-09, B-10 | The "effort should follow the variance" finding is limited to this path and separated from model error. The paper notes that a wide spread in dB raises the mean power in watts. |
| B-11, B-31, A-15 | Section 4 says what ITM's time variability covers and that percentages below 1% and above 99% are extrapolations. |
| B-16 to B-19, B-21 to B-27 | Wording and number corrections (spline flat spots, Equation (6) difference, 39.1 dB, 20 dB, receive gain in the equation, standard deviation rule, test vector precision, as-of date). |
| B-28 | Figure 6: the 95th percentile label no longer crosses the 99th percentile line. |

## Deferred, with a reason

| Finding | Reason |
| --- | --- |
| B-05 (shared atmosphere across base stations) | Belongs in the planned aggregate sections: add a sensitivity case with one time draw shared by all stations in a trial. |
| B-08 (what the CTIA percentiles range over) | Fixed: Section 3 now describes the CTIA heatmap method (60 cells, five 15-minute periods). Which CTIA dataset the workbook comes from is still TODO. |
| B-30 (figure captions say what to look at) | Fold into the next figure pass. |
| A-04, A-05 (convolution check 0.005 dB low; loose tolerance) | Negligible for the paper; tighten with the next test pass. |
| A-06, A-08, A-09, A-10 (test gaps: seeding pattern, column-to-input mapping, grid values, same-seed tests) | Add in the next test pass; the mutation-testing rung in the plan covers them. |
| A-11, A-12 (0 dB below 0.25 km; `Inf` distance accepted) | A project convention kept from the source function. Decide with Nick whether to raise an error instead. |
| A-17, A-18 (example 05 heights; reader error identifier) | Minor; next code pass. |
| B-32 (worked example wording) | Minor; next style pass. |

## Style pass

The Google developer documentation style pass ran on the paper after the
fixes: percent signs without a space, complete sentences before lists, units
repeated in ranges, EIRP defined at first use, descriptive link text, and
bold reserved for run-in headings. Numbered section headings, standards
designations, units, and the marking stay as domain conventions.
