function results = example_04_single_bs_100km_rev2(options)
%EXAMPLE_04_SINGLE_BS_100KM_REV2 Monte Carlo of one base station 100 km from the receiver, 2.7 GHz.
%   results = EXAMPLE_04_SINGLE_BS_100KM_REV2() combines the three inputs
%   into the power received from one base station:
%
%     P_rx (dBm) = EIRP - L_path - L_clutter
%
%   Each Monte Carlo draw takes three independent uniform draws, one per
%   input (draw_uniform_columns_rev1), maps each through its inverse CDF
%   (single_bs_inputs_rev1), and adds the results in dB. The receive
%   antenna gain is 0 dBi.
%
%   Two checks:
%     - the exact distribution of the sum, from convolving the three input
%       distributions (sum_of_independent_db_rev1), and
%     - the same draws with EIRP from the spline that FSS_Neighborhood uses
%       instead of the fitted normal distribution.
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
%   Changes from rev1: EIRP from the fitted normal distribution instead of
%   the spline; spread analysis moved to example 05; NTIA report styling.
%
%   See also single_bs_inputs_rev1, example_05_spread_rev1.

arguments
    options.n_draws (1,1) double {mustBeInteger, mustBePositive} = 1e5
    options.seed (1,1) double {mustBeInteger, mustBeNonnegative} = 2700
    options.h_tx_m (1,1) double {mustBePositive} = 30
    options.h_rx_m (1,1) double {mustBePositive} = 10
    options.save_out (1,1) logical = true
    options.out_root (1,1) string = fileparts(fileparts(mfilename("fullpath")))
end

in = single_bs_inputs_rev1(h_tx_m=options.h_tx_m, h_rx_m=options.h_rx_m, repo_root=options.out_root);

% --- Monte Carlo: three independent uniform draws per trial ---
u = draw_uniform_columns_rev1(options.n_draws, 3, options.seed);
eirp_dbm = in.eirp_q(100*u(:, 1));
path_db = in.path_q(100*u(:, 2));
clutter_db = in.clutter_q(100*u(:, 3));
prx_dbm = eirp_dbm - path_db - clutter_db;

% Same draws, EIRP from the spline through the table (production method)
eirp_spline_dbm = sample_from_percentile_table_rev1(in.eirp_table.percentile, ...
    in.eirp_table.eirp_db, u(:, 1), "spline");
prx_spline_dbm = eirp_spline_dbm - path_db - clutter_db;

% --- Summaries ---
pct = [1 5 10 25 50 75 80 90 95 99]';
prx_mc = prctile(prx_dbm, pct);
prx_spline = prctile(prx_spline_dbm, pct);

[x_grid, cdf] = sum_of_independent_db_rev1({in.eirp_q, in.path_q, in.clutter_q}, in.signs);
[cdf_u, iu] = unique(cdf);
prx_conv = interp1(cdf_u, x_grid(iu), pct/100, "linear");

median_of_terms_dbm = in.eirp_q(50) - in.path_q(50) - in.clutter_q(50);

tbl = table(pct, prx_mc(:), prx_conv(:), prx_mc(:) - prx_conv(:), prx_spline(:), ...
    VariableNames=["percentile", "monte_carlo_dbm", "convolution_dbm", "difference_db", ...
    "spline_eirp_dbm"]);

fprintf("One base station, 100 km, 2.7 GHz, %d draws\n", options.n_draws);
fprintf("  sum of the three medians : %.2f dBm\n", median_of_terms_dbm);
fprintf("  median of the sum        : %.2f dBm\n", prx_mc(pct == 50));
fprintf("  standard deviation       : %.2f dB\n", std(prx_dbm));
disp(tbl);

fig = local_figure(eirp_dbm, path_db, clutter_db, prx_dbm, pct, prx_mc, x_grid, cdf, options.n_draws);

results = struct("u", u, "eirp_dbm", eirp_dbm, "path_db", path_db, "clutter_db", clutter_db, ...
    "prx_dbm", prx_dbm, "prx_spline_dbm", prx_spline_dbm, ...
    "median_of_terms_dbm", median_of_terms_dbm, "table", tbl, ...
    "conv_x_dbm", x_grid, "conv_cdf", cdf, "figure", fig);

if options.save_out
    for out_folder = fullfile(options.out_root, "docs", ["results", "figures"])
        if ~isfolder(out_folder), mkdir(out_folder); end
    end
    writetable(tbl, fullfile(options.out_root, "docs", "results", "single_bs_100km_2700mhz.csv"));
    exportgraphics(fig, fullfile(options.out_root, "docs", "figures", "fig04_single_bs_100km_2700mhz.png"), Resolution=300);
end
end

