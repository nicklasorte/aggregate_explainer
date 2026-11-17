function results = example_01_p2108_2km_2700mhz_rev1(options)
%EXAMPLE_01_P2108_2KM_2700MHZ_REV1 P.2108 clutter loss distribution at 2 km, 2.7 GHz.
%   results = EXAMPLE_01_P2108_2KM_2700MHZ_REV1() shows how a uniform draw
%   becomes a clutter loss draw:
%     1. Draw u ~ U(0, 1).
%     2. Set the location percentage p = 100 u.
%     3. Evaluate P.2108-1 Section 3.2 at p. Equation (3a) is the inverse
%        CDF of the clutter loss, so step 3 is inverse-transform sampling.
%   It prints the worked example, writes docs/results/p2108_2km_2700mhz.csv,
%   and saves docs/figures/fig01_p2108_2km_2700mhz.png.
%
%   Name-value options:
%     n_draws    Number of uniform draws (100000)
%     seed       Random stream seed (2108)
%     save_out   Write the CSV and PNG (true)
%     out_root   Repository root (folder above examples/)
%
%   See also p2108_terrestrial_clutter_loss_vector_rev2, draw_uniform_rev1.

arguments
    options.n_draws (1,1) double {mustBeInteger, mustBePositive} = 1e5
    options.seed (1,1) double {mustBeInteger, mustBeNonnegative} = 2108
    options.save_out (1,1) logical = true
    options.out_root (1,1) string = fileparts(fileparts(mfilename("fullpath")))
end

freq_mhz = 2700;
dist_km = 2;
f_ghz = freq_mhz/1000;

% --- Worked example: intermediate terms of P.2108-1 Section 3.2 ---
L_l = -2*log10(10^(-5*log10(f_ghz) - 12.5) + 10^(-16.5));          % (4a)
L_s = 32.98 + 23.9*log10(dist_km) + 3*log10(f_ghz);                % (5a)
T_l = 10^(-0.2*L_l);
T_s = 10^(-0.2*L_s);
sigma_cb = sqrt((4^2*T_l + 6^2*T_s)/(T_l + T_s));                  % (3b)
L_median = -5*log10(T_l + T_s);                                    % (3a) at p = 50

fprintf("P.2108-1 Section 3.2, f = %.1f GHz, d = %.1f km\n", f_ghz, dist_km);
fprintf("  Ll       = %.2f dB   (4a)\n", L_l);
fprintf("  Ls       = %.2f dB   (5a)\n", L_s);
fprintf("  sigma_cb = %.2f dB   (3b)\n", sigma_cb);
fprintf("  median   = %.2f dB   (3a), p = 50\n", L_median);

% --- Percentile table straight from the model ---
pct = [1 5 10 25 50 75 90 95 99]';
loss_model_db = p2108_terrestrial_clutter_loss_vector_rev2([], freq_mhz, dist_km, pct);
loss_model_db = loss_model_db(:);

% --- Monte Carlo: uniform in, clutter loss out ---
u = draw_uniform_rev1(options.n_draws, options.seed);
loss_draws_db = p2108_terrestrial_clutter_loss_vector_rev2([], freq_mhz, dist_km, 100*u);
loss_draws_db = loss_draws_db(:);
loss_mc_db = prctile(loss_draws_db, pct);

% --- Same draws, made the way the production simulation makes them ---
grid_pct = sim_reliability_grid_rev1();
grid_db = p2108_terrestrial_clutter_loss_vector_rev2([], freq_mhz, dist_km, grid_pct);
loss_grid_draws_db = sim_grid_draws_rev1(grid_pct, grid_db(:), u, "linear");
loss_grid_db = prctile(loss_grid_draws_db, pct);

tbl = table(pct, loss_model_db, loss_mc_db(:), loss_mc_db(:) - loss_model_db, loss_grid_db(:), ...
    VariableNames=["p_pct", "model_db", "monte_carlo_db", "difference_db", "sim_grid_db"]);
disp(tbl);

% --- Figure: uniform -> inverse CDF -> output ---
curve_pct = linspace(0.1, 99.9, 500)';
curve_db = p2108_terrestrial_clutter_loss_vector_rev2([], freq_mhz, dist_km, curve_pct);
fig = plot_uniform_to_output_rev1(u, loss_draws_db, curve_pct, curve_db(:), ...
    title_str = sprintf("ITU-R P.2108-1 terrestrial clutter loss, %.1f GHz, %g km, one end", f_ghz, dist_km), ...
    x_label = "Clutter loss (dB)", ...
    pct_label = "Location percentage p (%)", ...
    marker_pct = pct, marker_x = loss_model_db);

results = struct("freq_mhz", freq_mhz, "dist_km", dist_km, "L_l_db", L_l, ...
    "L_s_db", L_s, "sigma_cb_db", sigma_cb, "median_db", L_median, ...
    "table", tbl, "u", u, "draws_db", loss_draws_db, "figure", fig);

if options.save_out
    writetable(tbl, fullfile(options.out_root, "docs", "results", "p2108_2km_2700mhz.csv"));
    exportgraphics(fig, fullfile(options.out_root, "docs", "figures", "fig01_p2108_2km_2700mhz.png"), Resolution=200);
end
end
