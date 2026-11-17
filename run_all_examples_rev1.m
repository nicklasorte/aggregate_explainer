function results = run_all_examples_rev1()
%RUN_ALL_EXAMPLES_REV1 Rebuild every figure and results table for the working paper.
%   results = RUN_ALL_EXAMPLES_REV1() runs setup, then examples 01-03, and
%   writes docs/figures/*.png and docs/results/*.csv.
%
%   See also setup_aggregate_explainer_rev1.

setup_aggregate_explainer_rev1();
results.p2108 = example_01_p2108_2km_2700mhz_rev1();
results.eirp = example_02_bs_eirp_distribution_rev1();
results.itm = example_03_itm_flat_100km_2700mhz_rev1();
end
