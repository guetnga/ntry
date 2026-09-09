# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-09-09

### Added

- `Ntry.retry/3` macro for describing retry decisions with pattern-matching clauses and guards.
- `Ntry.run/3` function API with support for zero- and one-arity operations and one- and
  two-arity result handlers.
- `:halt`, `{:halt, value}`, `:retry`, and `{:retry, delay}` handler decisions, including
  per-attempt delay overrides.
- Retry context containing the current attempt, maximum attempts, previous result, and
  user-defined metadata.
- Fixed, linear, and exponential backoff strategies.
- Configurable attempt count, fixed and base delays, and maximum backoff delay.
- Infinite retry policies and uncapped backoff through the `:infinity` value.
- Reusable policies through the `:with` option, with inline options taking precedence.
- Validation of policy options and `{:error, :invalid_policy}` responses for invalid policies.
- Lazy backoff streams with resumable cursors and explicit cursor cleanup.