function fig = local_figure(eirp_dbm, path_db, clutter_db, prx_dbm, pct, prx_mc, x_grid, cdf, n_draws)
% Row 1: the three inputs, small and gray. Row 2: the output, the hero.
c = figure_palette_rev1();
fig = figure(Color="w", Units="inches", Position=[1 1 6.5 4.9]);
if ~isMATLABReleaseOlderThan("R2025a")
    theme(fig, "light");
end
t = tiledlayout(fig, 2, 3, TileSpacing="loose", Padding="compact");

inputs = {eirp_dbm, path_db, clutter_db};
labels = ["EIRP (dBm)", "Path loss (dB)", "Clutter loss (dB)"];
heads = ["+ EIRP", char(8722) + " Path loss (ITM)", char(8722) + " Clutter loss (P.2108)"];
for k = 1:3
    ax = nexttile(t);
    x = inputs{k};
    [dens, xs] = ksdensity(x, linspace(prctile(x, 0.05), prctile(x, 99.95), 300));
    area(ax, xs, dens, FaceColor=c.mid_gray, FaceAlpha=0.35, EdgeColor=c.mid_gray, LineWidth=1.2);
    hold(ax, "on");
    xline(ax, median(x), "-", Color=c.dark_blue, LineWidth=0.8);
    text(ax, median(x), max(dens)*1.04, sprintf(" %.1f", median(x)), FontName=c.font, ...
        FontSize=8, Color=c.dark_blue, VerticalAlignment="bottom");
    hold(ax, "off");
    style_axes_rev1(ax);
    ax.YTickLabel = [];
    ylim(ax, [0 max(dens)*1.25]);
    xlabel(ax, labels(k));
    title(ax, heads(k));
end

ax = nexttile(t, [1 2]);
[dens, xs] = ksdensity(prx_dbm, linspace(prctile(prx_dbm, 0.05), prctile(prx_dbm, 99.95), 400));
area(ax, xs, dens, FaceColor=c.light_blue, FaceAlpha=0.35, EdgeColor=c.light_blue, LineWidth=1.6);
hold(ax, "on");
label_y = [1.04 0.62 0.36];             % stagger the labels down the right tail
marks = [50 95 99];
for k = 1:3
    v = prx_mc(pct == marks(k));
    xline(ax, v, ":", Color=c.dark_blue, LineWidth=1);
    align = "left";
    label = sprintf(" %dth: %.1f", marks(k), v);
    if marks(k) == 95                       % keep clear of the 99th-percentile line
        align = "right";
        label = sprintf("%dth: %.1f ", marks(k), v);
    end
    text(ax, v, max(dens)*label_y(k), label, FontName=c.font, FontSize=8, Color=c.dark_blue, ...
        FontWeight=string(ifelse(marks(k) == 50, "normal", "bold")), VerticalAlignment="bottom", ...
        HorizontalAlignment=align);
end
hold(ax, "off");
style_axes_rev1(ax);
ax.YTickLabel = [];
ylim(ax, [0 max(dens)*1.3]);
xlabel(ax, "Received power (dBm), 0 dBi receive antenna");
ax.XAxis.TickLabelFormat = "%g";
title(ax, "= Received power (dBm)");

ax = nexttile(t);
plot(ax, sort(prx_dbm), 100*(1:numel(prx_dbm))'/numel(prx_dbm), "-", LineWidth=3, Color=c.light_blue);
hold(ax, "on");
plot(ax, x_grid, 100*cdf, "-", LineWidth=0.9, Color=c.dark_blue);
hold(ax, "off");
style_axes_rev1(ax, XGrid=true);
xlim(ax, prctile(prx_dbm, [0.5 99.5]));
ylim(ax, [0 100]);
xlabel(ax, "Received power (dBm)");
ylabel(ax, "Not exceeded (%)");
title(ax, "Check: exact vs. draws");
text(ax, 0.04, 0.95, "Thick: draws", Units="normalized", FontName=c.font, FontSize=7.5, ...
    Color=c.light_blue, FontWeight="bold", VerticalAlignment="top");
text(ax, 0.04, 0.84, "Thin: exact", Units="normalized", FontName=c.font, FontSize=7.5, ...
    Color=c.dark_blue, VerticalAlignment="top");

add_figure_text_rev1(fig, t, ...
    Headline=sprintf("One base station at 100 km: received power spans %.0f dB from the 1%% to the 99%% draw", ...
        prx_mc(pct == 99) - prx_mc(pct == 1)), ...
    Subhead=sprintf("Received power = EIRP %s path loss %s clutter loss; 2.7 GHz, flat terrain, %s trials", ...
        char(8722), char(8722), format_thousands_rev1(n_draws)), ...
    Source="Source: CTIA EIRP table (fitted), ITM v1.4, ITU-R P.2108-1; aggregate_explainer example 04.");
end

function out = ifelse(cond, a, b)
if cond, out = a; else, out = b; end
end
