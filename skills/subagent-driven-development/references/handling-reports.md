<!-- Based on superpowers 7.0.2 by Jesse Vincent (MIT, see NOTICE).
Changes: PRECONDITION_FAILED with its re-queue or escalation rule; finished work is
committed by the controller before its review. -->
# Handling a Report That Isn't DONE

Part of rogue-workflow:subagent-driven-development.

**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them, commit the task as for DONE, and proceed to review. Do not commit while correctness or scope concerns are open: address them (re-dispatch the implementer with the concerns, or a fix agent), and commit once, when the task reports DONE, so the task stays one commit. The same holds after NEEDS_CONTEXT and BLOCKED re-dispatches: commit only on the final DONE.

**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
1. If it's a context problem, provide more context and re-dispatch with the same model
2. If the task requires more reasoning, re-dispatch with a more capable model
3. If the task is too large, break it into smaller pieces
4. If the plan itself is wrong, rule on the correction, ledger it, and re-dispatch with the ruling carried in the dispatch

**PRECONDITION_FAILED:** A file or symbol the task needs did not exist yet; the implementer stopped before writing code.
1. If the expected source is a task of this level still running: re-dispatch this task once that one reports DONE and is committed, and record `{ "task", "promoted_after", "reason" }` under `dependency_corrections` in the checkpoint. This is a map error: do not ask your human partner.
2. If that task has finished, the plan has a defect. If no task produces it, the plan lacks a task. In both cases rule on it, ledger the ruling, and re-dispatch with the ruling carried in the dispatch, or stop if every path forward is a guess.

**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.
