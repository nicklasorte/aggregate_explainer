function results = example_06_itm_vs_distance_rev1(options)
%EXAMPLE_06_ITM_VS_DISTANCE_REV1 How the ITM path loss distribution changes from 1 km to 200 km.
%   results = EXAMPLE_06_ITM_VS_DISTANCE_REV1() runs ITM v1.4
%   point-to-point over flat terrain at 2.7 GHz for every whole distance
%   from 1 km to 200 km. At each distance only the time percentage
%   (reliability) changes, from 0.01 % to 99.99 %; everything else is fixed
%   (TX 30 m, RX 10 m, confidence 50 %, the itm_p2p_rev1 defaults). It
%   reports, for each distance:
%     - the loss at the 1st, 5th, 10th, 25th, 50th, 75th, 90th, 95th, and
%       99th percentiles of time,
%     - the spread (5 % to 95 % and 1 % to 99 %),
%     - free-space loss and ITM's propagation mode.
%
%   Writes docs/results/itm_vs_distance_2700mhz.csv and
%   docs/figures/fig07_itm_vs_distance_2700mhz.png.
%
%   Name-value options:
%     dist_km    Distances, km (1:200)
%     h_tx_m     TX antenna height, m (30)
%     h_rx_m     RX antenna height, m (10)
%     step_m     Profile point spacing, m (100)
%     save_out   Write the CSV and PNG (true)
%     out_root   Repository root (folder above examples/)
%
%   Needs matlab_itm on the path.
%
%   See also itm_p2p_rev1, example_03_itm_flat_100km_2700mhz_rev1.

arguments
    options.dist_km (1,:) double {mustBeInRange(options.dist_km, 1, 2000)} = 1:200
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
pct = [1 5 10 25 50 75 90 95 99];
n_d = numel(options.dist_km);
loss = zeros(n_d, numel(pct));
free_space = zeros(n_d, 1);
mode = strings(n_d, 1);
for k = 1:n_d
    n_intervals = max(round(options.dist_km(k)*1000/options.step_m), 2);
    step = options.dist_km(k)*1000/n_intervals;
    pfl = [n_intervals, step, zeros(1, n_intervals + 1)];
    % validity "off": no caution warnings for tail percentages; hard limits still apply.
    [a, info] = itm_p2p_rev1(options.h_tx_m, options.h_rx_m, pfl, freq_mhz, pct, validity="off");
    loss(k, :) = a;
    free_space(k) = info.A_fs_db;
    mode(k) = string(info.mode_name);
end

names = "p" + compose("%02d", pct) + "_db";
tbl = [table(options.dist_km(:), mode, free_space, VariableNames=["distance_km", "mode", "free_space_db"]), ...
    array2table(loss, VariableNames=names)];
tbl.spread_5_95_db = loss(:, pct == 95) - loss(:, pct == 5);
tbl.spread_1_99_db = loss(:, pct == 99) - loss(:, pct == 1);

% Where the propagation mode changes
change = [true; mode(2:end) ~= mode(1:end-1)];
modes = table(tbl.distance_km(change), mode(change), VariableNames=["from_km", "mode"]);

fprintf("ITM v1.4, flat terrain, %.1f GHz, TX %g m, RX %g m, confidence 50%%\n", ...
    freq_mhz/1000, options.h_tx_m, options.h_rx_m);
disp(modes);
show = ismember(tbl.distance_km, [1 10 25 50 100 150 200]);
disp(tbl(show, ["distance_km", "mode", "free_space_db", "p01_db", "p50_db", "p99_db", ...
    "spread_5_95_db", "spread_1_99_db"]));

fig = local_figure(tbl, modes, freq_mhz);

[~, k_peak] = max(tbl.spread_1_99_db);
results = struct("table", tbl, "modes", modes, "peak_spread_km", tbl.distance_km(k_peak), "figure", fig);

if options.save_out
    for out_folder = fullfile(options.out_root, "docs", ["results", "figures"])
        if ~isfolder(out_folder), mkdir(out_folder); end
    end
    writetable(tbl, fullfile(options.out_root, "docs", "results", "itm_vs_distance_2700mhz.csv"));
    exportgraphics(fig, fullfile(options.out_root, "docs", "figures", "fig07_itm_vs_distance_2700mhz.png"), Resolution=300);
end
end

function fig = local_figure(tbl, modes, freq_mhz)
c = figure_palette_rev1();
fig = figure(Color="w", Units="inches", Position=[1 1 6.5 3.4]);
if ~isMATLABReleaseOlderThan("R2025a")
    theme(fig, "light");
end
t = tiledlayout(fig, 1, 5, TileSpacing="loose", Padding="compact");
d = tbl.distance_km;
col = @(p) tbl.("p" + compose("%02d", p) + "_db");

