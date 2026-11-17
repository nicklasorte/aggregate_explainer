# Changelog

Notable changes to the working paper and code. Newest first.

## Unreleased

### Added

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
