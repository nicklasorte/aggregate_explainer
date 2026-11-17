# Plan: Google style pass and independent review

**DRAFT//PRE-DECISIONAL** · Plan for [working_paper.md](working_paper.md) and
the MATLAB code · 2026-11-17

This plan covers two jobs:

- **Style pass.** Edit the working paper to the Google developer documentation
  style guide.
- **Review.** Have a reviewer that didn't write the paper or the code try to
  find what is wrong with them.

**Status (2026-11-17):** Steps 1, 2, 4, 5, and 6 have run once. The reviews
and what was done with each finding are in [review/TRIAGE.md](review/TRIAGE.md).
Steps 3 and 7, Nick's triage and final read, are open.

## Order of work

The review runs first and the style pass second. A reviewer can change
content: numbers, claims, and whole paragraphs. Styling text that the review
then rewrites is wasted work.

| Step | Work | Output |
| --- | --- | --- |
| 1 | Review the code. | `docs/review/code_review.md` |
| 2 | Review the paper. | `docs/review/paper_review.md` |
| 3 | Triage the findings with Nick. | Each finding marked fix, defer, or reject |
| 4 | Fix the accepted findings. Rerun examples and tests. | Commits, updated figures and CSVs |
| 5 | Run the style pass on the corrected paper. | Edited `working_paper.md`, change summary |
| 6 | Rebuild the Word file. Confirm CI passes. | `working_paper.docx` |
| 7 | Nick reads the result. | Approval, or another round |

Steps 3 and 7 are human gates. The reviewer and the style pass propose; Nick
decides.

## Part 1: review

### Who reviews

The reviewer is a separate agent that starts with no memory of this work. It
gets the repository and the instructions that follow, and nothing else: no
chat history, no summary of what the author thinks is correct. The author of
the code doesn't grade the code.

Two reviewers run, with different jobs:

- **Reviewer A, code.** Reads `src/`, `examples/`, `tests/`, and the root
  scripts.
- **Reviewer B, paper.** Reads `docs/working_paper.md` beside the CSVs in
  `docs/results/`, the figures, and the cited sources.

### What Reviewer A checks

1. **Model correctness.** Compare
   `p2108_terrestrial_clutter_loss_vector_rev2` line by line with
   Recommendation ITU-R P.2108-1 Section 3.2 and with the NTIA/ITS reference
   code. Confirm that every constant has a cited source.
1. **Statistics.** Confirm that the inverse-transform sampling is right for
   each input. Confirm that the three inputs in Example 4 are independent.
   Check `sum_of_independent_db_rev1` for binning error.
1. **Edge cases.** Try percentages near 0 and 100, distances at 0.25 km and
   2 km, empty and non-finite inputs, and row, column, and matrix shapes.
1. **Reproducibility.** Run each example twice with one seed and confirm
   identical output. Run with a different seed and confirm that the paper's
   conclusions hold.
1. **Test quality.** For each test, ask whether it would fail if the code were
   wrong. Break the code on purpose in a scratch copy (for example, swap a
   sign or a constant) and confirm that a test catches it.
1. **Fit to the production simulation.** Compare the explainer's draws with
   `vector_mc_seed_pr_eirp_clutter_rev1` and its helpers in General_Movelist.
   List every place where the explainer simplifies or differs.

### What Reviewer B checks

1. **Every number.** Match each number in the paper to a CSV cell or a line of
   example output. Report any number with no source.
1. **Every claim.** For each sentence that states a cause or a conclusion, find
   the evidence. Mark claims that the evidence doesn't support.
1. **Model descriptions.** Check the description of P.2108-1, ITM, and the
   EIRP table against the sources. Check what each percentage means:
   locations, time, or operating states.
1. **Assumptions.** List the assumptions that the paper makes without saying
   so. Check that the stated ones (the 7 GHz EIRP table at 2.7 GHz, flat
   terrain, 0 dBi receive antenna) appear where a reader needs them.
1. **Reader test.** Read the paper as a non-engineer. After each section,
   write one sentence that says what the section taught. Report the sections
   where that sentence is hard to write.
1. **Figures.** Check each figure for labeled axes, units, the
   `DRAFT//PRE-DECISIONAL` marking, and a caption that says what to look at.

### Questions that the reviewers must answer

These questions come from the author's own doubts. The reviewers answer each
with evidence, not opinion.

- Is it valid to treat the ITM time percentage as a uniform random draw for
  one base station at one moment?
- Example 3 runs ITM with validity checks off. Does any draw fall outside the
  range where ITM is meant to be used?
- The paper applies clutter loss at the base station end only. Is that what
  the production simulation does?
- The function returns 0 dB of clutter loss below 0.25 km. The Recommendation
  gives no value there. Is 0 dB the right convention for this paper?
- The two peaks in the EIRP output come from interpolating 11 points. Does the
  choice of spline, `pchip`, or linear change any conclusion in Example 4?
- Does the worst-case stack comparison in Section 6 use the right percentiles?

### Finding format

Each reviewer writes a Markdown file with one row for each finding:

| Field | Content |
| --- | --- |
| ID | `A-01`, `B-01`, and so on |
| Severity | Blocker, major, minor, or note |
| Location | File and line, or section and paragraph |
| Finding | What is wrong, in one or two sentences |
| Evidence | The command, calculation, or source that shows it |
| Suggested fix | The smallest change that resolves it |

Severity has these meanings:

- **Blocker.** A wrong result or a false statement in the paper.
- **Major.** A result that is right but unsupported, untested, or likely to
  mislead.
- **Minor.** A clarity or robustness problem.
- **Note.** An observation that needs no change.

