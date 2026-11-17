function plan = buildfile
%BUILDFILE Build plan for aggregate_explainer (run with buildtool).
%   buildtool              Run the default tasks: check, then test.
%   buildtool check        Code Analyzer on src/, examples/, tests/, and root files.
%   buildtool test         Unit tests in tests/.
%   buildtool examples     Rebuild docs/figures/*.png and docs/results/*.csv.
%                          Needs matlab_itm (setup clones it on first use).
%
%   The Word version of the paper is built outside MATLAB:
%     python3 docs/build/build_working_paper_docx.py
%
%   See also buildtool, run_all_examples_rev1.

import matlab.buildtool.tasks.CodeIssuesTask
import matlab.buildtool.tasks.TestTask

plan = buildplan(localfunctions);

plan("check") = CodeIssuesTask(["src", "examples", "tests", "buildfile.m", ...
    "setup_aggregate_explainer_rev1.m", "run_all_examples_rev1.m"], ...
    WarningThreshold=0);

plan("test") = TestTask("tests", ...
    SourceFiles=["src", "examples"], ...
    Strict=true);

plan("examples").Dependencies = "test";

plan.DefaultTasks = ["check", "test"];
end

function examplesTask(~)
% Rebuild every figure and results table for the working paper.
run_all_examples_rev1();
close all
end
