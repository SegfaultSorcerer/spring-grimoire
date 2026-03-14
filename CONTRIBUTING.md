# Contributing to Spring Grimoire

Contributions are welcome! Whether it's a new skill, a bug fix, or an improvement to an existing skill — we appreciate your help.

## How to Contribute

1. **Fork** the repository
2. **Create a branch** for your changes
3. **Make your changes** (see guidelines below)
4. **Open a Pull Request** with a clear description of what you changed and why

## Adding a New Skill

1. Create `skills/<spring-skill-name>/SKILL.md` with YAML frontmatter (`name`, `description`, `allowed-tools`)
2. Prefix the skill name with `spring-` for consistent grouping
3. Add reference material in `skills/<spring-skill-name>/references/` if needed
4. Keep `SKILL.md` under 500 lines — use reference files for detailed content
5. Make the `description` field specific enough for auto-triggering
6. Update the README with the new skill

## Improving an Existing Skill

- Read the skill's benchmark results in the README to understand current performance
- Test your changes against realistic Spring Boot projects
- If possible, run with-skill vs without-skill comparisons to validate improvements

## Code Style

- Skills are written in Markdown with YAML frontmatter
- Use `!` dynamic context commands to gather project information at runtime
- Prefer explaining *why* over rigid `MUST`/`NEVER` directives
- Include before/after code examples for non-trivial recommendations

## License

This project is dual-licensed under either of

- [Apache License, Version 2.0](LICENSE-APACHE)
- [MIT License](LICENSE-MIT)

at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in this project by you shall be dual-licensed as above, without any additional terms or conditions.
