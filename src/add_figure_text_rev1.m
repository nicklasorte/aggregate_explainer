function add_figure_text_rev1(fig, t, opts)
%ADD_FIGURE_TEXT_REV1 Headline, subhead, source line, and marking for a standalone figure.
%   ADD_FIGURE_TEXT_REV1(fig, t, Headline=..., Subhead=..., Source=...)
%   reserves space at the top and bottom of the figure, moves the tiled
%   layout t into the middle, and writes:
%     top right   DRAFT//PRE-DECISIONAL, on its own line
%     below it    the headline (bold, the takeaway) and the subhead (units, scope)
%     bottom left the source line
%   All text is dark blue Times New Roman (NTIA report style).
%
%   Name-value options:
%     Headline   Takeaway sentence (required)
%     Subhead    Units and scope ("")
%     Source     Source line ("")
%     FontSize   Body size in points (8); the headline is 2 points larger
%
%   Keep the headline to one line: about 90 characters at 6.5 inches wide.
%
%   See also style_axes_rev1, annotation.

arguments
    fig (1,1) matlab.ui.Figure
    t (1,1) matlab.graphics.layout.TiledChartLayout
    opts.Headline (1,1) string
    opts.Subhead (1,1) string = ""
    opts.Source (1,1) string = ""
    opts.FontSize (1,1) double {mustBePositive} = 8
end

c = figure_palette_rev1();
fig_in = fig.Position(4);                  % figure height, inches
line_h = @(pt) pt/72/fig_in * 1.4;         % one text line, normalized
head_pt = opts.FontSize + 2;
mark_pt = opts.FontSize - 1;

% Rows from the top: marking, headline, subhead. Source at the bottom.
top = line_h(mark_pt) + line_h(head_pt) + line_h(opts.FontSize) * (opts.Subhead ~= "") + 0.02;
bottom = line_h(opts.FontSize) * (opts.Source ~= "") + 0.015;
t.OuterPosition = [0 bottom 1 1 - top - bottom];

common = {"FontName", c.font, "Color", c.dark_blue, "LineStyle", "none", ...
    "Margin", 0, "Interpreter", "none", "FitBoxToText", "off"};
x0 = 0.012;
w = 0.976;
y = 1 - 0.008;

annotation(fig, "textbox", [x0, y - line_h(mark_pt), w, line_h(mark_pt)], ...
    "String", "DRAFT//PRE-DECISIONAL", "FontSize", mark_pt, "FontWeight", "bold", ...
    "HorizontalAlignment", "right", "VerticalAlignment", "top", common{:});
y = y - line_h(mark_pt);
annotation(fig, "textbox", [x0, y - line_h(head_pt), w, line_h(head_pt)], ...
    "String", opts.Headline, "FontSize", head_pt, "FontWeight", "bold", ...
    "VerticalAlignment", "top", common{:});
y = y - line_h(head_pt);
if opts.Subhead ~= ""
    annotation(fig, "textbox", [x0, y - line_h(opts.FontSize), w, line_h(opts.FontSize)], ...
        "String", opts.Subhead, "FontSize", opts.FontSize, "VerticalAlignment", "top", common{:});
end
if opts.Source ~= ""
    annotation(fig, "textbox", [x0, 0.008, w, line_h(opts.FontSize)], ...
        "String", opts.Source, "FontSize", opts.FontSize - 0.5, "VerticalAlignment", "bottom", common{:});
end
end
