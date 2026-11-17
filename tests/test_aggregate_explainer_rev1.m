function tests = test_aggregate_explainer_rev1
%TEST_AGGREGATE_EXPLAINER_REV1 Unit tests for the aggregate_explainer code.
%   results = runtests("tests/test_aggregate_explainer_rev1.m")
%
%   P.2108 reference values are the NTIA/ITS test vectors
%   (github.com/NTIA/p2108-test-data, TerrestrialStatisticalModelTestData.csv),
%   given to 0.1 dB.
tests = functiontests(localfunctions);
end

function setupOnce(tc)
repo_root = fileparts(fileparts(mfilename("fullpath")));
tc.TestData.repo_root = repo_root;
addpath(fullfile(repo_root, "src"), fullfile(repo_root, "examples"));
end

% ---------------- P.2108 ----------------

function test_p2108_ntia_vectors(tc)
% f_GHz, d_km, p, L_ctt_dB
v = [ 0.5   0.25 50    17.4
      0.5   0.25  1     3.9
      0.5   0.25 99    30.9
     26.6  15.8  45    32.5
     67     5.4  30.5  30.9
      3.5   1     0.1  16.8
      3.5   1    99.9  42.8];
for k = 1:height(v)
    L = p2108_terrestrial_clutter_loss_vector_rev2([], 1000*v(k,1), v(k,2), v(k,3));
    tc.verifyEqual(L, v(k,4), "AbsTol", 0.05, ...
        sprintf("f=%g GHz, d=%g km, p=%g", v(k,1), v(k,2), v(k,3)));
end
end

function test_p2108_2km_2700mhz_median(tc)
L = p2108_terrestrial_clutter_loss_vector_rev2([], 2700, 2, 50);
tc.verifyEqual(L, 29.29, AbsTol=0.005);
end

function test_p2108_equation6_cap(tc)
% Beyond 2 km the loss equals the 2 km value at every p.
p = [1 50 99.9];
L2 = p2108_terrestrial_clutter_loss_vector_rev2([], 2700, 2, p);
L50 = p2108_terrestrial_clutter_loss_vector_rev2([], 2700, 50, p);
tc.verifyLessThanOrEqual(L50, L2 + 1e-12);
% Below 2 km the loss never exceeds the 2 km value.
Lshort = p2108_terrestrial_clutter_loss_vector_rev2([], 3500, 1, 99.9);
L2b = p2108_terrestrial_clutter_loss_vector_rev2([], 3500, 2, 99.9);
tc.verifyLessThanOrEqual(Lshort, L2b);
end

function test_p2108_shapes(tc)
d_row = [0.5 1 2 5];
tc.verifySize(p2108_terrestrial_clutter_loss_vector_rev2([], 2700, d_row, 50), [1 4]);
tc.verifySize(p2108_terrestrial_clutter_loss_vector_rev2([], 2700, d_row', 50), [4 1]);
tc.verifySize(p2108_terrestrial_clutter_loss_vector_rev2([], 2700, d_row, [10 50 90]), [4 3]);
tc.verifySize(p2108_terrestrial_clutter_loss_vector_rev2([], 2700, magic(3), [10 90]), [9 2]);
end

function test_p2108_short_path_zero(tc)
L = p2108_terrestrial_clutter_loss_vector_rev2([], 2700, [0 0.1 0.249 0.25], 50);
tc.verifyEqual(L(1:3), [0 0 0]);
tc.verifyGreaterThan(L(4), 0);
end

function test_p2108_rejects_bad_inputs(tc)
tc.verifyError(@() p2108_terrestrial_clutter_loss_vector_rev2([], 400, 1, 50), "MATLAB:validators:mustBeInRange");
tc.verifyError(@() p2108_terrestrial_clutter_loss_vector_rev2([], 2700, 1, 0), "MATLAB:validators:mustBeGreaterThan");
tc.verifyError(@() p2108_terrestrial_clutter_loss_vector_rev2([], 2700, 1, 100), "MATLAB:validators:mustBeLessThan");
end

% ---------------- EIRP table and sampling ----------------

function test_eirp_table_read(tc)
t = read_bs_eirp_distribution_rev1(fullfile(tc.TestData.repo_root, "data", "7Ghz 0azi 0ele EIRP.xlsx"));
tc.verifyEqual(t.percentile', 0:10:100);
tc.verifyEqual(t.eirp_db([1 6 11])', [19.5 31.75 42.5]);
tc.verifyEqual(t.Properties.UserData.azimuth_deg, 0);
tc.verifyEqual(t.Properties.UserData.elevation_deg, 0);
end

function test_sampler_hits_table_points(tc)
pct = (0:10:100)';
val = [19.5 25.25 28 29.25 30.25 31.75 32.75 33.75 35.5 38.5 42.5]';
u = [0.1 0.5 0.9];
x = sample_from_percentile_table_rev1(pct, val, u);
tc.verifyEqual(x, [25.25 31.75 38.5], AbsTol=1e-12);
end

function test_sampler_requires_full_range(tc)
tc.verifyError(@() sample_from_percentile_table_rev1([10; 90], [1; 2], 0.5), ...
    "aggregate_explainer:TableRange");
end

function test_uniform_draws(tc)
u1 = draw_uniform_rev1(1000, 3);
u2 = draw_uniform_rev1(1000, 3);
tc.verifyEqual(u1, u2);
tc.verifyTrue(all(u1 > 0 & u1 < 1));
end

function test_sim_grid_draws_endpoints(tc)
g = sim_reliability_grid_rev1();
x = sim_grid_draws_rev1(g, g, [0 1]);
tc.verifyEqual(x, [0.001 99.999], AbsTol=1e-12);
end
