function tests = test_src_extra_rev1
%TEST_SRC_EXTRA_REV1 Further unit tests for every function in src/.
%   Complements test_aggregate_explainer_rev1.m: input validation, error
%   paths, shapes, and the plotting helper.
%
%   results = runtests("tests/test_src_extra_rev1.m")
tests = functiontests(localfunctions);
end

function setupOnce(tc)
repo_root = fileparts(fileparts(mfilename("fullpath")));
tc.TestData.repo_root = repo_root;
addpath(fullfile(repo_root, "src"));
old_visible = get(groot, "DefaultFigureVisible");
set(groot, "DefaultFigureVisible", "off");
tc.addTeardown(@() set(groot, "DefaultFigureVisible", old_visible));
end

% ---------------- p2108_terrestrial_clutter_loss_vector_rev2 ----------------

function test_p2108_vector_matches_scalar_calls(tc)
d = [0.3 1 2 7];
p = [1 50 99];
L = p2108_terrestrial_clutter_loss_vector_rev2([], 2700, d, p);
for i = 1:numel(d)
    for j = 1:numel(p)
        tc.verifyEqual(L(i,j), p2108_terrestrial_clutter_loss_vector_rev2([], 2700, d(i), p(j)), ...
            "AbsTol", 1e-12);
    end
end
end

function test_p2108_increases_with_p(tc)
L = p2108_terrestrial_clutter_loss_vector_rev2([], 2700, 2, linspace(0.1, 99.9, 200));
tc.verifyTrue(all(diff(L(:)) > 0));
end

function test_p2108_independent_equation6(tc)
% Recompute (3a)-(6) from the P.2108-1 equations in a different form:
% 10^(-0.2 Ll) = 10^(0.4 log10(...)), and Q^-1 via norminv.
f = 1.6; d = 0.5; p = 99.9;
Ll = -2*log10(10^(-5*log10(f) - 12.5) + 10^(-16.5));
lctt = @(dd) local_ref_lctt(f, dd, p, Ll);
expected = min(lctt(d), lctt(2));
L = p2108_terrestrial_clutter_loss_vector_rev2([], 1000*f, d, p);
tc.verifyEqual(L, expected, "AbsTol", 1e-9);
end

function L = local_ref_lctt(f, d, p, Ll)
Ls = 32.98 + 23.9*log10(d) + 3*log10(f);
s = sqrt((16*10^(-0.2*Ll) + 36*10^(-0.2*Ls))/(10^(-0.2*Ll) + 10^(-0.2*Ls)));
L = -5*log10(10^(-0.2*Ll) + 10^(-0.2*Ls)) - s*norminv(1 - p/100);
end

function test_p2108_default_p_is_median(tc)
tc.verifyEqual(p2108_terrestrial_clutter_loss_vector_rev2([], 2700, 2), ...
    p2108_terrestrial_clutter_loss_vector_rev2([], 2700, 2, 50));
end

function test_p2108_rejects_negative_distance(tc)
tc.verifyError(@() p2108_terrestrial_clutter_loss_vector_rev2([], 2700, -1, 50), ...
    "MATLAB:validators:mustBeNonnegative");
end

% ---------------- read_bs_eirp_distribution_rev1 ----------------

function test_eirp_reader_units_and_source(tc)
f = fullfile(tc.TestData.repo_root, "data", "7Ghz 0azi 0ele EIRP.xlsx");
t = read_bs_eirp_distribution_rev1(f);
tc.verifyEqual(string(t.Properties.VariableUnits), ["%", "dBm"]);
tc.verifyEqual(t.Properties.UserData.source, string(f));
tc.verifyTrue(issorted(t.eirp_db));
end

function test_eirp_reader_missing_file(tc)
tc.verifyError(@() read_bs_eirp_distribution_rev1("no_such_file.xlsx"), ...
    "MATLAB:validators:mustBeFile");
end

function test_eirp_reader_no_percentile_rows(tc)
folder = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
f = fullfile(folder, "bad.xlsx");
writecell({"Azimuth", 0; "Elevation", 0; "Note", 1}, f);
tc.verifyError(@() read_bs_eirp_distribution_rev1(f), "aggregate_explainer:EirpTable");
end

