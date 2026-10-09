# Standard make targets for py-dev-standards.
#
# Packages don't copy this file. Each package's Makefile includes a cached
# copy, which dev/hooks/load-standards.sh refreshes at every Claude session
# start (or run `make standards-update`). Package-specific settings go above
# the include in the package's Makefile; extra targets go below it.
#
# Settings a package can change (set them above the include):
#   COV_MIN       minimum total coverage percentage for `make coverage`
#   APP_CMD       command `make app` runs to start the dashboard
#   APP_SELECT    pytest selector for `make app-test` (default: -m app)
#   DOCS_DIR      documentation source directory (default: docs)
#   PKG_SRC       directory mypy type-checks (default: src)

COV_MIN    ?= 0
APP_CMD    ?=
APP_SELECT ?= -m app
DOCS_DIR   ?= docs
PKG_SRC    ?= src

UV ?= uv
# --locked syncs the environment from uv.lock but refuses to re-resolve, so an
# unapproved dependency edit in pyproject.toml fails loudly instead of being
# installed silently. Run `make lock` after an approved change.
RUN := $(UV) run --locked

.DEFAULT_GOAL := help

# The package settings allow-list `make test-one` and `make tutorial` with any
# arguments, so each must run on its own: `make test-one FILTER=x clean` would
# otherwise run a people-only target without a prompt.
ifneq ($(filter test-one tutorial,$(MAKECMDGOALS)),)
  ifneq ($(words $(MAKECMDGOALS)),1)
    $(error make $(firstword $(filter test-one tutorial,$(MAKECMDGOALS))) must be run on its own)
  endif
endif

.PHONY: help sync lock test test-one lint format typecheck check check-full \
  coverage docs docs-check docs-links tutorial app app-test build \
  standards-update standards-sync

help:  ## List targets
	@grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  %-17s %s\n", $$1, $$2}'

sync:  ## Install the project and every extra and dependency group
	$(UV) sync --all-extras --all-groups

lock:  ## Re-resolve uv.lock after an approved pyproject.toml dependency change
	$(UV) lock

test:  ## Run the full test suite
	$(RUN) pytest

# FILTER reaches pytest through the environment, never pasted into a command
# string, and may contain only letters, digits, '.', '_', '-' and spaces.
test-one:  ## Run matching tests: make test-one FILTER=<pattern>
	@case "$$FILTER" in \
	  "") echo "Usage: make test-one FILTER=<pattern>"; exit 1 ;; \
	  *[!A-Za-z0-9._\ -]*) echo "FILTER may contain only letters, digits, '.', '_', '-' and spaces."; exit 1 ;; \
	esac
	$(RUN) pytest -k "$$FILTER"

lint:  ## Check style and formatting (reports only; changes nothing)
	$(RUN) ruff check .
	$(RUN) ruff format --check .

format:  ## Apply formatting and safe automatic fixes
	$(RUN) ruff format .
	$(RUN) ruff check --fix .

typecheck:  ## Type-check the package with mypy
	$(RUN) mypy $(PKG_SRC)

check: lint typecheck test  ## Quick gate: lint, typecheck, tests. Run before hand-off

check-full: check coverage docs-check build  ## Full gate: adds coverage, docs and a build. Run before a PR
	$(RUN) twine check dist/*

coverage:  ## Print test coverage and fail below COV_MIN
	$(RUN) pytest --cov --cov-report=term-missing --cov-fail-under=$(COV_MIN)

# Builds into a temporary folder so a committed or ignored docs/_build is
# never touched and a stale build can never mask a failure.
docs:  ## Build the HTML documentation into a temp folder
	@out="$$(mktemp -d)"; \
	  $(RUN) sphinx-build -b html "$(DOCS_DIR)" "$$out" && \
	  echo "Built into $$out"

# -W turns warnings into errors (same as Read the Docs' fail_on_warning) and
# -n reports every unresolvable cross-reference. The coverage builder then
# fails the target if any public object is missing from the API pages.
docs-check:  ## Build docs with warnings as errors and verify every public object is documented
	@out="$$(mktemp -d)"; \
	  $(RUN) sphinx-build -b html -W --keep-going -n "$(DOCS_DIR)" "$$out/html" || exit 1; \
	  $(RUN) sphinx-build -b coverage "$(DOCS_DIR)" "$$out/coverage" > /dev/null || exit 1; \
	  if grep -q '^ \* ' "$$out/coverage/python.txt" 2> /dev/null; then \
	    echo "Public objects missing from the API documentation:"; \
	    grep '^ \* ' "$$out/coverage/python.txt"; \
	    echo "Add them to $(DOCS_DIR)/api.md."; \
	    exit 1; \
	  fi; \
	  echo "Docs OK."

# Kept out of check-full: linkcheck needs the network, so a flaky host or an
# offline machine would fail a gate that has nothing to do with the change.
docs-links:  ## Check external links in the documentation (needs network)
	@out="$$(mktemp -d)"; $(RUN) sphinx-build -b linkcheck "$(DOCS_DIR)" "$$out"

# Renders one tutorial into a temporary folder, executing its code. FILTER is
# the file name without its extension.
tutorial:  ## Render one tutorial to a temp folder: make tutorial FILTER=<name>
	@case "$$FILTER" in \
	  "") echo "Usage: make tutorial FILTER=<name>"; exit 1 ;; \
	  *[!A-Za-z0-9._-]*) echo "FILTER may contain only letters, digits, '.', '_' and '-'."; exit 1 ;; \
	esac
	@src="$$(ls $(DOCS_DIR)/tutorials/$$FILTER.* 2> /dev/null | head -1)"; \
	  if [ -z "$$src" ]; then echo "No tutorial named $$FILTER in $(DOCS_DIR)/tutorials/"; exit 1; fi; \
	  out="$$(mktemp -d)"; \
	  $(RUN) sphinx-build -b html "$(DOCS_DIR)" "$$out" "$$src" && \
	  echo "Rendered into $$out"

app:  ## Start the dashboard app (long-running; ask the developer first)
	@if [ -z "$(APP_CMD)" ]; then \
	  echo "This package has no dashboard app (APP_CMD is unset in the Makefile)."; \
	  exit 1; \
	fi
	$(APP_CMD)

app-test:  ## Run only the dashboard tests
	$(RUN) pytest $(APP_SELECT)

build:  ## Build the sdist and wheel into dist/
	$(UV) build

standards-update:  ## Re-download this file of shared targets
	curl -fsSL --max-time 30 "$(PY_STANDARDS_BASE)/shared/standards.mk" -o "$(STANDARDS_MK).tmp"
	mv -f "$(STANDARDS_MK).tmp" "$(STANDARDS_MK)"

standards-sync:  ## Refresh the committed dev/standards.md from the pinned ref
	curl -fsSL --max-time 30 "$(PY_STANDARDS_BASE)/standards.md" -o dev/standards.md.tmp
	@mv -f dev/standards.md.tmp dev/standards.md
	@echo "dev/standards.md updated from $(PY_STANDARDS_BASE). Commit it."
