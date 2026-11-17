function results = example_07_turn_off_list_toy_rev1(options)
%EXAMPLE_07_TURN_OFF_LIST_TOY_REV1 A worked turn-off list with ten base stations.
%   results = EXAMPLE_07_TURN_OFF_LIST_TOY_REV1() walks through the two
%   Monte Carlo simulations that size a turn-off list for one candidate
%   radius, with illustrative numbers small enough to follow by hand:
%
%     Inside the radius: six base stations, median received powers
%       -98, -100, -102, -104, -106, -108 dBm (already in median order).
%     Outside the radius: four base stations, -110, -112, -114, -116 dBm.
%       They can't be turned off, but they count in the validation run.
%     Each station's received power varies around its median by a normal
%       distribution in dB with a 5 dB standard deviation (a stand-in for the
%       combined EIRP, path loss, and clutter loss draws of examples 01-06).
%     Limit on the aggregate: -99 dBm.
%
%   Simulation 1 (build the list): order the inside stations once, by
%   median power. In each of 1,000 trials, redraw every station's power and
%   walk down the fixed order until the remaining stations meet the limit.
%   That trial's cut point is its list size. Take the 80th percentile of the
%   1,000 sizes, round up, and add one station as a margin (as the
%   production code does).
%
%   Simulation 2 (validate): with that list off, redraw all stations, inside
%   and outside, 1,000 times and check whether the 80th percentile of the
%   aggregate meets the limit.
%
%   For comparison it also computes, for every trial of simulation 1, the
%   smallest list that trial could use if it were free to choose its own
%   stations.
%
%   Writes docs/results/turn_off_toy_*.csv and
%   docs/figures/fig08_turn_off_list_toy.png.
%
%   Name-value options:
%     n_trials     Trials in each simulation (1000, as in production)
%     percentile   Monte Carlo percentile (80)
%     sigma_db     Spread of each station's power, dB (5)
%     limit_dbm    Limit on the aggregate, dBm (-99)
%     seed         Random stream seed (1)
%     save_out     Write the CSVs and PNG (true)
%     out_root     Repository root (folder above examples/)
%
%   See also draw_uniform_columns_rev1, norminv.

arguments
    options.n_trials (1,1) double {mustBeInteger, mustBePositive} = 1000
    options.percentile (1,1) double {mustBeInRange(options.percentile, 0, 100, "exclusive")} = 80
    options.sigma_db (1,1) double {mustBePositive} = 5
    options.limit_dbm (1,1) double = -99
    options.seed (1,1) double {mustBeInteger, mustBeNonnegative} = 1
    options.save_out (1,1) logical = true
    options.out_root (1,1) string = fileparts(fileparts(mfilename("fullpath")))
end

inside_dbm = [-98 -100 -102 -104 -106 -108];
outside_dbm = [-110 -112 -114 -116];
n_in = numel(inside_dbm);
n_out = numel(outside_dbm);
n = options.n_trials;

% One substream per station per simulation: columns 1-6 for simulation 1,
% columns 7-16 for simulation 2. Inverse transform: u -> normal offset in dB.
u = draw_uniform_columns_rev1(n, 2*n_in + n_out, options.seed);
offset_db = options.sigma_db * norminv(u);

% --- Simulation 1: fixed median order, one cut point per trial ---
p1 = inside_dbm + offset_db(:, 1:n_in);                 % n-by-6, columns in median order
size_fixed = local_cut_points(p1, options.limit_dbm);
size_free = local_cut_points(sort(p1, 2, "descend"), options.limit_dbm);
q_size = ceil(prctile(size_fixed, options.percentile));
list_size = min(q_size + 1, n_in);                      % production adds one station

% --- Simulation 2: validation with the list applied ---
p2_in = inside_dbm + offset_db(:, n_in + (1:n_in));
p2_out = outside_dbm + offset_db(:, 2*n_in + (1:n_out));
remaining = [p2_in(:, list_size+1:end), p2_out];
agg_dbm = 10*log10(sum(10.^(remaining/10), 2));
q_agg = prctile(agg_dbm, options.percentile);
passes = q_agg <= options.limit_dbm;

% --- Tables ---
k = (0:n_in)';
size_dist = table(k, 100*histcounts(size_fixed, -0.5:1:n_in + 0.5)'/n, ...
    100*histcounts(size_free, -0.5:1:n_in + 0.5)'/n, ...
    VariableNames=["stations_off", "fixed_order_pct", "free_choice_pct"]);
first = table((1:3)', round(p1(1:3, :), 1), size_fixed(1:3), ...
    VariableNames=["trial", "power_by_median_rank_dbm", "stations_off"]);
summary = table(options.percentile, q_size, list_size, q_agg, options.limit_dbm, passes, ...
    100*mean(agg_dbm <= options.limit_dbm), mean(size_fixed), mean(size_free), ...
    VariableNames=["percentile", "percentile_of_sizes", "list_size", "validation_aggregate_dbm", ...
    "limit_dbm", "passes", "trials_meeting_limit_pct", "mean_size_fixed", "mean_size_free"]);

fprintf("Turn-off list, toy example: 6 stations inside, 4 outside, limit %g dBm\n", options.limit_dbm);
disp(first);
disp(size_dist);
disp(summary);

fig = local_figure(size_dist, size_fixed, q_size, list_size, agg_dbm, q_agg, options);

results = struct("size_fixed", size_fixed, "size_free", size_free, "list_size", list_size, ...
    "q_size", q_size, "agg_dbm", agg_dbm, "q_agg", q_agg, "passes", passes, ...
    "size_dist", size_dist, "first_trials", first, "summary", summary, "figure", fig);

