function s = format_thousands_rev1(n)
%FORMAT_THOUSANDS_REV1 Integer as text with comma thousands separators.
%   s = FORMAT_THOUSANDS_REV1(100000) returns "100,000".
%
%   See also compose, regexprep.

arguments
    n (1,1) double {mustBeInteger}
end

s = regexprep(string(compose("%d", abs(n))), "(\d)(?=(\d{3})+$)", "$1,");
if n < 0
    s = "-" + s;
end
end
