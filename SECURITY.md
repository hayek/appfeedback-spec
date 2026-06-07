# Security Policy

## Supported versions

AppFeedback is pre-1.0 and evolving quickly. Spec changes land on the latest
`main`; there are no maintained back-release branches yet. Always check
against the current `main` before reporting.

## Reporting a vulnerability

Please report security issues **privately** — do not open a public issue.

- Email **hayek_dev@icloud.com**, or
- Open a [GitHub private security advisory](https://github.com/hayek/appfeedback-spec/security/advisories/new).

Include the affected version/commit and a clear description of impact. We aim
to acknowledge within a few days and will coordinate a fix and disclosure
timeline with you.

## Scope

This repository defines the cross-platform wire-format specification and its
golden fixtures. In scope: specification ambiguities or fixtures that could
lead to unsafe parsing/encoding across the SDKs (for example, payloads that
cause inconsistent or unbounded decoding). Implementation bugs belong in the
individual SDK repositories.
