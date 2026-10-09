# Lean workflow (v1.1): superbrainstorming instead of Superpowers

**Status:** implemented · **Date:** 2026-10-09

## Why

v1.0 required the Superpowers plugin and named five of its skills in the
workflow. The lab reached the same conclusion for the R standards
([r-bioc-dev-standards#10](https://github.com/campbio/r-bioc-dev-standards/pull/10)):
with current models the full workflow overspecs and burns context, and a
step-by-step implementation plan does not beat building from a spec. The parts
worth keeping are brainstorming and the structure around debugging.

This change mirrors that one, so the lab runs one process across both
languages.

## What changes

`standards.md` goes to v1.1:

- **Precedence** names superbrainstorming rather than Superpowers.
- **EVALUATE** reproduces a bug and reports its root cause before a fix is
  proposed, instead of invoking the systematic-debugging skill.
- **PLAN becomes SPEC:** what changes, why, and how it is tested. Small changes
  are specified in chat; larger or unclear ones get a file in `dev/plans/`,
  committed after branching. A brainstorming design counts as the spec. No
  step-by-step implementation plan.
- **EXECUTE** branches before any code is written, builds from the spec and
  stays within it, and spells out that a new test must fail on its assertion.
- **REVIEW** gives a fresh subagent the spec to check the diff against.

The Testing section gains the same ask-clause as EXECUTE: report a failing test
rather than weakening it, and ask if the test itself looks wrong.

`README.md` swaps the Superpowers install for superbrainstorming, adds the
optional grill-me skill, explains why Superpowers is now optional and which of
a skill's defaults these standards override, rewrites process steps 1-4 to
match, and adds the new tools and the discussion behind the change to Sources.
`ADOPTING.md` updates the per-machine install. The PR template's "Plan review"
becomes "Spec review". `template/` picks up the wording in `AGENTS.md`,
`contributing.md` and the committed `dev/standards.md`.

## Review

A fresh subagent checked the diff against this spec, as step 4 now requires. It
found the README's Testing section still carrying the old wording after
`standards.md` had changed, an ambiguous "both" in ADOPTING, `/grill-me` cited
without noting it is optional, an undercount of the skills in
`mattpocock/skills`, and two edits this spec didn't describe. All are fixed or
folded into the text above. It also pointed out that superbrainstorming's own
gate conflicts with step 3 — verified against the installed copy, and now named
explicitly in the README.

## Where this departs from the R version

- **The `docs/` rule has a different reason, and it is enforced.** The R
  standards keep specs out of `docs/` because pkgdown overwrites that folder.
  Here `docs/` is committed Sphinx source published to Read the Docs, and
  `make docs-check` runs with `-W`, so any page no toctree includes fails the
  build. Verified: a file dropped in `docs/specs/` fails with
  `document isn't included in any toctree`. The rule enforces itself rather
  than relying on an agent remembering it.
- **The test-first rule names Python's failure mode.** A test for a function
  that does not exist yet fails at import, as a collection error, before pytest
  evaluates any assertion — so it has demonstrated nothing.

## Not adopted

The same three the R change rejected: a Stop hook that blocks on a red build,
a hook that freezes test files, and review by a second model family.

## Publishing

Packages see v1.1 when `v1` is moved to the merge commit. A developer who still
has Superpowers installed keeps working; these standards override its plan and
TDD defaults. The PR template change reaches a package only when it runs
`copier update`.
