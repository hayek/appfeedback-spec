# appfeedback-spec

The cross-platform contract for the AppFeedback SDK family (Apple · Android · Web).

Every SDK is a write-only client that creates a GitHub issue in a byte-exact
body format which the AppFeedback inbox parses back. This repo is the single
source of truth for that format so the platform implementations cannot drift.

## Contents

- [`wire-format.md`](./wire-format.md) — the GitHub issue body + labels contract.
- [`relay-contract.md`](./relay-contract.md) — the browser ⇄ relay HTTP contract for the Web SDK.
- [`fixtures/`](./fixtures) — language-neutral golden fixtures (a `{ "version": 1, "cases": [...] }` envelope):
  - `format-cases.json` — `report` + `deviceInfo` + `uploaded` → exact expected body bytes.
  - `parse-cases.json` — issue body → expected parsed fields.

## How it is used

Each platform SDK vendors these fixtures into its test target and runs them as a
**blocking CI gate**. Any change to the wire format MUST add or update a fixture
here first. The Swift SDK at `../AppFeedbackSDK` is the reference implementation.

Run `scripts/sync-to-swift.sh` after editing `fixtures/` to copy them into the
Swift SDK's test resources.

## Versioning

The spec is versioned independently of the SDKs. Breaking changes to the wire
format bump the spec's MAJOR version and require a coordinated SDK + inbox update.
