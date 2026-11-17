function results = example_02_bs_eirp_distribution_rev1(options)
%EXAMPLE_02_BS_EIRP_DISTRIBUTION_REV1 Base station EIRP distribution from a percentile table.
%   results = EXAMPLE_02_BS_EIRP_DISTRIBUTION_REV1() shows how a uniform
%   draw becomes a base station EIRP draw:
%     1. Read the EIRP percentile table (0th to 100th, every 10th) for the
%        0 deg azimuth, 0 deg elevation cut: data/7Ghz 0azi 0ele EIRP.xlsx.
%     2. Draw u ~ U(0, 1).
%     3. Interpolate the table (the inverse CDF) at 100 u.
%   It also forms the median-normalized offset that FSS_Neighborhood adds
%   to its fixed median EIRP (50.5 dBm/10 MHz in rev25), writes
%   docs/results/bs_eirp_distribution.csv, and saves
%   docs/figures/fig02_bs_eirp_distribution.png.
%
%   Name-value options:
%     n_draws    Number of uniform draws (100000)
%     seed       Random stream seed (7)
%     method     interp1 method ("spline", as in FSS_Neighborhood)
%     save_out   Write the CSV and PNG (true)
%     out_root   Repository root (folder above examples/)
%
%   See also read_bs_eirp_distribution_rev1, sample_from_percentile_table_rev1.

arguments
    options.n_draws (1,1) double {mustBeInteger, mustBePositive} = 1e5
    options.seed (1,1) double {mustBeInteger, mustBeNonnegative} = 7
    options.method (1,1) string = "spline"
    options.save_out (1,1) logical = true
    options.out_root (1,1) string = fileparts(fileparts(mfilename("fullpath")))
end

xlsx_file = fullfile(options.out_root, "data", "7Ghz 0azi 0ele EIRP.xlsx");
eirp_table = read_bs_eirp_distribution_rev1(xlsx_file);
pct = eirp_table.percentile;
eirp_db = eirp_table.eirp_db;
median_db = interp1(pct, eirp_db, 50);

fprintf("EIRP table, azimuth %g deg, elevation %g deg (%d points)\n", ...
    eirp_table.Properties.UserData.azimuth_deg, ...
    eirp_table.Properties.UserData.elevation_deg, height(eirp_table));
fprintf("  min %.2f, median %.2f, max %.2f dB (units as in source workbook)\n", ...
    eirp_db(1), median_db, eirp_db(end));

% --- Monte Carlo: uniform in, EIRP out ---
u = draw_uniform_rev1(options.n_draws, options.seed);
eirp_draws_db = sample_from_percentile_table_rev1(pct, eirp_db, u, options.method);
eirp_mc_db = prctile(eirp_draws_db, pct);

% Interpolation choice: how far apart are the methods between table points?
grid_pct = (0:0.1:100)';
curve_spline = interp1(pct, eirp_db, grid_pct, "spline");
curve_pchip = interp1(pct, eirp_db, grid_pct, "pchip");
curve_linear = interp1(pct, eirp_db, grid_pct, "linear");
fprintf("  max |spline - pchip|  = %.3f dB\n", max(abs(curve_spline - curve_pchip)));
fprintf("  max |spline - linear| = %.3f dB\n", max(abs(curve_spline - curve_linear)));
fprintf("  spline is monotone on this table: %d\n", all(diff(curve_spline) >= 0));

tbl = table(pct, eirp_db, eirp_mc_db(:), eirp_db - median_db, ...
    VariableNames=["percentile", "table_db", "monte_carlo_db", "offset_from_median_db"]);
disp(tbl);

curve_x = interp1(pct, eirp_db, grid_pct, options.method);
fig = plot_uniform_to_output_rev1(u, eirp_draws_db, grid_pct, curve_x, ...
    title_str = "Base station EIRP, 0° azimuth, 0° elevation (FSS\_Neighborhood table)", ...
    x_label = "EIRP (dB, source units)", ...
    pct_label = "Percentile (%)", ...
    marker_pct = pct, marker_x = eirp_db);

results = struct("table", tbl, "median_db", median_db, "u", u, ...
    "draws_db", eirp_draws_db, "offset_draws_db", eirp_draws_db - median_db, ...
    "max_spline_pchip_db", max(abs(curve_spline - curve_pchip)), ...
    "max_spline_linear_db", max(abs(curve_spline - curve_linear)), "figure", fig);

if options.save_out
    for out_folder = fullfile(options.out_root, "docs", ["results", "figures"])
        if ~isfolder(out_folder), mkdir(out_folder); end
    end
    writetable(tbl, fullfile(options.out_root, "docs", "results", "bs_eirp_distribution.csv"));
    exportgraphics(fig, fullfile(options.out_root, "docs", "figures", "fig02_bs_eirp_distribution.png"), Resolution=200);
end
end
