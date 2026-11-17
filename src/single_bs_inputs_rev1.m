function inputs = single_bs_inputs_rev1(options)
%SINGLE_BS_INPUTS_REV1 The three inverse CDFs for one base station: EIRP, path loss, clutter loss.
%   inputs = SINGLE_BS_INPUTS_REV1() returns a struct with one quantile
%   function (percentage in, dB value out) for each random input of
%   P_rx = EIRP - L_path - L_clutter:
%
%     inputs.eirp_q     EIRP (dBm): normal distribution fitted to the CTIA table
%     inputs.path_q     path loss (dB): ITM v1.4 point-to-point, flat terrain,
%                       time percentage, confidence 50 %
%     inputs.clutter_q  clutter loss (dB): ITU-R P.2108-1 at the base station
%                       end, location percentage
%     inputs.names      ["EIRP", "Path loss", "Clutter loss"]
%     inputs.signs      [1 -1 -1], the sign of each term in P_rx
%     inputs.eirp_fit   output of fit_eirp_truncated_normal_rev1
%     inputs.eirp_table output of read_bs_eirp_distribution_rev1
%
%   Name-value options:
%     dist_km    Distance, km (100)
%     freq_mhz   Frequency, MHz (2700)
%     h_tx_m     Base station antenna height, m (30)
%     h_rx_m     Receiver antenna height, m (10)
%     step_m     Terrain profile spacing, m (100)
%     repo_root  Folder that holds data/ (repository root)
%
%   Needs matlab_itm on the path.
%
%   See also example_04_single_bs_100km_rev2, example_05_spread_rev1.

arguments
    options.dist_km (1,1) double {mustBePositive} = 100
    options.freq_mhz (1,1) double {mustBePositive} = 2700
    options.h_tx_m (1,1) double {mustBePositive} = 30
    options.h_rx_m (1,1) double {mustBePositive} = 10
    options.step_m (1,1) double {mustBePositive} = 100
    options.repo_root (1,1) string = fileparts(fileparts(mfilename("fullpath")))
end

if isempty(which("itm_p2p_rev1"))
    error("aggregate_explainer:NoItm", ...
        "itm_p2p_rev1 is not on the path. Run setup_aggregate_explainer_rev1 first.");
end

eirp_table = read_bs_eirp_distribution_rev1(fullfile(options.repo_root, "data", "7Ghz 0azi 0ele EIRP.xlsx"));
eirp_fit = fit_eirp_truncated_normal_rev1(eirp_table);

n_intervals = round(options.dist_km*1000/options.step_m);
pfl = [n_intervals, options.step_m, zeros(1, n_intervals + 1)];
h_tx = options.h_tx_m;
h_rx = options.h_rx_m;
f = options.freq_mhz;
d = options.dist_km;

inputs = struct();
inputs.eirp_q = @(p) reshape(icdf(eirp_fit.pd, p/100), size(p));
% validity "off": skip ITM's tail-percentage caution warnings; NTIA hard limits still apply.
inputs.path_q = @(p) reshape(itm_p2p_rev1(h_tx, h_rx, pfl, f, p, validity="off"), size(p));
inputs.clutter_q = @(p) reshape(p2108_terrestrial_clutter_loss_vector_rev2([], f, d, p), size(p));
inputs.names = ["EIRP", "Path loss", "Clutter loss"];
inputs.signs = [1 -1 -1];
inputs.eirp_fit = eirp_fit;
inputs.eirp_table = eirp_table;
inputs.settings = options;
end
