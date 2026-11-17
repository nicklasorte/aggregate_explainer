function x = sim_grid_draws_rev1(grid_pct, grid_value, u, method)
%SIM_GRID_DRAWS_REV1 Draws made the way the production simulation makes them.
%   x = SIM_GRID_DRAWS_REV1(grid_pct, grid_value, u) maps uniform draws u
%   to the percentage range of the grid, rand*(max - min) + min, and
%   interpolates the tabulated values linearly, as
%   monte_carlo_Pr_dBm_rev2_app and monte_carlo_clutter_rev3_app
%   (General_Movelist) do. Use method="spline" for the EIRP table, as
%   monte_carlo_super_bs_eirp_dist_rev5 does.
%
%   Compare with drawing straight from the model at 100*u: the grid
%   truncates the tails at its end points (0.001 % and 99.999 % for
%   sim_reliability_grid_rev1) and linearizes between grid points.
%
%   See also sim_reliability_grid_rev1, interp1.

arguments
    grid_pct (:,1) double
    grid_value (:,1) double
    u double {mustBeInRange(u, 0, 1)}
    method (1,1) string = "linear"
end

rel_min = min(grid_pct);
rel_max = max(grid_pct);
pct = u*(rel_max - rel_min) + rel_min;
x = interp1(grid_pct, grid_value, pct, method);
end
