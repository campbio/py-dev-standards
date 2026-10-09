# py-dev-standards

Development standards for the Campbell lab's Python packages, and a process for
adding or changing code in them with help from AI coding agents such as Claude
Code. The standards apply to people and agents alike, and anyone maintaining a
scientific Python package can use or adapt them.

This is the Python sibling of
[r-bioc-dev-standards](https://github.com/campbio/r-bioc-dev-standards), which
does the same job for the lab's R/Bioconductor packages.

This repo has two versions of the same standards:

- **`standards.md`** is the condensed version that Claude Code loads
  automatically at the start of every session in a package that uses it, and
  that every package commits at `dev/standards.md` for other agents to read.
  It's kept short because it takes up space in every session.
- **This README** explains the same rules in full, including why each one
  exists. Read this if you're new to a package that follows these standards, or
  if you want to understand or change a rule.

When you change a rule, update both files so they stay in sync.

## How the standards reach each package

The shared files live only in this repo. Packages keep small, stable pieces
that fetch or call them, so a fix made here reaches every package without
editing each one. There are four ways a file gets to a package:

- **Downloaded at session start.** Each package has a startup hook,
  `dev/hooks/load-standards.sh`, registered in its `.claude/settings.json`.
  When a Claude Code session starts, resumes, is cleared, or is compacted, the
  hook downloads `standards.md`, the lint hook, and the shared make targets
  into `~/.cache/py-dev-standards/`, then adds `standards.md` to Claude's
  context. If GitHub can't be reached it uses the last downloaded copies; if
  there are none it falls back to the package's committed `dev/standards.md`.
  Either way it says the copy may be out of date, and it always exits 0, so a
  network problem never blocks a session.
- **Committed in the package.** `dev/standards.md` is a copy of the same file.
  Claude Code never needs it, but Gemini, Codex and anything else reading
  `AGENTS.md` do, because an instruction to go and fetch a URL is not reliably
  followed. `make standards-sync` refreshes it and a workflow warns when it has
  fallen behind.
- **Called by GitHub.** The workflows that run CI, check pull-request base
  branches, publish releases and watch for standards drift live in this repo's
  `.github/workflows/`. Each package has short workflows that call them.
- **Generated once by copier, then owned by the package.** Files that differ
  between packages — `pyproject.toml`, the Makefile, `AGENTS.md`,
  `.claude/settings.json`, the docs tree — come from `template/` and belong to
  the package afterwards. `copier update` re-applies later improvements without
  discarding local edits.

A second hook, `dev/hooks/lint-changed.sh`, runs ruff and mypy on each Python
file right after Claude edits it and passes the findings back, so style and
type problems are caught as the code is written rather than in CI. It only
reports; it never rewrites the file, because auto-formatting on every edit
buries the real change in formatting noise.

Both hooks are registered with paths relative to the package root
(`bash dev/hooks/...`), so start `claude` from the package's top folder.

**Versions.** Packages use the `v1` tag of this repo, not `main`. Changes
merged to `main` reach packages only when the maintainer moves `v1`, which
gives a chance to test a change first (see "Changing these standards"). Because
packages download and run scripts and make recipes from this repo, `main` is
protected and changes arrive by pull request.

Each package's own `AGENTS.md` adds what's specific to that package: its
structure, its public API, slow tests, its dashboard, related packages, and any
exceptions to these standards. When the two disagree, the package's "Overrides"
section wins, then these standards, then the default behavior of any skill
Claude is using. That order lets a package make a deliberate exception without
editing the shared rules, and it keeps general-purpose skills from overriding
the standards.

To set up a package, follow [ADOPTING.md](ADOPTING.md). To use these standards
for your own packages, fork this repo, point each package's hook and Makefile at
your fork, and adapt the rules.

## Files in this repo

| File | Purpose |
|---|---|
| `standards.md` | The condensed standards, loaded into each session |
| `README.md` | The full explanation of each rule (this file) |
| `ADOPTING.md` | Steps to set up a package |
| `copier.yml` | The questions asked when generating or updating a package |
| `template/` | Everything a package gets: code layout, config, docs, `dev/`, workflows |
| `hooks/load-standards.sh` | The startup hook, copied once into each package's `dev/hooks/` |
| `hooks/lint-changed.sh` | Stub for the after-edit lint hook, copied once into each package |
| `shared/standards.mk` | The standard `make` targets, downloaded and included by each package's Makefile |
| `shared/lint-changed.sh` | The lint hook itself, downloaded at session start |
| `.github/workflows/ci.yaml` | Shared workflow: lint, typecheck, test matrix, coverage, docs |
| `.github/workflows/pr-base-devel.yaml` | Shared workflow: fails pull requests aimed at `main` |
| `.github/workflows/release.yaml` | Shared workflow: build and publish to PyPI by trusted publishing |
| `.github/workflows/standards-drift.yaml` | Shared workflow: warns when a package's `dev/standards.md` is stale |
| `.github/workflows/self-check.yaml` | This repo's own CI: consistency, plus a generated package's full gate |
| `dev/check-repo.sh` | Checks that `template/`'s committed copies match their originals |
| `dev/plans/` | Specs for changes to this repo |

## What you need on your machine

- **[uv](https://docs.astral.sh/uv/)** for environments, locking and building.
- **Claude Code.**
- **The superbrainstorming plugin**, which provides the brainstorming skill
  used to design features (step 1 below). Install it once, from inside Claude
  Code:

  ```
  /plugin marketplace add harrymunro/superbrainstorming
  /plugin install superbrainstorming@superbrainstorming
  ```
- **Optional: the grill-me skill**, which you start with `/grill-me` to have
  Claude question you about a spec or an issue you wrote, one round of numbered
  questions at a time, until nothing is left assumed. It calls a second skill,
  `grilling`, so link both:

  ```bash
  git clone https://github.com/mattpocock/skills.git ~/src/mattpocock-skills
  ln -s ~/src/mattpocock-skills/skills/productivity/grill-me ~/.claude/skills/
  ln -s ~/src/mattpocock-skills/skills/productivity/grilling ~/.claude/skills/
  ```

  Run `git pull` in that clone now and then. The `mattpocock-skills` plugin
  installs it too, along with three dozen other skills you may not want.

`copier` is run through `uvx copier`, so there is nothing to install for it.

**Superpowers is optional.** Version 1.0 of these standards required the
[Superpowers](https://github.com/obra/superpowers) plugin and named five of its
skills in the workflow. With current models its step-by-step implementation
plans cost a lot of context and time without improving the result (see "Write a
spec" below), so the standards now use only its brainstorming part, through
superbrainstorming. You can still use Superpowers if you prefer it, but install
it or superbrainstorming, not both: each has a `brainstorming` skill and a
session-start hook.

Where a skill's defaults conflict with these standards, the standards win (see
"Precedence" in `standards.md`). Two conflicts come up in normal use.
Superbrainstorming writes its design to `docs/specs/` and commits it; here specs
go in `dev/plans/`, because `docs/` is published. And it starts building as soon
as you approve the design, where these standards first have Claude create the
work branch (step 3). Superpowers additionally wants a detailed implementation
plan, which step 2 replaces with a spec.

The standards still make sense if a skill is missing: each step also describes
what to do, so the process can be followed by hand.

## Why uv, ruff, pytest and mypy

One toolchain for every package, so that moving between them costs nothing and
so the shared make targets mean the same thing everywhere.

**uv** resolves and installs in seconds, produces a cross-platform `uv.lock`
that pins the whole dependency graph, and manages Python versions itself, so a
new contributor needs nothing on their machine but uv. The targets run
`uv run --locked`, which installs from the lockfile but refuses to re-resolve:
an unapproved dependency edit in `pyproject.toml` fails loudly instead of being
installed silently.

**ruff** replaces flake8, isort, pydocstyle, pyupgrade and black with one tool
that runs fast enough to use as an edit-time hook. That speed is what makes the
`lint-changed` hook possible.

**mypy** in strict mode on `src/` is what makes a type annotation worth
writing. Tests are checked less strictly, because a test that needs a
deliberately wrong argument should be allowed to pass one.

**pytest** collects `src/` as well as `tests/`, so `--doctest-modules` runs
every `Examples` block in every docstring. The standards require those examples
to work as pasted; this is what checks it, rather than trusting a reviewer to
notice.

**hatchling** builds the package with no configuration beyond naming the
source directory.

## The development process

Six steps, each ending somewhere the developer can look at the work. The shape
is deliberate: an agent that is allowed to evaluate, specify, write, review and
then stop produces something reviewable, while an agent that goes from a
one-line request straight to a pull request does not.

### 1. Evaluate before writing anything

No edits. For a bug, Claude reproduces it first, so the fix can be shown to
work, then traces it to its root cause and reports that before proposing
anything; a fix aimed at a symptom often just moves the bug. For a feature, the
brainstorming skill asks questions one at a time until the design is clear, and
offers two or three approaches where there is a real choice. To have your own
idea questioned harder, run `/grill-me`, if you installed that optional skill. For a dependency change, read the
upstream changelog and list the call sites it affects. Then wait.

The point is to separate "what is actually wrong" from "what shall we do about
it". An agent that starts editing while it is still forming a hypothesis
produces changes that are hard to review, because the diff contains both the
investigation and the fix.

### 2. Write a spec

Claude writes a spec: what will change, why, and how it will be tested. It
covers whichever of these apply: code, type annotations, tests, docstrings,
documentation pages, tutorials, the changelog, the version bump, the dashboard,
and the checks to run. A small change gets a few sentences in the chat. A larger
one, or one where the approach is unclear, gets a file in `dev/plans/`,
committed once the work branch exists. When the brainstorming skill produced a
design, that design is the spec.

A spec is not a step-by-step implementation plan. Current models do better
building from a spec than from a script of every edit, and a long plan takes
time to write and review and fills the context the model needs for the work
itself. Keep the spec in proportion to the change.

Specs can't go in `docs/`: that folder is published to Read the Docs, and
`make docs-check` fails on any page no toctree includes — which is what a spec
dropped there would be. That includes `docs/specs/`, where superbrainstorming
saves them by default.

Then wait. Review the spec before approving it: correcting a wrong approach in a
spec takes minutes, correcting it after implementation takes hours.

### 3. Execute on a new branch

Fetch the shared repository's `devel`, then branch as `fix/<topic>` or
`feature/<topic>`, before any code is written. Never work on `devel` or `main`
directly.

Claude builds from the approved spec and stays within it. Problems it notices
elsewhere become issues rather than getting fixed on the way, which keeps the
diff reviewable.

Write the test first. For a bug fix that means a regression test that fails for
the reason the bug exists; for a new function it means tests for the expected
result and for the error paths. The failure has to be the right one: the
assertion fails because the behavior is wrong, not because the function doesn't
exist yet. In Python that distinction matters more than it looks, because a test
for a function that hasn't been written fails at import, before pytest ever
reaches the assertion — so the test has told you nothing.

Claude never weakens, skips, or deletes a test to make it pass. If a test looks
wrong, it says so and asks. A test edited to match the code has stopped checking
anything.

Commit in small pieces, with messages that say what changed and why.

### 4. Review

A fresh subagent, which hasn't watched the work happen, is given the spec and
checks the diff against it. Then Claude runs `/code-review` on the whole branch
and fixes what it finds before showing it to you. Where a finding doesn't apply,
it says why. The two reviews catch different things: the first checks that the
spec was carried out and nothing more, and `/code-review` looks for bugs and
risks in the diff itself, including in files the spec never mentioned. A
reviewer with a fresh context is likelier to question the work than the session
that wrote it.

### 5. Hand off to the developer

Stop before anything leaves the machine. Give a summary, list anything that
wasn't verified, say whether results, numbers or plots change, and show
`git log devel..HEAD` and `git diff devel...HEAD`.

This is the most important step. Everything up to here is reversible with
`git checkout`; a push is not. The permission settings make `git push` and
`gh pr create` prompt even in auto-accept mode, so this pause happens whether
or not the agent remembers to make it.

### 6. Push and open a pull request

After approval: push the branch and open a pull request with base `devel`.
Never `main`.

Fill in the template, except the "Scientific correctness" section — a person
decides whether the numbers are still right, and passing tests is not evidence
that they are. The "Generated content" section says which parts an agent wrote,
so reviewers know where to look hardest.

Follow-up fixes go on the same branch. Never open a second pull request for the
same piece of work: review history belongs in one place. Merge only after CI is
green and a person approves on GitHub. No local merges, and no history rewrites
after a push.

## Remotes

Identify remotes by URL (`git remote -v`), not by name. `origin` is usually
where you push; when working from a fork, the shared repository is usually
named after the organization. Names are a local convention and differ between
clones, so a rule phrased in terms of them is not a rule.

## Branches, releases and tags

Two long-lived branches:

- **`devel`** holds all development and is the base for every pull request.
- **`main`** is the GitHub default branch and holds the last released state.

`main` is the default branch because `pip install git+https://...` with no ref
installs the default branch's HEAD. That is how students, collaborators and
reviewers usually get a package before it is on PyPI, and they should get
released code. If development happened on `main`, every one of those installs
would pick up whatever was merged most recently, finished or not.

This is the one place where the Python model is simpler than the Bioconductor
one. Bioconductor owns the release branch, so the R standards need a
CI-maintained copy of it and `RELEASE_X_Y` branches. Here nothing external owns
`main`, so a release is an ordinary pull request from `devel` into `main`, an
annotated tag on the merge commit, and a GitHub Release. The `pr-base-devel`
workflow fails any other pull request aimed at `main`, which is the one thing
that could quietly break the guarantee.

The cost is that anyone who clones lands on `main` and has to switch to
`devel`. That is the same trip-up the lab's Bioconductor packages already have.
`release/x.y` branches exist only if a backport is ever needed, and are created
by a person.

Agents never create, move or push tags. A tag is the identity of a release, and
moving one makes a published artifact unreproducible.

## Commands

Everything runs through `make`, and only through `make`:

| Target | What it does |
|---|---|
| `sync` | Install the package with every extra and dependency group |
| `lock` | Re-resolve `uv.lock` after an approved dependency change |
| `test` | The whole suite, including docstring examples |
| `test-one FILTER=<pattern>` | Matching tests only |
| `lint` | ruff check and format check; reports, changes nothing |
| `format` | Apply formatting and safe automatic fixes |
| `typecheck` | mypy on `src/` |
| `check` | lint + typecheck + test |
| `check-full` | check + coverage + docs + build + `twine check` |
| `coverage` | Coverage report, failing below the package's floor |
| `docs` | Build the HTML docs into a temp folder |
| `docs-check` | Build with warnings as errors, and verify every public object is documented |
| `docs-links` | Check external links (needs network) |
| `tutorial FILTER=<name>` | Execute and render one tutorial |
| `app` | Start the dashboard |
| `app-test` | The dashboard tests only |
| `build` | sdist and wheel |

While developing, use `test-one`. Before hand-off, `check` and `coverage`.
Before a pull request, `check-full`.

Three reasons for the rule:

**The same command means the same thing everywhere.** CI runs these targets,
not its own recipe, so a green CI and a green machine are the same claim.

**The flags are decided once.** `make docs-check` is
`sphinx-build -b html -W --keep-going -n`, which is what Read the Docs does.
Nobody has to remember that, and nobody can accidentally run the weaker
version.

**It is the surface the permission settings can describe.** The allow-list in
`.claude/settings.json` names targets. If agents ran tools directly, the
settings would have to allow arbitrary shell, and the distinction between a
test run and a destructive command would be gone.

`make test-one FILTER=<pattern>` and `make tutorial FILTER=<name>` must be the
only target on their command line, and `FILTER` may contain only letters,
digits, `.`, `_` and `-`. The settings allow `make test-one` with any
arguments, so the Makefile checks the arguments itself, before anything runs.
Without those guards, `make test-one FILTER=x clean` would run a people-only
target with no prompt, and a `FILTER` containing shell metacharacters would run
as a command. The Makefile also refuses any other variable on the command line,
since one could change which shell, makefile or source is used.

Extra targets are allowed, but they must be listed in `AGENTS.md` with whether
an agent may run them. Targets that are for people only go in `PEOPLE_ONLY`,
which makes them refuse to run when `CLAUDECODE` is set, and in the settings
deny list. Two mechanisms because the deny list matches exact command strings
and the Makefile check does not care how the target was invoked.

Never substitute raw `pytest`, `ruff`, `mypy`, `pip`, `uv add` or
`sphinx-build`, even when a skill suggests them. If a target is missing, ask.

## Writing code for novice users

Docstring examples, tutorials and the README are read by people who will paste
the code and run it. Many of them are learning Python at the same time as they
are learning the package.

- One operation per line, with descriptive names and a short comment per step.
- Use defaults; pass only the arguments being demonstrated.
- `import package as pkg` and then plain calls. No star imports.
- Avoid comprehension chains, `lambda`, `map`/`filter` and ad hoc helpers.
  Clever code teaches the reader about Python, not about the package.
- Bundled or simulated data only, and seed every random number generator with
  `rng = np.random.default_rng(0)` rather than the global `np.random.seed`,
  which leaks state between cells.
- Tutorials stay short, use small data, and end by printing the versions used,
  so a result that cannot be reproduced can at least be explained.

Tutorials are MyST Markdown notebooks executed by `myst-nb` when the docs are
built. Markdown rather than `.ipynb` because a notebook's JSON diff is
unreadable in review, and executed rather than pasted because a tutorial that
no longer runs should be a failed build, not a page of stale output.

When behavior changes, update the affected examples and tutorials in the same
pull request.

## Package code conventions

**Layout.** `src/<package>/`, so that tests run against the installed package
rather than the working directory, and a packaging mistake fails in CI instead
of after release. Public API is listed in `__all__` and re-exported from
`__init__.py`; everything else is internal and prefixed with `_`.

**Types.** Annotate every public signature including the return type.
`from __future__ import annotations` at the top of every module. Prefer
concrete types over `Any`. A package with a `py.typed` marker is making a
promise to its users' type checkers, which is worth more than the annotations
cost.

**Errors.** Validate inputs early. `TypeError` for a wrong type, `ValueError`
for a bad value, and the message names the argument and the problem. Never
`assert` for validation, because `python -O` removes it. Never catch bare
`Exception` to hide an error.

`warn_unreachable` is deliberately off in mypy, because it flags exactly these
runtime `isinstance` checks: mypy already believes the argument has the right
type, and a novice passing a DataFrame where a string belongs still deserves a
clear message.

**Logging.** A module-level `logger = logging.getLogger(__name__)` for progress
and diagnostics, never `print`, and never configure handlers inside the
package. A library that configures logging takes over its caller's application.

**Style.** 88 columns, sorted imports, NumPy-style docstrings. Run `make
format` on new files only. Never reformat existing code as part of a functional
change: a diff that mixes the two cannot be reviewed. A formatting backlog is
its own pull request.

## Documentation and data

Every public object gets a NumPy-style docstring with a summary, `Parameters`
with types and defaults, `Returns`, `Raises` where it applies, and a runnable
`Examples` block. The examples are run by pytest, so they cannot rot silently.

Documentation is Sphinx with MyST, built by Read the Docs from the committed
`.readthedocs.yaml`. `latest` tracks `devel` and `stable` tracks the newest
tag, so the default version a reader lands on documents the version they can
install.

`docs/api.md` is the hand-maintained index of public objects — the analogue of
`_pkgdown.yml` in the R standards. `make docs-check` imports the package,
reads `__all__`, and fails if any name is missing from that page, so a new
public function cannot ship undocumented. The page uses an `eval-rst` block
rather than the MyST spelling of `autosummary`, because autosummary finds
objects by scanning source text for `.. autosummary::` and silently generates
nothing for the MyST form.

Never hand-edit generated files: `uv.lock`, `docs/_build/`,
`docs/api/_autosummary/`. Edit the source and re-run the target.

`CHANGELOG.md` follows Keep a Changelog, with an `## Unreleased` section that
every user-facing change updates in the same pull request that makes the
change. Writing the changelog at release time means writing it from the commit
log, which is where entries like "fix bug" come from.

Bundled data is loaded through `importlib.resources`, never a path relative to
`__file__`, which breaks in a zipped install. Large data is downloaded by
`pooch` with a recorded hash, not committed. Every bundled dataset has a
generating script under `data-raw/` with a fixed seed.

## Testing

Bug fixes start with a failing regression test, because a test written after
the fix often passes against the broken code too.

New functions get tests for the expected result and for the error paths, with
`pytest.raises(ValueError, match="...")` — `match` matters, since a test that
accepts any `ValueError` passes when the function fails for the wrong reason.

The whole suite must pass, not just the nearby tests. Fixtures stay tiny and
live in `conftest.py`. Use `tmp_path` rather than a hard-coded temp directory,
and never write inside the repository. Optional dependencies use
`pytest.importorskip` so the suite skips cleanly rather than failing on a
machine that doesn't have them.

Coverage must not drop, and the floor is set per package in the Makefile.

`filterwarnings = ["error"]` turns warnings into failures. This is stricter
than most projects and it is deliberate: a `DeprecationWarning` from a
dependency is the earliest and cheapest notice that something will break, and
it is worth more during development than it is in a user's terminal, where
nobody reads it.

Never weaken an assertion, add a skip, or loosen a tolerance to make a test
pass. Report the failure; if the test itself looks wrong, say so and ask. A test
edited to match the code has stopped checking anything.

## Dashboard apps

The app lives in `src/<package>/app/` as a real subpackage, installed by an
optional `app` extra and started by `make app`.

A subpackage rather than a loose directory, because it is then imported,
linted, type-checked and tested like everything else. The R standards put Shiny
apps in `inst/shiny` and have to warn that `R CMD check` does not look inside;
Python has no such excuse. An extra rather than a hard dependency, so importing
the package in a script or a notebook does not pull in a web framework.

**The app contains no analysis logic.** Its callbacks only call public, tested
functions. A new feature is written and tested as a package function first,
then wired in. This is the same rule as the R standards and it exists for the
same reason: logic that lives in a UI callback is logic nobody can test, reuse
from a script, or cite in a paper.

The framework is chosen per package and recorded in `AGENTS.md`, with an ADR
for the choice. **Streamlit** for simple displays — it is the easiest for
trainees and `streamlit.testing.v1.AppTest` runs the whole script headlessly,
so the tests exercise real behavior. **Shiny for Python** for medium-sized
analysis toolkits, where reactivity earns its keep and the server functions can
be unit-tested directly.

Verify any visual change with a Playwright screenshot of the running app and
attach it to the pull request. Tests can say the number is right; only looking
says the page is.

`make app` is not in the permission allow-list, because it starts a server that
keeps running.

## Versions and releases

Semantic versioning, with `version` in `pyproject.toml` as the single source of
truth and `__version__` read from installed metadata. The version is bumped as
part of the change, not at release — the same discipline as the Bioconductor
`z` bump, and it means the version in the tree always says what the tree is.

Deprecate before removing: `DeprecationWarning` for one minor release, removal
in the next, both noted in the changelog. Changing the minimum Python version
needs an ADR.

Releases follow `dev/RELEASE.md` and are run by a person: prepare on a branch
off `devel`, merge to `devel`, open the one pull request that targets `main`,
tag the merge commit, publish a GitHub Release. Publishing the release triggers
the workflow that builds and uploads to PyPI through trusted publishing, so no
API token exists anywhere to leak. Zenodo archives the release and mints a DOI;
the conda-forge or bioconda bot opens a version-bump pull request a few hours
later.

## Checks

`make check` before hand-off, `make check-full` before a pull request. Any
ruff, mypy, pytest or Sphinx error or warning blocks.

Triage each finding as a defect, an environment gap, or a false positive, and
say which. Never silence one with `# noqa`, `# type: ignore` or a `pyproject`
exclusion without naming the rule and the reason, in the line and in the
hand-off. An unexplained suppression is indistinguishable from a bug that
somebody decided not to look at.

Findings that are real but out of scope become GitHub issues, one category per
fix pull request.

## Scope and safety

Minimal, on-topic changes. Unrelated problems become issues.

Decisions that are hard to reverse need an approved ADR in `dev/adr/` before
the work starts: a dependency change, a public API change, a module
reorganization, a change to the minimum Python version, the choice of dashboard
framework, a change to the build, test, docs or release machinery. The test is
whether someone six months from now would ask "why is it like this?" ADRs are
append-only: a later one supersedes an earlier one and both stay, because the
record of what was decided before is the point.

Agents never edit `.claude/settings.json`, the `Makefile`, `dev/hooks/`,
`dev/standards.md`, `uv.lock`, or the downloaded cache. Those are the
guardrails; an agent that can edit its own guardrails doesn't have any. They
propose changes instead.

Never delete files or branches, run `git clean`, or force-push. No secrets,
tokens or absolute local paths in commits. No network calls at import time or
in tests.

## Changing these standards

1. Open a pull request in this repo. A rule change updates both `standards.md`
   and this README, and `bash dev/check-repo.sh --fix` refreshes the copy under
   `template/`.
2. Try the change before merging, by starting a session in any package that
   uses the standards, pointed at your branch. The hooks and `make` both read
   the same setting:

   ```bash
   PY_STANDARDS_REF=<branch> claude
   ```

3. Merge the pull request. Nothing reaches packages yet.
4. Publish it by moving the `v1` tag to the merge commit:

   ```bash
   git tag -f v1 <commit>
   git push -f origin refs/tags/v1
   ```

   Every package picks up the change at its next session start. GitHub's file
   cache can delay this by a few minutes.
5. A change that would break existing packages — renaming a make target they
   rely on, requiring a new input to a shared workflow — goes out as `v2`
   instead. Each package moves to `v2` when it's ready.
6. Bump the version in `standards.md`'s title for meaningful changes.

A fork sets `PY_STANDARDS_BASE` (in the package Makefile and the hook, or in
the environment) to its own raw-file URL, and points the package workflows'
`uses:` lines at the fork.

Keep `standards.md` short. Explanations belong here, and rules for a single
package belong in that package's `AGENTS.md`.

## Sources

- [r-bioc-dev-standards](https://github.com/campbio/r-bioc-dev-standards): the
  R/Bioconductor standards this repo is modelled on
- [superbrainstorming](https://github.com/harrymunro/superbrainstorming): the
  brainstorming skill from Superpowers, without the rest of the workflow
- [mattpocock/skills](https://github.com/mattpocock/skills): source of the
  optional grill-me skill
- [Superpowers](https://github.com/obra/superpowers): the full workflow plugin
  the standards used before v1.1; optional
- ["Opus 5.5 - is the Superpowers skill still needed?"](https://www.reddit.com/r/ClaudeAI/comments/1wt84ix/opus_55_is_the_superpowers_skill_still_needed/)
  (r/ClaudeAI): the discussion behind the v1.1 workflow changes
- [Scientific Python Development Guide](https://learn.scientific-python.org/development/):
  community conventions for packaging, typing and testing
- [uv](https://docs.astral.sh/uv/), [ruff](https://docs.astral.sh/ruff/) and
  [copier](https://copier.readthedocs.io/)
- [Keep a Changelog](https://keepachangelog.com/) and
  [Semantic Versioning](https://semver.org/)
