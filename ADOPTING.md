# Setting up a package

These steps put a Python package under these standards, so that every coding
agent working in it loads the same rules and every check runs the same way.

There are two starting points — a new package, or one that already exists —
and both use the same `copier` template, so neither drifts from the other.

## Once per machine

1. **[uv](https://docs.astral.sh/uv/)**, which manages environments, the
   lockfile and the build:

   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. **Claude Code**, and the **Superpowers plugin**, which provides the workflow
   skills the standards refer to (brainstorming, writing plans, test-driven
   development, code review). From inside Claude Code:

   ```
   /plugin install superpowers@claude-plugins-official
   ```

`copier` needs no install: `uvx copier` runs it. The standards still make sense
if a skill is missing — each step also says what to do, so the process can be
followed by hand.

## A new package

```bash
uvx copier copy gh:campbio/py-dev-standards my-package
cd my-package
```

Copier asks for the distribution name, the import name, a one-line
description, the author, the Python versions to support, the coverage floor,
whether the package has a dashboard (and which framework), and where it will be
published. Then:

```bash
git init
git add -A
git commit -m "Initial commit"
make lock
make sync
make check
```

`make check` must pass on a package that has just been generated. If it does
not, something is wrong with the template rather than with your package: open
an issue here.

Fill in `AGENTS.md` next. It is the first file every coding agent reads, and
the placeholders in angle brackets are the parts no one else can write for you.
Then delete the seed module and its tests (`src/<module>/example.py`,
`tests/test_example.py`) once you have real code, remembering to remove
`gc_content` from `__init__.py` and `docs/api.md`.

Now do the GitHub, Read the Docs and publishing setup below.

## An existing package

Work on a branch, with a clean working tree, so that `git` shows you exactly
what the template changed:

```bash
git switch -c adopt-py-dev-standards
uvx copier copy --overwrite gh:campbio/py-dev-standards .
```

Answer the questions with the package's real name, module and description.
`--overwrite` lets copier write its files without prompting for each one;
nothing is lost, because every change is in the working tree and `git diff`
shows it.

Then reconcile, in this order:

1. **`pyproject.toml`** — the template's version replaced yours. Put your real
   dependencies, version, classifiers and entry points back, and keep the
   template's `[tool.ruff]`, `[tool.mypy]`, `[tool.pytest.ini_options]` and
   `[tool.coverage.*]` sections. `git diff pyproject.toml` shows both halves.
2. **`README.md`** — the template's version replaced yours. Keep your content
   and take the "Development" section from the template.
3. **The seed files** — delete `src/<module>/example.py`,
   `tests/test_example.py`, and their entries in `__init__.py` and
   `docs/api.md`. Replace `docs/api.md` with your real public objects and
   `docs/tutorials/getting-started.md` with a real tutorial.
4. **`.gitignore`** — merge, rather than replace, if yours had entries the
   template lacks.
5. **`Makefile`** — move the package's existing extra targets below the
   `include` line, and delete any of its own versions of the standard targets.
   List the extra targets in `AGENTS.md`, and put the ones only people should
   run in `PEOPLE_ONLY`.
6. **`AGENTS.md`** — if the package already had one, keep only what is specific
   to the package; the general rules are now in `dev/standards.md`.

Then make it pass:

```bash
make lock
make check
```

Expect work here. A package that has never been linted or type-checked will
have findings. Fix what is quick, and record the rest as issues rather than
holding up the adoption: `make check` passing is the goal, and a backlog of
style fixes is its own pull request.

Merge this branch into `devel` by pull request, like any other change.

## GitHub

1. **Create `devel` and make `main` the default.** A new package starts with
   both branches on the same commit:

   ```bash
   git switch -c devel
   git push -u origin main
   git push -u origin devel
   ```

   In the repository's **Settings → General**, set the default branch to
   `main`. That is what a bare `pip install git+...` and a plain `git clone`
   get, and it is why `main` holds only released code.

2. **Protect `main`.** Under **Settings → Rules → Rulesets**, add a branch
   ruleset targeting `main` with **Restrict deletions**, **Block force
   pushes**, and **Require a pull request before merging** turned on. The
   `pr-base-devel` workflow then refuses any pull request to `main` that does
   not come from `devel` or a `release/*` branch.

3. **Protect `devel`** the same way, minus the pull-request requirement if you
   want to allow direct pushes for trivial fixes. The standards tell agents not
   to, regardless.

4. The workflows and the pull-request template are already in `.github/`.
   They call the shared workflows in this repository, so they rarely change.

## Read the Docs

1. Import the repository at [readthedocs.org](https://readthedocs.org/). The
   committed `.readthedocs.yaml` configures the build; nothing needs to be set
   up in the web interface for it to work.
2. Under **Versions**, activate `devel` and set its slug to `latest`, and make
   sure `stable` tracks tags. Set the **default version** to `stable`, so
   readers land on the documentation for the version they can install.
3. Under **Settings → Advanced**, turn on **Build pull requests for this
   project**, so a documentation change can be previewed in review.
4. Check the first build. `make docs-check` locally runs the same flags, so a
   failure there is usually reproducible on your machine.

## PyPI

Publishing uses **trusted publishing**, so there is no API token to store or
leak. Before the first release, at
[pypi.org/manage/account/publishing](https://pypi.org/manage/account/publishing/),
add a pending publisher with:

- **PyPI project name:** the distribution name
- **Owner:** your GitHub organization
- **Repository:** the repository name
- **Workflow name:** `release.yaml`
- **Environment name:** `pypi`

Then create a `pypi` environment in the repository's **Settings →
Environments**. Add yourself as a required reviewer if you want a human
approval between pressing "publish release" and the upload.

Rehearse on TestPyPI first. Register the same pending publisher at
test.pypi.org, then run the release workflow once with
`repository-url: https://test.pypi.org/legacy/` in
`.github/workflows/release.yaml`, and remove that line afterwards.

## Zenodo

If the package should have a DOI for citation: sign in at
[zenodo.org](https://zenodo.org/) with GitHub, and enable the repository under
**GitHub**. Zenodo then archives every GitHub Release and mints a DOI. The
`CITATION.cff` in the repository supplies the metadata; fill in the author
names before the first release. Put the concept DOI badge in `README.md`.

## conda-forge or bioconda

Only after the package is on PyPI. Follow the
[conda-forge](https://conda-forge.org/docs/maintainer/adding_pkgs/) or
[bioconda](https://bioconda.github.io/contributor/index.html) contribution
guide to add the recipe once. After that, their bots open a version-bump pull
request within hours of each PyPI release; review and merge it. `dev/RELEASE.md`
lists this as a release step.

## Verify

Start a new `claude` session in the package and approve the hooks when asked.
Then ask, without letting it read any files:

> Which branch do the standards say is the base for pull requests, and when may
> a pull request be opened?

It should answer `devel`, and only after the developer has reviewed the branch.
If it cannot, run the hook by hand to see what happened:

```bash
bash dev/hooks/load-standards.sh | head
```

Then edit a Python file so that it has an obvious problem — an unused import —
and confirm the lint finding comes straight back. That is the second hook
working.

## Updating

When the maintainer moves the `v1` tag, changes to `standards.md`, the lint
hook, the shared make targets and the shared workflows reach every package at
its next session start or workflow run. Nothing in the package changes.

Two things do need a step in the package:

- **The committed `dev/standards.md`**, which agents other than Claude Code
  read. `make standards-sync` refreshes it; commit the result. The
  `standards-drift` workflow warns when it has fallen behind.
- **The per-package files** — `pyproject.toml`, the Makefile, the workflows,
  `.claude/settings.json`. Pick up improvements to those with:

  ```bash
  uvx copier update
  ```

  Run it on a clean tree and on a branch. Copier re-applies the template to
  your recorded answers and leaves your own edits alone, writing `.rej` files
  where it cannot merge. Review the diff, run `make check-full`, and merge it
  by pull request.

A change that would break existing packages goes out as `v2` instead, and each
package moves when it is ready.
