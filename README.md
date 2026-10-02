# My Justfiles

A personal library of reusable [`just`](https://just.systems/) files for individual projects
and commands used across projects.

While just is not typically used in bioinformatics, I've adopted it because it is simpler
than make and helps improve reproducibility within and across projects on my systems.

## Repository Structure

```text
global/
    Personal commands used across repositories and from the home directory.
```

## Requirements

The global justfile requires `just`. Install additional tools as needed for the recipes you use.

### Global Justfile

The global justfile requires `zsh`. Its personal recipes use additional tools,
including Git, GitHub CLI, `uv`, `prek`, Conda, Homebrew, Node.js, Ruby, and
project-level utilities. Install only the tools needed for the recipes you use.

### Repository Tests

The local test requires Bash and `just`. ShellCheck is also recommended when
modifying the test script.

## Usage

The file at `global/justfile` is a tracked copy of my personal justfile used
from the `home` directory. Copy it to `~/.justfile` only after reviewing paths and
commands that are specific to your local system.

### Git Hooks

Repositories define their checks in `.pre-commit-config.yaml`; the global
justfile provides a consistent interface for running them with `prek`:

```bash
just hooks-install
just hooks-run
just hooks-all
just hooks-update-check
just hooks-update
```

`hooks-run` checks staged files. `hooks-all` checks every tracked file and asks
for confirmation because formatters may modify files. `hooks-update-check`
reports available hook updates without editing the configuration, while
`hooks-update` updates pinned revisions after confirmation.

## Tool Roles

I also use these tools to check my projects:

- [prek](https://prek.j178.dev/) manages Git hooks. I use it to run each repository's formatting and code checks.

## Testing

Run the interface tests:

```bash
bash tests/test-justfiles.sh
```

The tests use temporary fake executables to verify generated commands.

## License

This repository is available under the [MIT License](LICENSE).
