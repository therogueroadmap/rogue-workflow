---
name: subagent-driven-development
description: Use when executing an implementation plan that has a dependency map, in the current session. Dispatches implementers in parallel by dependency level.
---

<!-- Based on superpowers 7.0.2 by Jesse Vincent (MIT, see NOTICE).
Changes: parallel execution by level; precondition check and re-queue; typed agents;
the controller makes commits; a checkpoint for external drivers; three fix rounds;
no worktree creation; own closing steps; no batching reference. -->

# Subagent-Driven Development

Execute a plan by dispatching implementers in parallel for the tasks of each dependency level, one task review per task, and a broad whole-branch review at the end.

**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.

**Core principle:** Tasks in one level are independent and run together. Levels run in order. Each task is reviewed, and the suite runs when a level closes.

**Narration:** between tool calls, narrate at most one short line — the
ledger and the tool results carry the record.

**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are the four named below, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.

**Rulings, not stalls.** A running plan does not wait on a human. Conflicts,
ambiguities, plan defects, a cap you would have asked to exceed — decide
them. The spec is the binding authority, the plan is its argument, and your
judgment settles what neither answers. Record every decision in the ledger as
`Ruling: <what you decided> — <why> — <what it costs if wrong>`, and keep
going. A wrong ruling costs rework your human partner can see and undo; a
session parked on a question costs their whole day and buys nothing.

Four things stop you, and only these: an irreversible or destructive
operation; a security-sensitive action; a side effect outside this worktree
that norms say you ask about first (a merge, a push to a shared branch, a
publish); and a plan so broken that every path forward is a guess. For those,
stop and ask.

## When to Use

Use this when the plan has a Dependency Map. If it has none, treat each task as its own level, in plan order.

## Parallel Execution by Level

```
Setup, once
For each level, in ascending order:
  1. Dispatch every implementer of the level in one message
  2. Handle each report; commit the finished tasks in one shell call, one commit per task
  3. Dispatch one reviewer per task, in one message
  4. Fix rounds, one fix commit per round
  5. Run the full suite, update the ledger and checkpoint
Final review, then close
```

**Parallel dispatch is valid only inside one level.** Never start a level before the previous one has closed.

**Before dispatching a level,** compare the Files sections of its tasks. Tasks that share a file run one after another; record it in the ledger as a gap in the plan.

Single-level mode: if the prompt asks to run only the next pending level, read it from the checkpoint, complete the level through section 6 (Close the level, checkpoint updated), and stop. Skip the final review and closing.

## Setup

Work on the active branch. Do not create branches or worktrees. If the active branch is main or master, stop and ask for consent first. If the working tree is not clean, ignoring the plan file, the spec it names, the checkpoint, `.rogue-workflow/`, and the files an external driver writes in `docs/superpowers/plans/` (`.driver-*`, `.final-review-*.md`), stop and ask, because the controller commits exactly what implementers report.

Starting this skill authorizes local commits. Never push, merge or publish without asking.

Conversation memory does not survive compaction. In real sessions,
controllers that lost their place have re-dispatched entire completed task
sequences. Track progress in a ledger file, not only in todos. A ledger line
never takes a turn of its own: write it in the same message as your next
dispatch or commit.

- Each plan owns a workspace: at skill start, run this skill's
  `bash scripts/sdd-workspace PLAN_FILE` by its absolute path, from the
  working tree you're executing in — it prints the plan's git-ignored
  directory (under `<repo-root>/.rogue-workflow/sdd/`), home to
  every artifact for THIS plan: ledger, briefs, reports, review packages.
  Another plan's directory is never yours to read or write.
- Check for this plan's ledger at `<workspace>/progress.md`. If one exists,
  read [references/resuming.md](references/resuming.md) before anything
  else: it says whose ledger it is and where to resume.
- Create the ledger with its identity as the first line:
  `# SDD ledger — plan: <plan file path>`.
- Create or update the checkpoint `docs/superpowers/plans/.controller-state.json`
  with `{ "plan": "<filename>", "completed_levels": [], "current_level": 0, "tasks": {} }`,
  unless it already names this plan. External drivers read it; this
  plugin's `docs/driver-contract.md` holds the contract.
- The ledger is your recovery map: the commits it names exist in git even
  when your context no longer remembers creating them. After compaction,
  trust the ledger and `git log` over your own recollection.
