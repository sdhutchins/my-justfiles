# Contributing to My Justfiles

Contributions should keep the library simple, browsable, and easy to copy from.

## Adding or Updating a Template

1. Place project templates under
   `project-specific/<ecosystem>/<project-archetype>/justfile`.
2. Keep recipes short, explicit, and free of hidden side effects.
3. Check required tools without installing them automatically.
4. Give destructive recipes clear names and require deliberate invocation.
5. Validate the template before opening a pull request:

   ```bash
   just --justfile path/to/justfile --list
   just --fmt --check --justfile path/to/justfile
   ```

Open issues and pull requests in the
[my-justfiles repository](https://github.com/sdhutchins/my-justfiles).
