# rogue-workflow

A development workflow for Claude Code that I use in my own projects: idea, plan, and execution with subagents running in parallel by dependency level.

It is built on [superpowers](https://github.com/obra/superpowers) by Jesse Vincent. Superpowers runs one implementer at a time. I wanted plans that declare their dependencies, so independent tasks can run together. The full credit and license are in [NOTICE](NOTICE), and each derived skill lists its changes in its header.

## Skills

| Skill | What it adds to the superpowers original |
|---|---|
| `brainstorming` | Checks for prior specs and plans. Leaves the commit to you. Asks for technical content in software specs |
| `writing-plans` | Dependency map with levels, and a verifier that checks every assumed symbol against the code |
| `subagent-driven-development` | Parallel execution by level, one commit per task made by the controller, and a checkpoint on disk |

## Install

From the [The Rogue Roadmap catalog](https://github.com/therogueroadmap/marketplace):

```text
/plugin marketplace add therogueroadmap/marketplace
/plugin install rogue-workflow@therogueroadmap
```

## Using it next to superpowers

You do not need superpowers installed. If you have both, three skills overlap: `brainstorming`, `writing-plans` and `subagent-driven-development`. Each plugin registers its own, prefixed with its plugin name, so they never collide. What I saw when testing both together: if you name the skill, the one you named runs. If you do not, `superpowers:brainstorming` won in my test. Superpowers injects its own skill index at session start, which names only its own skills, and `brainstorming` has the same description in both plugins.

Ways to pick:

- Name it with the qualified form: `/rogue-workflow:brainstorming`, `/rogue-workflow:writing-plans`, `/rogue-workflow:subagent-driven-development`.
- For requests without a name, add a line to your project or user `CLAUDE.md`, for example "For brainstorming, plans and plan execution use the `rogue-workflow:*` skills."

The workflow keeps itself together: `rogue-workflow:brainstorming` hands off to `rogue-workflow:writing-plans`, which hands off to `rogue-workflow:subagent-driven-development`. A chain that starts in superpowers continues in superpowers.

## Commits

Starting a plan execution authorizes local commits. The workflow never pushes or merges on its own.

## Requirements

- Claude Code.
- `bash` for the execution scripts (Git Bash on Windows).
- `git`, which the scripts call to inspect and commit the repository.
- `node` for the optional visual companion in `brainstorming`.

## Status

Version 0.1.0. In progress: I am still testing it against real plans.