- `git clean -fdx` will destroy the workspace (it's git-ignored scratch); if
  that happens, recover from `git log`.

Read the plan once, note its context and Global Constraints, and create a
todo per task. If the plan names a Spec, read that too: the spec is the
authority the plan argues from, and conflicts inside the plan resolve
against it. A plan with no reachable spec gets a ledger note saying so —
rulings made without one are provisional.

Before dispatching the first level, read [references/preflight.md](references/preflight.md)
and run the conflict scan it describes. Its table and rulings go in the
ledger.

## Model Selection

Every dispatch names its agent. An omitted agent or model inherits the session's model, the most expensive one.

| Role | Agent | Add `model:` when |
|---|---|---|
| Implementer | `rogue-workflow:implementer` (sonnet) | The task carries an open design decision: `opus` |
| Task reviewer | `rogue-workflow:reviewer` (sonnet) | All files are small, or the change is architectural: `opus` |
| Fix, rounds 1 and 2 | `rogue-workflow:fix-agent` (haiku) | A Critical, a race or a contract change: `sonnet`, or `opus` for a contract change |
| Fix, round 3 | `rogue-workflow:fix-agent` | Always one tier above the previous round |
| Scoped re-review | `rogue-workflow:reviewer` (sonnet) | Never |
| Final review | `rogue-workflow:reviewer` | Always: `opus` |

Use `model:` only to move up a tier.

**Turn count beats token price.** Cheap models can take 2-3× the turns on multi-step work. Keep a mid-tier floor for implementers working from signatures and tests. Fix agents are the exception, because they transcribe a written diagnosis.

To locate code, dispatch `Explore`, which is read-only and returns excerpts.

## The Level Loop

Everything you paste into a dispatch prompt — and everything a subagent
prints back — stays resident in your context for the rest of the session
and is re-read on every later turn. Hand artifacts over as files.

**Waiting on dispatched subagents:** never poll a wait interface with
short timeouts, and never sit in one silent, open-ended wait either.
While you have local work — ledger updates, packaging the next review,
reading reports — keep working; child results arrive on their own.
When you are genuinely idle, wait in bounded stretches (five to ten
minutes, where your platform allows), and between stretches post one
line of status and reconcile your live children: list them, and chase
any that finished without reporting. A bounded stretch keeps nearly
all of a long wait's efficiency while guaranteeing a stuck or lost
child is noticed within minutes, not at the end of the session.

**A subagent that dies or stalls.** Re-dispatch once with a header stating the prior attempt failed and repeating the file and test rules, without any `model:` override. If it fails again, split the task: implementation apart from tests, or one sub-task per file, with the same scope. A split task gets two attempts per piece and may split once more. After that, escalate with the tree of attempts. Do not revert partial work: the new implementer's precondition check starts from what exists. Commit a split task once, after all its pieces report DONE, with the union of their files, so it stays one commit.

### 1. Dispatch the implementers

Dispatch the level's implementers in one message, one per task.

- **Task brief:** before dispatching an implementer, run this skill's
  `bash scripts/task-brief PLAN_FILE N` by its absolute path, from the
  working tree you're executing in — it extracts the task's full text to a
  uniquely named file and prints the path. Compose the dispatch so the
  brief stays the single source of
  requirements. Your dispatch should contain: (1) one line on where this
  task fits in the project; (2) the brief path, introduced as "read this
  first — it is your requirements, with the exact values to use verbatim";
  (3) interfaces and decisions from earlier tasks that the brief cannot
  know; (4) your resolution of any ambiguity you noticed in the brief;
  (5) the report-file path and report contract. Exact values (numbers,
  magic strings, signatures, test cases) appear only in the brief. Never
  make a subagent read the whole plan file.
- **Report file:** name the implementer's report file after the brief
  (brief `…/task-N-brief.md` → report `…/task-N-report.md`) and put it in
  the dispatch prompt. The implementer writes the full report there and
  returns only status, changed files, a one-line test summary, and concerns.
- A dispatch prompt describes one task, not the session's history. Do not
  paste accumulated prior-task summaries ("state after Tasks 1-3") into
  later dispatches — a real session's dispatch hit 42k chars of which 99%
  was pasted history. A fresh subagent needs its task, the interfaces it
  touches, and the global constraints. Nothing else.
- The dispatch carries the no-subagents contract (it is in the
  implementer template): the implementer never dispatches subagents —
  not helpers, and never a reviewer. Review arrives from you, after the
  report. In real sessions, every reviewer a worker spawned duplicated
  the task review the controller dispatched anyway — a full extra
  review seat per task.
- If an earlier task parked a finding in the area this task touches, carry
  a pointer to that ledger entry in the dispatch.

Template: [implementer-prompt.md](implementer-prompt.md)

### 2. Handle the report

Implementer subagents report one of five statuses. Handle each appropriately:

**DONE:** Commit it with the level's other finished tasks (below), then review it (step 3).

**Commit a level's DONE tasks in one shell call,** one commit per task: for each, `git add -- <files>` then `git commit -m "<message>" -- <files>` with exactly the files it reported. Chain with `&&`, append the SHA from `git rev-parse --short HEAD` to the ledger only after its commit succeeds, and stop at the first failure. If `git status --porcelain` shows a file nobody reported (other than the files the Setup check ignores), attribute it to a task or stop and ask. Never use `git add -A`.

**Any other status** (DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED, PRECONDITION_FAILED): read
[references/handling-reports.md](references/handling-reports.md) and follow
it, every time you get one.

If the implementer asks questions — before starting or mid-task — answer
clearly and completely, provide additional context if needed, and don't
rush it into implementation.

### 3. Review the task

Dispatch the reviewers of a level in one message, one per task. A single reviewer covers spec compliance and quality.

Per-task reviews are task-scoped gates. The broad review happens once, at the
final whole-branch review. Never skip the task review, and never accept a
report missing either verdict — spec compliance AND task quality are both
required. Implementer self-review never replaces the task review; both are
needed.

- Hand the reviewer its diff as a file: run this skill's
  `bash scripts/review-package PLAN_FILE <SHA>~1 <SHA>` by its absolute path,
  from the working tree you're executing in, where `<SHA>` is the task's
  commit, and pass the reviewer the file path it prints (or, without bash:
  `git log --oneline`, `git diff --stat`, and `git diff -U10` for the range,
  redirected to one uniquely named file). The output never enters your own
  context, and the reviewer sees the commit list, stat summary, and full
  diff with context in one Read call. Each task and each fix round is
  exactly one commit, so this range holds only its own changes even with
  parallel work. Never dispatch a task reviewer without a diff file.
- **Reviewer inputs:** the task reviewer gets three paths — the same brief
  file, the report file, and the review package — plus the global
  constraints that bind the task.
- The global-constraints block you hand the reviewer is its attention
  lens. Copy the binding requirements verbatim from the plan's Global
  Constraints section or the spec: exact values, exact formats, and the
  stated relationships between components ("same layout as X", "matches
  Y"). The reviewer's template already carries the process rules (YAGNI,
  test hygiene, review method) — the constraints block is for what THIS
  project's spec demands.
- Do not add open-ended directives like "check all uses" or "run race tests
  if useful" without a concrete, task-specific reason
- Do not ask a reviewer to re-run tests the implementer already ran on the
  same code — the implementer's report carries the test evidence
- Do not pre-judge findings for the reviewer — never instruct a reviewer to
  ignore or not flag a specific issue. If you believe a finding would be a
  false positive, let the reviewer raise it and adjudicate it in the review
  loop. If the prompt you are writing contains "do not flag," "don't treat X
  as a defect," "at most Minor," or "the plan chose" — stop: you are
  pre-judging, usually to spare yourself a review loop.
If the reviewer reports "⚠️ Cannot verify from diff" items, read
[references/cannot-verify.md](references/cannot-verify.md) before you mark
the task complete.

Template: [task-reviewer-prompt.md](task-reviewer-prompt.md)

### 4. The fix loop

The loop triggers when the review reports spec ❌, any Critical or Important
finding, or a ⚠️ item you confirmed as a real gap. Three rounds maximum per task.

When it triggers, read [references/fix-loop.md](references/fix-loop.md) and
follow it. Read it again before every round, even if you read it earlier in
this session: it holds the round cap, the breaker, and the ledger line each
round writes, and your memory of it does not survive compaction.

### 5. Complete the task

When the review comes back clean — or every open finding is parked with a
ruling at the cap — append the completion line to the ledger in the same
message as your other bookkeeping:

- `Task <N>: complete (commit <sha7>, review clean)`
- `Task <N>: complete (commit <sha7>, <K> parked)` after the round cap

Then mark the todo complete. Never close the level while
the review has open Critical/Important issues that are neither fixed nor
parked-with-ruling at the cap.

### 6. Close the level

Run the full test suite in the foreground and wait for the result. If it fails, identify the task responsible and treat the failure as a finding in that task's fix loop. A failure no task explains goes to the controller as a ruling or a stop.

Update the ledger, and update the checkpoint: add the level to `completed_levels`, set `current_level` to the next level, and for each task record `{ "status", "files", "concerns" }`.

## Final Review

When every level is closed, read
[references/final-review.md](references/final-review.md) and follow it. It
covers the whole-branch review, its single fix wave, the rulings list and the closing options.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Close enough on spec compliance" | Reviewer found spec gaps = not done. Fix or hit the cap and adjudicate — those are the only exits. |
| "I'll fix it myself, dispatching is overhead" | Controller fixes pollute your context and skip review. Dispatch a fix agent. |
| "One more round will converge" | Past the cap, rounds don't converge — the failure is structural. Adjudicate and route. |
| "The reviewer will just find something new anyway" | Scoped re-reviews verify fixes; they cannot wander. New findings on untouched code go to the ledger, not the loop. |
| "This finding is obviously wrong, I'll drop it" | You adjudicate only at the cap, and every ruling is a ledger entry. Silent discards are forbidden. |
| "The fix was small, skip the re-review" | Unreviewed fixes are how regressions land. Every round ends with a scoped re-review. |
| "Reviews slow the loop down" | The loop without reviews is just unverified churn. Reviews are the loop's brakes and steering. |
| "Ledger bookkeeping is overhead" | The ledger is what survives compaction. Controllers without one have re-dispatched entire completed task sequences. |
| "The implementer spawned its own reviewer — free extra assurance" | It's a duplicate seat reviewing the same diff; the task review is the gate. A worker-spawned reviewer is a defect to flag, not rigor. |
