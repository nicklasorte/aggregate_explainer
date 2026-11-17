# Review B: working paper "How an aggregate interference Monte Carlo simulation works"

**DRAFT//PRE-DECISIONAL** · Reviewer B (independent) · Paper at commit `d6cd603` · 2026-11-17

## Summary

The arithmetic holds up. I recomputed every number in the paper that can be
recomputed, and all but three match the CSV files or an independent Python
calculation to within rounding. The three that don't:

- "Holding EIRP ... fixed narrows it by only 3 dB or less." The actual
  narrowing is 3.7 dB.
- The second flat spot in the spline is placed in the wrong decile.
- "No difference at 2 km and beyond." The actual difference is up to 0.05 dB.

The larger problems are about interpretation. They matter most for the
policy audience.

1. **What the output percentiles mean.** The received-power distribution
   mixes time (ITM), locations (P.2108), and EIRP states, and the source of
   the EIRP percentiles isn't documented. The paper still calls the 99th
   percentile what one base station causes "1% of the time."
2. **Independence is assumed, not argued.** No section states it as an
   assumption or justifies it. Section 6 states it as fact ("Because the
   three inputs are independent"). The "worst cases don't stack" and
   "spreads add as variances" lessons depend entirely on it. Independent
   ITM time draws for each base station, which the production code also
   uses, become a substantive assumption once Section 8 adds stations
   together.
3. **The production description leaves out material behavior.** The
   production code:
   - seeds its three draws with `seed+k`, `seed+k+1`, and `seed+k+2`, so
     the uniform vectors repeat across iterations at lags 1 and 2;
   - uses a median EIRP of 50.5 dBm/10 MHz, but the paper adds the
     table's absolute dBm with no bandwidth;
   - applies clutter only to urban and suburban stations;
   - applies a horizontal antenna pattern to the base station.
4. **Section 7 generalizes beyond its evidence.** "Effort ... should follow
   the variance" rests on one flat, 100 km troposcatter path, and it treats
   random spread as if it were model error.
5. **Stated assumptions are missing where a reader needs them.** The paper
   never says which end of the path gets clutter, never says the base
   station is assumed to point at the receiver, and never gives the
   bandwidth of the EIRP.

## Findings

| ID | Severity | Location | Finding | Evidence | Suggested fix |
| --- | --- | --- | --- | --- | --- |
| B-01 | blocker | §7, finding 1, last sentence | "Holding EIRP or clutter loss fixed narrows it by only 3 dB or less" is false for EIRP. | `single_bs_100km_spread.csv`: 5–95% range 33.63 (all vary), 29.97 (EIRP held) → 3.66 dB. Clutter: 2.62 dB. | "...by 3.7 dB (EIRP) and 2.6 dB (clutter loss)." |
| B-02 | major | §7, finding 3, last sentence | "A worst-case stack overstates the interference that one base station causes 1% of the time by about 15 dB" misstates what the percentile means. The 99th percentile of P_rx is taken over time × locations × EIRP states together. It isn't a time percentage. Clutter location is a fixed property of a site, so for one real base station most of the clutter spread doesn't vary with time. | §5 table itself labels the inputs "Time", "Locations", "Operating states". `single_bs_inputs_rev1.m` mixes them in one sum. | Say "in 1% of trials (combinations of time, location, and EIRP state)". Add one paragraph in §6 on how to read a mixed percentile, and on what changes if the location is fixed. |
| B-03 | major | §7, finding 3 | "Worst-case stack" is the wrong name. It stacks 1% tails, not worst cases: the truncated EIRP maximum is 42.5 dBm, and the production grid goes to 0.001%. Comparing it with the 99th percentile of the sum compares an event with joint probability about 10⁻⁶ (under independence) with a 10⁻² event. The percentile directions are right (99th EIRP, 1st path loss, 1st clutter loss). | `example_05_spread_rev1.m`: `eirp_q(99) - path_q(1) - clutter_q(1)` = 41.52 − 174.38 − 19.97 = −152.82 dBm (recomputed). | Rename it "1%-each stack". State that its joint probability under independence is about 1 in a million. Optionally report the percentile of the sum that −152.8 dBm falls at. |
| B-04 | major | §6 "Exact convolution" bullet; §1; §3–§5 | Independence of the three inputs is stated as fact ("Because the three inputs are independent"), never as an assumption, and never justified. Plausible dependencies: EIRP (traffic load) and the atmosphere both follow time of day; clutter and EIRP both depend on the site. §7's "worst cases don't stack" and "spreads add as variances" depend entirely on independence. | §6 text; no section states independence as an assumption. | Add an "Assumptions" box in §1 or §6: independence across inputs, and what correlation would do (it widens the tails and moves the stack toward the sum). |
| B-05 | major | §1, para 1; §8 (planned) | Independent ITM time draws for each base station in one iteration mean that no iteration represents a single moment. At any moment the atmosphere is largely common to all paths in a region (ducting and refractivity), so independent draws average out across stations and understate the aggregate tails. The paper doesn't flag this. The production code does the same thing. | `vector_mc_seed_pr_eirp_clutter_rev1.m`: `rand_pr_all(:,k)=rand(num_bs,1)...` gives each station an independent reliability. | State it as a modeling choice in §1 and §4. Plan to treat it in §8 (for example, a sensitivity case with one shared time draw for each iteration). |
| B-06 | major | §1 "draws three independent numbers"; Purpose; §2 "the way the production simulation does" | The production code seeds iteration k with `rng(seed+k)`, `rng(seed+k+1)`, and `rng(seed+k+2)`. The EIRP vector at k is therefore bit-identical to the path-loss vector at k+1, and the clutter vector at k matches the path-loss vector at k+2. Draws are independent within an iteration but not across iterations. The paper's description omits this, though CLAUDE.md forbids the pattern and GM ships a checker for it. | `/home/claude/dl/gm/vector_mc_seed_pr_eirp_clutter_rev1.m` lines 24–31; `/home/claude/dl/gm/check_mc_seed_independence_rev1.m` header. | Add a "Differences from the production code" note. Each iteration's marginal distribution is still correct, but iterations are serially dependent, which matters for the "80th of 1,000" step in §8. |
| B-07 | major | §3 "Values are in dBm"; §6 table and Fig. 4; §3 "Only the shape ... matters" | The paper says production uses only the offset added to a fixed median, yet §6 uses the table's absolute level (median 31.68 dBm) with no bandwidth. Production uses `bs_eirp=50.5` dBm/10 MHz. The −194 dBm received power is therefore not the production level (about 19 dB off), and no reader can compare it with a threshold. | `init_sim_folder_FSS_neigh_rev25_fdr_github.m` line 157 (`bs_eirp=50.5; %EIRP [dBm/10MHz]`) and lines 461–465 (normalize to the 50th). | Give the reference bandwidth. Either use median 50.5 dBm/10 MHz (or a 2.7 GHz value, marked TODO) plus the fitted offset, or label §6 received power as "relative to an illustrative EIRP". |
| B-08 | major | §3 "Where the table comes from"; §5 "Operating states" | What a CTIA percentile ranges over (time at one station, many stations, measurement bins) isn't documented. Calling it "operating states" and saying it "reflects how the measured base stations actually operated" is unsupported. If the percentiles pool many stations, part of the spread is a fixed per-station property, and redrawing it every trial misstates time behavior. | `data/SOURCES.md` says only "empirical measurements of base stations in the field". | State what is known. Mark the percentile basis TODO, and say what treating it as a per-trial draw assumes. |
| B-09 | major | §7, finding 4 | "Effort on the inputs should follow the variance ... A better path loss model ... changes the answer far more than refining the EIRP table or the clutter model" is unsupported. Variance share measures random spread for one flat 100 km troposcatter path. It says nothing about bias or model error, such as the EIRP level and bandwidth (B-07), the 7→2.7 GHz transfer, or whether clutter applies at a 30 m antenna (B-12). On shorter line-of-sight paths ITM time variability is small and the ranking can flip. The paper's own confidence table shows a 7.1 dB median shift from one parameter choice. | `single_bs_100km_variance_share.csv` covers one geometry only. §4 confidence table. | Limit the claim to "for this path". Separate "spread" from "error". Or delete the finding until it's backed by several distances and terrain types. |
| B-10 | major | §7, finding 2; §8 | For the planned aggregate, the dB spread is not only uncertainty. It raises mean linear power. For a normal distribution in dB, the mean in watts exceeds the median by σ²·ln10/20, which is 12 dB at σ = 10.2 dB. The "spreads ... partly cancel" framing may lead a policy reader to think spread is benign. | Recomputed: σ = 10.24 dB → +12.1 dB; σ = 8.2 → +7.7 dB. | Add a sentence in §7 or §8 noting that powers add in watts, so a wider spread raises the aggregate. |
| B-11 | major | §4 "The model"; §4 notice 1 | The validity of ITM time variability for this use isn't stated. ITM time variability describes hourly medians over a long period (about a year), with no within-hour fading and no explicit ducting. The tails (below 1% and above 99%) are extrapolations, and the code switches off ITM's tail cautions (`validity="off"`) while 2% of draws fall there. Interference studies often use P.452 for small time percentages. "Time variability of path loss is the largest random term" holds for this model and path only. | `examples/example_03_itm_flat_100km_2700mhz_rev1.m` comment on `validity "off"`; `itm_p2p_rev1.m` help text (caution for "a reliability far in a tail"). | Add 2–3 sentences: what ITM time percentage covers, the validity range, and the tail handling. Qualify notice 1 ("in ITM, on this path"). |
| B-12 | major | §6 "The calculation"; §2 | The paper never says which end of the path gets clutter, and never justifies P.2108-1 §3.2 (a terminal *within* clutter) for a 30 m base station antenna, which often sits above local clutter. The code applies clutter at the base station end only (`single_bs_inputs_rev1.m` help). Production applies clutter only to urban and suburban stations (`tf_clutter=3`, stations tagged by height 20/25/35 m), and none to rural. Fig. 1's subhead says "at one end", but the text doesn't. | `src/single_bs_inputs_rev1.m` help; `init_sim_...rev25` lines 169 and 413–419. | In §6 say "clutter at the base station end only; none at the radar". Note the rural exclusion and the applicability question. |
| B-13 | major | §3 "The input"; §6 | The paper doesn't state that the base station is assumed to point at the receiver. The 0°-azimuth, 0°-elevation table is boresight. Production applies the same offset distribution at every azimuth plus a horizontal antenna pattern (80° beamwidth, 40 dB floor), so off-boresight stations get up to 40 dB less. | `init_sim_...rev25` lines 395–401 (1-sector branch), 421–427 (`horizontal_antenna_loss_mod2_app`), 503–512. | State "base station pointed at the receiver (worst azimuth)" in §6, and that production adds an antenna pattern. |
| B-14 | major | Purpose; §8 | The paper doesn't say that the production run is a 7250 MHz FSS case with FDR (`tf_fdr=1`), I/N −10.5 dB, mc_size 1,000, mc_percentile 80, and morphology heights 20/25/35 m, against the explainer's 30 m. Engineers checking the method can't tell what was changed for the recast. | `init_sim_...rev25` lines 150–171, 413–419. | Add a short table: production setting, explainer setting, why. |
| B-15 | minor | §1 steps 1–2; §2 "Simulation grid" | Production doesn't draw u on (0, 1) and multiply by 100. It draws a percentage uniformly on [0.001, 99.999], the ends of the grid, and interpolates. When `rel_min==rel_max`, all three inputs are fixed at that percentage. | `vector_mc_seed...rev1.m` lines 12–16 and 25; `sim_grid_draws_rev1.m` mirrors it. | One sentence in §1 or §2. |
| B-16 | minor | §3 "A spline through the points" | "Flattest between the 30th and 40th and between the 60th and 70th" is wrong for the second peak. The not-a-knot spline's slope minima are at 32.1% (29.4 dBm) and 59.3% (32.7 dBm). The table steps 50→60 and 60→70 are both 1.0 dB. | Python `CubicSpline(bc='not-a-knot')`, same as MATLAB `spline`. | "...near the 32nd and 59th percentiles (about 29.4 and 32.7 dBm)." |
| B-17 | minor | §2 "Equation (6)" bullet | "At 2 km and beyond, there is no difference" is slightly false. The rev1 clamp gives L(2 km), while `min(L(d), L(2 km))` differs by up to 0.05 dB for d > 2 km. "Largest difference found is 2.0 dB (1.6 GHz, 0.5 km, p = 99.9)": that point gives 1.98 dB. A finer search gives 2.00 dB at 0.72 GHz, 0.375 km. | Python reimplementation of (3a)–(6); grid 0.5–67 GHz, 0.25–100 km. | "Negligible (≤0.05 dB) at 2 km and beyond". "About 2 dB at most (for example...)". |
| B-18 | minor | §5 table, path loss span | 39.2 dB should be 39.1 dB: 213.5256 − 174.3767 = 39.149. It was computed from rounded values. | `itm_flat_100km_2700mhz.csv`. | 39.1. |
| B-19 | minor | §4 notice 1 | The comparison mixes measures: path loss and clutter use the 1–99% span (39, 19 dB), but EIRP uses its full 0–100% range (23 dB). On the same basis EIRP is 20.4 dB. | §3 text and §5 table. | Use 20 dB for EIRP. |
| B-20 | minor | §3 fit table; Fig. 2 | The misfit is systematic in the interference-relevant tail. The fit is 0.69 dB *low* at the 90th percentile, and the table's upper tail is heavier than the normal (+6.75/+10.75 dB above the median against −6.5/−12.25 dB below). The paper reports only magnitude. Headline "EIRP is close to a bell curve" presents the fitted shape as a finding about EIRP. | `bs_eirp_distribution.csv` `residual_db` at 90 = −0.685. | Note the sign. Retitle "A bell curve fits the CTIA table to within 0.7 dB". |
| B-21 | minor | §3 "A normal distribution in dB ... many small effects multiplied together" | The justification is unsupported. Beam steering and load aren't many small multiplicative effects, and the fit is empirical. | None given. | Drop the causal clause, or call the choice empirical. |
| B-22 | minor | §4 "reference attenuation adds 58.97 dB" | A reader who adds 141.08 + 58.97 = 200.05 gets a number that doesn't match the 197.13 dB median, and the 2.9 dB gap (ITM's median time-variability adjustment for climate 5) isn't explained. 58.97, the horizons, and "troposcatter" come from console output, not a CSV. I recomputed free space (141.08) and the horizons (22.6, 13.0 km from N_s = 301), and they match. I couldn't recompute A_ref. | `example_03...rev1.m` prints `info.A_ref_db`, which isn't saved. | Explain the gap in one clause, or drop A_ref. Write `info` fields to a CSV. |
| B-23 | minor | §1 equation | The equation has "+ G_antennas", but EIRP already includes the base station antenna gain, so only receive gain belongs there. §6 drops the term without comment. "Adds the three values in dB" (§6 step 3) should say "adds EIRP and subtracts the two losses". | §1, §6. | Use $G_\mathrm{rx}$ and define it. Fix the step 3 wording. |
| B-24 | minor | §7, finding 2 | The math is correct: for independent terms, variances add (output σ 10.24 dB against root-sum-square 10.26 dB). But "Spreads add as variances, not as decibels" is muddled, because σ is itself in dB. "Partly cancel each other's extremes" is informal. The rule holds for σ, not for percentile ranges in general. Here the root-sum-square of the 1–99% spans is 47.9 dB against 48.2 dB actual, close only by coincidence of shape. The rule also rests on independence (B-04). | CSV std values; recomputed. | "Standard deviations combine as the square root of the sum of squares, not by simple addition, when the inputs are independent." |
| B-25 | minor | §3 "The production simulation can take either one" | Unverified. Production reads the xlsx from row 3 with fixed columns, and its all-azimuth CSV uses `0th%` headers. `export_eirp_percentile_table` writes `p000`–`p100`. The layouts are similar, not identical. | `init_sim_...rev25` lines 444–450 and 354–359; imt-matlab README. | "...could feed the same step after a format conversion." |
| B-26 | minor | §2 "The model" | "It is the current version of the Recommendation" needs an as-of date. ITU-R working parties have open contributions on P.2108. | The ITU-R P.2108 page and WP3K/3M documents appear in search; I didn't confirm whether there's a newer version. | "Current as of <date>". |
| B-27 | minor | §2 "passes all seven NTIA test vectors" | The test compares against values hand-transcribed to 0.1 dB with a 0.05 dB tolerance. One vector (67 GHz, 5.4 km, 30.5%) computes to 30.950 against 30.9, right at the tolerance. The NTIA CSV isn't in the repo (the `ref/p2108/extern/test-data` submodule is empty). The NTIA code also uses the Abramowitz & Stegun approximation for Q⁻¹, where rev2 uses the exact `erfcinv`. | `tests/test_aggregate_explainer_rev1.m` lines 19–33; NTIA `InverseComplementaryCumulativeDistribution.cpp`. | Say "to 0.1 dB". Pull the full-precision vectors. |
| B-28 | minor | Fig. 4 | The label "95th: −176.6" is crossed by the 99th-percentile dotted line ("−1│76.6"). The top-row panels have no y-axis label. The x-axis "dBm" has no bandwidth (see B-07). | Fig. 4 PNG. | Move the 95th label left of its line, or shorten it. Add the bandwidth. |
| B-29 | minor | Fig. 5 | The diamond's value (−152.8 dBm) isn't printed. In grayscale the highlighted light-blue bar (luminance about 116) and the mid-gray bars (about 141) are hard to tell apart. The caption says "worst-case stack" (see B-03). | Palette `5674C4` against `8A8D91`. | Label the value. Darken the highlight, or add a pattern. Rename. |
| B-30 | minor | Figs. 1–3 captions | The captions describe the panels but not what to look at. The circles (model percentiles 1, 5, 10, 25, 50, 75, 90, 95, 99, or table points) aren't explained in the Fig. 1 and Fig. 3 captions. Fig. 3 shows a shoulder near 193 dB in the density that the text doesn't explain. | PNGs. | Add one "look at" sentence to each caption, and explain the circles. |
| B-31 | minor | §4 "Sweeping the reliability from 0 to 100" | ITM requires 0 < reliability < 100, and the figure curve spans 0.1–99.9. | `itm_p2p_rev1.m` help. | "from just above 0 to just below 100". |
| B-32 | note | §2 worked example | "L_s is 12 dB above L_l, so the L_l term controls the result: at 2 km the loss is at its ceiling" joins two separate facts. The ceiling holds by definition of (6) at 2 km. The dominance of L_l explains why σ_cb ≈ σ_l = 4. | Recomputed: L_l 29.30, L_s 41.47, σ_cb 4.01, median 29.29. | Split into two sentences. |
| B-33 | note | §6 | Heights of 30 m (TX) and 10 m (RX, "radar") aren't justified in the text. Radar antennas are often higher. Results at 100 km on flat terrain are sensitive to both. | `single_bs_inputs_rev1.m` defaults. | Mark them as illustrative (TODO for radar height). |
| B-34 | note | §3 "Assumption to confirm" (7 GHz table at 2.7 GHz) | This is stated well in §3, but §6 and §7, where it drives the numbers, don't repeat it. | §6, §7. | One-line reminder in §6. |

