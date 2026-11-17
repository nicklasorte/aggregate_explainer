function c = figure_palette_rev1()
%FIGURE_PALETTE_REV1 NTIA colors and font for the working paper figures.
%   c = FIGURE_PALETTE_REV1() returns a struct of RGB triplets (0 to 1):
%     dark_blue   #163353  text, headlines, the model curve
%     light_blue  #5674C4  the one highlight in each panel
%     purple      #6E4F92  a second highlight, or an alert
%     mid_gray    #8A8D91  context data
%     fill_gray   #E8E9EA  fills only
%     grid        #E6E6E6  gridlines
%   and c.font, the report font (Times New Roman, NTIA style guide July 2026).
%
%   Source: slide-design skill, references/color.md (NTIA brand palette).
%
%   See also style_axes_rev1.

hex = @(h) reshape(double(hex2dec([extractBetween(h, 1, 2), extractBetween(h, 3, 4), extractBetween(h, 5, 6)])), 1, 3) / 255;
c = struct( ...
    "dark_blue", hex("163353"), ...
    "light_blue", hex("5674C4"), ...
    "purple", hex("6E4F92"), ...
    "mid_gray", hex("8A8D91"), ...
    "fill_gray", hex("E8E9EA"), ...
    "grid", hex("E6E6E6"), ...
    "font", "Times New Roman");
end
