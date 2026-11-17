function results = run_all_examples_rev1(options)
%RUN_ALL_EXAMPLES_REV1 Rebuild every figure and results table for the working paper.
%   results = RUN_ALL_EXAMPLES_REV1() runs setup, then examples 00-07, and
%   writes docs/figures/*.png and docs/results/*.csv.
%
%   Name-value options (defaults reproduce the paper):
%     n_draws    Uniform draws per example (100000)
%     save_out   Write the PNG and CSV files (true)
%     out_root   Repository root to write under (this folder)
%
%   See also setup_aggregate_explainer_rev1.

arguments
    options.n_draws (1,1) double {mustBeInteger, mustBePositive} = 1e5
    options.save_out (1,1) logical = true
    options.out_root (1,1) string = fileparts(mfilename("fullpath"))
end

setup_aggregate_explainer_rev1();
common = {"n_draws", options.n_draws, "save_out", options.save_out, "out_root", options.out_root};
results.uniform = example_00_uniform_input_rev1(common{:});
results.p2108 = example_01_p2108_2km_2700mhz_rev1(common{:});
results.eirp = example_02_bs_eirp_distribution_rev2(common{:});
results.itm = example_03_itm_flat_100km_2700mhz_rev1(common{:});
results.single_bs = example_04_single_bs_100km_rev2(common{:});
results.spread = example_05_spread_rev1(common{:});
results.itm_distance = example_06_itm_vs_distance_rev1(save_out=options.save_out, out_root=options.out_root);
results.turn_off_toy = example_07_turn_off_list_toy_rev1(save_out=options.save_out, out_root=options.out_root);
end
