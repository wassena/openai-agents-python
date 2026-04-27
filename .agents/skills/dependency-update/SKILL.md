# Dependency Update Skill

This skill automates the process of checking for outdated dependencies and creating pull requests to update them in the `openai-agents-python` project.

## Overview

The dependency update skill performs the following tasks:

1. **Audit current dependencies** — Scans `pyproject.toml` and `requirements*.txt` files for declared dependencies.
2. **Check for updates** — Queries PyPI to find newer versions of each dependency.
3. **Assess compatibility** — Evaluates whether updates are patch, minor, or major version bumps.
4. **Run verification** — Executes the existing test suite to confirm nothing breaks after updates.
5. **Generate a report** — Summarizes which packages were updated, skipped, or flagged for manual review.
6. **Open a PR** — Creates a pull request with the proposed changes and the generated report as the PR body.

## When to Use

- Scheduled (e.g., weekly) dependency maintenance runs.
- After a security advisory is published for a transitive or direct dependency.
- Before a release to ensure the project ships with up-to-date dependencies.

## Inputs

| Variable | Required | Default | Description |
|---|---|---|---|
| `UPDATE_STRATEGY` | No | `patch` | One of `patch`, `minor`, or `major`. Controls which semver bumps are applied automatically. |
| `SKIP_PACKAGES` | No | `` | Comma-separated list of package names to exclude from updates. |
| `DRY_RUN` | No | `false` | If `true`, reports proposed changes without modifying files or opening a PR. |
| `BASE_BRANCH` | No | `main` | The branch to base the update PR against. |
| `GITHUB_TOKEN` | Yes | — | Token with `repo` scope used to open the pull request. |

## Outputs

- A new branch named `chore/dependency-updates-<date>` containing updated dependency files.
- A pull request opened against `BASE_BRANCH` with a structured report in the body.
- A JSON summary written to `dependency-update-report.json` in the workspace root.

## Workflow

```
audit deps → check PyPI → filter by strategy → run tests → commit changes → open PR
```

## Notes

- The skill respects version constraints already expressed in `pyproject.toml` (e.g., `>=1.0,<2.0`). It will not widen upper bounds automatically.
- Major version updates are always flagged for manual review regardless of `UPDATE_STRATEGY`.
- If the test suite fails after an update, that package is rolled back and added to the "needs manual review" section of the report.
- Requires Python 3.9+ and `pip`, `pip-api`, and `packaging` to be available in the runtime environment.