% Left: fan chart of loss against distance
ax = nexttile(t, [1 3]);
hold(ax, "on");
fill(ax, [d; flipud(d)], [col(1); flipud(col(99))], c.light_blue, FaceAlpha=0.15, EdgeColor="none");
fill(ax, [d; flipud(d)], [col(5); flipud(col(95))], c.light_blue, FaceAlpha=0.25, EdgeColor="none");
fill(ax, [d; flipud(d)], [col(25); flipud(col(75))], c.light_blue, FaceAlpha=0.45, EdgeColor="none");
plot(ax, d, col(50), "-", Color=c.dark_blue, LineWidth=1.6);
plot(ax, d, tbl.free_space_db, "--", Color=c.mid_gray, LineWidth=1);
for k = 2:height(modes)
    xline(ax, modes.from_km(k), ":", Color=c.mid_gray, LineWidth=0.8);
end
hold(ax, "off");
style_axes_rev1(ax);
ax.YDir = "reverse";                       % more loss lower down: weaker signal
xlim(ax, [0 max(d)]);
xlabel(ax, "Distance (km)");
ylabel(ax, "Basic transmission loss (dB)");
title(ax, "Loss by percentage of time");
y_lim = ylim(ax);
x_lab = max(d)*0.98;
p50 = col(50); p01 = col(1); p99 = col(99);
text(ax, x_lab, p50(end), "median ", FontName=c.font, FontSize=7.5, Color=c.dark_blue, ...
    HorizontalAlignment="right", VerticalAlignment="bottom", FontWeight="bold");
text(ax, x_lab, tbl.free_space_db(end), "free space ", FontName=c.font, FontSize=7.5, ...
    Color=c.dark_blue, HorizontalAlignment="right", VerticalAlignment="bottom");
text(ax, x_lab, p01(end), "1% of time ", FontName=c.font, FontSize=7.5, Color=c.dark_blue, ...
    HorizontalAlignment="right", VerticalAlignment="bottom");
text(ax, x_lab, p99(end), "99% of time ", FontName=c.font, FontSize=7.5, Color=c.dark_blue, ...
    HorizontalAlignment="right", VerticalAlignment="top");
for k = 1:height(modes)
    x_end = max(d);
    if k < height(modes), x_end = modes.from_km(k + 1); end
    text(ax, (modes.from_km(k) + x_end)/2, y_lim(1) + 0.03*range(y_lim), local_short_mode(modes.mode(k)), ...
        FontName=c.font, FontSize=7, Color=c.dark_blue, HorizontalAlignment="center", VerticalAlignment="top");
end

% Right: spread against distance
ax = nexttile(t, [1 2]);
hold(ax, "on");
plot(ax, d, tbl.spread_1_99_db, "-", Color=c.mid_gray, LineWidth=1.4);
plot(ax, d, tbl.spread_5_95_db, "-", Color=c.light_blue, LineWidth=2.2);
for k = 2:height(modes)
    xline(ax, modes.from_km(k), ":", Color=c.mid_gray, LineWidth=0.8);
end
hold(ax, "off");
style_axes_rev1(ax);
xlim(ax, [0 max(d)]);
ylim(ax, [0 ceil(max(tbl.spread_1_99_db)/10)*10 + 5]);
xlabel(ax, "Distance (km)");
ylabel(ax, "Spread (dB)");
title(ax, "Spread over time");
text(ax, max(d)*0.98, tbl.spread_1_99_db(end), "1% to 99% ", FontName=c.font, FontSize=7.5, ...
    Color=c.dark_blue, HorizontalAlignment="right", VerticalAlignment="bottom");
text(ax, max(d)*0.98, tbl.spread_5_95_db(end), "5% to 95% ", FontName=c.font, FontSize=7.5, ...
    Color=c.light_blue, FontWeight="bold", HorizontalAlignment="right", VerticalAlignment="top");

near = tbl(find(d >= 10, 1), :);
[~, k_peak] = max(tbl.spread_1_99_db);
peak = tbl(k_peak, :);
add_figure_text_rev1(fig, t, ...
    Headline=sprintf("Past the radio horizon, the 1%%-99%% range of path loss grows from %.1f dB (%g km) to %.0f dB (%g km)", ...
        near.spread_1_99_db, near.distance_km, peak.spread_1_99_db, peak.distance_km), ...
    Subhead=sprintf("ITM v1.4 point-to-point, flat terrain, %.1f GHz, TX 30 m, RX 10 m, confidence 50%%; bands: 1%%-99%%, 5%%-95%%, 25%%-75%% of time", ...
        freq_mhz/1000), ...
    Source="Source: NTIA/ITS Irregular Terrain Model v1.4 (matlab_itm port); aggregate_explainer example 06.");
end

function s = local_short_mode(m)
% Short label for an ITM propagation mode name.
s = m;
if contains(lower(m), "line")
    s = "line of sight";
elseif contains(lower(m), "diffraction")
    s = "diffraction";
elseif contains(lower(m), "scatter")
    s = "troposcatter";
end
end
