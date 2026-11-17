function x = sample_from_percentile_table_rev1(percentile, value, u, method)
%SAMPLE_FROM_PERCENTILE_TABLE_REV1 Inverse-transform sampling from a percentile table.
%   x = SAMPLE_FROM_PERCENTILE_TABLE_REV1(percentile, value, u) maps
%   uniform draws u (0 < u < 1) to values of a random variable whose
%   cumulative distribution is given by the table: value(k) is the
%   percentile(k)-th percentile. It interpolates the inverse CDF at 100*u.
%
%   x = SAMPLE_FROM_PERCENTILE_TABLE_REV1(..., method) sets the interp1
%   method. The default, "spline", matches FSS_Neighborhood
%   (init_sim_folder_FSS_neigh_rev25_fdr_github.m). "pchip" never
%   overshoots between table points; "linear" is the plain empirical CDF.
%
%   x has the size of u.
%
%   See also interp1, read_bs_eirp_distribution_rev1.

arguments
    percentile (:,1) double {mustBeInRange(percentile, 0, 100)}
    value (:,1) double {mustBeFinite}
    u double {mustBeGreaterThan(u, 0), mustBeLessThan(u, 1)}
    method (1,1) string {mustBeMember(method, ["spline", "pchip", "linear", "makima"])} = "spline"
end

if numel(percentile) ~= numel(value)
    error("aggregate_explainer:TableSize", "percentile and value must have the same length.");
end
if percentile(1) > 0 || percentile(end) < 100
    error("aggregate_explainer:TableRange", ...
        "The table must span 0 to 100 percent so that every draw is an interpolation.");
end

x = interp1(percentile, value, 100*u, method);
end
