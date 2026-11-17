function setup_aggregate_explainer_rev1(options)
%SETUP_AGGREGATE_EXPLAINER_REV1 Put the explainer code and matlab_itm on the path.
%   SETUP_AGGREGATE_EXPLAINER_REV1() adds src/ and examples/ to the path.
%   If itm_p2p_rev1 is not already on the path, it clones
%   https://github.com/nicklasorte/matlab_itm into ext/matlab_itm (once)
%   and adds it.
%
%   Name-value options:
%     itm_folder  Existing matlab_itm folder to use instead of cloning ("")
%
%   See also gitclone, addpath.

arguments
    options.itm_folder (1,1) string = ""
end

repo_root = fileparts(mfilename("fullpath"));
addpath(fullfile(repo_root, "src"), fullfile(repo_root, "examples"));

if ~isempty(which("itm_p2p_rev1"))
    return
end

if options.itm_folder == ""
    itm_folder = fullfile(repo_root, "ext", "matlab_itm");
    if ~isfolder(itm_folder)
        gitclone("https://github.com/nicklasorte/matlab_itm", itm_folder, Depth=1);
    end
else
    itm_folder = options.itm_folder;
end

if ~isfile(fullfile(itm_folder, "itm_p2p_rev1.m"))
    error("aggregate_explainer:NoItm", "itm_p2p_rev1.m not found in %s.", itm_folder);
end
addpath(itm_folder);
end
