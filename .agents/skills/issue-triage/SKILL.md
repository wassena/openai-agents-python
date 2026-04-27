# Issue Triage Skill

This skill automates the triage of GitHub issues for the openai-agents-python repository. It analyzes new and existing issues, applies appropriate labels, assigns priority levels, and suggests relevant team members or components.

## What This Skill Does

- Reads open GitHub issues that lack triage labels
- Classifies issues by type: `bug`, `enhancement`, `question`, `documentation`, `performance`
- Assigns priority labels: `priority:critical`, `priority:high`, `priority:medium`, `priority:low`
- Identifies affected components: `agents`, `tools`, `streaming`, `tracing`, `memory`, `handoffs`
- Posts a structured triage comment summarizing findings
- Optionally closes duplicate or out-of-scope issues with a polite explanation

## Inputs

| Variable | Description | Required |
|---|---|---|
| `GITHUB_TOKEN` | GitHub token with issues read/write access | Yes |
| `GITHUB_REPOSITORY` | Repository in `owner/repo` format | Yes |
| `ISSUE_NUMBER` | Specific issue number to triage (optional, triages all untriaged if omitted) | No |
| `DRY_RUN` | If `true`, only prints actions without applying them | No |

## Outputs

- Labels applied to the issue
- Triage comment posted to the issue
- JSON summary written to `triage-results.json`

## Usage

### Trigger on new issues via GitHub Actions

```yaml
on:
  issues:
    types: [opened, reopened]

jobs:
  triage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run issue triage
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GITHUB_REPOSITORY: ${{ github.repository }}
          ISSUE_NUMBER: ${{ github.event.issue.number }}
        run: bash .agents/skills/issue-triage/scripts/run.sh
```

### Manual triage of all open issues

```bash
export GITHUB_TOKEN=your_token
export GITHUB_REPOSITORY=openai/openai-agents-python
bash .agents/skills/issue-triage/scripts/run.sh
```

## Classification Logic

The skill uses keyword matching combined with an LLM call to determine:

1. **Issue type** — based on title, body, and existing labels
2. **Affected component** — based on code references, stack traces, and mentioned modules
3. **Priority** — based on user impact, frequency indicators, and severity language
4. **Duplicate detection** — semantic similarity against recently closed issues

## Notes

- Requires `gh` CLI or direct GitHub API access via `GITHUB_TOKEN`
- The LLM call uses the OpenAI Agents SDK itself as a dogfooding exercise
- Results are idempotent: re-running on an already-triaged issue will not duplicate labels or comments