if options.save_out
    for out_folder = fullfile(options.out_root, "docs", ["results", "figures"])
        if ~isfolder(out_folder), mkdir(out_folder); end
    end
    writetable(size_dist, fullfile(options.out_root, "docs", "results", "turn_off_toy_list_sizes.csv"));
    writetable(splitvars(first), fullfile(options.out_root, "docs", "results", "turn_off_toy_first_trials.csv"));
    writetable(summary, fullfile(options.out_root, "docs", "results", "turn_off_toy_summary.csv"));
    exportgraphics(fig, fullfile(options.out_root, "docs", "figures", "fig08_turn_off_list_toy.png"), Resolution=300);
end
end

function k = local_cut_points(p_dbm, limit_dbm)
% Smallest k such that the stations after the first k meet the limit.
% p_dbm is trials-by-stations, columns in removal order.
lin = 10.^(p_dbm/10);
tail = cumsum(lin, 2, "reverse");                 % tail(:, j) = sum of stations j..end
remaining = [tail, zeros(size(lin, 1), 1)];       % column k+1: after removing the first k
meets = 10*log10(remaining) <= limit_dbm;
[~, first_ok] = max(meets, [], 2);                % first column that meets the limit
k = first_ok - 1;
end

function fig = local_figure(size_dist, size_fixed, q_size, list_size, agg_dbm, q_agg, opt)
c = figure_palette_rev1();
fig = figure(Color="w", Units="inches", Position=[1 1 6.5 3.3]);
if ~isMATLABReleaseOlderThan("R2025a")
    theme(fig, "light");
end
t = tiledlayout(fig, 1, 2, TileSpacing="loose", Padding="compact");

% Left: how many stations each trial needed off
ax = nexttile(t);
b = bar(ax, size_dist.stations_off, size_dist.fixed_order_pct, 0.7, FaceColor="flat", EdgeColor="none");
b.CData = repmat(c.mid_gray, height(size_dist), 1);
b.CData(size_dist.stations_off == q_size, :) = c.light_blue;
hold(ax, "on");
plot(ax, size_dist.stations_off, size_dist.free_choice_pct, "o-", Color=c.dark_blue, ...
    MarkerFaceColor="w", MarkerSize=3.5, LineWidth=1);
hold(ax, "off");
style_axes_rev1(ax);
xlabel(ax, "Stations off in that trial");
ylabel(ax, "Share of trials (%)");
title(ax, "Simulation 1: one list size per trial");
ax.XTick = size_dist.stations_off;
% Label to the right of the highlighted bar, clear of the free-choice line.
text(ax, q_size - 0.25, size_dist.fixed_order_pct(size_dist.stations_off == q_size) + 3, ...
    sprintf("%dth percentile: %d", opt.percentile, q_size), FontName=c.font, FontSize=7.5, ...
    Color=c.light_blue, FontWeight="bold", HorizontalAlignment="left", VerticalAlignment="bottom");
y_free = size_dist.free_choice_pct;
[~, k_free] = max(y_free);
text(ax, size_dist.stations_off(k_free) - 0.35, y_free(k_free), "free choice ", FontName=c.font, ...
    FontSize=7.5, Color=c.dark_blue, HorizontalAlignment="right", VerticalAlignment="middle");
ylim(ax, [0 max([size_dist.fixed_order_pct; y_free])*1.25]);
text(ax, 0.02, 0.97, sprintf("mean: %.2f fixed order, %.2f free choice", mean(size_fixed), ...
    sum(size_dist.stations_off .* y_free)/100), Units="normalized", FontName=c.font, FontSize=7.5, ...
    Color=c.dark_blue, VerticalAlignment="top");

% Right: validation with the list applied
ax = nexttile(t);
x = sort(agg_dbm);
plot(ax, x, 100*(1:numel(x))'/numel(x), "-", Color=c.light_blue, LineWidth=2.2);
hold(ax, "on");
xline(ax, opt.limit_dbm, "-", Color=c.purple, LineWidth=1);
yline(ax, opt.percentile, ":", Color=c.mid_gray, LineWidth=1);
plot(ax, q_agg, opt.percentile, "o", MarkerSize=5, MarkerFaceColor=c.light_blue, MarkerEdgeColor="none");
hold(ax, "off");
style_axes_rev1(ax, XGrid=true);
xlabel(ax, "Aggregate with the list off (dBm)");
ylabel(ax, "Trials not exceeding (%)");
title(ax, sprintf("Simulation 2: %d off, everyone else on", list_size));
text(ax, opt.limit_dbm, 8, sprintf(" limit %g dBm", opt.limit_dbm), FontName=c.font, FontSize=7.5, ...
    Color=c.purple, FontWeight="bold");
text(ax, q_agg, opt.percentile, sprintf("%dth: %.1f dBm ", opt.percentile, q_agg), FontName=c.font, ...
    FontSize=7.5, Color=c.dark_blue, HorizontalAlignment="right", VerticalAlignment="bottom");
ylim(ax, [0 100]);

verdict = "passes";
if q_agg > opt.limit_dbm, verdict = "fails"; end
add_figure_text_rev1(fig, t, ...
    Headline=sprintf("The %dth percentile of trial list sizes, plus one, sets the list; with it off, the radius %s", ...
        opt.percentile, verdict), ...
    Subhead=sprintf("Illustrative: 6 base stations inside the radius, 4 outside, %g dB spread, limit %g dBm, %s trials per simulation", ...
        opt.sigma_db, opt.limit_dbm, format_thousands_rev1(opt.n_trials)), ...
    Source="Source: aggregate_explainer example 07 (illustrative numbers).");
end
