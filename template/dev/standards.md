# Python Package Development Standards v1.0

Rules for developing Python packages in the Campbell lab. Claude Code loads
this file at session start through a hook; every package also commits a copy at
`dev/standards.md` so any agent can read it. Rationale for each rule: README.md
in the py-dev-standards repo.

## Precedence
1. Package AGENTS.md "Overrides"
2. This file
3. Skill defaults (Superpowers, others)

On conflict, follow the higher level and say so.

## Workflow
1. EVALUATE, no edits. Bug: systematic-debugging, report the root cause.
   Feature: brainstorming. Dependency change: read the upstream changelog and
   list affected call sites. Wait for the go-ahead.
2. PLAN: writing-plans. Cover whichever apply: code, type annotations, tests,
   docstrings, docs pages, tutorials, CHANGELOG, version bump, dashboard,
   checks. Wait for approval.
3. EXECUTE: fetch the shared repo's `devel`, then branch as `fix/<topic>` or
   `feature/<topic>`. Never work on `devel` or `main`. Small plan:
   executing-plans. Multi-task plan: subagent-driven-development. Use TDD with
   pytest. Make small local commits whose messages say what and why.
4. REVIEW: requesting-code-review against the plan, then `/code-review` on the
   branch. Fix findings, or say why one doesn't apply.
5. HAND OFF: stop before anything leaves the machine. Give a summary, list
   anything unverified, say whether results, numbers, or plots change, and show
   `git log devel..HEAD` and `git diff devel...HEAD`. No push, PR, or merge
   until the developer approves.
6. AFTER APPROVAL: push the branch and open a PR with base `devel` (never
   `main`). Fill in the PR template, but never its "Scientific correctness"
   section; a person verifies that. Put follow-up fixes on the same branch;
   never open a second PR. Merge only after CI is green and a person approves
   on GitHub. No local merges. No history rewrites after a push.

Plans and designs go in `dev/plans/`, never `docs/`.

## Remotes
- Identify remotes by URL (`git remote -v`), not by name.
- Usual names: `origin` = where you push; the GitHub org or owner name =
  shared repo (when working from a fork).
- Never push to `main` on any remote. That is a release action.

## Branches and tags
- `devel`: all development, and the PR base for everything.
- `main` (the GitHub default): the last released state, what a bare
  `pip install git+...` gets. Never commit to it, branch from it, or open a PR
  against it. The only PR into `main` is a release, opened by a person.
- Never create, move, or push tags. A person tags each release on `main`.
- `release/x.y` branches exist only when the maintainer creates one for a
  backport. Never create one.

## Commands
- Use only Makefile targets: `sync`, `lock`, `test`, `test-one FILTER=<pat>`,
  `lint`, `format`, `typecheck`, `check`, `check-full`, `coverage`, `docs`,
  `docs-check`, `docs-links`, `tutorial FILTER=<name>`, `app`, `app-test`,
  `build`.
- Extra targets are allowed only if AGENTS.md lists them. Ask before running
  any extra target that AGENTS.md doesn't mark as safe.
- `make test-one FILTER=<pattern>` and `make tutorial FILTER=<name>` each run
  on their own: no other targets, variables, or flags on that command line.
- While developing: `test-one`. Before hand-off: `check` and `coverage`.
  Before a PR: `check-full`.
- If a target is missing, ask. Never substitute raw `pytest`, `ruff`, `mypy`,
  `uv run`, `uv add`, `pip`, or `sphinx-build`, even when a skill suggests them.
- Never install into the environment by hand. A dependency change means editing
  `pyproject.toml`, then `make lock` and `make sync`, and it needs an ADR.
- `make app` starts a server that keeps running. Ask before using it.

## User-facing code (docstring examples, tutorials, README)
Audience: Python novices who copy code verbatim. The code must run as pasted.
- One operation per line, descriptive names, a short comment per step.
- Use defaults; pass only the arguments being demonstrated.
- `import package as pkg` at the top, then plain calls. No star imports.
- Avoid comprehension chains, `lambda`, `map`/`filter`, decorators, and ad hoc
  helper functions.
- Bundled or simulated data only. Seed every random number generator
  (`rng = np.random.default_rng(0)`), never the global `np.random.seed`.
- Tutorials: short, small data, runnable end to end, and they end by printing
  package and dependency versions. Long real-data workflows get their own
  tutorial page, not the quickstart.
- When behavior changes, update the affected docstring examples and tutorials.

## Package code
- `src/<package>/` layout. Match the package's existing naming for modules,
  functions, and arguments.
- Keep related functions in one module; put utilities in their own module.
  Public API is declared in `__all__` and re-exported from `__init__.py`.
- Keep functions small, with no duplicated logic. Prefix internal helpers and
  modules with `_`.
