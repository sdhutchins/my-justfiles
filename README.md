# My Justfiles

[![CI](https://img.shields.io/github/actions/workflow/status/sdhutchins/my-justfiles/ci.yml?branch=main&label=CI)](https://github.com/sdhutchins/my-justfiles/actions/workflows/ci.yml)

A personal library of reusable [`just` files](https://just.systems/).

## Table of Contents

- [Project Background](#project-background)
- [Install & Setup](#install--setup)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Authors](#authors)

## Project Background

While just is not typically used in bioinformatics, I've adopted it because it is simpler
than make and helps improve reproducibility within and across projects on my systems.

## Install & Setup

Install `just` and the tools needed for the recipes you use. Project templates
use Bash. My global justfile uses `zsh`.

| Justfile | Recipe dependencies |
| --- | --- |
| [R package](project-specific/r/package/justfile) | R, `lintr`, `devtools`, `rcmdcheck`, `pkgdown` |
| [Python package](project-specific/python/package/justfile) | `uv`, Ruff, pytest, mypy |
| [nf-core pipeline](project-specific/nextflow/nf-core/justfile) | Nextflow, compatible Java, nf-core tools, Docker for the default test profile |
| [Global](global/justfile) | Personal tools and scripts referenced by each recipe; `prek` for Git hooks |

`actionlint` checks workflow files. `act` runs workflows locally using a
Docker-compatible runtime. In the R template, `just lintr` also runs `actionlint`.

Copy the appropriate template into an existing project:

```bash
cp project-specific/r/package/justfile ~/projects/my-package/justfile
```

For personal commands, review the paths and scripts in `global/justfile` before
copying it to `~/.justfile`.

## Usage

From a project containing a justfile, list its recipes and run a task:

```bash
just --list
just test
```

To inspect a template before copying it:

```bash
just --justfile project-specific/r/package/justfile --list
```

The global Git hook recipes use the current repository's `.pre-commit-config.yaml`.
`hooks-install` installs hooks. `hooks-run` checks staged files. `hooks-all`
checks all tracked files after confirmation. `hooks-update-check` reports available
updates. `hooks-update` applies them after confirmation.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for template conventions and contribution guidance.

With Bash, `just`, and `zsh` installed, run the repository tests:

```bash
bash tests/test-justfiles.sh
```

The tests check parsing, formatting, and recipe commands using temporary mock tools.
The CI workflow also checks Markdown style, shell scripts, and documentation links.

## License

[MIT License](LICENSE).

## Authors

[Shaurita D. Hutchins](https://github.com/sdhutchins) · [✉️](mailto:shaurita.d.hutchins@gmail.com)
