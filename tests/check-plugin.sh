#!/usr/bin/env bash
# Comprobaciones estáticas del plugin. Uso: check-plugin.sh <componente|all>
set -uo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
comp=${1:-all}
fail=0
err() { echo "FAIL: $*"; fail=1; }
need() { [ -f "$root/$1" ] || err "missing $1"; }
has() { grep -qF -- "$2" "$root/$1" 2>/dev/null || err "$1 lacks: $2"; }
hasnt() { [ -f "$root/$1" ] || { err "missing $1"; return; }; if grep -qF -- "$2" "$root/$1"; then err "$1 still has: $2"; fi; }

check_manifest() {
  need .claude-plugin/plugin.json; need LICENSE; need NOTICE; need README.md; need CHANGELOG.md
  need .github/workflows/publishable.yml; need docs/driver-contract.md
  python -c "import json,sys; d=json.load(open(sys.argv[1],encoding='utf-8')); assert d['name']=='rogue-workflow'; assert d['version']=='0.1.0'; assert 'dependencies' not in d" "$root/.claude-plugin/plugin.json" || err "bad plugin.json"
  has NOTICE "Jesse Vincent"; has NOTICE "Permission is hereby granted"; has README.md "obra/superpowers"; has README.md "## Requirements"
}
check_brainstorming() {
  f=skills/brainstorming/SKILL.md
  need "$f"; need skills/brainstorming/builder-check-prompt.md; need skills/brainstorming/visual-companion.md; need skills/brainstorming/scripts/server.cjs
  has "$f" "name: brainstorming"; has "$f" "Based on superpowers 7.0.2"; has "$f" "## Prior Work Check"
  has "$f" "rogue-workflow:writing-plans"; has "$f" "error handling"
  hasnt "$f" "superpowers:"; hasnt "$f" ", committed."
  has skills/brainstorming/builder-check-prompt.md "rogue-workflow:reviewer"
  hasnt skills/brainstorming/builder-check-prompt.md "general-purpose"
  hasnt skills/brainstorming/scripts/server.cjs "primeradiant.com"
  hasnt skills/brainstorming/scripts/start-server.sh ".superpowers"
  hasnt skills/brainstorming/visual-companion.md ".superpowers"
}
check_writing_plans() {
  f=skills/writing-plans/SKILL.md
  need "$f"
  has "$f" "name: writing-plans"; has "$f" "Based on superpowers 7.0.2"; has "$f" "## Dependency Analysis"
  has "$f" "## Dependency Map"; has "$f" "**Depends on:**"; has "$f" "**Level:**"; has "$f" "## Dependency Verification"
  has "$f" "GHOST"; has "$f" "rogue-workflow:subagent-driven-development"; has "$f" "run-plan"
  hasnt "$f" "superpowers:"; hasnt "$f" "git commit -m"; hasnt "$f" "D:\\"
}
check_sdd() {
  d=skills/subagent-driven-development
  for x in SKILL.md implementer-prompt.md task-reviewer-prompt.md re-review-prompt.md final-reviewer-prompt.md scripts/task-brief scripts/sdd-workspace scripts/review-package scripts/sdd-repo; do need "$d/$x"; done
  refs="fix-loop final-review handling-reports resuming preflight cannot-verify"
  for r in $refs; do
    need "$d/references/$r.md"; has "$d/references/$r.md" "Based on superpowers 7.0.2"; has "$d/references/$r.md" "Part of rogue-workflow:subagent-driven-development"
  done
  [ ! -e "$root/$d/references/batching.md" ] || err "$d/references/batching.md must not exist"
  f=$d/SKILL.md
  if [ -f "$root/$f" ]; then n=$(wc -c < "$root/$f" | tr -d ' '); [ "$n" -lt 18000 ] || err "$f is $n bytes, budget is under 18000"; fi
  has "$f" "name: subagent-driven-development"; has "$f" "Based on superpowers 7.0.2"; has "$f" "## Parallel Execution by Level"
  has "$f" "PRECONDITION_FAILED"; has "$f" ".controller-state.json"; has "$f" "rogue-workflow:implementer"; has "$f" "rogue-workflow:fix-agent"
  has "$f" "Three rounds maximum per task"; has "$f" "<SHA>~1 <SHA>"; has "$f" "main or master"; has "$f" "Single-level mode"
  for r in fix-loop handling-reports final-review resuming; do has "$f" "references/$r.md"; done
  hasnt "$f" "TaskOutput"; hasnt "$f" "Never dispatch multiple implementation subagents"
  r=$d/references
  has "$r/fix-loop.md" "Three rounds maximum per task"; has "$r/fix-loop.md" "rogue-workflow:fix-agent"; has "$r/fix-loop.md" "<FIX_SHA>~1 <FIX_SHA>"; has "$r/fix-loop.md" "fix round <R>/3"
  has "$r/handling-reports.md" "PRECONDITION_FAILED"; has "$r/handling-reports.md" "dependency_corrections"
  has "$r/resuming.md" "completed_levels"
  has "$r/final-review.md" "Rulings I made"; has "$r/final-review.md" "../final-reviewer-prompt.md"; has "$r/final-review.md" "<FIX_SHA>~1 <FIX_SHA>"
  for x in SKILL.md $(for r in $refs; do echo "references/$r.md"; done); do
    for s in "Five rounds" "FIX_BASE" "batching.md" "superpowers:" ".superpowers/" "finishing-a-development-branch" "requesting-code-review" "using-git-worktrees"; do hasnt "$d/$x" "$s"; done
  done
  has "$d/implementer-prompt.md" "Do not run git add or git commit"
  hasnt "$d/implementer-prompt.md" "Commit your work"
  for x in implementer-prompt.md task-reviewer-prompt.md re-review-prompt.md final-reviewer-prompt.md; do hasnt "$d/$x" "general-purpose"; done
  for x in task-brief sdd-workspace review-package sdd-repo; do hasnt "$d/scripts/$x" ".superpowers"; done
}
check_budget() {
  for f in "$root"/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    n=$(wc -c < "$f" | tr -d ' ')
    [ "$n" -lt 20000 ] || err "${f#"$root"/} is $n bytes, every SKILL.md must stay under 20000"
  done
}
check_agents() {
  for a in implementer reviewer fix-agent; do
    f=agents/$a.md; need "$f"; has "$f" "name: $a"; hasnt "$f" "my-subagent-driven-development"; hasnt "$f" "graphify"; hasnt "$f" "Compact Report Override"
  done
  has agents/implementer.md "model: sonnet"; has agents/reviewer.md "model: sonnet"; has agents/fix-agent.md "model: haiku"
  has agents/implementer.md "do not run git add or git commit"; has agents/fix-agent.md "do not run git add or git commit"
}
check_private() {
  # Same private rules as the publishable scanner: one Python regex per line, '#' comments.
  # They live outside every repo; without the file (CI, another machine) the check is skipped.
  pf=${PUBLISHABLE_PRIVATE_PATTERNS:-$HOME/.config/publishable/private-patterns.txt}
  if [ ! -f "$pf" ]; then echo "WARN: private check skipped, no patterns file at $pf"; return; fi
  # A Python failure must never read as "no private content": keep its status and stderr apart from the hits.
  errf=$(mktemp); rc=0
  hits=$(${PYTHON:-python} - "$root" "$pf" 2>"$errf" <<'PY'
import os, re, sys
root, pf = sys.argv[1], sys.argv[2]
rules = []
with open(pf, encoding="utf-8-sig") as fh:
    for line in fh:
        rule = line.strip()
        if rule and not rule.startswith("#"):
            rules.append(re.compile(rule, re.IGNORECASE))
if not rules:
    sys.exit("no patterns read from " + pf)
for dirpath, dirnames, filenames in os.walk(root):
    dirnames[:] = [d for d in dirnames if d != ".git"]
    for name in filenames:
        path = os.path.join(dirpath, name)
        try:
            with open(path, encoding="utf-8") as fh:
                lines = fh.read().splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        for n, text in enumerate(lines, 1):
            if any(r.search(text) for r in rules):
                print(f"{os.path.relpath(path, root)}:{n}")
PY
) || rc=$?
  if [ "$rc" -ne 0 ]; then
    cat "$errf" >&2; rm -f "$errf"
    err "private check could not run (python exit $rc)"; return
  fi
  rm -f "$errf"
  [ -z "$hits" ] || err "private references (scanner patterns): $hits"
}
case "$comp" in
  manifest) check_manifest ;;
  brainstorming) check_brainstorming ;;
  writing-plans) check_writing_plans ;;
  sdd) check_sdd ;;
  agents) check_agents ;;
  private) check_private ;;
  all) check_manifest; check_brainstorming; check_writing_plans; check_sdd; check_agents; check_private; check_budget ;;
  *) echo "unknown component: $comp"; exit 2 ;;
esac
[ "$fail" -eq 0 ] && echo "OK: $comp"
exit "$fail"
