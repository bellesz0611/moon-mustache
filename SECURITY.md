# Security Policy

## Supported Versions

The latest published release on mooncakes.io and the current `main` branch receive active attention.

## Reporting a Vulnerability

If you believe Moon Mustache has a security-sensitive defect, please avoid opening a public issue first.

Preferred path:

1. Use GitHub private security reporting if available for the repository.
2. If that path is unavailable, contact the maintainer directly and include:
   - affected version or commit
   - reproduction details
   - expected risk and possible impact
   - whether the issue affects library rendering, CLI file flows, bundle generation, or the playground bridge

We will try to acknowledge a valid report quickly, reproduce it, assess user impact, and prepare a fix or mitigation before public disclosure.

## Scope Notes

The most sensitive areas in this repository are:

- file-backed CLI rendering paths
- bundle output path validation
- browser demo bridge interactions
- third-party fixture import and release workflows

General rendering mismatches that do not create a security impact should be reported through the standard bug-report template instead.
