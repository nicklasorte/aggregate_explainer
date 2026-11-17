function u = draw_uniform_rev1(n, seed)
%DRAW_UNIFORM_REV1 Reproducible uniform draws on the open interval (0, 1).
%   u = DRAW_UNIFORM_REV1(n, seed) returns an n-by-1 vector of independent
%   uniform draws from a dedicated mrg32k3a stream, so the draws do not
%   depend on or change the global random number generator.
%
%   rand never returns exactly 0 or 1, so every draw is a valid
%   percentage for P.2108 (0 < p < 100) and ITM (0 < reliability < 100).
%
%   See also RandStream, rand.

arguments
    n (1,1) double {mustBeInteger, mustBePositive}
    seed (1,1) double {mustBeInteger, mustBeNonnegative} = 0
end

stream = RandStream("mrg32k3a", Seed=seed);
u = rand(stream, n, 1);
end
