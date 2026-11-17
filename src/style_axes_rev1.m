function style_axes_rev1(ax, opts)
%STYLE_AXES_REV1 Decluttered NTIA report styling for one axes.
%   STYLE_AXES_REV1(ax) applies the look used in every figure of the working
%   paper: Times New Roman, dark blue text, no box, no value-axis line, light
%   horizontal gridlines only, and a left-aligned bold panel title.
%
%   Name-value options:
%     FontSize   Text size in points at final size (8)
%     YGrid      Horizontal gridlines (true)
%     XGrid      Vertical gridlines (false)
%
%   Adapted from briefing_style.m in the slide-design skill (NTIA palette:
%   dark blue #163353 text, mid gray #8A8D91 context, light gray #E6E6E6 grid).
%
%   See also figure_palette_rev1, add_figure_text_rev1.

arguments
    ax (1,1) matlab.graphics.axis.Axes
    opts.FontSize (1,1) double {mustBePositive} = 8
    opts.YGrid (1,1) logical = true
    opts.XGrid (1,1) logical = false
end

c = figure_palette_rev1();

box(ax, "off")
ax.Color = "w";
ax.FontName = c.font;
ax.FontSize = opts.FontSize;
ax.TickDir = "out";
ax.TickLength = [0 0];
ax.LineWidth = 0.75;
ax.XColor = c.dark_blue;
ax.YColor = c.dark_blue;
ax.XGrid = matlab.lang.OnOffSwitchState(opts.XGrid);
ax.YGrid = matlab.lang.OnOffSwitchState(opts.YGrid);
ax.GridColor = c.grid;
ax.GridAlpha = 1;
ax.Layer = "bottom";
ax.XAxis.Color = c.mid_gray;
ax.XAxis.TickLabelColor = c.dark_blue;
ax.XAxis.Label.Color = c.dark_blue;
ax.YAxis(1).Color = "none";
ax.YAxis(1).TickLabelColor = c.dark_blue;
ax.YAxis(1).Label.Color = c.dark_blue;
ax.Title.FontWeight = "bold";
ax.Title.FontSize = opts.FontSize + 1;
ax.Title.Color = c.dark_blue;
ax.TitleHorizontalAlignment = "left";
legend(ax, "off")
end
