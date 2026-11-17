function Lctt = p2108_terrestrial_clutter_loss_vector_rev2(app, FreqMHz, dist_km, p)
%P2108_TERRESTRIAL_CLUTTER_LOSS_VECTOR_REV2 ITU-R P.2108-1, Annex 1, Section 3.2.
%   Lctt = P2108_TERRESTRIAL_CLUTTER_LOSS_VECTOR_REV2(app, FreqMHz, dist_km, p)
%   returns the terrestrial clutter loss, in dB, not exceeded for p percent
%   of locations, for clutter at ONE end of the path.
%
%   Inputs:
%     app      Unused. Kept so the call matches App Designer code.
%     FreqMHz  Frequency (MHz), 500 to 67000 (P.2108-1: 0.5 to 67 GHz).
%     dist_km  Total path length (km), any size, nonnegative.
%     p        Percentage of locations, 0 < p < 100, any size (default 50).
%
%   Output:
%     Lctt     Clutter loss (dB). If p is a scalar, Lctt has the size of
%              dist_km. Otherwise Lctt is numel(dist_km)-by-numel(p), with
%              dist_km taken in column order (dist_km(:)).
%
%   Equations (ITU-R P.2108-1, 09/2021):
%     (3a) Lctt  = -5 log10(10^(-0.2 Ll) + 10^(-0.2 Ls)) - sigma_cb Q^-1(p/100)
%     (3b) sigma_cb = sqrt((sigma_l^2 10^(-0.2 Ll) + sigma_s^2 10^(-0.2 Ls))
%                          / (10^(-0.2 Ll) + 10^(-0.2 Ls)))
%     (4a) Ll    = -2 log10(10^(-5 log10(f) - 12.5) + 10^(-16.5))
%     (4b) sigma_l = 4 dB
%     (5a) Ls    = 32.98 + 23.9 log10(d) + 3 log10(f)
%     (5b) sigma_s = 6 dB
%     (6)  Lctt may not exceed the value computed for a 2 km path.
%
%   Changes from p2108_terrestrial_clutter_loss_vector (general_terrestrial_pathloss):
%     1. Equation (6) is applied as min(Lctt(d), Lctt(2 km)), as the
%        Recommendation and the NTIA/ITS reference code (NTIA/p2108) do.
%        rev1 clamped d to 2 km before the calculation. The two agree at
%        p <= 50 but differ at high p, because sigma_cb changes with d: at
%        3.5 GHz, 1 km, p = 99.9, rev1 gives 43.4 dB and the NTIA test
%        vector is 42.8 dB.
%     2. The documented output shape [numel(d) numel(p)] now holds for row
%        and matrix dist_km. rev1 errored or returned the wrong shape there.
%
%   Project convention (not in P.2108-1): for d < 0.25 km the model is
%   outside its range and this function returns 0 dB, as rev1 did.
%   P.2108-1 also requires d >= 1 km when the correction is applied at both
%   ends of the path; call this function once per end.
%
%   Example (2.7 GHz, 2 km, median):
%     L = p2108_terrestrial_clutter_loss_vector_rev2([], 2700, 2, 50)   % 29.29 dB
%
%   See also erfcinv, read_bs_eirp_distribution_rev1.

arguments
    app %#ok<INUSA> kept for App Designer signature compatibility
    FreqMHz (1,1) double {mustBeInRange(FreqMHz, 500, 67000)}
    dist_km double {mustBeNonnegative, mustBeNonempty}
    p double {mustBeGreaterThan(p, 0), mustBeLessThan(p, 100)} = 50
end

f_GHz = FreqMHz/1000;
d_col = dist_km(:);                       % N-by-1
p_row = reshape(p, 1, []);                % 1-by-M

is_too_short = d_col < 0.25;
d_eff = max(d_col, 0.25);                 % avoid log10(0); masked below

% Q^-1(x) = sqrt(2) erfcinv(2x): inverse complementary standard normal.
% norminv(1 - x) is equivalent but loses precision for x near 0.
inv_q = sqrt(2) * erfcinv(2 * p_row/100); % 1-by-M

L_d   = local_lctt(f_GHz, d_eff, inv_q);  % N-by-M
L_2km = local_lctt(f_GHz, 2, inv_q);      % 1-by-M
Lctt  = min(L_d, L_2km);                  % Equation (6)

Lctt(is_too_short, :) = 0;                % project convention, see help

if isscalar(p)
    Lctt = reshape(Lctt, size(dist_km));
end
end

function L = local_lctt(f_GHz, d_km, inv_q)
% Equations (3a)-(5b). d_km is a column, inv_q is a row.
sigma_l = 4;                                                  % (4b)
sigma_s = 6;                                                  % (5b)
T_l = (10.^(-5*log10(f_GHz) - 12.5) + 10^(-16.5)).^0.4;       % 10^(-0.2 Ll), (4a)
L_s = 32.98 + 23.9*log10(d_km) + 3*log10(f_GHz);              % (5a)
T_s = 10.^(-0.2*L_s);
sigma_cb = sqrt((sigma_l^2*T_l + sigma_s^2*T_s) ./ (T_l + T_s)); % (3b)
L = -5*log10(T_l + T_s) - sigma_cb .* inv_q;                  % (3a)
end
