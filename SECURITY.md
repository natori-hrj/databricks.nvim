# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in databricks.nvim, please report it responsibly.

**Do not open a public GitHub issue for security vulnerabilities.**

Instead, please send an email or contact the maintainer directly through GitHub.

### What to include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response timeline

- **Acknowledgment**: within 48 hours
- **Initial assessment**: within 1 week
- **Fix release**: as soon as possible, depending on severity

## Security Design

This plugin follows these security principles:

- **No credential storage**: Authentication is fully delegated to the Databricks CLI
- **Input validation**: All user inputs (paths, IDs, profiles) are validated before use
- **Injection prevention**: Shell arguments are escaped; JSON payloads use temp files instead of shell interpolation
- **Information masking**: Tokens and host URLs are masked in error messages
- **Minimal permissions**: The plugin only requires read access to local `.py` files and execution of the `databricks` CLI
