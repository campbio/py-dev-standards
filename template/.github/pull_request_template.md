<!-- Base branch: devel. The only pull request that targets main is a release. -->

## What changed and why

<!-- Link the issue if there is one. -->

## How it was tested

## Checklist

- [ ] Tests added or updated, `make test` passes, and `make coverage` didn't drop
- [ ] `make check-full` passes
- [ ] New public objects added to `docs/api.md`, and `make docs-check` passes
- [ ] Docstrings updated, with runnable `Examples`
- [ ] Affected tutorials re-rendered with `make tutorial FILTER=<name>`
- [ ] `CHANGELOG.md` updated under `## Unreleased` for user-facing changes
- [ ] Version bumped in `pyproject.toml`
- [ ] `uv.lock` regenerated with `make lock` if dependencies changed
- [ ] Plan review and `/code-review` run; findings fixed or answered
- [ ] Dashboard only: `make app-test` passes and a screenshot of the running app is attached

## ADR

<!-- Link to dev/adr/NNNN-*.md for a decision that is hard to reverse (a new
     dependency, a public API change, a module reorganization), or write "N/A". -->

## Scientific correctness

<!-- REQUIRES HUMAN JUDGMENT. An agent must never fill this in.
     If this PR changes numerical results, statistical methods, model output,
     or what a plot shows, say who verified the output is still scientifically
     correct and how. Passing tests is not enough.
     Otherwise write "No change to results". -->

## Generated content

<!-- If an AI agent wrote part of this PR, say which parts, so reviewers know
     where to focus. -->
