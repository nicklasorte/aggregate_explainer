# aggregate_explainer

A working paper and MATLAB examples that explain, one input at a time, how an
aggregate interference Monte Carlo simulation works, using 2.7 GHz and a radar
receiver as the case.

- Paper: [docs/working_paper.md](docs/working_paper.md) (Word version: [docs/working_paper.docx](docs/working_paper.docx), rebuilt with `python3 docs/build/build_working_paper_docx.py`)
- Instructions for contributors and Claude: [CLAUDE.md](CLAUDE.md)

## Quick start

```matlab
setup_aggregate_explainer_rev1     % adds paths, fetches matlab_itm
buildtool                          % Code Analyzer and unit tests
buildtool examples                 % rebuilds docs/figures and docs/results
```

## Examples

| Example | What it shows | Figure |
| --- | --- | --- |
| `example_00_uniform_input_rev1` | Why inputs are uniform random numbers: ten equal slices through the clutter loss curve | `docs/figures/fig00_uniform_input.png` |
| `example_01_p2108_2km_2700mhz_rev1` | ITU-R P.2108-1 clutter loss, 2 km, 2.7 GHz | `docs/figures/fig01_p2108_2km_2700mhz.png` |
| `example_02_bs_eirp_distribution_rev2` | Base station EIRP: normal distribution fitted to the CTIA table | `docs/figures/fig02_bs_eirp_distribution.png` |
| `example_03_itm_flat_100km_2700mhz_rev1` | ITM v1.4 point-to-point, flat terrain, 100 km, 2.7 GHz | `docs/figures/fig03_itm_flat_100km_2700mhz.png` |
| `example_04_single_bs_100km_rev2` | EIRP − path loss − clutter loss for one base station at 100 km | `docs/figures/fig04_single_bs_100km_2700mhz.png` |
| `example_05_spread_rev1` | Which input sets the spread of received power | `docs/figures/fig05_single_bs_100km_spread.png` |
| `example_06_itm_vs_distance_rev1` | ITM path loss distribution from 1 km to 200 km, flat terrain | `docs/figures/fig07_itm_vs_distance_2700mhz.png` |
| `example_07_turn_off_list_toy_rev1` | Turn-off list worked example: fixed median order, list sizes over 1,000 trials, and the validation run | `docs/figures/fig08_turn_off_list_toy.png` |
