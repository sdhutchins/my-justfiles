# My Justfiles

A personal library of reusable [`just`](https://just.systems/) files for individual projects
and commands used across projects.

While just is not typically used in bioinformatics, I've adopted it because it is simpler
than make and helps improve reproducibility within and across projects on my systems.

## Repository Structure

```text
global/
    Personal commands used across repositories and from the home directory.

project-specific/
    Copyable templates organized by ecosystem and project archetype.
```

The first project-specific templates cover the project types used most often:

```text
project-specific/
├── python/
│   └── package/
│       └── justfile
└── r/
    └── package/
        └── justfile
```

New templates should follow the same hierarchy:

```text
project-specific/<ecosystem>/<project-archetype>/justfile
```

## Requirements

Every template requires `just`. Install additional tools as needed for the recipes you use.

### R Package

- R, including `Rscript`
- R packages: `lintr`, `devtools`, `rcmdcheck`, and `pkgdown`
- `actionlint` for GitHub Actions validation in `just lintr`
- `act` and a Docker-compatible runtime for the `actions-*` recipes

### Python Package

- `uv` for environment management, command execution, and package builds
- Project development dependencies: Ruff, pytest, and mypy
- `actionlint` for `just actions-lint`
- `act` and a Docker-compatible runtime for the remaining `actions-*` recipes

### Global Justfile

The global justfile requires `zsh`. Its personal recipes use additional tools,
including Git, GitHub CLI, `uv`, `prek`, Conda, Homebrew, Node.js, Ruby, and
project-level utilities. Install only the tools needed for the recipes you use.

### Repository Tests

The local test requires Bash and `just`. ShellCheck is also recommended when
modifying the test script.

## Usage

Copy a template into a project:

```bash
cp project-specific/r/package/justfile ~/projects/my-package/justfile
```

Inspect a template without copying it:

```bash
just --justfile project-specific/r/package/justfile --list
```

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
- [actionlint](https://github.com/rhysd/actionlint) checks GitHub Actions workflow files for syntax and expression errors.
- [act](https://nektosact.com/) runs supported GitHub Actions jobs locally so I can test and debug workflows on my machine.
- [GitHub Actions](https://docs.github.com/en/actions) runs automated checks when I push changes or open pull requests.

## Shared Local and CI Commands

Project templates provide short commands for both local use and GitHub Actions.
For example, an R package developer and the package's workflow can both run:

```bash
just check
```

Defining the underlying command once in the project `justfile` keeps local and
CI instructions consistent and avoids duplication in documentation and workflow YAML.

## Testing

Run the interface tests:

```bash
bash tests/test-justfiles.sh
```

The tests use temporary fake executables to verify generated commands.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidance. Keep new
templates focused, explicit, and understandable from a single file.

## License

This repository is available under the [MIT License](LICENSE).
