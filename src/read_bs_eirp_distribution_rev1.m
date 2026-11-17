function eirp_table = read_bs_eirp_distribution_rev1(xlsx_file)
%READ_BS_EIRP_DISTRIBUTION_REV1 Read a base station EIRP percentile table.
%   eirp_table = READ_BS_EIRP_DISTRIBUTION_REV1(xlsx_file) reads a workbook
%   in the layout of "7Ghz 0azi 0ele EIRP.xlsx" (FSS_Neighborhood):
%
%     Azimuth     0
%     Elevation   0
%      0th%       19.5
%     10th%       25.25
%     ...
%     100th%      42.5
%
%   and returns a table with variables percentile (%) and eirp_db, one row
%   per percentile, sorted by percentile. The azimuth and elevation of the
%   cut are stored in eirp_table.Properties.UserData.
%
%   Units: the workbook does not state them. FSS_Neighborhood normalizes
%   the table to its 50th percentile and adds the result to a fixed median
%   EIRP, so only the shape (dB relative to the median) is used there.
%
%   See also sample_from_percentile_table_rev1, readcell.

arguments
    xlsx_file (1,1) string {mustBeFile}
end

% readcell, not readtable: column 1 mixes header text and labels such as
% " 0th%" and "20th", which readtable would coerce.
c = readcell(xlsx_file);

labels = string(c(:, 1));
values = c(:, 2);

is_azi = strtrim(labels) == "Azimuth";
is_ele = strtrim(labels) == "Elevation";
is_pct = contains(labels, "th");
if ~any(is_pct)
    error("aggregate_explainer:EirpTable", ...
        "No percentile rows (for example ""50th%%"") found in %s.", xlsx_file);
end

percentile = str2double(extract(labels(is_pct), digitsPattern));
eirp_db = cell2mat(values(is_pct));

if any(isnan(percentile)) || any(~isfinite(eirp_db))
    error("aggregate_explainer:EirpTable", "Unparseable percentile row in %s.", xlsx_file);
end

eirp_table = sortrows(table(percentile, eirp_db), "percentile");
eirp_table.Properties.VariableUnits = ["%", "dB"];
if ~issorted(eirp_table.eirp_db)
    error("aggregate_explainer:EirpTable", ...
        "EIRP must not decrease with percentile in %s.", xlsx_file);
end
eirp_table.Properties.UserData = struct( ...
    "azimuth_deg", values{find(is_azi, 1)}, ...
    "elevation_deg", values{find(is_ele, 1)}, ...
    "source", xlsx_file);
end
