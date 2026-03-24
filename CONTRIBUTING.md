# Contributing to databricks.nvim

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/<your-username>/databricks.nvim.git`
3. Create a feature branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Run tests: `make test`
6. Commit and push
7. Open a Pull Request

## Development Setup

### Requirements

- Neovim >= 0.9
- [plenary.nvim](https://github.com/nvim-nui/plenary.nvim) (for running tests)
- [StyLua](https://github.com/JohnnyMorganz/StyLua) (for formatting)

### Running Tests

```bash
make test
```

### Formatting

```bash
make format
```

## Code Guidelines

- Write Lua code following existing style in the project
- Use `vim.fn.shellescape()` for any shell arguments
- Never store or log credentials/tokens
- Validate all external inputs (paths, IDs, etc.)
- Keep functions focused and small
- Add tests for new functionality

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add cluster start/stop commands
fix: handle empty JSON response from CLI
docs: update installation instructions
test: add tests for path validation
```

## Pull Request Process

1. Update the README.md if your change affects the public API
2. Add or update tests to cover your changes
3. Ensure all tests pass
4. Update the CHANGELOG.md under the `[Unreleased]` section
5. Your PR will be reviewed and merged once approved

## Reporting Bugs

Use the [Bug Report](https://github.com/natori/databricks.nvim/issues/new?template=bug_report.md) issue template.

## Requesting Features

Use the [Feature Request](https://github.com/natori/databricks.nvim/issues/new?template=feature_request.md) issue template.

## Security

If you discover a security vulnerability, please **do not** open a public issue. Instead, see [SECURITY.md](SECURITY.md) for responsible disclosure instructions.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
