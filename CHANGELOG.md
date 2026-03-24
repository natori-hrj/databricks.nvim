# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-03-24

### Added

- `:DatabricksRun` command to execute Python files on a Databricks cluster
- `:DatabricksClusterList` command to list available clusters
- `:DatabricksClusterSelect` command to interactively select a cluster
- `:DatabricksOutput` command to re-display the last run output
- Async execution — editor is never blocked
- Input validation for cluster IDs, DBFS paths, local paths, and profile names
- Security: credential masking in error messages, injection prevention
- Output buffer with real-time status updates
