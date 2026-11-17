# Code review A: aggregate_explainer at d6cd603

Reviewer A (independent). Scope: `src/`, `examples/`, `tests/`, `buildfile.m`,
`setup_aggregate_explainer_rev1.m`, `run_all_examples_rev1.m`. No repository file
was modified. Scratch work is in `/home/claude/review/scratch/`.

## Summary

- **The P.2108 model is correct.** `p2108_terrestrial_clutter_loss_vector_rev2`
  matches the NTIA/ITS C++, which I compiled and ran over 320 cases. The largest
  difference is 0.0026 dB. It comes from NTIA's Abramowitz and Stegun
  approximation of Q^-1; the repository uses the exact `erfcinv`. Every constant
  matches (3a) to (6). The P.2108 tests are strong: every mutation I tried was
  caught except the 0.25 km threshold moving down.
- **The EIRP fit reproduces** (mu 31.736, sigma 5.042, one global optimum from
  780 starting points). But the reason the code gives for it is not supported.
  The table itself has a density dip at 40 to 50 %, so the "two artificial peaks"
  are in the data, not added by the spline. The fit also lowers the upper tail:
  the 95th percentile offset is 7.66 dB, against 8.63 dB from the table spline
  that production uses.
- **Inverse-transform sampling is correct** for all three inputs. The three
  columns in example 04 are independent (mrg32k3a substreams). Results are
  reproducible from the seed.
- **ITM with validity "off":** 169 of 100,000 draws in example 03 (0.17 %) fall
  in ITM's "far in the tail" band (|z| > 3.10, which is p < 0.097 % or
  p > 99.903 %). So do 4 of the 47 grid points. No other ITM flag fires.
- **The convolution check** has a systematic bias of -h/2 (-0.005 dB). It's
  negligible, but the tests can't detect it.
- **Test gaps:** the independence test can't detect the seed+k pattern that
  CLAUDE.md forbids. The sum tests can't detect a one-bin shift. The 47-point grid
  values aren't pinned. Only example 01 has a reproducibility test.
- **Fit to production:** I list 12 differences (A-20). Main ones: the draw range,
  linear interpolation on the grid, the global-RNG seed+k seeding, the fitted
  normal EIRP, clutter applied to every base station, and absolute EIRP.
  Production's seeding reuses the same uniform sequence at lags 0, 1, and 2
  across Monte Carlo iterations. The explainer's help text understates this as
  "can correlate".

MATLAB check: I ran the two `src` test files in MATLAB R2025b on the user's Mac.
That working tree is byte-identical to this one for every in-scope file (md5
checked); 48 of 48 tests passed. I also ran the ITM and edge-case checks there.
After that the device stopped responding, so I ran the mutation tests and the
EIRP and convolution checks as Python ports (`scratch/*.py`). These ports pass
every P.2108 test assertion unmutated. An interrupted call may have left a
scratch copy at `tempdir/aggx_mut` on the Mac. It is outside the repository and
safe to delete.

