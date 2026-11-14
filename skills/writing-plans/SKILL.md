---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code. Emits a dependency map so independent tasks can run in parallel.
---

<!-- Based on superpowers 7.0.2 by Jesse Vincent (MIT, see NOTICE).
Changes: dependency analysis, levels and map; dependency verifier with GHOST detection;
the controller makes commits; hand-off to level execution or multi-session. -->

# Writing Plans

## Overview

Write implementation plans for an engineer who has not seen this codebase or this spec. Assume they write idiomatic code in the project's language once they know the exact interface and the exact test, and that they will make a reasonable choice wherever the plan leaves one open. What they cannot know is what you decided: which files, which names and signatures, which values from the spec, which tests prove each task. Document those. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. One commit per task, made by the controller.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Dependency Analysis

Before writing tasks, work out the functional dependencies between them. This is what allows parallel execution.

**Task B depends on Task A when:**
- B uses types, interfaces or functions first defined in A
- B imports from files created in A
- B's test setup needs A's implementation to exist
- B tests behavior built directly on A's output

**Task B does not depend on Task A when:**
- They touch different files with no shared interface
- B's tests could pass without A existing
- B only depends on an external system, not on A's code

Tasks at the same level must not share files. Keep chains short: if C depends on B and B on A, check whether C could depend on A directly.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Step Granularity

**Each step is one action with a checkable result:**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Report the changed files" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use rogue-workflow:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Spec:** [path to the spec/design doc this plan implements — the plan
argues from the spec, so the spec travels with it; executors read both]

## Dependency Map

| Task | Depends On | Level |
|------|-----------|-------|
| Task 1: [name] | none | 0 |
| Task 2: [name] | none | 0 |
| Task 3: [name] | Task 1 | 1 |

**Parallel groups:**
- **Level 0 (parallel):** Task 1, Task 2
- **Level 1:** Task 3

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

## Review Focus

[The five input classes or failure modes the spec implies but no task's
tests exercise that are most likely to bite a person using this software
— one line each, naming the input or condition and the behavior a
reasonable person would expect, most likely first. The spec is a vision
document: it says what the software must do, not everything it will
meet, and its silence on an input is not permission for that input to
break the program. Write the list here, once, with the spec in front of
you. Then, for each line, add the test that pins it to the task that
owns the code, in that task's own step style.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Depends on:** none | Task X, Task Y
**Level:** N
**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Implement `function(input: InputType) -> ResultType` in `exact/path/to/file.py`**

One line on the approach when the signature and the test leave a choice
(which library call, which data structure); a code block only for an
algorithm they do not determine.

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Report the changed files**

Leave the changes uncommitted. Do not run `git add` or `git commit`. List every file you created or changed in your report: the controller commits them as one commit for this task.
````

## What a Step Contains

A step is done when the implementer can write exactly one reasonable thing
from it. That is the whole requirement: unambiguous, not complete. Each kind
of step carries what makes it unambiguous and nothing more:

- **A test step:** the test's name and its assertions, as code, with the
  spec's exact values in them.
- **A code step:** the exact signature (name, parameters, return type), the
  file it lives in, and the specific values the spec pins. The implementer
  writes the body. A body appears only for an algorithm the signature and
  tests do not determine, or for exact copy the spec fixes.
- **A verification step:** the command to run and the output that means it
  passed.
- **A reference to another task:** that task's Interfaces block says what
  to use; the plan does not repeat that task's code.

A plan is the set of decisions the implementer cannot make alone. A plan
longer than the code it describes has written the code instead. Lines that
decide nothing ("TBD", "handle edge cases", "add appropriate validation",
"write tests for the above", a type or function no task defines) are the
opposite failure, and the self-review catches both.

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Step scan:** Every step must let the implementer write exactly one reasonable thing, and no step may carry more than that: a line that decides nothing is a gap, a function body the signature and tests already determine is a transcript. Fix both.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Review Focus:** For each input class or failure mode the spec implies, is there a task whose tests exercise it? The five uncovered ones most likely to bite a person go in the Review Focus section, and each line there gets its test added to the owning task. An empty section means you checked and found none, not that you skipped the check.

**5. Proportion:** Compare the plan's length to the spec's. A plan several times longer than the spec it implements is a transcript of the program, not a plan. If code blocks are most of the document, replace bodies with signatures, test names and assertions, and check that each step is still unambiguous.

**6. Dependency correctness:** Is every dependency accurate? Could a missing one break a parallel task? Does a false one serialize tasks needlessly?

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Dependency Verification

After Self-Review, dispatch `rogue-workflow:reviewer` with `model: sonnet`, before the hand-off.

```
You verify the dependencies of an implementation plan. You edit nothing.

Plan: [PLAN_FILE]

1. For each task, read its Interfaces block and code blocks and list:
   - CREATES: types, functions, constants and file paths it produces
   - CONSUMES: what it uses from other tasks or from the existing code
2. Cross-reference:
   - If B consumes what A creates, B must declare a dependency on A.
   - If B declares a dependency on A and consumes nothing from A, it is false.
3. If C depends on B and B on A, but C only uses A's artifacts, C can move to an earlier level.
4. A consumed symbol that no task creates is claimed to exist already. Do not trust the claim. Open the code and confirm its path, signature and return type:
   - All confirmed: AMBIENT
   - Different path, signature or return type, or not found: GHOST

Reply only with:
---DEPS---
MISSING: TaskB -> TaskA (reason)
FALSE: TaskC -> TaskB (reason)
CHAIN: TaskD could be Level 1 (reason)
AMBIENT: Symbol in path (confirmed)
GHOST: symbol assumed by TaskF; real symbol and location, or not found
OK (if there are no issues)
---END---
```

Then fix the plan and save it:

- MISSING, FALSE, CHAIN: update the map and recalculate levels.
- GHOST: rewrite the affected steps with the real symbol. If it really must be created, it is not ambient: add the task that creates it, with its dependency.

## Execution Handoff

After saving and self-reviewing the plan, link it for your human partner
to read. If they have already explicitly supplied an execution method, ask
them to review the plan and confirm it captures what they want; wait for that
review before implementation, then use the preserved method. Otherwise, ask
them to review the plan and choose an execution method before implementation.

**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Please review the plan. Which execution approach would you prefer?**

- **By level** - Subagents implement each level in parallel, each task is reviewed, and the controller commits one commit per task. Run it in a new session: `/rogue-workflow:subagent-driven-development <absolute path of the plan>`. The controller re-reads its whole context on every turn, and carrying this brainstorming and planning (about 100k tokens over some 70 turns) costs on the order of 7M tokens and brings compaction closer. If your human partner asks to run it in this session, do so. Starting it authorizes local commits; it never pushes or merges.
- **Multi-session** - Only if the `multisession-dev-plugin:run-plan` skill is available and the plan stays in one repository. Each level runs in its own unattended session, which suits long plans.

**For this plan I recommend <one>, because <one sentence: number of levels and how long the plan is>. Does the plan capture what you want, and which approach should we use?"**

If they already chose a method, only ask them to review the plan.

**If By level chosen:**
- Print the new-session command with the plan's absolute path and stop.
- **REQUIRED SUB-SKILL**, only if they asked to run it in this session: Use rogue-workflow:subagent-driven-development

**If Multi-session chosen:**
- **REQUIRED SUB-SKILL:** Use multisession-dev-plugin:run-plan
