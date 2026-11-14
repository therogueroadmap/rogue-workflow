#!/usr/bin/env bash
# Prueba los scripts de ejecución sobre un repo temporal.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
s="$root/skills/subagent-driven-development/scripts"
t=$(mktemp -d); o=$(mktemp -d); trap 'rm -rf "$t" "$o"' EXIT
cd "$t"; git init -q -b feature; git config user.email t@t; git config user.name t
mkdir -p docs/superpowers/plans
printf '# P\n\n### Task 1: One\n\nbody one\n\n### Task 2: Two\n\nbody two\n' > docs/superpowers/plans/p.md
echo base > base.txt; git add -A; git commit -qm base
plan=docs/superpowers/plans/p.md

ws=$(bash "$s/sdd-workspace" "$plan")
case "$ws" in */.rogue-workflow/sdd/p) ;; *) echo "FAIL workspace: $ws"; exit 1 ;; esac
[ -z "$(git status --porcelain)" ] || { echo "FAIL workspace not ignored"; git status --porcelain; exit 1; }

# D15: fuera de un repo, sin -C, los scripts se niegan; con -C usan el repo indicado.
if ! git -C "$o" rev-parse --git-dir >/dev/null 2>&1; then
  if (cd "$o" && bash "$s/sdd-workspace" "$t/$plan") >/dev/null 2>&1; then echo "FAIL workspace outside a repo"; exit 1; fi
fi
ws2=$(cd "$o" && bash "$s/sdd-workspace" -C "$t" "$t/$plan")
[ "$ws2" = "$ws" ] || { echo "FAIL -C workspace: $ws2 (expected $ws)"; exit 1; }

brief=$(bash "$s/task-brief" "$plan" 2 | sed -n 's/^wrote \(.*\): .*/\1/p')
grep -q 'body two' "$brief" || { echo "FAIL brief lacks task text"; exit 1; }
if grep -q 'body one' "$brief"; then echo "FAIL brief has other task"; exit 1; fi

# Dos tareas en paralelo: cada paquete debe contener solo su commit.
echo a > a.txt; git add a.txt; git commit -qm taskA; A=$(git rev-parse HEAD)
echo b > b.txt; git add b.txt; git commit -qm taskB; B=$(git rev-parse HEAD)
out=$(bash "$s/review-package" "$plan" "$A~1" "$A")
pkg=$(echo "$out" | sed -n 's/^wrote \(.*\): .*/\1/p')
grep -q 'a.txt' "$pkg" || { echo "FAIL package lacks a.txt"; exit 1; }
if grep -q 'b.txt' "$pkg"; then echo "FAIL package has b.txt"; exit 1; fi
out=$(cd "$o" && bash "$s/review-package" -C "$t" "$t/$plan" "$B~1" "$B")
pkg=$(echo "$out" | sed -n 's/^wrote \(.*\): .*/\1/p')
grep -q 'b.txt' "$pkg" || { echo "FAIL package lacks b.txt"; exit 1; }
if grep -q 'a.txt' "$pkg"; then echo "FAIL package has a.txt"; exit 1; fi

# check_private: a missing patterns file skips with a warning; a Python failure must fail the check.
cp="$root/tests/check-plugin.sh"; pd=$(mktemp -d)
trap 'rm -rf "$t" "$o" "$pd"' EXIT
out=$(PUBLISHABLE_PRIVATE_PATTERNS="$pd/absent.txt" bash "$cp" private 2>&1) || { echo "FAIL private: absent file must skip"; exit 1; }
case "$out" in *"WARN: private check skipped"*) ;; *) echo "FAIL private: no skip warning"; exit 1 ;; esac
printf '# comment only
qq-no-such-token-z{3}
' > "$pd/ok.txt"
PUBLISHABLE_PRIVATE_PATTERNS="$pd/ok.txt" bash "$cp" private >/dev/null 2>&1 || { echo "FAIL private: clean patterns must pass"; exit 1; }
printf '(unclosed
' > "$pd/bad.txt"                 # invalid regex: Python raises
printf '# only comments
' > "$pd/empty.txt"         # zero patterns read
for pf in "$pd/bad.txt" "$pd/empty.txt"; do
  if PUBLISHABLE_PRIVATE_PATTERNS="$pf" bash "$cp" private >/dev/null 2>"$pd/err.txt"; then echo "FAIL private: Python failure must fail ($pf)"; exit 1; fi
  [ -s "$pd/err.txt" ] || { echo "FAIL private: no error on stderr ($pf)"; exit 1; }
done
if PUBLISHABLE_PRIVATE_PATTERNS="$pd/ok.txt" PYTHON=no-such-python-binary bash "$cp" private >/dev/null 2>&1; then echo "FAIL private: missing interpreter must fail"; exit 1; fi
echo "OK: scripts"
