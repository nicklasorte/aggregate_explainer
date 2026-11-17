function tests = test_examples_rev1
%TEST_EXAMPLES_REV1 Tests for examples/, setup, run-all, and the build plan.
%   Each example runs with a small number of draws. Example 03 and the
%   run-all test need matlab_itm; they are filtered (not failed) when
%   itm_p2p_rev1 isn't on the path and ext/matlab_itm doesn't exist.
%
%   results = runtests("tests/test_examples_rev1.m")
tests = functiontests(localfunctions);
end

function setupOnce(tc)
repo_root = fileparts(fileparts(mfilename("fullpath")));
tc.TestData.repo_root = repo_root;
tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo_root, "src")));
tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo_root, "examples")));
tc.applyFixture(matlab.unittest.fixtures.PathFixture(repo_root));
itm_folder = fullfile(repo_root, "ext", "matlab_itm");
if isempty(which("itm_p2p_rev1")) && isfile(fullfile(itm_folder, "itm_p2p_rev1.m"))
    tc.applyFixture(matlab.unittest.fixtures.PathFixture(itm_folder));
end
tc.TestData.has_itm = ~isempty(which("itm_p2p_rev1"));
old_visible = get(groot, "DefaultFigureVisible");
set(groot, "DefaultFigureVisible", "off");
tc.addTeardown(@() set(groot, "DefaultFigureVisible", old_visible));
end

function setup(tc)
tc.addTeardown(@() close("all"));
end

function root = temp_repo_root(tc)
% A scratch "repository root" with the data folder the examples read.
root = string(tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder);
copyfile(fullfile(tc.TestData.repo_root, "data"), fullfile(root, "data"));
end

% ---------------- example 01 ----------------

function test_example01(tc)
out = struct();
evalc("out = example_01_p2108_2km_2700mhz_rev1(n_draws=2000, save_out=false);");
tc.verifyEqual(out.L_l_db, 29.30, "AbsTol", 0.005);
tc.verifyEqual(out.L_s_db, 41.47, "AbsTol", 0.005);
tc.verifyEqual(out.sigma_cb_db, 4.01, "AbsTol", 0.005);
tc.verifyEqual(out.median_db, 29.29, "AbsTol", 0.005);
tc.verifyEqual(height(out.table), 9);
tc.verifyEqual(out.table.model_db(out.table.p_pct == 50), out.median_db, "AbsTol", 1e-9);
tc.verifySize(out.draws_db, [2000 1]);
tc.verifyLessThan(max(abs(out.table.sim_grid_db - out.table.model_db)), 1.5);
tc.verifyClass(out.figure, "matlab.ui.Figure");
end

function test_example01_writes_files(tc)
root = temp_repo_root(tc);
evalc("example_01_p2108_2km_2700mhz_rev1(n_draws=500, out_root=root);");
tc.verifyTrue(isfile(fullfile(root, "docs", "results", "p2108_2km_2700mhz.csv")));
tc.verifyTrue(isfile(fullfile(root, "docs", "figures", "fig01_p2108_2km_2700mhz.png")));
t = readtable(fullfile(root, "docs", "results", "p2108_2km_2700mhz.csv"));
tc.verifyEqual(string(t.Properties.VariableNames), ...
    ["p_pct", "model_db", "monte_carlo_db", "difference_db", "sim_grid_db"]);
end

function test_example01_reproducible(tc)
a = struct(); b = struct();
evalc("a = example_01_p2108_2km_2700mhz_rev1(n_draws=300, seed=5, save_out=false);");
evalc("b = example_01_p2108_2km_2700mhz_rev1(n_draws=300, seed=5, save_out=false);");
tc.verifyEqual(a.draws_db, b.draws_db);
end

% ---------------- example 02 ----------------

function test_example02(tc)
out = struct();
evalc("out = example_02_bs_eirp_distribution_rev2(n_draws=5000, save_out=false, out_root=tc.TestData.repo_root);");
tc.verifyEqual(out.median_db, 31.68, "AbsTol", 0.01);
tc.verifyEqual(out.std_db, 4.67, "AbsTol", 0.01);
tc.verifyEqual(height(out.table), 11);
tc.verifyEqual(out.table.offset_from_median_db(out.table.percentile == 50), 0, "AbsTol", 1e-12);
tc.verifyEqual(out.offset_draws_db, out.draws_db - out.median_db, "AbsTol", 1e-12);
tc.verifyGreaterThanOrEqual(min(out.draws_db), 19.5);
tc.verifyLessThanOrEqual(max(out.draws_db), 42.5);
% The fitted draws have one peak; the spline draws are the rev1 method.
tc.verifySize(out.spline_draws_db, size(out.draws_db));
tc.verifyEqual(median(out.draws_db), median(out.spline_draws_db), "AbsTol", 0.3);
end

