function [x_grid, cdf] = sum_of_independent_db_rev1(quantile_fcns, signs, options)
%SUM_OF_INDEPENDENT_DB_REV1 CDF of a signed sum of independent dB terms, by convolution.
%   [x_grid, cdf] = SUM_OF_INDEPENDENT_DB_REV1(quantile_fcns, signs)
%   returns the CDF of  sum_k signs(k) * X_k,  where the X_k are independent
%   and quantile_fcns{k}(p) returns the p-th percentile (0 < p < 100) of X_k.
%
%   This is a deterministic check on a Monte Carlo result: each term's
%   distribution is built from its quantile function on a fine percentile
%   grid, binned, and the probability mass functions are convolved.
%
%   Name-value options:
%     n_quantiles  Percentile points per term (20000)
%     bin_db       Bin width, dB (0.01)
%
%   See also conv, histcounts.

arguments
    quantile_fcns (1,:) cell
    signs (1,:) double {mustBeMember(signs, [-1 1])}
    options.n_quantiles (1,1) double {mustBeInteger, mustBePositive} = 2e4
    options.bin_db (1,1) double {mustBePositive} = 0.01
end

if numel(quantile_fcns) ~= numel(signs)
    error("aggregate_explainer:SumTerms", "One sign is needed per quantile function.");
end

% Midpoint percentiles: each point carries probability 1/n_quantiles.
p = ((1:options.n_quantiles)' - 0.5) / options.n_quantiles * 100;
h = options.bin_db;

pmf = 1;
x_min = 0;
for k = 1:numel(quantile_fcns)
    x = signs(k) * reshape(quantile_fcns{k}(p), [], 1);
    if any(~isfinite(x))
        error("aggregate_explainer:SumTerms", "Quantile function %d returned a non-finite value.", k);
    end
    lo = floor(min(x)/h);
    idx = round(x/h) - lo + 1;                       % bin index of each point
    term_pmf = accumarray(idx, 1) / options.n_quantiles;
    pmf = conv(pmf, term_pmf);
    x_min = x_min + lo*h;
end

x_grid = x_min + h*(0:numel(pmf) - 1)';
cdf = min(cumsum(pmf), 1);
end
