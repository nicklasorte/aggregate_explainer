# Changelog

Notable changes to the working paper and code. Newest first.

## Unreleased

### Added

- Example 07 and paper Sections 8-13: how the turn-off list is built (fixed
  median order, one cut point per trial, 80th percentile plus one), the two
  Monte Carlo simulations, the radius search, five meanings of
  "percentage," what is random and what is fixed, and link budget terms
  (noise, FDR, polarization, ITM confidence and ground, clutter scope, EIRP
  level, model versions). Old Sections 8 and 9 are now 14 and 15.
- Paper Section 3: how CTIA built the EIRP heatmap (60 measured cells, five
  15-minute periods, extrapolated to 7 GHz), from the CTIA working paper of
  August 10, 2026. Resolves review item B-08.
- `docs/PLAN_explain_aggregate_zones.md`: plan for what the explainer must
  teach, based on the technical questions raised in review of the aggregate
  zones working paper.
- Independent code and paper reviews (`docs/review/`), their triage, the
  fixes, and a Google style pass on the paper; new paper Section 8 on
  differences from the production simulation.

- Example 06 and paper Section 4: the ITM path loss distribution at every
  distance from 1 km to 200 km (spread under 2 dB within 10 km, peaking at
  39.5 dB near 115 km).

- Paper Section 1, "Why the inputs are uniform random numbers": the
  inverse-transform argument, a ten-slice figure (example 00), simpler
  alternatives and why they fall short, and rules for using uniform draws,
  including the sampling error of a percentile.

- EIRP drawn from a normal distribution in dBm fitted to the CTIA table
  (`fit_eirp_truncated_normal_rev1`, example 02 rev2), replacing the spline,
  whose two peaks came from interpolation. Largest misfit 0.7 dB.
- Example 05 and paper Section 7: where the spread of received power comes
  from (path loss 64% of the variance; worst-case stacking overstates the
  99th percentile by about 15 dB).
- NTIA report styling for every figure: takeaway headline, subhead, source
  line, marking, gray plus one accent, Times New Roman, 300 dpi
  (`style_axes_rev1`, `figure_palette_rev1`, `add_figure_text_rev1`,
  `plot_uniform_to_output_rev2`).

### Removed

- `example_02_bs_eirp_distribution_rev1`, `example_04_single_bs_100km_rev1`,
  and `plot_uniform_to_output_rev1`, replaced by the revisions above (still
  in the git history).

- Example 04 and paper Section 6: Monte Carlo of one base station at 100 km
  (EIRP − ITM path loss − P.2108 clutter loss), checked against an exact
  convolution. New `draw_uniform_columns_rev1` (independent substreams) and
  `sum_of_independent_db_rev1`.
- `docs/PLAN_style_and_review.md`: plan for the Google style pass and an
  independent review of the code and paper.

- Tests for all MATLAB code: `tests/test_src_extra_rev1.m` and
  `tests/test_examples_rev1.m` (48 tests in all). CI clones `matlab_itm` so
  the example 03 tests run there too.
- `run_all_examples_rev1` takes `n_draws`, `save_out`, and `out_root`
  options; defaults are unchanged.

- EIRP provenance in the paper (Section 3): the table is CTIA field
  measurement data. New subsection on how such a table can be modeled
  (imt-matlab, ITU-R M.2101-0 AAS), and a flagged assumption that the 7 GHz
  distribution shape applies at 2.7 GHz.

- Working paper `docs/working_paper.md`, with a Word version
  `docs/working_paper.docx` built by `docs/build/build_working_paper_docx.py`.
- Example 01: ITU-R P.2108-1 clutter loss distribution at 2 km, 2.7 GHz.
- Example 02: base station EIRP distribution from the FSS_Neighborhood
  percentile table (dBm).
- Example 03: ITM v1.4 point-to-point loss distribution on a flat 100 km path
  at 2.7 GHz.
- `p2108_terrestrial_clutter_loss_vector_rev2`, adapted from
  `general_terrestrial_pathloss` and checked against P.2108-1 and the NTIA/ITS
  reference implementation.
- Plan for the turn-off list section, `docs/PLAN_turn_off_list_section.md`.
- `buildfile.m` (`buildtool check`, `test`, `examples`), GitHub Actions CI,
  `CLAUDE.md`, `.gitattributes`, pull request template, citation file.

### Fixed (relative to the `general_terrestrial_pathloss` copy)

- P.2108-1 Equation (6) applied as `min(L(d), L(2 km))` instead of clamping
  the distance; the two differ by up to 2.0 dB at high percentages below 2 km.
- Output shape for row and matrix distance inputs.