function test_example02_density_is_unimodal(tc)
out = struct();
evalc("out = example_02_bs_eirp_distribution_rev2(n_draws=50000, save_out=false, out_root=tc.TestData.repo_root);");
[f, x] = ksdensity(out.draws_db, linspace(21, 41, 200));
tc.verifyEqual(nnz(islocalmax(f, MinProminence=0.002)), 1);
[g, ~] = ksdensity(out.spline_draws_db, x);
tc.verifyGreaterThan(nnz(islocalmax(g, MinProminence=0.002)), 1);   % rev1's two peaks
end

function test_example02_writes_files(tc)
root = temp_repo_root(tc);
evalc("example_02_bs_eirp_distribution_rev2(n_draws=500, out_root=root);");
t = readtable(fullfile(root, "docs", "results", "bs_eirp_distribution.csv"));
tc.verifyEqual(string(t.Properties.VariableNames), ...
    ["percentile", "table_dbm", "fitted_dbm", "residual_db", "monte_carlo_dbm", "offset_from_median_db"]);
tc.verifyTrue(isfile(fullfile(root, "docs", "figures", "fig02_bs_eirp_distribution.png")));
end

% ---------------- example 03 (needs matlab_itm) ----------------

function test_example03(tc)
tc.assumeTrue(tc.TestData.has_itm, "matlab_itm is not on the path");
out = struct();
evalc("out = example_03_itm_flat_100km_2700mhz_rev1(n_draws=2000, save_out=false);");
tc.verifyEqual(out.info.A_fs_db, 141.08, "AbsTol", 0.005);
tc.verifyEqual(out.info.A_ref_db, 58.97, "AbsTol", 0.005);
tc.verifyEqual(string(out.info.mode_name), "Troposcatter");
tc.verifyEqual(out.table.model_db(out.table.reliability_pct == 50), 197.13, "AbsTol", 0.005);
tc.verifyEqual(out.table.model_db(out.table.reliability_pct == 1), 174.38, "AbsTol", 0.005);
tc.verifyEqual(out.table.model_db(out.table.reliability_pct == 99), 213.53, "AbsTol", 0.005);
rc = out.table_rel_conf;
tc.verifyEqual(rc.conf_10_db(rc.reliability_pct == 50), 190.03, "AbsTol", 0.005);
tc.verifyEqual(rc.conf_90_db(rc.reliability_pct == 50), 204.23, "AbsTol", 0.005);
tc.verifyTrue(issorted(out.table.model_db));
end

function test_example03_writes_files(tc)
tc.assumeTrue(tc.TestData.has_itm, "matlab_itm is not on the path");
root = temp_repo_root(tc);
evalc("example_03_itm_flat_100km_2700mhz_rev1(n_draws=500, out_root=root);");
tc.verifyTrue(isfile(fullfile(root, "docs", "results", "itm_flat_100km_2700mhz.csv")));
tc.verifyTrue(isfile(fullfile(root, "docs", "results", "itm_flat_100km_2700mhz_rel_conf.csv")));
tc.verifyTrue(isfile(fullfile(root, "docs", "figures", "fig03_itm_flat_100km_2700mhz.png")));
end

function test_example03_without_itm_errors(tc)
tc.assumeFalse(tc.TestData.has_itm, "matlab_itm is on the path; error path not reachable");
tc.verifyError(@() example_03_itm_flat_100km_2700mhz_rev1(save_out=false), ...
    "aggregate_explainer:NoItm");
end

% ---------------- examples 04 and 05 (need matlab_itm) ----------------

function test_single_bs_inputs(tc)
tc.assumeTrue(tc.TestData.has_itm, "matlab_itm is not on the path");
in = single_bs_inputs_rev1(repo_root=tc.TestData.repo_root);
tc.verifyEqual(in.signs, [1 -1 -1]);
tc.verifyEqual(in.eirp_q(50), 31.68, "AbsTol", 0.01);
tc.verifyEqual(in.path_q(50), 197.13, "AbsTol", 0.01);
tc.verifyEqual(in.clutter_q(50), 29.29, "AbsTol", 0.01);
tc.verifySize(in.path_q([10 50; 90 99]), [2 2]);
end

function test_single_bs_inputs_without_itm(tc)
tc.assumeFalse(tc.TestData.has_itm, "matlab_itm is on the path; error path not reachable");
tc.verifyError(@() single_bs_inputs_rev1(repo_root=tc.TestData.repo_root), "aggregate_explainer:NoItm");
end

function test_example04(tc)
tc.assumeTrue(tc.TestData.has_itm, "matlab_itm is not on the path");
out = struct();
evalc("out = example_04_single_bs_100km_rev2(n_draws=5000, save_out=false, out_root=tc.TestData.repo_root);");
tc.verifyEqual(out.prx_dbm, out.eirp_dbm - out.path_db - out.clutter_db, "AbsTol", 1e-12);
tc.verifyEqual(out.median_of_terms_dbm, 31.681 - 197.128 - 29.293, "AbsTol", 0.01);
mid = out.table.percentile >= 5 & out.table.percentile <= 95;
tc.verifyLessThan(max(abs(out.table.difference_db(mid))), 0.6);
% Fitted EIRP and the production spline give nearly the same received power.
tc.verifyLessThan(max(abs(out.table.spline_eirp_dbm - out.table.monte_carlo_dbm)), 1);
tc.verifyEqual(height(out.table), 10);
end

