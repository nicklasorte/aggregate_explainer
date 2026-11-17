function results = example_02_bs_eirp_distribution_rev2(options)
%EXAMPLE_02_BS_EIRP_DISTRIBUTION_REV2 Base station EIRP as a normal distribution fitted to the CTIA table.
%   results = EXAMPLE_02_BS_EIRP_DISTRIBUTION_REV2() shows how a uniform
%   draw becomes a base station EIRP draw:
%     1. Read the CTIA EIRP percentile table (0th to 100th, every 10th) for
%        the 0 deg azimuth, 0 deg elevation cut.
%     2. Fit a normal distribution in dBm, truncated to the table's 0th and
%        100th percentiles (fit_eirp_truncated_normal_rev1).
%     3. Draw u ~ U(0, 1) and take the fitted distribution's inverse CDF at u.
%   It reports how far the fit is from each table point, and how the fit
%   compares with the spline interpolation that FSS_Neighborhood uses.
%
%   Writes docs/results/bs_eirp_distribution.csv and
%   docs/figures/fig02_bs_eirp_distribution.png.
%
%   Name-value options:
%     n_draws    Number of uniform draws (100000)
%     seed       Random stream seed (7)
%     save_out   Write the CSV and PNG (true)
%     out_root   Repository root (folder above examples/)
%
%   Changes from rev1: rev1 drew from a spline through the 11 table points,
%   which puts two artificial peaks in the density. rev2 draws from the
%   fitted normal distribution.
%
%   See also fit_eirp_truncated_normal_rev1, read_bs_eirp_distribution_rev1.

arguments
    options.n_draws (1,1) double {mustBeInteger, mustBePositive} = 1e5
    options.seed (1,1) double {mustBeInteger, mustBeNonnegative} = 7
    options.save_out (1,1) logical = true
    options.out_root (1,1) string = fileparts(fileparts(mfilename("fullpath")))
end

xlsx_file = fullfile(options.out_root, "data", "7Ghz 0azi 0ele EIRP.xlsx");
eirp_table = read_bs_eirp_distribution_rev1(xlsx_file);
fit = fit_eirp_truncated_normal_rev1(eirp_table);
pct = eirp_table.percentile;

fprintf("EIRP fit: normal in dBm, mu %.2f, sigma %.2f, truncated to [%.2f, %.2f]\n", ...
    fit.mu_db, fit.sigma_db, fit.lower_db, fit.upper_db);
fprintf("  fitted median %.2f dBm, standard deviation %.2f dB\n", fit.median_db, fit.std_db);
fprintf("  residuals: rms %.2f dB, largest %.2f dB\n", fit.rms_db, max(abs(fit.residuals.residual_db)));

% --- Monte Carlo: uniform in, EIRP out ---
u = draw_uniform_rev1(options.n_draws, options.seed);
eirp_draws_db = icdf(fit.pd, u);
eirp_mc_db = prctile(eirp_draws_db, pct);

% --- The spline that FSS_Neighborhood uses, for comparison ---
spline_draws_db = sample_from_percentile_table_rev1(pct, eirp_table.eirp_db, u, "spline");

tbl = [fit.residuals, table(eirp_mc_db(:), fit.residuals.fitted_dbm - fit.median_db, ...
    VariableNames=["monte_carlo_dbm", "offset_from_median_db"])];
disp(tbl);

curve_pct = linspace(0.1, 99.9, 500)';
fig = plot_uniform_to_output_rev2(u, eirp_draws_db, curve_pct, icdf(fit.pd, curve_pct/100), ...
    Headline = sprintf("Base station EIRP is close to a bell curve: median %.1f dBm, standard deviation %.1f dB", ...
        fit.median_db, fit.std_db), ...
    Subhead = sprintf("Normal distribution in dBm fitted to the CTIA table (circles), 0%s azimuth, 0%s elevation; largest misfit %.1f dB; %s draws", ...
        char(176), char(176), max(abs(fit.residuals.residual_db)), format_thousands_rev1(options.n_draws)), ...
    Source = "Source: CTIA field measurements (FSS_Neighborhood workbook); aggregate_explainer example 02.", ...
    XLabel = "EIRP (dBm)", ...
    PctLabel = "Percentile (%)", ...
    MarkerPct = pct, MarkerX = eirp_table.eirp_db);

results = struct("fit", fit, "table", tbl, "median_db", fit.median_db, "std_db", fit.std_db, ...
    "u", u, "draws_db", eirp_draws_db, "offset_draws_db", eirp_draws_db - fit.median_db, ...
    "spline_draws_db", spline_draws_db, "figure", fig);

if options.save_out
    for out_folder = fullfile(options.out_root, "docs", ["results", "figures"])
        if ~isfolder(out_folder), mkdir(out_folder); end
    end
    writetable(tbl, fullfile(options.out_root, "docs", "results", "bs_eirp_distribution.csv"));
    exportgraphics(fig, fullfile(options.out_root, "docs", "figures", "fig02_bs_eirp_distribution.png"), Resolution=300);
end
end
