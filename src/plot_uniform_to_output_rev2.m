function fig = plot_uniform_to_output_rev2(u, x, curve_pct, curve_x, opts)
%PLOT_UNIFORM_TO_OUTPUT_REV2 Three-panel inverse-transform figure, NTIA report style.
%   fig = PLOT_UNIFORM_TO_OUTPUT_REV2(u, x, curve_pct, curve_x, Name=Value)
%   draws one row of three panels that read left to right:
%     1. the uniform input draws u (gray histogram),
%     2. the curve that turns a percentage into a value (dark blue), with
%        one example draw traced across it (light blue, dotted),
%     3. the output draws x (light blue density, median marked).
%   Then it adds the headline, subhead, source line, and marking.
%
%   Required name-value options:
%     Headline     Takeaway sentence for the figure
%     XLabel       Output label with units, for example "Clutter loss (dB)"
%
%   Optional name-value options:
%     Subhead      Units and scope ("")
%     Source       Source line ("")
%     PctLabel     Percentage axis label ("Percentage (%)")
%     MarkerPct    Table points to mark on the curve ([])
%     MarkerX      Values at those points ([])
%     TracePct     Percentage of the example draw to trace (90)
%     Width        Figure width, inches (6.5, one report column)
%
%   See also style_axes_rev1, add_figure_text_rev1, ksdensity.

arguments
    u double
    x double
    curve_pct double
    curve_x double
    opts.Headline (1,1) string
    opts.XLabel (1,1) string
    opts.Subhead (1,1) string = ""
    opts.Source (1,1) string = ""
    opts.PctLabel (1,1) string = "Percentage (%)"
    opts.MarkerPct double = []
    opts.MarkerX double = []
    opts.TracePct (1,1) double {mustBeInRange(opts.TracePct, 0, 100, "exclusive")} = 90
    opts.Width (1,1) double {mustBePositive} = 6.5
end

c = figure_palette_rev1();
fig = figure(Color="w", Units="inches", Position=[1 1 opts.Width 2.9]);
if ~isMATLABReleaseOlderThan("R2025a")
    theme(fig, "light");
end
t = tiledlayout(fig, 1, 3, TileSpacing="loose", Padding="compact");

% 1. Uniform input
ax1 = nexttile(t);
histogram(ax1, 100*u, 0:5:100, Normalization="pdf", FaceColor=c.mid_gray, ...
    EdgeColor="w", FaceAlpha=1);
style_axes_rev1(ax1);
xlim(ax1, [0 100]);
ylim(ax1, [0 0.015]);
ax1.YTick = [0 0.01];
xlabel(ax1, "Uniform draw \times 100 (%)");
ylabel(ax1, "Density");
title(ax1, "1. Draw a uniform number");

% 2. The curve, with one draw traced across it
ax2 = nexttile(t);
trace_x = interp1(curve_pct, curve_x, opts.TracePct);
plot(ax2, curve_pct, curve_x, "-", LineWidth=1.8, Color=c.dark_blue);
hold(ax2, "on");
if ~isempty(opts.MarkerPct)
    plot(ax2, opts.MarkerPct, opts.MarkerX, "o", MarkerSize=3.5, ...
        MarkerFaceColor="w", MarkerEdgeColor=c.dark_blue, LineWidth=0.8);
end
y_floor = min(curve_x) - 0.05*range(curve_x);
plot(ax2, [opts.TracePct opts.TracePct 0], [y_floor trace_x trace_x], ":", ...
    LineWidth=1.4, Color=c.light_blue);
plot(ax2, opts.TracePct, trace_x, "o", MarkerSize=5, MarkerFaceColor=c.light_blue, ...
    MarkerEdgeColor="none");
text(ax2, opts.TracePct - 3, trace_x, sprintf("%g%% \\rightarrow %.1f", opts.TracePct, trace_x), ...
    HorizontalAlignment="right", VerticalAlignment="bottom", FontName=c.font, ...
    FontSize=8, FontWeight="bold", Color=c.light_blue);
hold(ax2, "off");
style_axes_rev1(ax2);
xlim(ax2, [0 100]);
ylim(ax2, [y_floor, max(curve_x) + 0.05*range(curve_x)]);
xlabel(ax2, opts.PctLabel);
ylabel(ax2, opts.XLabel);
title(ax2, "2. Read the curve");

% 3. Output distribution
ax3 = nexttile(t);
[dens, xs] = ksdensity(x, linspace(min(x), max(x), 400));
area(ax3, xs, dens, FaceColor=c.light_blue, FaceAlpha=0.35, EdgeColor=c.light_blue, LineWidth=1.4);
hold(ax3, "on");
med = median(x);
xline(ax3, med, "-", Color=c.dark_blue, LineWidth=0.8);
text(ax3, med, max(dens)*1.04, sprintf("median %.1f ", med), FontName=c.font, FontSize=8, ...
    Color=c.dark_blue, VerticalAlignment="bottom", HorizontalAlignment="right");
xline(ax3, trace_x, ":", Color=c.light_blue, LineWidth=1.4);
hold(ax3, "off");
style_axes_rev1(ax3);
ylim(ax3, [0 max(dens)*1.18]);
xlabel(ax3, opts.XLabel);
ylabel(ax3, "Density");
title(ax3, "3. Repeat: the output distribution");

add_figure_text_rev1(fig, t, Headline=opts.Headline, Subhead=opts.Subhead, Source=opts.Source);
end
