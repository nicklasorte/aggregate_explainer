function fig = plot_uniform_to_output_rev1(u, x, inv_cdf_pct, inv_cdf_x, opts)
%PLOT_UNIFORM_TO_OUTPUT_REV1 Three-panel inverse-transform figure.
%   fig = PLOT_UNIFORM_TO_OUTPUT_REV1(u, x, inv_cdf_pct, inv_cdf_x) draws:
%     1. a histogram of the uniform input draws u,
%     2. the mapping curve, inv_cdf_x versus inv_cdf_pct (the inverse CDF
%        that turns a percentage into an output value),
%     3. a histogram of the output draws x.
%
%   Name-value options:
%     title_str    Figure title (string)
%     x_label      Output axis label (string), for example "Clutter loss (dB)"
%     pct_label    Percentage axis label ("Percentage (%)")
%     marker_pct   Table points to mark on the mapping curve ([])
%     marker_x     Values at those points ([])
%
%   See also tiledlayout, histogram, exportgraphics.

arguments
    u double
    x double
    inv_cdf_pct double
    inv_cdf_x double
    opts.title_str (1,1) string = ""
    opts.x_label (1,1) string = "Output"
    opts.pct_label (1,1) string = "Percentage (%)"
    opts.marker_pct double = []
    opts.marker_x double = []
end

fig = figure(Color="w", Position=[100 100 1200 380]);
if ~isMATLABReleaseOlderThan("R2025a")
    theme(fig, "light");   % same figure on screens set to dark mode
end
t = tiledlayout(fig, 1, 3, TileSpacing="compact", Padding="compact");
title(t, opts.title_str, FontWeight="bold");
subtitle(t, "DRAFT//PRE-DECISIONAL");

ax1 = nexttile(t);
histogram(ax1, 100*u, 0:5:100, Normalization="pdf", FaceColor=[0.35 0.55 0.80]);
xlabel(ax1, "Uniform draw \times 100 (%)");
ylabel(ax1, "Probability density");
title(ax1, "1. Input: uniform draws");
grid(ax1, "on");

ax2 = nexttile(t);
plot(ax2, inv_cdf_pct, inv_cdf_x, "-", LineWidth=1.8, Color=[0.20 0.20 0.20]);
hold(ax2, "on");
if ~isempty(opts.marker_pct)
    plot(ax2, opts.marker_pct, opts.marker_x, "o", MarkerSize=6, ...
        MarkerFaceColor=[0.85 0.33 0.10], MarkerEdgeColor="none");
end
hold(ax2, "off");
xlabel(ax2, opts.pct_label);
ylabel(ax2, opts.x_label);
title(ax2, "2. Mapping: inverse CDF");
xlim(ax2, [0 100]);
grid(ax2, "on");

ax3 = nexttile(t);
histogram(ax3, x, 60, Normalization="pdf", FaceColor=[0.85 0.33 0.10]);
xlabel(ax3, opts.x_label);
ylabel(ax3, "Probability density");
title(ax3, "3. Output distribution");
grid(ax3, "on");
end