function test_eirp_reader_decreasing_values(tc)
folder = tc.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
f = fullfile(folder, "decreasing.xlsx");
writecell({"Azimuth", 0; "Elevation", 0; "0th%", 30; "50th%", 20; "100th%", 40}, f);
tc.verifyError(@() read_bs_eirp_distribution_rev1(f), "aggregate_explainer:EirpTable");
end

% ---------------- sample_from_percentile_table_rev1 ----------------

function test_sampler_keeps_shape(tc)
pct = (0:10:100)';
val = (1:11)';
u = reshape(linspace(0.05, 0.95, 6), 2, 3);
x = sample_from_percentile_table_rev1(pct, val, u, "linear");
tc.verifySize(x, [2 3]);
tc.verifyEqual(x, 1 + 10*u, "AbsTol", 1e-12);
end

function test_sampler_methods_agree_at_nodes(tc)
pct = (0:10:100)';
val = [19.5 25.25 28 29.25 30.25 31.75 32.75 33.75 35.5 38.5 42.5]';
u = (10:10:90)/100;
for method = ["spline", "pchip", "linear", "makima"]
    x = sample_from_percentile_table_rev1(pct, val, u, method);
    tc.verifyEqual(x(:), val(2:10), "AbsTol", 1e-9, method);
end
end

function test_sampler_length_mismatch(tc)
tc.verifyError(@() sample_from_percentile_table_rev1([0; 100], [1; 2; 3], 0.5), ...
    "aggregate_explainer:TableSize");
end

function test_sampler_rejects_bad_method(tc)
tc.verifyError(@() sample_from_percentile_table_rev1([0; 100], [1; 2], 0.5, "cubic"), ...
    "MATLAB:validators:mustBeMember");
end

function test_sampler_rejects_u_at_bounds(tc)
tc.verifyError(@() sample_from_percentile_table_rev1([0; 100], [1; 2], 0), ...
    "MATLAB:validators:mustBeGreaterThan");
tc.verifyError(@() sample_from_percentile_table_rev1([0; 100], [1; 2], 1), ...
    "MATLAB:validators:mustBeLessThan");
end

% ---------------- draw_uniform_rev1 ----------------

function test_uniform_size_and_seed(tc)
tc.verifySize(draw_uniform_rev1(5), [5 1]);
tc.verifyNotEqual(draw_uniform_rev1(100, 1), draw_uniform_rev1(100, 2));
tc.verifyEqual(draw_uniform_rev1(10), draw_uniform_rev1(10, 0));
end

function test_uniform_leaves_global_stream_alone(tc)
rng(123);
before = rand(1, 3);
rng(123);
draw_uniform_rev1(1000, 9);
after = rand(1, 3);
tc.verifyEqual(after, before);
end

function test_uniform_mean_and_spread(tc)
u = draw_uniform_rev1(1e5, 4);
tc.verifyEqual(mean(u), 0.5, "AbsTol", 0.005);
tc.verifyEqual(var(u), 1/12, "AbsTol", 0.002);
end

function test_uniform_rejects_zero(tc)
tc.verifyError(@() draw_uniform_rev1(0), "MATLAB:validators:mustBePositive");
end

% ---------------- sim_reliability_grid_rev1 / sim_grid_draws_rev1 ----------------

