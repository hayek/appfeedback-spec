# appfeedback-spec

The cross-platform contract for the [AppFeedback SDK family](https://hayek.github.io/appfeedback-docs/) (Apple · Android · Web).

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

After editing `fixtures/`, run the sync scripts to copy them into each SDK's test
resources: `scripts/sync-to-swift.sh`, `scripts/sync-to-android.sh`,
`scripts/sync-to-web.sh`.

## Versioning

The spec is versioned independently of the SDKs. Breaking changes to the wire
format bump the spec's MAJOR version and require a coordinated SDK + inbox update.

## License

MIT © Amir Hayek. See [LICENSE](./LICENSE).
