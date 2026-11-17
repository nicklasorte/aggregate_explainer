function u = draw_uniform_columns_rev1(n, n_cols, seed)
%DRAW_UNIFORM_COLUMNS_REV1 Independent uniform draws, one column per random input.
%   u = DRAW_UNIFORM_COLUMNS_REV1(n, n_cols, seed) returns an n-by-n_cols
%   matrix of uniform draws on (0, 1). Column k comes from substream k of
%   one mrg32k3a stream, so the columns are statistically independent and
%   each column is reproducible on its own.
%
%   Use one column per input that must vary independently, for example
%   EIRP, path loss, and clutter loss.
%
%   Why substreams: seeding separate streams with seed, seed+1, seed+2 can
%   correlate the inputs. Substreams of one mrg32k3a stream are designed to
%   be independent.
%
%   See also RandStream, draw_uniform_rev1.

arguments
    n (1,1) double {mustBeInteger, mustBePositive}
    n_cols (1,1) double {mustBeInteger, mustBePositive}
    seed (1,1) double {mustBeInteger, mustBeNonnegative} = 0
end

stream = RandStream("mrg32k3a", Seed=seed);
u = zeros(n, n_cols);
for k = 1:n_cols
    stream.Substream = k;
    u(:, k) = rand(stream, n, 1);
end
end