## Numbers check (all others)

These match a CSV cell or my recomputation, to rounding:

- **§2:** 29.30, 41.47, 4.01, 29.29. The 7-row table. 0.1 dB and 0.02 dB agreement. 43.4 and 42.8 dB.
- **§3:** Table offsets. Fit μ 31.74, σ 5.04, truncated median 31.68, SD 4.67 (scipy `truncnorm` fit reproduces them). Residual table. RMS 0.35. 1st and 99th percentiles 21.1 and 41.5 dBm. 20.4 dB span. Spline effect at most 0.4 dB (actual maximum 0.32 dB, at the 1st percentile).
- **§4:** Table. 22.8 and 16.4 dB. Confidence table. 7.1 dB.
- **§5:** 18.7 and 20.4 dB.
- **§6:** Table. Agreement within 0.1 dB (maximum 0.08). Sum of medians −194.74 dBm.
- **§7:** 48.2. The table. 64/21/15% (shares sum to 100.4% because of sample covariance). 8.20, 4.66, 4.02. 16.9. 10.24 and 10.26. −152.8, −168.3, 15.4.

## Answers to the specific questions

1. **Is it valid to treat the ITM time percentage as a uniform random draw for one base station at one moment?** Yes for one link at a randomly chosen hour. That's inverse-transform sampling of ITM's long-term (hourly-median) time distribution. Three conditions apply:
   - It excludes within-hour fading.
   - It relies on extrapolated tails below 1% and above 99%, with cautions turned off.
   - It holds for each link on its own, not jointly across links: drawing an independent time for every station in the same iteration isn't physical (B-05, B-11).
