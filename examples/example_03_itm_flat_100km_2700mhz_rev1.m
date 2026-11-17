function results = example_03_itm_flat_100km_2700mhz_rev1(options)
%EXAMPLE_03_ITM_FLAT_100KM_2700MHZ_REV1 ITM point-to-point loss distribution, flat 100 km path, 2.7 GHz.
%   results = EXAMPLE_03_ITM_FLAT_100KM_2700MHZ_REV1() shows how a uniform
%   draw becomes an ITM basic transmission loss draw:
%     1. Build a flat terrain profile (all elevations 0 m) 100 km long.
%     2. Draw u ~ U(0, 1).
%     3. Set the time percentage (reliability) to 100 u, hold confidence
%        at 50 %, and evaluate ITM v1.4 point-to-point mode
%        (itm_p2p_rev1 from nicklasorte/matlab_itm).
%   ITM returns the loss not exceeded for that percentage of time, so
%   step 3 is inverse-transform sampling of time variability.
%   It also tabulates reliability against confidence (situation
%   variability), writes docs/results/itm_flat_100km_2700mhz*.csv, and
%   saves docs/figures/fig03_itm_flat_100km_2700mhz.png.
%
%   Needs matlab_itm on the path (setup_aggregate_explainer_rev1 adds it).
%
%   Name-value options:
%     n_draws     Number of uniform draws (100000)
%     seed        Random stream seed (1968)
%     h_tx_m      TX antenna height above ground, m (30)
%     h_rx_m      RX antenna height above ground, m (10)
%     step_m      Profile point spacing, m (100)
%     save_out    Write the CSVs and PNG (true)
%     out_root    Repository root (folder above examples/)
%
%   ITM settings are the itm_p2p_rev1 defaults: climate 5 (continental
%   temperate), N_0 = 301 N-units, vertical polarization, epsilon 25,
%   sigma 0.02 S/m, mdvar 13 (broadcast, location variability removed).
%
%   See also itm_p2p_rev1, draw_uniform_rev1.

arguments
    options.n_draws (1,1) double {mustBeInteger, mustBePositive} = 1e5
    options.seed (1,1) double {mustBeInteger, mustBeNonnegative} = 1968
    options.h_tx_m (1,1) double {mustBePositive} = 30
    options.h_rx_m (1,1) double {mustBePositive} = 10
    options.step_m (1,1) double {mustBePositive} = 100
    options.save_out (1,1) logical = true
    options.out_root (1,1) string = fileparts(fileparts(mfilename("fullpath")))
end

if isempty(which("itm_p2p_rev1"))
    error("aggregate_explainer:NoItm", ...
        "itm_p2p_rev1 is not on the path. Run setup_aggregate_explainer_rev1 first.");
end

freq_mhz = 2700;
dist_km = 100;

% --- Flat terrain in ITM PFL format: [np, xi_m, z_0 ... z_np] ---
n_intervals = round(dist_km*1000/options.step_m);
pfl = [n_intervals, options.step_m, zeros(1, n_intervals + 1)];

% validity "off": skip the tail-percentage caution warnings, which would
% fire for many of the 1e5 draws. The path (100 km) is inside the 1-2000 km
% range, and NTIA hard limits still raise errors.
itm_args = {options.h_tx_m, options.h_rx_m, pfl, freq_mhz};

% --- Percentile table straight from the model ---
pct = [1 5 10 25 50 75 90 95 99]';
[loss_model_db, info] = itm_p2p_rev1(itm_args{:}, pct, validity="off");
fprintf("ITM v1.4 p2p, flat terrain, %g km, %.1f GHz, TX %g m, RX %g m\n", ...
    dist_km, freq_mhz/1000, options.h_tx_m, options.h_rx_m);
fprintf("  mode            : %s\n", string(info.mode_name));
fprintf("  free-space loss : %.2f dB\n", info.A_fs_db);
fprintf("  reference atten.: %.2f dB (median loss over free space, before variability)\n", info.A_ref_db);

% --- Monte Carlo: uniform in, loss out ---
u = draw_uniform_rev1(options.n_draws, options.seed);
loss_draws_db = itm_p2p_rev1(itm_args{:}, 100*u, validity="off");
loss_mc_db = prctile(loss_draws_db, pct);

% --- Same draws, made the way the production simulation makes them ---
grid_pct = sim_reliability_grid_rev1();
grid_db = itm_p2p_rev1(itm_args{:}, grid_pct, validity="off");
loss_grid_draws_db = sim_grid_draws_rev1(grid_pct, grid_db(:), u, "linear");
loss_grid_db = prctile(loss_grid_draws_db, pct);

tbl = table(pct, loss_model_db(:), loss_mc_db(:), loss_mc_db(:) - loss_model_db(:), loss_grid_db(:), ...
    VariableNames=["reliability_pct", "model_db", "monte_carlo_db", "difference_db", "sim_grid_db"]);
disp(tbl);

% --- Reliability by confidence (time by situation variability) ---
conf = [10 50 90];
rel_conf_db = itm_p2p_rev1(itm_args{:}, pct, confidence=conf, validity="off");
tbl_rc = array2table([pct, rel_conf_db], ...
    VariableNames=["reliability_pct", "conf_10_db", "conf_50_db", "conf_90_db"]);
disp(tbl_rc);

% --- Figure ---
curve_pct = linspace(0.1, 99.9, 500)';
curve_db = itm_p2p_rev1(itm_args{:}, curve_pct, validity="off");
fig = plot_uniform_to_output_rev1(u, loss_draws_db, curve_pct, curve_db, ...
    title_str = sprintf("ITM v1.4 point-to-point, flat terrain, %g km, %.1f GHz, confidence 50%%", ...
        dist_km, freq_mhz/1000), ...
    x_label = "Basic transmission loss (dB)", ...
    pct_label = "Time percentage (reliability, %)", ...
    marker_pct = pct, marker_x = loss_model_db(:));

results = struct("freq_mhz", freq_mhz, "dist_km", dist_km, "info", info, ...
    "table", tbl, "table_rel_conf", tbl_rc, "u", u, "draws_db", loss_draws_db, ...
    "figure", fig);

if options.save_out
    writetable(tbl, fullfile(options.out_root, "docs", "results", "itm_flat_100km_2700mhz.csv"));
    writetable(tbl_rc, fullfile(options.out_root, "docs", "results", "itm_flat_100km_2700mhz_rel_conf.csv"));
    exportgraphics(fig, fullfile(options.out_root, "docs", "figures", "fig03_itm_flat_100km_2700mhz.png"), Resolution=200);
end
end
