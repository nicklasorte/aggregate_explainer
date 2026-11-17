function results = example_05_spread_rev1(options)
%EXAMPLE_05_SPREAD_REV1 Where the spread of received power comes from, one base station at 100 km.
%   results = EXAMPLE_05_SPREAD_REV1() uses the draws of example 04 and
%   asks how wide the received-power distribution would be if one input
%   didn't vary. For each input it holds that input at its median, keeps
%   the other two random, and records the percentiles of
%   P_rx = EIRP - L_path - L_clutter. It also reports:
%     - each input's share of the output variance (independent terms in dB:
%       variances add), and
%     - the "worst-case stack": the 99th percentile EIRP, the 1st percentile
%       path loss, and the 1st percentile clutter loss added together.
%
%   Writes docs/results/single_bs_100km_spread.csv and
%   docs/figures/fig05_single_bs_100km_spread.png.
%
%   Name-value options:
%     n_draws    Monte Carlo draws (100000)
%     seed       Random stream seed (2700, the same draws as example 04)
%     save_out   Write the CSV and PNG (true)
%     out_root   Repository root (folder above examples/)
%
%   See also example_04_single_bs_100km_rev2, single_bs_inputs_rev1.

arguments
    options.n_draws (1,1) double {mustBeInteger, mustBePositive} = 1e5
    options.seed (1,1) double {mustBeInteger, mustBeNonnegative} = 2700
    options.save_out (1,1) logical = true
    options.out_root (1,1) string = fileparts(fileparts(mfilename("fullpath")))
end

in = single_bs_inputs_rev1(repo_root=options.out_root);
u = draw_uniform_columns_rev1(options.n_draws, 3, options.seed);
q = {in.eirp_q, in.path_q, in.clutter_q};

terms = zeros(options.n_draws, 3);
medians = zeros(1, 3);
for k = 1:3
    terms(:, k) = in.signs(k) * q{k}(100*u(:, k));
    medians(k) = in.signs(k) * q{k}(50);
end

% Scenario 1: everything varies. Scenarios 2-4: one input held at its median.
scenario = ["All three vary", "EIRP held at median", "Path loss held at median", ...
    "Clutter loss held at median"]';
pct = [1 5 50 95 99];
p = zeros(4, numel(pct));
sd = zeros(4, 1);
for s = 1:4
    x = terms;
    if s > 1
        x(:, s - 1) = medians(s - 1);
    end
    prx = sum(x, 2);
    p(s, :) = prctile(prx, pct);
    sd(s) = std(prx);
end
range_5_95 = p(:, 4) - p(:, 2);
range_1_99 = p(:, 5) - p(:, 1);

tbl = table(scenario, p(:, 1), p(:, 2), p(:, 3), p(:, 4), p(:, 5), range_5_95, range_1_99, sd, ...
    VariableNames=["scenario", "p01_dbm", "p05_dbm", "p50_dbm", "p95_dbm", "p99_dbm", ...
    "range_5_95_db", "range_1_99_db", "std_db"]);

term_var = var(terms);
share = table(in.names', sqrt(term_var'), 100*term_var'/var(sum(terms, 2)), ...
    VariableNames=["input", "std_db", "share_of_variance_pct"]);

worst_stack_dbm = in.eirp_q(99) - in.path_q(1) - in.clutter_q(1);
p99_all = p(1, 5);

fprintf("Spread of received power, one base station at 100 km\n");
disp(tbl);
disp(share);
fprintf("  worst-case stack (99th EIRP, 1st path loss, 1st clutter): %.1f dBm\n", worst_stack_dbm);
fprintf("  99th percentile of the sum: %.1f dBm (%.1f dB lower)\n", p99_all, worst_stack_dbm - p99_all);

fig = local_figure(tbl, share, worst_stack_dbm);

results = struct("table", tbl, "share", share, "worst_stack_dbm", worst_stack_dbm, ...
    "p99_dbm", p99_all, "figure", fig);

if options.save_out
    for out_folder = fullfile(options.out_root, "docs", ["results", "figures"])
        if ~isfolder(out_folder), mkdir(out_folder); end
    end
    writetable(tbl, fullfile(options.out_root, "docs", "results", "single_bs_100km_spread.csv"));
    writetable(share, fullfile(options.out_root, "docs", "results", "single_bs_100km_variance_share.csv"));
    exportgraphics(fig, fullfile(options.out_root, "docs", "figures", "fig05_single_bs_100km_spread.png"), Resolution=300);
