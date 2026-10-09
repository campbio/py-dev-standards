# Architecture Decision Records

Decisions about this package that are hard to reverse, or that a future
contributor would otherwise question and reopen, are recorded here as numbered
ADRs.

## When an ADR is required

Write one before implementing any change that:

- adds, removes, or replaces a runtime dependency;
- changes the public API or breaks backward compatibility;
- splits, merges, or reorganizes modules;
- changes the minimum supported Python version;
- chooses or changes the dashboard framework;
- changes the build, test, documentation, or release machinery;
- introduces compiled, GPU, or otherwise platform-specific code;
- changes how data is stored, downloaded, or represented.

Routine choices don't need one: a new keyword argument, a bug fix, a refactor
inside one function, or anything a reviewer could evaluate from the diff alone.
The test is whether someone six months from now would ask "why is it like
this?"

## Process

1. Propose the decision in a GitHub issue.
2. Draft the ADR from `template.md` with status **Proposed**.
3. The maintainer approves it; the status becomes **Accepted** and the ADR gets
   the next number.
4. Implement.

ADRs are append-only. An accepted ADR is never edited or deleted. A later ADR
supersedes it, the old one's status changes to **Superseded by NNNN**, and both
stay in place, because the record of what was decided before, and why, is the
point.

## Index

| # | Title | Status | Date |
|---|---|---|---|