Note: the working tree is ahead of d6cd603. It has an untracked
`examples/example_00_uniform_input_rev1.m` and modified `run_all_examples_rev1.m`
and `tests/test_examples_rev1.m` (someone else's work in progress). I reviewed
the committed versions. A-21 covers example 00 briefly.

## Findings

| ID | Severity | Location | Finding | Evidence | Suggested fix |
| --- | --- | --- | --- | --- | --- |
| A-01 | major | `examples/example_02_bs_eirp_distribution_rev2.m:22-24`; `src/fit_eirp_truncated_normal_rev1.m:22-25`; `tests/test_examples_rev1.m:87-94` | The claim that the spline "puts two artificial peaks in the density" is not supported. The table's own decile widths give mean densities of 0.100, 0.067, and 0.100 per dB for 30-40 %, 40-50 %, and 50-60 %, so the dip at 40-50 % is in the CTIA data (or its 0.25 dB rounding). Linear interpolation shows the same dip. The test at line 93 locks in the claim. | `python3`: decile widths 1.00, 1.50, 1.00 dB (table values 29.25, 30.25, 31.75, 32.75). | Reword: the fit smooths a dip that is in the table. Say whether the dip is real or comes from rounding, and drop "artificial". |
| A-02 | major | `src/fit_eirp_truncated_normal_rev1.m:43-47`; `src/single_bs_inputs_rev1.m:54` | The fitted normal is narrower than the table in the upper tail, which is the tail that drives interference. Fit vs the table spline (which production uses), as offsets from the median: 95th 7.66 vs 8.63 dB, 99th 9.84 vs 10.32 dB, standard deviation 4.67 vs 4.89 dB. Table 90th is 38.5 dBm; the fit gives 37.81 (residual -0.69 dB). In example 04 this moves the received-power 95th percentile only 0.15 dB, because path loss dominates. In an aggregate of many base stations the effect is larger and non-conservative. No test checks the tail. | `scratch/eirp.py` (400,000 draws); `docs/results/single_bs_100km_2700mhz.csv` rows 95 and 99. | Keep the spline (or pchip) as the default for production parity. Present the fit as a smoothing option and state the tail change. Or weight the fit toward the upper percentiles. Add a test on the 90th and 95th percentile offsets. |
| A-03 | note | `src/fit_eirp_truncated_normal_rev1.m` | Values confirmed: mu 31.7362, sigma 5.0419, median 31.6807, standard deviation 4.6703, rms residual 0.353, largest residual 0.685. Nelder-Mead from 780 starts finds one optimum. The fitted median is 0.07 dB below the table's 31.75; production normalizes to the table's 50th percentile. | `scratch/eirp.py` | None. Optionally say in the help text that the fitted median is not the table median. |
| A-04 | minor | `src/sum_of_independent_db_rev1.m:40,46-47` | CDF bias of -h/2. Each point is rounded to a bin center, and `cdf(k)` includes that bin's mass, so reading quantiles at bin centers biases them low by h/2 (-0.005 dB at the default h). The midpoint grid of n = 2e4 truncates each term at 0.0025 % and 99.9975 %, which is fine for the 1st to 99th percentiles. | Python port, three normals: errors -0.0044 to -0.0056 dB at h = 0.01, -0.05 at h = 0.1, -0.25 at h = 0.5. | Return `x_grid + h/2` as the CDF abscissa (the upper bin edge). Or document the bias in the help text. |
| A-05 | minor | `tests/test_src_extra_rev1.m:319-338` | The sum tests can't detect a one-bin shift (tolerance 0.02 dB vs h = 0.01; 0.002 dB vs h = 0.001) or a round-to-floor mutation (shift -0.015 dB). | `scratch/conv.py`: the +1-bin mutant gives a median error of 0.005 dB, which passes. | Tighten to h/4, or test against an exact discrete case (two uniforms give a triangular distribution). |
| A-06 | minor | `tests/test_src_extra_rev1.m:302-308` | The independence test can't detect the forbidden pattern. Building column k from `RandStream("mrg32k3a", Seed=seed+k)` passes it: the correlation stays below 0.02, and a "shifted by one row" copy never occurs with either generator. The production defect is reuse across iterations, not a row shift (see A-20, item 3). | Code reading. With mrg32k3a, different seeds don't produce shifted copies. | Pin the structure: check that `u(:,k)` equals `rand(RandStream("mrg32k3a",Seed=s,Substream=k)...)`, or pin a few known values. |
| A-07 | minor | `src/draw_uniform_columns_rev1.m:11-13` | The help text says seed, seed+1, seed+2 "can correlate the inputs". In production, with `rng(seed+mc_iter+j)`, the EIRP draws at iteration k are bit-identical to the path-loss draws at iteration k+1, and clutter at k equals path loss at k+2. The draws are one sequence read at three lags, not a weak correlation. | `General_Movelist/vector_mc_seed_pr_eirp_clutter_rev1.m:25-32`; `check_mc_seed_independence_rev1.m` (the author's own check). | State the exact lag-reuse mechanism. |
| A-08 | minor | `tests/test_examples_rev1.m:168-174` | `test_example04_inputs_independent` checks `corr(out.u)`. That tests `draw_uniform_columns_rev1` again, not that example 04 sends a different column to each input. A mutant that uses `u(:,1)` for path loss is still caught, but only through `test_example04` (convolution difference > 0.6 dB; by estimate the standard deviation of E - L drops from 9.4 to about 3.5 dB). | Code reading and a normal-approximation estimate. | Check `corr(out.eirp_dbm, out.path_db)` and the other pairs instead. |
| A-09 | minor | `tests/test_src_extra_rev1.m:161-167` | The 47-point grid values aren't pinned. Changing any interior value (for example 99.5 to 99.6) passes. I confirmed the grid equals production line 162 exactly. | Python comparison against `init_sim_folder_FSS_neigh_rev25_fdr_github.m:162`. | Compare the whole vector to a literal. |
| A-10 | minor | `tests/test_examples_rev1.m:63-68` | Only example 01 has a same-seed reproducibility test. Examples 02 to 05 are deterministic by construction (no global RNG, deterministic `fminsearch`), but that isn't tested. | Code reading; `grep rng\|rand(` finds no global-generator use in `src/` or `examples/`. | Add one same-seed check for example 04 (u, P_rx) and one different-seed check. |
| A-11 | minor | `src/p2108_terrestrial_clutter_loss_vector_rev2.m:38-39,59,70` | Returning 0 dB below 0.25 km is a step of about 20 dB: at 2.7 GHz, p = 50, the loss is 19.86 dB at 0.25 km and 0 just below. NTIA returns error code 49 instead (test vector 10, 0.24, 50). The 0 is conservative for interference (more power reaches the receiver) and never applies in examples 01 to 05 (d = 2 and 100 km). Lowering the threshold (0.25 to 0.2) is not caught by any test, because the test only probes 0.249. | MATLAB: `p2108_...([],2700,0.25,50)` gives 19.857. Python mutation run. | Keep it, but say in the help text that it is conservative and discontinuous. Offer an error or clamp-to-0.25 option. Add a probe at 0.2 km. |
| A-12 | minor | `src/p2108_terrestrial_clutter_loss_vector_rev2.m:51` | `dist_km = Inf` is accepted and silently returns the 2 km value (29.29 dB). `NaN`, a negative distance, `p = 0`, `p = 100`, and `p = NaN` are rejected. `p = []` with a scalar distance returns an empty 1-by-0 without error. | MATLAB R2025b runs. | Add `mustBeFinite` to `dist_km`, and `mustBeNonempty` to `p`. |
| A-13 | note | `src/p2108_terrestrial_clutter_loss_vector_rev2.m:64` | The exact `erfcinv` vs NTIA's A&S 26.2.23 approximation: largest difference 0.0026 dB over the sweep (f 0.5 to 67 GHz, d 0.25 to 100 km, p 0.001 to 99.999). The help text claims exactness against NTIA only at the 0.1 dB vector level, so this is fine. For p → 0 the loss goes negative (p = 1e-12 gives -1.38 dB at 2 km). That is the equation's behavior and isn't reachable with `rand` at 1e5 draws (the smallest p is about 0.001 %, which gives about 12 dB). | NTIA C++ compiled (`scratch/drv.cpp`, `scratch/cmp.py`); MATLAB. | Note the A&S difference in the help text. Optionally state the negative-loss limit. |
| A-14 | minor | `tests/test_aggregate_explainer_rev1.m:19-33` | NTIA vectors are rounded to 0.1 dB but checked at `AbsTol` 0.05, the rounding half-width. A correct result that lands right at a rounding boundary could fail by floating-point noise. All 7 pass now with a margin of at least 0.03 dB. The error-code vectors (rows 8 to 12) aren't exercised, and row 10 (d = 0.24) deliberately differs. | Python port against the CSV. | Use `AbsTol` 0.05 + eps, or compare to the compiled NTIA values to 0.003 dB. Add a comment on rows 8 to 12. |
| A-15 | note | `examples/example_03_itm_flat_100km_2700mhz_rev1.m:55-57`; `src/single_bs_inputs_rev1.m:55-56` | Answer to question 7a: yes. With seed 1968, 169 of 100,000 draws (0.17 %) set ITM's 0x2000 flag ("far in the tail", \|z_T\| > 3.10). The flagged draws span 0.0051 % to 0.0967 % and 99.903 % to 99.9999 %. Grid points 0.001, 0.01, 99.99, and 99.999 are flagged too. Distance (100 km), heights, and frequency raise no flags (the only warning values are 0 and 8192). The comment's "many of the draws" overstates it. The reported 1st to 99th percentiles are unaffected. | MATLAB: `itm_p2p_rev1(30,10,pfl,2700,100*u,validity="off")` and `info.warnings`; threshold at `matlab_itm/private/itm_p2p_core.m:752`. | Say "about 0.2 % of draws (p < 0.1 % or > 99.9 %)". Report the count in the example output. |
| A-16 | minor | `examples/example_0[1-5]_*.m` (`exportgraphics` lines 88, 77, 114, 91, 88) | Figures are written at `Resolution=300`, but CLAUDE.md says 200 dpi. | grep | Use 200, or update CLAUDE.md. |
| A-17 | minor | `examples/example_05_spread_rev1.m:18,31` | Says "the same draws as example 04", but calls `single_bs_inputs_rev1` without example 04's `h_tx_m`/`h_rx_m` options. Same only at the defaults. | Code reading. | Add the height options and pass them through. |
| A-18 | minor | `src/read_bs_eirp_distribution_rev1.m:47,59-62` | Doesn't fail loudly with an identifier when the Azimuth or Elevation row is missing (`values{[]}` makes `struct` throw a generic error), or when a percentile cell is `<missing>` (`cell2mat` throws first). | Code reading. | Check `any(is_azi)` and `any(is_ele)` and the cell types, and raise `aggregate_explainer:EirpTable`. |
| A-19 | note | `src/sim_grid_draws_rev1.m`; `examples/example_0[124]` | The production stand-ins are faithful. `sim_grid_draws_rev1` (linear `interp1`) is the same as `monte_carlo_Pr_dBm_rev2_app` and `monte_carlo_clutter_rev3_app` (nearest previous and next, then linear). The single spline on the 11-point table differs from production's triple spline (table, then 0:1:100, then normalize to the 50th, then the 47-point grid, then a spline at the draw) by at most 0.002 dB in the quantiles. | `scratch/eirp.py` (rows "single spline" and "prod triple spline"). | None. You can say so in the paper. |
| A-20 | note | Fit to production (question 6) | Differences between explainer and production draws: (1) **Range:** the explainer uses 100u on (0, 100); production maps u to 0.001 + 99.998u and clips to the grid. (2) **Path loss and clutter:** the explainer evaluates the model exactly at p; production interpolates linearly on the 47-point grid. Examples 01 and 03 quantify this in the `sim_grid_db` column (≤ 0.13 dB at the 1st to 99th percentiles). (3) **Seeding:** the explainer uses mrg32k3a substreams in a private stream; production uses the global `rng(seed+k)`, `rng(seed+k+1)`, `rng(seed+k+2)` (default Mersenne Twister), so the draws are one sequence at lags 0, 1, and 2 across iterations (A-07). (4) **EIRP:** the explainer uses a fitted truncated normal; production uses the spline (A-02). (5) **EIRP level:** the explainer uses absolute dBm from the CTIA table (median 31.68); production uses only the shape relative to the 50th percentile, plus a fixed `bs_eirp` = 50.5 dBm/10 MHz minus reductions. (6) **Clutter population:** production `tf_clutter=3` ("Distribution and Just Urban and Suburban") applies clutter only to urban and suburban base stations (column 7, clutter index); the explainer applies it to every base station. (7) **Clutter end:** production keeps one clutter table per base station (one end), which matches the explainer. I couldn't confirm which end, because the function that builds the table (`part1_calc_pathloss_clutter2108_dist_max64_rev14`) isn't in the provided repositories. (8) **Equation (6):** production uses the rev1 distance clamp; identical for d ≥ 2 km, so example 04 is unaffected; differs at high p for d < 2 km. (9) **Frequency:** production 7250 MHz; explainer 2700 MHz (by design). (10) **Antennas and FDR:** production adds the AAS azimuth pattern, radar antenna gain, and FDR; the explainer uses 0 dBi and co-channel. (11) **Draws per run:** production `mc_size` = 1000 at the 80th percentile; explainer 1e5. (12) **ITM settings:** the explainer uses `itm_p2p_rev1` defaults (climate 5, mdvar 13, confidence 50); production confidence is 50, and its other settings aren't visible in the provided code. | `General_Movelist/vector_mc_seed_pr_eirp_clutter_rev1.m:9-45`; `monte_carlo_*`; `FSS_Neighborhood/init_sim_folder_FSS_neigh_rev25_fdr_github.m:157-169, 411-418, 444-472`. | Add a "Differences from production" table to the paper. Include item 3 as a known production issue. |
| A-21 | minor | `examples/example_00_uniform_input_rev1.m:46-48,70` (uncommitted) | Outside d6cd603; listed for awareness. The first and last slice widths come from the sample minimum and maximum (14.0 and 12.3 dB in the CSV), so they depend on n and the seed: the true widths are unbounded. It writes at 300 dpi (A-16). | `docs/results/uniform_input_slices.csv` | Report the tail slices as open-ended, or use the 0.1st and 99.9th percentiles with a label. |
| A-22 | note | `buildfile.m` | The task structure is correct (check, then test; examples depends on test). I couldn't run `buildtool check` (Code Analyzer with `WarningThreshold=0`) because the device timed out. | — | Run `buildtool check` locally. |

### Mutation results (P.2108, Python port of the test assertions)

| Mutation | Caught by |
| --- | --- |
| 23.9 → 23.8 | NTIA vectors, independent Eq. (6), example 01 worked vs model |
| 32.98 → 32.9 | NTIA vectors, independent Eq. (6), example 01 |
| 3 log f → 2 log f | NTIA vectors, independent Eq. (6), example 01 |
| sigma_s 6 → 6.1; sigma_l 4 → 4.1 | NTIA vectors, independent Eq. (6) |
| exponent 0.4 → 0.2; -12.5 → -12.4 | five tests |
| sign of Q^-1 flipped | NTIA vectors, increases with p, independent Eq. (6) |
| drop Eq. (6) | NTIA vectors, Eq. (6) cap, independent Eq. (6), single_bs clutter |
| rev1 clamp (d ≤ 2 before calculation) | NTIA vectors, Eq. (6) cap, independent Eq. (6) |
| threshold 0.25 → 0.3 | NTIA vectors, short-path zero |
| **threshold 0.25 → 0.2** | short-path zero only (it probes 0.249) |
| no 0 dB mask | short-path zero |

Mutations not caught elsewhere: seed+k streams in `draw_uniform_columns_rev1`
(A-06), a one-bin or floor shift in `sum_of_independent_db_rev1` (A-05), and
interior grid values (A-09).

## What I checked and how

1. **P.2108 model.** I compared the code line by line with (3a) to (6), and
   T_l = X^0.4 with 10^(-0.2 Ll). I compiled the NTIA C++ (`TerrestrialStatisticalModel.cpp`
   and `InverseComplementaryCumulativeDistribution.cpp`) and swept 4 frequencies
   × 8 distances × 10 percentages against a Python port: largest difference
   0.0026 dB. I checked all 12 NTIA test vectors (7 values, 5 error codes).
2. **Statistics.**
   - Inverse transform: P.2108 (3a) is the quantile in p; ITM is the quantile in
     reliability; the EIRP uses `icdf` of the truncated normal; the table sampler
     uses `interp1` at 100u. All read correctly.
   - Independence: substreams from one mrg32k3a stream.
   - EIRP fit: reproduced with SciPy `truncnorm` and Nelder-Mead from 780 starts.
   - Spline vs fit: tail quantiles compared on 400,000 draws.
   - Convolution: compared against exact normal sums for several values of h and n.
3. **Edge cases (MATLAB).**
   - p at 1e-12 and 100 - 1e-12; p equal to 0 or 100 errors.
   - d at 0, 0.1, 0.249, 0.25, 2, 50, 100, and Inf; NaN and negative values.
   - Empty d and empty p.
   - Shapes: row d, column d, matrix d with a column p, matrix p, and a row d
     with a column p.
4. **Reproducibility.** Code reading: no global RNG in `src/` or `examples/`.
   Existing tests pass in MATLAB (`test_uniform_draws`,
   `test_uniform_columns_reproducible`). I did not rerun examples 02 to 05 twice.
5. **Tests.** I read every test.
   - P.2108: mutation run in a Python port of all P.2108-touching assertions,
     including the example 01, `single_bs_inputs`, and example 04 checks.
   - Other functions: mutations reasoned from the code (A-05, A-06, A-08, A-09);
     not executed in MATLAB, because the device stopped responding.
   - `src` test files: 48 of 48 pass in R2025b.
   - `test_examples_rev1.m`: not run (device timeout).
6. **Production.** I read `vector_mc_seed_pr_eirp_clutter_rev1`,
   `monte_carlo_Pr_dBm_rev2_app`, `monte_carlo_clutter_rev3_app`,
   `monte_carlo_super_bs_eirp_dist_rev5`, `check_mc_seed_independence_rev1`, the
   FSS_Neighborhood setup (lines 150-230 and 340-530), and
   `load_p2108_clutter_rev1`. I reimplemented the production triple-spline EIRP
   in Python. The production clutter-table builder is not in the provided repos.
7. **ITM range (MATLAB).** I counted `info.warnings` bits for the example 03
   draws and the grid, found the threshold in `itm_p2p_core.m:752`, and confirmed
   the distance (100 km) is inside 1 to 2000 km.
8. **Not checked:** `docs/` text (except results CSVs), the figure appearance,
   Code Analyzer output, the CI workflow, and the Word build.