function test_grid_shape(tc)
g = sim_reliability_grid_rev1();
tc.verifySize(g, [47 1]);
tc.verifyTrue(issorted(g) && numel(unique(g)) == 47);
tc.verifyEqual(g([1 end])', [0.001 99.999]);
tc.verifyTrue(any(g == 50));
end

function test_grid_draws_linear_matches_interp1(tc)
g = sim_reliability_grid_rev1();
v = 100 - g;                      % any monotone table
u = [0.1 0.37 0.5 0.92];
x = sim_grid_draws_rev1(g, v, u);
pct = u*(99.999 - 0.001) + 0.001;
tc.verifyEqual(x, interp1(g, v, pct), "AbsTol", 1e-12);
end

function test_grid_draws_spline_option(tc)
g = sim_reliability_grid_rev1();
v = g.^2;
x = sim_grid_draws_rev1(g, v, 0.5, "spline");
tc.verifyEqual(x, interp1(g, v, 0.5*(99.999 - 0.001) + 0.001, "spline"), "AbsTol", 1e-9);
end

function test_grid_draws_rejects_u_outside(tc)
g = sim_reliability_grid_rev1();
tc.verifyError(@() sim_grid_draws_rev1(g, g, 1.5), "MATLAB:validators:mustBeInRange");
end

% ---------------- plot_uniform_to_output_rev1 ----------------

function test_plot_has_three_panels_and_marking(tc)
u = draw_uniform_rev1(500, 1);
x = 10 + 4*randn(RandStream("mrg32k3a", Seed=1), 500, 1);
fig = plot_uniform_to_output_rev1(u, x, (1:99)', (1:99)', ...
    title_str = "Test title", x_label = "Loss (dB)", ...
    marker_pct = [10 50 90], marker_x = [10 50 90]);
tc.addTeardown(@() close(fig));
ax = findobj(fig, "Type", "axes");
tc.verifyNumElements(ax, 3);
titles = sort(string(arrayfun(@(a) a.Title.String, ax, UniformOutput=false)));
tc.verifyEqual(titles', sort(["1. Input: uniform draws", "2. Mapping: inverse CDF", "3. Output distribution"]));
t = findobj(fig, "Type", "tiledlayout");
tc.verifyEqual(string(t.Title.String), "Test title");
tc.verifyEqual(string(t.Subtitle.String), "DRAFT//PRE-DECISIONAL");
markers = findobj(fig, "Type", "line", "Marker", "o");
tc.verifyNumElements(markers, 1);
end

function test_plot_without_markers(tc)
u = draw_uniform_rev1(100, 2);
fig = plot_uniform_to_output_rev1(u, u, (1:99)', (1:99)');
tc.addTeardown(@() close(fig));
tc.verifyEmpty(findobj(fig, "Type", "line", "Marker", "o"));
end

% ---------------- draw_uniform_columns_rev1 ----------------

function test_uniform_columns_shape_and_range(tc)
u = draw_uniform_columns_rev1(1000, 3, 7);
tc.verifySize(u, [1000 3]);
tc.verifyTrue(all(u(:) > 0 & u(:) < 1));
end

function test_uniform_columns_independent(tc)
u = draw_uniform_columns_rev1(50000, 4, 1);
r = corr(u);
tc.verifyLessThan(max(abs(r(~eye(4)))), 0.02);
% No column repeats another, shifted by one row (the seed+k pitfall).
tc.verifyFalse(isequal(u(2:end, 1), u(1:end-1, 2)));
end

function test_uniform_columns_reproducible(tc)
a = draw_uniform_columns_rev1(100, 3, 11);
b = draw_uniform_columns_rev1(100, 2, 11);
tc.verifyEqual(a(:, 1:2), b);   % a column doesn't depend on how many follow
tc.verifyNotEqual(a, draw_uniform_columns_rev1(100, 3, 12));
end

% ---------------- sum_of_independent_db_rev1 ----------------

function test_sum_two_normals(tc)
% N(10, 3) - N(4, 4) is N(6, 5): check median and 95th percentile.
q1 = @(p) 10 + 3*norminv(p/100);
q2 = @(p) 4 + 4*norminv(p/100);
[x, cdf] = sum_of_independent_db_rev1({q1, q2}, [1 -1]);
[c, i] = unique(cdf);
tc.verifyEqual(interp1(c, x(i), 0.5), 6, "AbsTol", 0.02);
tc.verifyEqual(interp1(c, x(i), 0.95), 6 + 5*norminv(0.95), "AbsTol", 0.05);
tc.verifyEqual(cdf(end), 1, "AbsTol", 1e-9);
tc.verifyTrue(all(diff(cdf) >= 0));
end

function test_sum_constant_shift(tc)
% A constant term only shifts the distribution.
qu = @(p) p/100;                 % uniform on (0, 1)
qc = @(p) 5 + 0*p;
[x, cdf] = sum_of_independent_db_rev1({qu, qc}, [1 1], bin_db=0.001);
[c, i] = unique(cdf);
tc.verifyEqual(interp1(c, x(i), 0.25), 5.25, "AbsTol", 0.002);
end

function test_sum_validation(tc)
q = @(p) p;
tc.verifyError(@() sum_of_independent_db_rev1({q, q}, 1), "aggregate_explainer:SumTerms");
tc.verifyError(@() sum_of_independent_db_rev1({q}, 2), "MATLAB:validators:mustBeMember");
tc.verifyError(@() sum_of_independent_db_rev1({@(p) Inf + p}, 1), "aggregate_explainer:SumTerms");
end
