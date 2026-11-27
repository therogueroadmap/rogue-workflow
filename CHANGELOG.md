# Changelog

## [Unreleased]

### Added
- Plugin icon (`.claude-plugin/icon.png`).

### Security
- Brainstorm companion: the bootstrap page embeds the server token instead of the key read from the request, and escapes `<` in it.

## [0.1.0] - 2026-11-14

### Added
- `brainstorming`, `writing-plans` and `subagent-driven-development`, derived from superpowers 7.0.2.
- `implementer`, `reviewer` and `fix-agent` agents.
- README: `git` listed as a requirement, and a section on using the plugin next to superpowers.
