function fit = fit_eirp_truncated_normal_rev1(eirp_table)
%FIT_EIRP_TRUNCATED_NORMAL_REV1 Fit a truncated normal distribution (in dBm) to an EIRP percentile table.
%   fit = FIT_EIRP_TRUNCATED_NORMAL_REV1(eirp_table) takes the table from
%   read_bs_eirp_distribution_rev1 (percentile, eirp_db) and returns a
%   normal distribution in dB, truncated to the table's 0th and 100th
%   percentile values, whose percentiles best match the table:
%
%     fit.pd         prob.TruncatableDistribution (use icdf, cdf, pdf, random)
%     fit.mu_db      mean of the normal before truncation (dBm)
%     fit.sigma_db   standard deviation before truncation (dB)
%     fit.lower_db   truncation limits: the table's 0th and 100th
%     fit.upper_db   percentiles (dBm)
%     fit.median_db  median of the fitted distribution (dBm)
%     fit.std_db     standard deviation of the fitted distribution (dB)
%     fit.residuals  table: percentile, table_dbm, fitted_dbm, residual_db
%     fit.rms_db     root-mean-square residual over the interior percentiles
%
%   Method: least squares on the interior percentiles (every row except
%   the 0th and 100th), solved with fminsearch over mu and log(sigma). The
%   end points are matched exactly by the truncation.
%
%   Why: an 11-point table interpolated with a spline puts bumps in the
%   density between table points. The fit gives a smooth bell shape that
%   stays within the measured range. A normal distribution in dB is a
%   lognormal distribution in linear power.
%
%   See also makedist, truncate, fminsearch, read_bs_eirp_distribution_rev1.

arguments
    eirp_table table
end

pct = eirp_table.percentile;
val = eirp_table.eirp_db;
if pct(1) ~= 0 || pct(end) ~= 100 || numel(pct) < 4
    error("aggregate_explainer:EirpFit", ...
        "The table needs the 0th and 100th percentiles and at least two interior points.");
end
lower_db = val(1);
upper_db = val(end);
inner = pct > 0 & pct < 100;

make_pd = @(th) truncate(makedist("Normal", "mu", th(1), "sigma", exp(th(2))), lower_db, upper_db);
cost = @(th) sum((icdf(make_pd(th), pct(inner)/100) - val(inner)).^2);

start = [interp1(pct, val, 50), log((val(end) - val(1))/4)];
[th, ~, flag] = fminsearch(cost, start, optimset("TolX", 1e-8, "TolFun", 1e-10, "MaxFunEvals", 2e4));
if flag ~= 1
    error("aggregate_explainer:EirpFit", "fminsearch did not converge (exit flag %d).", flag);
end

pd = make_pd(th);
fitted = icdf(pd, pct/100);
residuals = table(pct, val, fitted, fitted - val, ...
    VariableNames=["percentile", "table_dbm", "fitted_dbm", "residual_db"]);

fit = struct("pd", pd, "mu_db", th(1), "sigma_db", exp(th(2)), ...
    "lower_db", lower_db, "upper_db", upper_db, ...
    "median_db", median(pd), "std_db", std(pd), ...
    "residuals", residuals, "rms_db", sqrt(mean(residuals.residual_db(inner).^2)));
end