A reviewer that finds nothing reports what it checked and how, so that "no
findings" can be told apart from "didn't look."

## Part 2: Google style pass

### Mode and scope

The pass uses the skill's edit mode: it rewrites `working_paper.md` in place
and returns a change summary grouped by rule. It covers the working paper
only. `README.md`, `CLAUDE.md`, and the plan files get the same pass later if
Nick wants it.

Style never overrides correctness. The pass changes no number, equation, or
technical claim.

### What a first scan found

A quick scan of the paper against the core rules found these patterns. The
full pass confirms and extends the list.

| Pattern | Example in the paper | Change |
| --- | --- | --- |
| Space before the percent sign | "50 %", "1 % to 99 %" | "50%", "1% to 99%" |
| Bold used for emphasis | "**P.2108 clutter loss is a normal distribution in dB**" | Italics, or no emphasis |
| List introduced by a fragment | "Things to notice:" | A complete sentence |
| Unit not repeated in a range | "0.5 to 67 GHz" | "0.5 GHz to 67 GHz" |
| Abbreviation not defined at first use | EIRP, TX, RX | Spell out once, then abbreviate |
| File name as link text | "See PLAN_turn_off_list_section.md" | Descriptive link text |
| Ambiguous "may" | "may not exceed the value" | "can't exceed the value" |
| Forward-looking text in the body | "planned" sections named mid-paper | Keep in the "Planned sections" section only |
| Sentences over 26 words | Several in Sections 2 and 3 | Split |
| Passive voice | "is checked against", "is called" | Active, where the actor matters |

### Domain conventions to keep

The skill allows a field's conventions to stand. The pass keeps the following
conventions and says so in its change summary:

- **Numbered section headings.** Google style says not to number headings. A
  working paper needs section numbers for cross-references, so they stay.
- **Standards designations.** "ITU-R P.2108-1", "ITM v1.4", and equation
  labels such as "(3a)" keep their official form.
- **Units.** dB, dBm, dBi, GHz, and N-units stay as the standards write them.
- **The marking.** `DRAFT//PRE-DECISIONAL` stays in capitals.
- **Math.** Equations and the minus sign in tables are not restyled.
- **Roadmap facts.** The pass moves planned work into the "Planned sections"
  section. It doesn't delete it.

### Checks on the style pass

- Compare the numbers in the paper before and after the pass with a script.
  The two sets must be identical.
- Rebuild the Word file and look at every page.
- Run the skill's review mode on the edited paper. The pass is done when the
  review reports no clarity or correctness issue.

## Checks on the whole plan

| Check | Who runs it |
| --- | --- |
| `buildtool check test` passes after every fix | CI and the author |
| Each accepted finding has a commit that names its ID | The author |
| Each blocker has a new test that fails before the fix and passes after it | The author |
| Paper numbers match the CSVs | Script, then Reviewer B |
| Final read | Nick |

## Ambition ladder

The base plan gives one review and one style pass. These rungs go further.
Each one is a request that you can paste.

### Depth: review the way a verification team does

This dimension fits because the paper's claim is "every number comes from the
code," and that claim is testable.

1. **Numbers under test.** "Write a script that pulls every number out of
   `working_paper.md`, matches it to a CSV cell in `docs/results/`, and fails
   CI when a number has no match or the wrong value."
   *Needs:* a tag in the Markdown for each number's source.
   *Check:* change one digit in the paper and confirm that CI fails.
1. **Independent reimplementation.** "Have a separate agent write the P.2108
   calculation and the Example 4 Monte Carlo from the Recommendation and the
   paper's text alone, in Python, without seeing the MATLAB. Compare the
   results."
   *Needs:* nothing new.
   *Check:* agreement to 0.01 dB on the model, and to sampling error on the
   Monte Carlo result.
1. **Mutation testing.** "Make 30 single-line changes to the `src/` functions,
   one at a time, and report which ones the tests don't catch. Add a test for
   each survivor."
   *Needs:* nothing new.
   *Check:* the count of surviving changes drops to zero, or each survivor is
   explained.

### Altitude: aim at what the paper is for

This dimension fits because the paper exists so that people trust and
understand the simulation, and neither is tested by a style check.

1. **Reader trial.** "Give the paper to three fresh agents that play a policy
   analyst, a radar engineer, and a wireless-industry engineer. Each answers
   five questions on what the simulation does. Report the wrong answers and
   the sections that caused them."
   *Needs:* Nick's five questions, or approval of drafted ones.
   *Check:* a human reader from outside the project tries the same questions.
1. **Standing review gate.** "Add the reviewer as a step that runs on every
   pull request that changes `docs/working_paper.md` or `src/`, and posts its
   findings as a comment."
   *Needs:* a decision on where the reviewer runs and who reads its output.
   *Check:* a seeded error in a test pull request produces a finding.

### Range: borrow from other fields

This dimension fits because the audience includes people who will test the
paper's weak points.

1. **Opposing filer.** "Have a red-team agent write the strongest technical
   rebuttal that a party opposed to this analysis would file. Answer each
   point in the paper or record it as an open issue."
   *Needs:* nothing new; public material only.
   *Check:* Nick judges whether the rebuttal points are real.
1. **Accessibility check.** "Check the figures and the Word file against
   Section 508: color contrast, color-only encoding, alt text, table headers,
   and reading order."
   *Needs:* nothing new.
   *Check:* the Word accessibility checker reports no errors.

## Decisions needed

1. Which rung runs first, after the base plan: depth 1 (numbers under test),
   depth 2 (independent reimplementation), or range 1 (opposing filer)?
1. Does the style pass also cover `README.md` and the plan files?
