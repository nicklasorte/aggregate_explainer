# aggregate_explainer

A working paper and MATLAB examples that explain, one input at a time, how an
aggregate interference Monte Carlo simulation works, using 2.7 GHz and a radar
receiver as the case.

- Paper: [docs/working_paper.md](docs/working_paper.md)
- Instructions for contributors and Claude: [CLAUDE.md](CLAUDE.md)

## Quick start

```matlab
setup_aggregate_explainer_rev1                       % adds paths, fetches matlab_itm
runtests("tests/test_aggregate_explainer_rev1.m")
run_all_examples_rev1                                % rebuilds docs/figures and docs/results
```

## Examples

| Example | Input distribution | Figure |
| --- | --- | --- |
| `example_01_p2108_2km_2700mhz_rev1` | ITU-R P.2108-1 clutter loss, 2 km, 2.7 GHz | `docs/figures/fig01_p2108_2km_2700mhz.png` |
| `example_02_bs_eirp_distribution_rev1` | Base station EIRP percentile table | `docs/figures/fig02_bs_eirp_distribution.png` |
| `example_03_itm_flat_100km_2700mhz_rev1` | ITM v1.4 point-to-point, flat terrain, 100 km, 2.7 GHz | `docs/figures/fig03_itm_flat_100km_2700mhz.png` |
