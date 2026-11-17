function results = example_00_uniform_input_rev1(options)
%EXAMPLE_00_UNIFORM_INPUT_REV1 Why every model input starts as a uniform random number.
%   results = EXAMPLE_00_UNIFORM_INPUT_REV1() splits the uniform draws into
%   10 equal slices (0-10 %, 10-20 %, ..., 90-100 %). Each slice holds one
%   tenth of the draws. It maps every slice through the P.2108-1 clutter
%   loss curve (2.7 GHz, 2 km) and shows that:
%     - the slices stay equally likely after the mapping, but
%     - they cover unequal widths of loss: narrow near the median, wide in
%       the tails, which is why the output piles up in the middle.
%   It also lists five example draws, u -> p -> loss, for the paper.
%
%   Writes docs/results/uniform_input_slices.csv,
%   docs/results/uniform_input_example_draws.csv, and
%   docs/figures/fig00_uniform_input.png.
%
%   Name-value options:
%     n_draws    Number of uniform draws (100000)
%     seed       Random stream seed (2108)
%     save_out   Write the CSVs and PNG (true)
%     out_root   Repository root (folder above examples/)
%
%   See also example_01_p2108_2km_2700mhz_rev1, draw_uniform_rev1.

arguments
    options.n_draws (1,1) double {mustBeInteger, mustBePositive} = 1e5
    options.seed (1,1) double {mustBeInteger, mustBeNonnegative} = 2108
    options.save_out (1,1) logical = true
    options.out_root (1,1) string = fileparts(fileparts(mfilename("fullpath")))
end

freq_mhz = 2700;
dist_km = 2;
loss_q = @(p) reshape(p2108_terrestrial_clutter_loss_vector_rev2([], freq_mhz, dist_km, p), size(p));

u = draw_uniform_rev1(options.n_draws, options.seed);
loss_db = loss_q(100*u);

% --- Ten equal slices of u and the loss range each one maps to ---
edges_pct = 0:10:100;
slice = discretize(100*u, edges_pct);
n_slices = numel(edges_pct) - 1;
share_pct = 100*accumarray(slice, 1, [n_slices 1]) / options.n_draws;
edge_loss = loss_q(min(max(edges_pct, 1e-6), 100 - 1e-6))';   % 0 % and 100 % are open ends
lo_db = edge_loss(1:end-1);
hi_db = edge_loss(2:end);
lo_db(1) = min(loss_db);                                       % finite ends for the table
hi_db(end) = max(loss_db);
width_db = hi_db - lo_db;
slice_name = compose("%d%% to %d%%", edges_pct(1:end-1)', edges_pct(2:end)');
slices = table(slice_name, share_pct, lo_db, hi_db, width_db, ...
    VariableNames=["slice", "share_of_draws_pct", "loss_from_db", "loss_to_db", "width_db"]);

% --- Five example draws for the paper ---
ex = table(u(1:5), 100*u(1:5), loss_db(1:5), VariableNames=["u", "percentage", "clutter_loss_db"]);

fprintf("Ten equal slices of the uniform draws, mapped through P.2108 (2.7 GHz, 2 km)\n");
disp(slices);
disp(ex);

fig = local_figure(u, loss_db, edges_pct, edge_loss, slices, loss_q, options.n_draws);

results = struct("slices", slices, "examples", ex, "u", u, "loss_db", loss_db, "figure", fig);

if options.save_out
    for out_folder = fullfile(options.out_root, "docs", ["results", "figures"])
        if ~isfolder(out_folder), mkdir(out_folder); end
    end
    writetable(slices, fullfile(options.out_root, "docs", "results", "uniform_input_slices.csv"));
    writetable(ex, fullfile(options.out_root, "docs", "results", "uniform_input_example_draws.csv"));
    exportgraphics(fig, fullfile(options.out_root, "docs", "figures", "fig00_uniform_input.png"), Resolution=300);
end
end

function fig = local_figure(u, loss_db, edges_pct, edge_loss, slices, loss_q, n_draws)
c = figure_palette_rev1();
fig = figure(Color="w", Units="inches", Position=[1 1 6.5 3.2]);
if ~isMATLABReleaseOlderThan("R2025a")
    theme(fig, "light");
end
t = tiledlayout(fig, 1, 2, TileSpacing="loose", Padding="compact");
band = @(k) ifelse(mod(k, 2) == 1, c.light_blue, c.mid_gray);
y_lo = 10;
y_hi = 45;

% Left: the curve. Vertical bands are the ten equal slices of u; dotted
% lines carry each slice edge across to the loss axis.
ax = nexttile(t);
hold(ax, "on");
for k = 1:10
    if mod(k, 2) == 1
        patch(ax, [edges_pct(k) edges_pct(k+1) edges_pct(k+1) edges_pct(k)], [y_lo y_lo y_hi y_hi], ...
            c.light_blue, FaceAlpha=0.12, EdgeColor="none");
    end
end
for k = 2:10
    plot(ax, [0 edges_pct(k) edges_pct(k)], [edge_loss(k) edge_loss(k) y_lo], ":", ...
        Color=c.mid_gray, LineWidth=0.8);
end
p = linspace(0.05, 99.95, 600);
plot(ax, p, loss_q(p), "-", LineWidth=1.8, Color=c.dark_blue);
hold(ax, "off");
style_axes_rev1(ax);
ax.YGrid = "off";
xlim(ax, [0 100]);
ylim(ax, [y_lo y_hi]);
ax.XTick = 0:20:100;
xlabel(ax, "Uniform draw \times 100 (%), in ten equal slices");
ylabel(ax, "Clutter loss (dB)");
title(ax, "Equal slices in, unequal widths out");
mid = slices.width_db(5:6);
text(ax, 50, edge_loss(6) - 0.06*(y_hi - y_lo), sprintf("middle slices: %.1f dB each", mean(mid)), ...
    FontName=c.font, FontSize=7.5, Color=c.dark_blue, HorizontalAlignment="center", VerticalAlignment="top");
text(ax, 88, edge_loss(10) + 0.04*(y_hi - y_lo), "top 10%: open-ended", ...
    FontName=c.font, FontSize=7.5, Color=c.dark_blue, HorizontalAlignment="right", VerticalAlignment="bottom");

% Right: the output histogram, stacked by slice so the colors don't overlap
ax = nexttile(t);
bin_edges = y_lo:0.25:y_hi;
slice = discretize(100*u, edges_pct);
counts = zeros(numel(bin_edges) - 1, 10);
for k = 1:10
    counts(:, k) = histcounts(loss_db(slice == k), bin_edges)';
end
centers = bin_edges(1:end-1) + 0.125;
b = bar(ax, centers, counts, 1, "stacked", EdgeColor="none");
for k = 1:10
    b(k).FaceColor = band(k);
end
style_axes_rev1(ax);
ax.YTickLabel = [];
xlim(ax, [y_lo y_hi]);
xlabel(ax, "Clutter loss (dB)");
title(ax, "Each color holds 10% of the draws");

add_figure_text_rev1(fig, t, ...
    Headline="Uniform draws make every slice equally likely; the model curve decides the shape", ...
    Subhead=sprintf("Ten equal slices of %s uniform draws mapped through ITU-R P.2108-1 clutter loss, 2.7 GHz, 2 km", ...
        format_thousands_rev1(n_draws)), ...
    Source="Source: aggregate_explainer example 00.");
end

function out = ifelse(cond, a, b)
if cond, out = a; else, out = b; end
end