- Annotate every public signature, including the return type. Prefer concrete
  types; use `npt.NDArray`, `pd.DataFrame`, and protocol types rather than
  `Any`. `from __future__ import annotations` at the top of every module.
- Validate inputs early. Raise `TypeError` for a wrong type and `ValueError`
  for a bad value, and name the argument and the problem in the message. Never
  `assert` for input validation.
- Never catch bare `Exception` to hide an error; let it propagate or re-raise
  with context.
- A module-level `logger = logging.getLogger(__name__)` for progress and
  diagnostics. Never `print()` in library code, and never configure logging
  handlers inside the package.
- Ruff and mypy must pass: 88 columns, no unused imports, sorted imports,
  NumPy-style docstrings on every public object.
- `make format` on new files only. Never reformat existing code in a functional
  change; a formatting backlog gets its own PR.

## Docs and data
- Every public object: a NumPy-style docstring with a one-line summary,
  `Parameters` (each with its type and default), `Returns`, `Raises` where it
  applies, and a runnable `Examples` block.
- Never hand-edit generated files: `uv.lock`, `docs/_build/`,
  `docs/api/_autosummary/`, or anything a build writes. Edit the source and
  re-run the target.
- Add every new public object to `docs/api.md`, then run `make docs-check`.
  Render an edited tutorial with `make tutorial FILTER=<name>`.
- CHANGELOG.md: an entry for every user-facing change, under `## Unreleased`,
  in the file's existing Keep a Changelog format.
- Bundled data lives in the package and is loaded through
  `importlib.resources`, never a path relative to `__file__`. Large data is
  downloaded by `pooch` with a recorded hash, never committed.
- Every bundled dataset: a generating script under `data-raw/` with a fixed
  seed, and a documented loader function.

## Testing
- Bug fixes start with a failing regression test.
- New functions: test expected results plus error paths with
  `pytest.raises(ValueError, match="...")`.
- The whole suite must pass, not just nearby tests.
- Tiny fixtures in `tests/conftest.py`. Use `tmp_path`, never a hard-coded
  temp path, and never write inside the repo.
- Coverage (`make coverage`) must not drop.
- Optional dependencies: `pytest.importorskip` so the suite skips cleanly when
  one is missing.
- Never weaken an assertion, add a `skip`, or loosen a tolerance to make a test
  pass. Report the failure instead.

## Dashboard apps
The app lives in `src/<package>/app/` as a real subpackage, behind an optional
`app` extra, and is started by `make app`.
- No analysis logic in the app. Its callbacks only call public, tested package
  functions. Implement a new feature as a package function with tests first,
  then wire it into the app.
- The framework (Streamlit or Shiny for Python) is named in AGENTS.md. Changing
  it needs an ADR.
- Test the app's logic with `make app-test`: Streamlit through
  `streamlit.testing.v1.AppTest`, Shiny by unit-testing the server functions.
- Verify any visual change with a Playwright screenshot of the running app and
  attach it to the PR.

## Versions and releases
- SemVer in `pyproject.toml`'s `version`, which is the single source of truth;
  `__version__` reads it through `importlib.metadata`.
- Bump the patch for a fix, the minor for a backward-compatible addition, the
  major for a breaking change. Bump as part of the change, not at release.
- Deprecate before removing: `warnings.warn(..., DeprecationWarning,
  stacklevel=2)` for one minor release, remove in the next. Note both in the
  CHANGELOG.
- Never drop or raise the minimum Python version without an ADR.
- Releases follow `dev/RELEASE.md` and are run by a person.

## Checks
- `make check` must pass before hand-off; `make check-full` before a PR.
- Any ruff, mypy, pytest, or Sphinx error or warning blocks. Triage each
  finding as a defect, an environment gap, or a false positive, and say which.
- Never silence a finding with `# noqa`, `# type: ignore`, or a `pyproject`
  exclusion without naming the rule and giving the reason in the same line and
  in the hand-off.
- Record real findings that are out of scope as GitHub issues, one category per
  fix PR.

## Scope and safety
- Minimal, on-topic changes. Log unrelated problems as issues.
- Structural changes need an approved ADR in `dev/adr/` (see its README):
  adding or removing a dependency, changing the public API, reorganizing
  modules, changing the minimum Python version, choosing or changing the
  dashboard framework, or changing build, test, docs, or release machinery.
  Propose it through an issue.
- Never edit `.claude/settings.json`, `Makefile`, `dev/hooks/`,
  `dev/standards.md`, `uv.lock`, the downloaded copies in
  `~/.cache/py-dev-standards/`, or this file. Propose changes instead.
- Never delete files or branches, run `git clean`, or force-push. Ask the
  developer.
- No secrets, tokens, or absolute local paths in commits. No network calls at
  import time or in tests.
- Flag any effect on related packages named in AGENTS.md.
- Maintainer docs live in `dev/`.
