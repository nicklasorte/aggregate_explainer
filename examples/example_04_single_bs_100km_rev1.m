function results = example_04_single_bs_100km_rev1(options)
%EXAMPLE_04_SINGLE_BS_100KM_REV1 Monte Carlo of one base station 100 km from the receiver, 2.7 GHz.
%   results = EXAMPLE_04_SINGLE_BS_100KM_REV1() combines the three inputs
%   of examples 01-03 into the power received from one base station:
%
%     P_rx (dBm) = EIRP - L_path - L_clutter
%
%   Each Monte Carlo draw takes three independent uniform draws, one per
%   input, maps each through its inverse CDF, and adds the results in dB:
%     EIRP       FSS_Neighborhood/CTIA percentile table, 0 deg az, 0 deg el (dBm)
%     L_path     ITM v1.4 p2p, flat terrain, 100 km, TX 30 m, RX 10 m,
%                confidence 50 %, time percentage = 100 u
%     L_clutter  ITU-R P.2108-1 at the base station end, location
%                percentage = 100 u (at 100 km Equation (6) caps it at the
%                2 km value)
%   The receive antenna gain is 0 dBi: no radar antenna yet.
%
%   The result is checked against an independent calculation: the exact
%   distribution of the sum, from convolving the three input distributions
%   (sum_of_independent_db_rev1).
%
%   Writes docs/results/single_bs_100km_2700mhz.csv and
%   docs/figures/fig04_single_bs_100km_2700mhz.png.
%
%   Name-value options:
%     n_draws    Monte Carlo draws (100000)
%     seed       Random stream seed (2700)
%     h_tx_m     Base station antenna height, m (30)
%     h_rx_m     Receiver antenna height, m (10)
%     save_out   Write the CSV and PNG (true)
%     out_root   Repository root (folder above examples/)
%
%   See also example_01_p2108_2km_2700mhz_rev1, example_02_bs_eirp_distribution_rev1,
%   example_03_itm_flat_100km_2700mhz_rev1, draw_uniform_columns_rev1.

arguments
    options.n_draws (1,1) double {mustBeInteger, mustBePositive} = 1e5
    options.seed (1,1) double {mustBeInteger, mustBeNonnegative} = 2700
    options.h_tx_m (1,1) double {mustBePositive} = 30
    options.h_rx_m (1,1) double {mustBePositive} = 10
    options.save_out (1,1) logical = true
    options.out_root (1,1) string = fileparts(fileparts(mfilename("fullpath")))
end

if isempty(which("itm_p2p_rev1"))
    error("aggregate_explainer:NoItm", ...
        "itm_p2p_rev1 is not on the path. Run setup_aggregate_explainer_rev1 first.");
end

freq_mhz = 2700;
dist_km = 100;
step_m = 100;

% --- The three inverse CDFs (percentage in, dB value out) ---
eirp_table = read_bs_eirp_distribution_rev1(fullfile(options.out_root, "data", "7Ghz 0azi 0ele EIRP.xlsx"));
eirp_q = @(p) interp1(eirp_table.percentile, eirp_table.eirp_db, p, "spline");

n_intervals = round(dist_km*1000/step_m);
pfl = [n_intervals, step_m, zeros(1, n_intervals + 1)];
path_q = @(p) reshape(itm_p2p_rev1(options.h_tx_m, options.h_rx_m, pfl, freq_mhz, p, ...
    validity="off"), size(p));

clutter_q = @(p) reshape(p2108_terrestrial_clutter_loss_vector_rev2([], freq_mhz, dist_km, p), size(p));

% --- Monte Carlo: three independent uniform draws per trial ---
u = draw_uniform_columns_rev1(options.n_draws, 3, options.seed);
eirp_dbm = eirp_q(100*u(:, 1));
path_db = path_q(100*u(:, 2));
clutter_db = clutter_q(100*u(:, 3));
prx_dbm = eirp_dbm - path_db - clutter_db;

% --- Summaries ---
pct = [1 5 10 25 50 75 80 90 95 99]';
prx_mc = prctile(prx_dbm, pct);

[x_grid, cdf] = sum_of_independent_db_rev1({eirp_q, path_q, clutter_q}, [1 -1 -1]);
[cdf_u, iu] = unique(cdf);
prx_conv = interp1(cdf_u, x_grid(iu), pct/100, "linear");

median_of_terms_dbm = eirp_q(50) - path_q(50) - clutter_q(50);

tbl = table(pct, prx_mc(:), prx_conv(:), prx_mc(:) - prx_conv(:), ...
    VariableNames=["percentile", "monte_carlo_dbm", "convolution_dbm", "difference_db"]);