2. **Does the worst-case stack comparison in Section 7 use the right percentiles?** The directions are right (99th EIRP, 1st path loss, 1st clutter loss). The label "worst case" and the reading "1% of the time" are wrong (B-02, B-03).
3. **Is the "Spreads add as variances" statement correct?** Yes for standard deviations of independent terms, and the numbers confirm it (10.24 against 10.26 dB). The wording is loose, and the claim inherits the independence assumption (B-24, B-04).
4. **Does the paper's description of the production simulation match the production code?** It matches on the 47-point grid from 0.001 to 99.999, linear interpolation for path loss and clutter, the spline for EIRP, normalization of EIRP to the median, confidence 50, and three draws for each station in each iteration. It doesn't match on:
   - seed reuse across iterations (B-06);
   - draws taken directly on [0.001, 99.999] (B-15);
   - absolute EIRP and bandwidth (B-07);
   - clutter for urban and suburban only (B-12);
   - the base station antenna pattern and azimuth (B-13);
   - 7250 MHz, FDR, and heights (B-14).

## Reader test: one sentence for each section

- **Purpose:** The paper explains one production Monte Carlo, recast for 2.7 GHz and a radar. Easy.
- **§1:** Each random input is a uniform draw read off an inverse CDF. Easy, and the best section.
- **§2:** At 2 km, P.2108 clutter loss is a normal distribution with a 29.3 dB median and a 4.0 dB SD. The "check" subsection is for engineers only; consider an appendix.
- **§3:** EIRP comes from an 11-point CTIA table, smoothed with a fitted normal. The imt-matlab digression and the offset-versus-absolute question (B-07) blur the point.
- **§4:** ITM path loss on this path varies 39 dB over time, and confidence is a second knob. "Reference attenuation" and "confidence" are hard for a policy reader.
- **§5:** The three inputs share one mechanism but differ in meaning and width. Easy, and the "meaning" column needs to carry into §6 and §7 (B-02).
- **§6:** One station's received power spans 48 dB. This is hard: a reader can't tell whether −168 dBm matters, because there's no threshold or bandwidth.
- **§7:** Path loss drives the spread, and 1% tails don't coincide. Clear, but the policy takeaways are overstated (B-02, B-03, B-09).
- **§8:** Planned work only.

