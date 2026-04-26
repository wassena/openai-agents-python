# PR Review Skill

This skill automates pull request review by analyzing code changes, checking for common issues, and providing structured feedback.

## Overview

The PR Review skill performs the following tasks:
1. Fetches the diff of a pull request
2. Analyzes changes for code quality, potential bugs, and style issues
3. Checks that tests are included for new functionality
4. Verifies documentation is updated where needed
5. Posts a structured review comment summarizing findings

## Usage

This skill is triggered automatically on pull request creation and update events, or can be invoked manually.

### Inputs

| Variable | Description | Required |
|---|---|---|
| `PR_NUMBER` | The pull request number to review | Yes |
| `REPO` | The repository in `owner/repo` format | Yes |
| `GITHUB_TOKEN` | GitHub token with PR read/write access | Yes |
| `OPENAI_API_KEY` | OpenAI API key for AI-assisted review | Yes |
| `BASE_BRANCH` | Base branch to diff against (default: `main`) | No |
| `REVIEW_LEVEL` | Review depth: `light`, `standard`, `thorough` (default: `standard`) | No |

### Outputs

- A review comment posted to the pull request
- A structured JSON report saved to `pr-review-report.json`
- Exit code `0` on success, non-zero on failure

## Review Checks

### Code Quality
- Detects common anti-patterns
- Flags overly complex functions (cyclomatic complexity)
- Identifies hardcoded secrets or credentials
- Checks for TODO/FIXME comments introduced in the diff

### Testing
- Verifies new functions/classes have corresponding tests
- Warns if test coverage appears to decrease
- Checks for test file naming conventions

### Documentation
- Flags public API changes without docstring updates
- Checks that `CHANGELOG.md` or `CHANGES.md` is updated for significant changes
- Verifies README is updated if new features are added

### Style & Conventions
- Checks commit message format
- Validates file naming conventions
- Ensures consistent import ordering

## Configuration

Create a `.agents/skills/pr-review/config.yaml` to customize behavior:

```yaml
review_level: standard
skip_checks:
  - changelog
custom_rules:
  - pattern: "TODO"
    message: "Avoid merging TODOs — create a follow-up issue instead"
    severity: warning
```

## Agent Configuration

See `agents/openai.yaml` for the OpenAI agent configuration used by this skill.