term_names = ["EIRP"; "Path loss (ITM)"; "Clutter loss (P.2108)"];
term_var = [var(eirp_dbm); var(path_db); var(clutter_db)];
spread = table(term_names, sqrt(term_var), 100*term_var/var(prx_dbm), ...
    VariableNames=["term", "std_db", "share_of_variance_pct"]);

fprintf("One base station, %g km, %.1f GHz, %d draws\n", dist_km, freq_mhz/1000, options.n_draws);
fprintf("  sum of the three medians : %.2f dBm\n", median_of_terms_dbm);
fprintf("  median of the sum        : %.2f dBm\n", prx_mc(pct == 50));
fprintf("  mean of the sum          : %.2f dBm\n", mean(prx_dbm));
disp(tbl);
disp(spread);

% --- Figure ---
fig = local_figure(eirp_dbm, path_db, clutter_db, prx_dbm, median_of_terms_dbm, pct, prx_mc, ...
    x_grid, cdf, dist_km, freq_mhz);

results = struct("u", u, "eirp_dbm", eirp_dbm, "path_db", path_db, "clutter_db", clutter_db, ...
    "prx_dbm", prx_dbm, "median_of_terms_dbm", median_of_terms_dbm, "table", tbl, ...
    "spread", spread, "conv_x_dbm", x_grid, "conv_cdf", cdf, "figure", fig);

if options.save_out
    for out_folder = fullfile(options.out_root, "docs", ["results", "figures"])
        if ~isfolder(out_folder), mkdir(out_folder); end
    end
    writetable(tbl, fullfile(options.out_root, "docs", "results", "single_bs_100km_2700mhz.csv"));
    writetable(spread, fullfile(options.out_root, "docs", "results", "single_bs_100km_2700mhz_spread.csv"));
    exportgraphics(fig, fullfile(options.out_root, "docs", "figures", "fig04_single_bs_100km_2700mhz.png"), Resolution=200);
end
end

function fig = local_figure(eirp_dbm, path_db, clutter_db, prx_dbm, median_of_terms_dbm, pct, prx_mc, ...
    x_grid, cdf, dist_km, freq_mhz)
% Row 1: the three input distributions. Row 2: the output.
fig = figure(Color="w", Position=[100 100 1200 700]);
if ~isMATLABReleaseOlderThan("R2025a")
    theme(fig, "light");
end
t = tiledlayout(fig, 2, 3, TileSpacing="compact", Padding="compact");
title(t, sprintf("One base station at %g km, %.1f GHz: P_{rx} = EIRP - L_{path} - L_{clutter}", ...
    dist_km, freq_mhz/1000), FontWeight="bold");
subtitle(t, "DRAFT//PRE-DECISIONAL");

blue = [0.35 0.55 0.80];
orange = [0.85 0.33 0.10];

inputs = {eirp_dbm, path_db, clutter_db};
labels = ["EIRP (dBm)", "Path loss, ITM (dB)", "Clutter loss, P.2108 (dB)"];
heads = ["Input 1: EIRP", "Input 2: path loss", "Input 3: clutter loss"];
for k = 1:3
    ax = nexttile(t);
    histogram(ax, inputs{k}, 60, Normalization="pdf", FaceColor=blue);
    xline(ax, median(inputs{k}), "-", sprintf("median %.1f", median(inputs{k})), ...
        LabelVerticalAlignment="top", LineWidth=1.2);
    xlabel(ax, labels(k));
    ylabel(ax, "Probability density");
    title(ax, heads(k));
    grid(ax, "on");
end

ax = nexttile(t, [1 2]);
histogram(ax, prx_dbm, 80, Normalization="pdf", FaceColor=orange);
hold(ax, "on");
mark = [50 95 99];
for m = mark
    v = prx_mc(pct == m);
    xline(ax, v, "--", sprintf("%dth %.1f dBm", m, v), LabelVerticalAlignment="top", LineWidth=1.2);
end
hold(ax, "off");
xlabel(ax, "Received power P_{rx} (dBm), 0 dBi receive antenna");
ylabel(ax, "Probability density");
title(ax, "Output: received power from one base station");
grid(ax, "on");

ax = nexttile(t);
plot(ax, sort(prx_dbm), (1:numel(prx_dbm))'/numel(prx_dbm)*100, "-", LineWidth=2.5, Color=orange);
hold(ax, "on");
plot(ax, x_grid, 100*cdf, "k:", LineWidth=1.5);
xline(ax, median_of_terms_dbm, "-", "sum of medians", LabelVerticalAlignment="middle", ...
    HandleVisibility="off");
hold(ax, "off");
xlabel(ax, "P_{rx} (dBm)");
ylabel(ax, "Percentage not exceeded (%)");
title(ax, "CDF: Monte Carlo vs. convolution");
legend(ax, ["Monte Carlo", "Convolution (exact)"], Location="northwest");
xlim(ax, prctile(prx_dbm, [0.1 99.9]));
grid(ax, "on");
end
