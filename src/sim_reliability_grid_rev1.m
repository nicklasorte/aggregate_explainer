function reliability = sim_reliability_grid_rev1()
%SIM_RELIABILITY_GRID_REV1 The 47-point percentage grid of the production simulation.
%   reliability = SIM_RELIABILITY_GRID_REV1() returns the column of
%   percentages at which init_sim_folder_FSS_neigh_rev25_fdr_github.m
%   (nicklasorte/FSS_Neighborhood) tabulates ITM, P.2108 clutter loss, and
%   the base station EIRP distribution. The Monte Carlo step
%   (vector_mc_seed_pr_eirp_clutter_rev1, General_Movelist) draws
%   rand*(99.999 - 0.001) + 0.001 and interpolates each table at that
%   percentage: linearly for path loss and clutter, by spline for EIRP.
%
%   See also sim_grid_draws_rev1.

reliability = [0.001, 0.01, 0.1, 0.2, 0.3, 0.5, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ...
    15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 91, 92, 93, ...
    94, 95, 96, 97, 98, 99, 99.5, 99.7, 99.8, 99.9, 99.99, 99.999]';
end