end
end

function fig = local_figure(tbl, share, worst_stack_dbm)
c = figure_palette_rev1();
fig = figure(Color="w", Units="inches", Position=[1 1 6.5 3.3]);
if ~isMATLABReleaseOlderThan("R2025a")
    theme(fig, "light");
end
t = tiledlayout(fig, 1, 5, TileSpacing="loose", Padding="compact");

% Left: range bars, one row per scenario
ax = nexttile(t, [1 3]);
n = height(tbl);
y = n:-1:1;
hold(ax, "on");
for s = 1:n
    col = c.mid_gray;
    if s == 1, col = c.light_blue; end
    if s == 3, col = c.dark_blue; end
    plot(ax, [tbl.p01_dbm(s) tbl.p99_dbm(s)], [y(s) y(s)], "-", Color=col, LineWidth=1.2);
    plot(ax, [tbl.p05_dbm(s) tbl.p95_dbm(s)], [y(s) y(s)], "-", Color=col, LineWidth=6);
    plot(ax, tbl.p50_dbm(s), y(s), "o", MarkerSize=5, MarkerFaceColor="w", MarkerEdgeColor=col, LineWidth=1.2);
    text(ax, tbl.p99_dbm(s) + 1, y(s), sprintf("%.0f dB", tbl.range_5_95_db(s)), FontName=c.font, ...
        FontSize=8, Color=c.dark_blue, FontWeight=string(ifelse(s == 1 || s == 3, "bold", "normal")), ...
        VerticalAlignment="middle");
end
plot(ax, worst_stack_dbm, y(1), "d", MarkerSize=6, MarkerFaceColor=c.purple, MarkerEdgeColor="none");
text(ax, worst_stack_dbm, y(1) + 0.32, "worst-case stack", FontName=c.font, FontSize=7.5, ...
    Color=c.purple, FontWeight="bold", HorizontalAlignment="center", VerticalAlignment="bottom");
hold(ax, "off");
style_axes_rev1(ax, YGrid=false, XGrid=true);
ax.YTick = fliplr(y);
ax.YTickLabel = flipud(tbl.scenario);
ylim(ax, [0.4 n + 0.75]);
xlim(ax, [floor(min(tbl.p01_dbm)/5)*5, max(worst_stack_dbm, max(tbl.p99_dbm)) + 9]);
xlabel(ax, "Received power (dBm)");
title(ax, "Thick bar: 5% to 95% of draws; thin: 1% to 99%");

% Right: variance share, sorted
ax = nexttile(t, [1 2]);
[v, order] = sort(share.share_of_variance_pct, "ascend");
names = share.input(order);
b = barh(ax, 1:numel(v), v, 0.6, FaceColor="flat", EdgeColor="none");
b.CData = repmat(c.mid_gray, numel(v), 1);
b.CData(names == "Path loss", :) = c.dark_blue;
for k = 1:numel(v)
    text(ax, v(k) + 2, k, sprintf("%.0f%%", v(k)), FontName=c.font, FontSize=8, ...
        Color=c.dark_blue, VerticalAlignment="middle", ...
        FontWeight=string(ifelse(names(k) == "Path loss", "bold", "normal")));
end
style_axes_rev1(ax, YGrid=false);
ax.YAxis(1).Color = c.mid_gray;
ax.YAxis(1).TickLabelColor = c.dark_blue;
ax.XAxis.Color = "none";
ax.XTick = [];
ax.YTick = 1:numel(v);
ax.YTickLabel = names;
xlim(ax, [0 max(v)*1.3]);
title(ax, "Share of the variance");

all_row = tbl(1, :);
pl_row = tbl(3, :);
add_figure_text_rev1(fig, t, ...
    Headline=sprintf("Path loss drives the spread: fixing it narrows the middle 90%% from %.0f dB to %.0f dB", ...
        all_row.range_5_95_db, pl_row.range_5_95_db), ...
    Subhead="Received power from one base station at 100 km, 2.7 GHz, with each input in turn held at its median", ...
    Source="Source: aggregate_explainer example 05 (same 100,000 draws as example 04).");
end

function out = ifelse(cond, a, b)
if cond, out = a; else, out = b; end
end