## What I checked and how

- I read `docs/working_paper.md` in full, all 7 CSVs in `docs/results/`, and examples 02–05 with their `src/` helpers: `fit_eirp_truncated_normal_rev1`, `single_bs_inputs_rev1`, `sum_of_independent_db_rev1`, `sim_reliability_grid_rev1`, `sim_grid_draws_rev1`, `figure_palette_rev1`, and the P.2108 rev2 header. I also read `data/SOURCES.md` and the repo tests for the NTIA vectors.
- I matched each number to a CSV cell. For numbers not in a CSV, I reimplemented the calculation in Python (numpy and scipy):
  - P.2108-1 Equations (3a)–(6), the Equation (6) clamp against `min`, and a grid search over frequency, distance, and p;
  - the truncated-normal EIRP fit (Nelder-Mead on the interior percentiles), its percentiles and moments;
  - the not-a-knot spline flat spots;
  - free-space loss and smooth-earth horizons with N_s = 301;
  - the 1%-each stack, the root-sum-square, and the mean-versus-median shift of a normal distribution in dB.

  I couldn't run ITM (no MATLAB or Octave), so I didn't verify A_ref = 58.97.
- I traced production: `init_sim_folder_FSS_neigh_rev25_fdr_github.m` (settings, EIRP normalization, clutter flag, antenna pattern, heights), then `neighborhood_wrapper_rev23_ue_grid.m`, then `subchunk_ml_man_azi_rev11.m`, then `vector_mc_seed_pr_eirp_clutter_rev1.m` and its helpers `monte_carlo_Pr_dBm_rev2_app`, `monte_carlo_super_bs_eirp_dist_rev5`, `monte_carlo_clutter_rev3_app`, and `check_mc_seed_independence_rev1`. `part1_calc_pathloss_clutter2108_dist_max64_rev14` isn't in the download, so I couldn't verify production's ITM climate, ground, and mdvar settings or its clutter computation.
- I read `itm_p2p_rev1.m` (defaults, validity, CR mode), NTIA P.2108 `TerrestrialStatisticalModel.cpp` and its inverse-Q code, and the imt-matlab README (user sampler, export format, what's excluded).
- I viewed all 5 PNGs for marking, axes, units, overlap, and headline-to-number agreement, and computed the grayscale luminance of the palette.
- I didn't modify any repository file.
