<!-- Based on superpowers 7.0.2 by Jesse Vincent (MIT, see NOTICE).
Changes: resume by level with the checkpoint; the old flat-path note is dropped. -->
# Resuming From an Existing Ledger

Part of rogue-workflow:subagent-driven-development. This plan's workspace
already has a ledger at `<workspace>/progress.md`.

If the ledger's first line names your plan file, resume at the first level
not listed in `completed_levels` of the checkpoint
(`docs/superpowers/plans/.controller-state.json`), not at the first task
without a commit. Inside that level, tasks with a `Task <N>: complete` line
are DONE — do not re-dispatch them. A task with a commit and no completion
line still needs its review. A task whose last line is a fix round is
mid-loop: resume the loop at the next round. A ledger with more progress
than the checkpoint wins: update the checkpoint to match it. A ledger whose
first line names a different plan file is another plan's progress: leave it
in place and start your own, fresh.
