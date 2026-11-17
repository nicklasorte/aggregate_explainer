# CLAUDE.md

Instructions for Claude (and people) working in this repository.

## Purpose

This repository explains, step by step, how an aggregate interference Monte
Carlo simulation works. It pairs a working paper (`docs/working_paper.md`)
with small MATLAB examples that each make one figure and one results table.

The model for the explanation is the production simulation
`init_sim_folder_FSS_neigh_rev25_fdr_github.m` in
[nicklasorte/FSS_Neighborhood](https://github.com/nicklasorte/FSS_Neighborhood)
and its Monte Carlo step `vector_mc_seed_pr_eirp_clutter_rev1.m` in
[nicklasorte/General_Movelist](https://github.com/nicklasorte/General_Movelist).
The explainer recasts it for **2.7 GHz and a radar receiver**.

The core idea the paper teaches: every random input starts as a uniform draw
on (0, 1). The draw becomes a percentage, and each model's inverse CDF turns
the percentage into a value (clutter loss, EIRP, path loss).

## Layout

| Path | Contents |
| --- | --- |
| `setup_aggregate_explainer_rev1.m` | Adds `src/` and `examples/` to the path; clones `matlab_itm` into `ext/` if it isn't on the path. |
| `run_all_examples_rev1.m` | Rebuilds every figure and results table. |
| `src/` | Reusable functions. |
| `examples/` | One function per paper example, `example_NN_<topic>_revN.m`. Each writes `docs/figures/figNN_*.png` and `docs/results/*.csv`. |
| `tests/` | `test_aggregate_explainer_rev1.m` (MATLAB unit tests). |
| `data/` | Input tables, with provenance in `data/SOURCES.md`. |
| `docs/working_paper.md` | The working paper (source). |
| `docs/working_paper.docx` | Word version, built from the Markdown by `docs/build/build_working_paper_docx.py`. Don't edit it by hand. |
| `ext/` | Cloned dependencies (git-ignored). |

## Run

```matlab
setup_aggregate_explainer_rev1
results = runtests("tests/test_aggregate_explainer_rev1.m");
run_all_examples_rev1
```

## Dependencies

- MATLAB R2025b (tested). Keep code compatible with R2024b.
- Statistics and Machine Learning Toolbox (`prctile`).
- [nicklasorte/matlab_itm](https://github.com/nicklasorte/matlab_itm) for
  ITM v1.4 point-to-point (`itm_p2p_rev1`). Setup clones it; don't copy its
  code into this repository.

## Conventions

- Use built-in MATLAB and toolbox functions before writing custom logic.
  Verify each call against `help` in the live MATLAB session.
- File names carry a revision suffix: `_rev1`, `_rev2`. Change behavior in a
  new revision; don't edit a revision that the paper already cites.
- `snake_case` variable names. `arguments` blocks for input validation.
- Fail loudly: `error()` with an identifier `aggregate_explainer:<Name>`. No
  `pause`, no silent fallbacks.
- Cite the equation number and Recommendation version beside every model
  equation (for example, `% (3a), ITU-R P.2108-1`). Don't invent constants;
  mark unknown values `TODO`.
- Random draws come from `draw_uniform_rev1` (a dedicated `RandStream`), never
  from the global generator, so every figure is reproducible from its seed.
- Each example function takes `save_out` and writes its figure with
  `exportgraphics` at 200 dpi. Figures carry the `DRAFT//PRE-DECISIONAL`
  marking.
- After changing an example, rerun it, commit the regenerated PNG and CSV,
  and update the numbers in `docs/working_paper.md`.
- After changing `docs/working_paper.md` or a figure, rebuild the Word file
  with `python3 docs/build/build_working_paper_docx.py` (needs pandoc 3.x and
  python-docx) and commit it with the change.
- Write math in the paper as LaTeX between `$` signs. GitHub renders it, and
  the build turns it into native Word equations. Don't use HTML `<sub>` or
  `<sup>`: pandoc drops raw HTML from Word output.

## Writing

- Follow the Google developer documentation style guide: second person,
  active voice, present tense, sentence-case headings, short paragraphs.
- Use only public or cleared material.
- When a code result disagrees with a reference (an ITU-R Recommendation, an
  NTIA reference implementation), say so in the paper and in the function's
  help text.

## Known items

- `p2108_terrestrial_clutter_loss_vector_rev2` fixes two issues in the rev1
  copy in `general_terrestrial_pathloss`: Equation (6) applied as a distance
  clamp, and the output shape for row or matrix distances. See its help text.
- The EIRP workbook is in dBm. The production simulation uses only its shape
  relative to the median.
- The turn-off list section teaches the simple descending sort by median
  received power first, then gives the near-optimal order (`tf_opt=1`) one
  paragraph.
