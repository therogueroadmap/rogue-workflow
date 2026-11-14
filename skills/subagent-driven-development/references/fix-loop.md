<!-- Based on superpowers 7.0.2 by Jesse Vincent (MIT, see NOTICE).
Changes: three rounds instead of five; fix-agent in rounds 1 and 2 and a fresh agent one
tier higher in round 3; one controller commit per round; each re-review covers only that
round's commit; breaker outcomes recorded as concerns or rulings. -->
# The Fix Loop

Part of rogue-workflow:subagent-driven-development. The task review reported
spec ❌, a Critical or Important finding, or a ⚠️ item you confirmed as a real
gap.

Before the loop starts, two routes leave it immediately:

- Record Minor findings in the progress ledger as you go
  (`Task <N>: minor (deferred): <one-liner>`), and point the final
  whole-branch review at that list so it can triage which must be fixed
  before merge. A roll-up nobody reads is a silent discard. Minor findings
  never enter the loop.
- A finding labeled plan-mandated — or any finding that conflicts with
  what the plan's text requires — is yours to rule on: weigh the finding
  against the plan text, decide with the spec as the binding authority, and
  ledger the ruling before you act on it. Do not dismiss the finding because
  the plan mandates it, and do not dispatch a fix that contradicts the plan
  without a recorded ruling.
Everything else enters the loop. A fix round is one fix dispatch, one commit
by the controller, and one scoped re-review. Three rounds maximum per task:

**Rounds 1 and 2 — `rogue-workflow:fix-agent`.** Send it the open findings
verbatim, the brief path and the report-file path: the report file is the
persistent memory. Move it up a tier (SKILL.md's Model Selection) for a
Critical finding, a race condition or a contract change.

**Round 3 — a fresh `rogue-workflow:fix-agent` one tier above the previous
round,** with the brief path, the report-file path, the open findings, and
this framing: "Earlier attempts fixed these findings [N] times without
success; you own them now. Read the report file for what was tried." A loop
that survives two rounds usually means the fixer cannot see its own
problem — fresh eyes and a capability bump in one move.

Fixes of different tasks run in parallel; each round still gets its own
commit.

**Every round:** the agent fixes, re-runs the tests covering the amended
code, appends its fix report to the same report file, and lists the files it
changed. Commit exactly those files as one commit (`git add -- <files>`, then
`git commit -m "<message>" -- <files>`); that commit is `<FIX_SHA>`. Before
re-dispatching the reviewer, confirm the fix report contains the covering
tests, the command run, and the output; dispatch the re-review once all
three are present. Name the covering test files in the fix message — a
one-line fix does not need the whole suite.

**Fix dispatch and report.** The fix prompt carries: the open findings
verbatim (file:line, description), the brief path, the report-file path, and
this report format: `STATUS: FIXED | BLOCKED`, `FILES:` every file changed,
`TESTS:` the covering test files, the command run and its output, and, for
BLOCKED, `REASON:` and the finding it concerns. The agent appends the same
text to the report file. It does not commit.

**A fix agent that reports BLOCKED** made no changes worth committing: do
not commit, and the round does not count. Re-dispatch the same findings
once, one tier up (haiku to sonnet, sonnet to opus), with its REASON in the
prompt. If the reason is a contract change or an open-ended finding, rule on
the concrete fix yourself and carry the ruling into the dispatch. If an opus
fix agent is BLOCKED, or the re-dispatch is also BLOCKED, treat it as the
cap: adjudicate as in the breaker.

**The re-review is scoped.** Run `bash scripts/review-package PLAN_FILE <FIX_SHA>~1 <FIX_SHA>`
by its absolute path, from the working tree you're executing in, and dispatch
[re-review-prompt.md](../re-review-prompt.md) with the findings list, the
brief, the report file, and the printed diff path; its fix base is
`<FIX_SHA>~1`. The range holds only this round's commit, even when other
tasks committed in between. The re-reviewer verdicts each finding ADDRESSED
or NOT ADDRESSED and flags new breakage in the fix diff only. New
Critical/Important breakage in the fix diff joins the open findings list.
Out-of-scope observations go to the ledger as deferred minors — they never
extend the loop.

**After each round,** append to the ledger:
`Task <N>: fix round <R>/3 (<X> addressed, <Y> open — <finding one-liners>; commit <sha7>)`

Never fix findings yourself in the controller session — your context stays
clean for coordination, and controller fixes skip review.

**The breaker.** When round 3's re-review still leaves findings open, stop
dispatching. Adjudicate each open finding yourself — you hold the plan and
the cross-task context the reviewer lacks:

- **Out of scope for the task, the reviewer is wrong, or the point is
  contestable:** park it —
  `Task <N>: parked — <finding> — Ruling: <why the code stands>`, and add it
  to the task's `concerns` in the checkpoint. The final review sees both
  sides.
- **Real, but nothing downstream builds on it:** park it the same way, with
  a ruling that says it's real and deferred.
- **Breaks the spec or the task's done criteria, or is load-bearing** — a
  later task builds on it, or it reveals a plan defect: rule on the smallest
  change that unblocks the dependent work, ledger it as
  `Task <N>: Ruling: <finding> — <what you decided and why>`, and carry it
  into the next dispatch that builds on it. It reaches your human partner in
  the final "Rulings I made" list. Parking a structural failure silently lets
  every dependent task build on it. Stop only when the defect leaves every
  path forward a guess.

Adjudicate only at the cap. Adjudicating earlier to end a loop is
pre-judging with a different name. Every adjudication is a ledger entry —
a silent discard is forbidden.
