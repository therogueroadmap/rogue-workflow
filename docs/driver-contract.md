# Contract for external drivers

`subagent-driven-development` keeps this contract so a driver can run a plan across separate sessions.

## Checkpoint

Path: `docs/superpowers/plans/.controller-state.json`. Written at setup and whenever a level closes.

```json
{
  "plan": "feature-plan.md",
  "completed_levels": [0, 1],
  "current_level": 2,
  "tasks": {
    "Task1": { "status": "DONE", "files": ["src/a.py"], "concerns": null }
  }
}
```

`dependency_corrections` is optional: a list of `{ "task", "promoted_after", "reason" }` found at runtime.

## Single-level mode

When the prompt asks to run only the next pending level, the skill finds it in the checkpoint, completes its review and fix cycle, updates the checkpoint and stops. It does not run the final review or the closing steps.

## Precedence

A driver's prompt overrides the skill's stopping and ruling rules for that session.