function test_example04_inputs_independent(tc)
tc.assumeTrue(tc.TestData.has_itm, "matlab_itm is not on the path");
out = struct();
evalc("out = example_04_single_bs_100km_rev2(n_draws=20000, save_out=false, out_root=tc.TestData.repo_root);");
r = corr(out.u);
tc.verifyLessThan(max(abs(r(~eye(3)))), 0.03);
end

function test_example04_writes_files(tc)
tc.assumeTrue(tc.TestData.has_itm, "matlab_itm is not on the path");
root = temp_repo_root(tc);
evalc("example_04_single_bs_100km_rev2(n_draws=500, out_root=root);");
tc.verifyTrue(isfile(fullfile(root, "docs", "results", "single_bs_100km_2700mhz.csv")));
tc.verifyTrue(isfile(fullfile(root, "docs", "figures", "fig04_single_bs_100km_2700mhz.png")));
end

function test_example05(tc)
tc.assumeTrue(tc.TestData.has_itm, "matlab_itm is not on the path");
out = struct();
evalc("out = example_05_spread_rev1(n_draws=20000, save_out=false, out_root=tc.TestData.repo_root);");
t = out.table;
tc.verifyEqual(height(t), 4);
% Holding any input fixed narrows the distribution; path loss narrows it most.
tc.verifyTrue(all(t.std_db(2:4) < t.std_db(1)));
[~, k] = min(t.std_db);
tc.verifyEqual(t.scenario(k), "Path loss held at median");
% Independent terms: the fixed-input variances match var(total) - var(input).
v_all = t.std_db(1)^2;
v_in = out.share.std_db.^2;
tc.verifyEqual(t.std_db(2:4).^2, v_all - v_in, "RelTol", 0.03);
tc.verifyEqual(sum(out.share.share_of_variance_pct), 100, "AbsTol", 3);
tc.verifyEqual(out.share.input(out.share.share_of_variance_pct == max(out.share.share_of_variance_pct)), "Path loss");
% The worst-case stack sits far above the 99th percentile of the sum.
tc.verifyGreaterThan(out.worst_stack_dbm - out.p99_dbm, 10);
end

function test_example05_writes_files(tc)
tc.assumeTrue(tc.TestData.has_itm, "matlab_itm is not on the path");
root = temp_repo_root(tc);
evalc("example_05_spread_rev1(n_draws=500, out_root=root);");
tc.verifyTrue(isfile(fullfile(root, "docs", "results", "single_bs_100km_spread.csv")));
tc.verifyTrue(isfile(fullfile(root, "docs", "results", "single_bs_100km_variance_share.csv")));
tc.verifyTrue(isfile(fullfile(root, "docs", "figures", "fig05_single_bs_100km_spread.png")));
end

function test_example04_without_itm_errors(tc)
tc.assumeFalse(tc.TestData.has_itm, "matlab_itm is on the path; error path not reachable");
tc.verifyError(@() example_04_single_bs_100km_rev2(save_out=false), "aggregate_explainer:NoItm");
end

% ---------------- setup and run-all ----------------

function test_setup_adds_paths(tc)
tc.assumeTrue(tc.TestData.has_itm, "setup would clone matlab_itm");
tc.applyFixture(matlab.unittest.fixtures.PathFixture(tempdir));   % restores the path afterwards
setup_aggregate_explainer_rev1();
tc.verifyNotEmpty(which("example_01_p2108_2km_2700mhz_rev1"));
tc.verifyNotEmpty(which("draw_uniform_rev1"));
tc.verifyNotEmpty(which("itm_p2p_rev1"));
end

function test_setup_bad_itm_folder(tc)
tc.assumeFalse(tc.TestData.has_itm, "matlab_itm is on the path; folder option not used");
tc.applyFixture(matlab.unittest.fixtures.PathFixture(tempdir));
tc.verifyError(@() setup_aggregate_explainer_rev1(itm_folder=tempdir), "aggregate_explainer:NoItm");
end

function test_run_all(tc)
tc.assumeTrue(tc.TestData.has_itm, "matlab_itm is not on the path");
root = temp_repo_root(tc);
out = struct();
evalc("out = run_all_examples_rev1(n_draws=300, out_root=root);");
tc.verifyEqual(string(fieldnames(out))', ["p2108", "eirp", "itm", "single_bs", "spread"]);
figs = dir(fullfile(root, "docs", "figures", "*.png"));
csvs = dir(fullfile(root, "docs", "results", "*.csv"));
tc.verifyNumElements(figs, 5);
tc.verifyNumElements(csvs, 7);
end

% ---------------- build plan ----------------

function test_buildfile_tasks(tc)
plan = buildfile();
tc.verifyEqual(sort(string({plan.Tasks.Name})), sort(["check", "examples", "test"]));
tc.verifyEqual(string(plan.DefaultTasks), ["check", "test"]);
tc.verifyEqual(string(plan("examples").Dependencies), "test");
end
