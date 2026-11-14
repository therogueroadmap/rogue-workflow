<!-- Based on superpowers 7.0.2 by Jesse Vincent (MIT, see NOTICE).
Changes: local final-reviewer template and typed agents; the fix wave is one commit and its
re-review covers that commit; own closing steps, which never push or merge. -->
# Final Review and Close

Part of rogue-workflow:subagent-driven-development. Every level is closed.
Single-level mode skips this file.

The final whole-branch review gets a package too: run
`bash scripts/review-package PLAN_FILE MERGE_BASE HEAD` by its absolute path,
from the working tree you're executing in (MERGE_BASE =
`git merge-base <base> HEAD`, with `<base>` from Base branch below) and include the
printed path in the final review dispatch, so the final reviewer reads
one file instead of re-deriving the branch diff with git commands. Dispatch
`rogue-workflow:reviewer` with `model: opus` (see SKILL.md's Model
Selection), using [final-reviewer-prompt.md](../final-reviewer-prompt.md).
Point it at the ledger's deferred-minor and parked lines so it can triage
which must be fixed before merge.

If the final whole-branch review returns findings, dispatch ONE
`rogue-workflow:fix-agent` with the complete findings list, with `model: sonnet`
or higher (the wave spans files and findings) and the report format from
`fix-loop.md` — not one fixer
per finding. Per-finding fixers each rebuild context and re-run suites; a
real session's final-review fix wave cost more than all its tasks combined.
Commit the files it reports as one commit, `<FIX_SHA>`. Then run exactly
one scoped re-review of the fix wave
(`bash scripts/review-package PLAN_FILE <FIX_SHA>~1 <FIX_SHA>` by its
absolute path, from the working tree you're executing in,
[re-review-prompt.md](../re-review-prompt.md)).
Adjudicate any residual findings as in the fix loop's breaker
([fix-loop.md](fix-loop.md)): park with rulings, or rule on the load-bearing
ones and ledger what you decided. Only the four things that stop a running
plan (top of SKILL.md) stop you here. There is no second fix wave —
residual load-bearing findings surface to your human partner in the
closing options below.

### Base branch

The base branch is the one the work branch came from. Take it, in order:

1. The branch your prompt, the plan or the checkpoint names.
2. Otherwise, for each of `develop`, `main`, `master` that exists
   (`git rev-parse --verify --quiet <b>`), take `git merge-base <b> HEAD`.
   The base is the candidate whose merge-base is newest
   (`git log -1 --format=%ct <sha>`). On a tie, or if none exists, go to 3.
3. If no rule settles it, use your best candidate for the review package
   and ask your human partner to confirm it at Close.

### Finish

Before you delete anything, collect every ledger line containing `Ruling:` —
preflight rulings, parked findings, breaker adjudications, all of them — into
your final message under "Rulings I made", in the order you made them, each
with what it costs if wrong. The list is exhaustive: if the ledger holds a
ruling, the list holds it. That list is the only place the decisions you
took on your human partner's behalf reach them — they read it and rework
whatever you got wrong. A ruling that dies with the workspace was a decision
made in secret.

When the final whole-branch review is clean and its fix wave is committed,
delete this plan's workspace (`rm -rf <workspace>`) — the git history is
the record now. Sibling directories belong to other plans; leave them
alone. Keep the checkpoint in `docs/superpowers/plans/`: drivers read it.

### Close

1. Run the full test suite. If it fails, report it and stop.
2. Show the branch, the base branch you used, its commits since it, and
   these options, without acting on them:
   - Merge locally into the base branch
   - Push and open a pull request
   - Keep the branch as it is
3. Do what your human partner chooses. Never discard work without their
   explicit confirmation.
