# Contributing to AppFeedback (wire-format spec)

Thanks for helping improve AppFeedback! This repository is the **source of
truth** for the cross-platform wire format: the specification prose plus the
golden fixtures every SDK is tested against.

## What's here

- The wire-format specification.
- `fixtures/*.json` — golden fixtures shared by all SDKs.
- `scripts/sync-to-{swift,android,web}.sh` — copy fixtures into each SDK repo.

There is no build step. Changes are made by editing the spec and its fixtures.

## The golden rule

The Swift, Android, and Web SDKs must all encode and decode byte-for-byte
identical payloads. The fixtures here define that contract.

**This repo changes first.** Any wire-format change starts here — update the
spec prose and the golden fixtures together, then propagate. Never edit a
fixture in an SDK repo just to make a test pass; that silently breaks the
other platforms. If an SDK disagrees with a fixture, either the SDK is wrong,
or the fixture is — fix it here and re-sync, deliberately.

## Workflow

1. Edit the spec and the relevant `fixtures/*.json`.
2. Run the sync scripts to push the fixtures into the SDK repos:

   ```sh
   scripts/sync-to-swift.sh
   scripts/sync-to-android.sh
   scripts/sync-to-web.sh
   ```

3. Open coordinated PRs in the affected SDK repos so their conformance tests
   pass against the new fixtures.
4. Note the change in `CHANGELOG.md` under `[Unreleased]`.

## Questions

See the docs at <https://hayek.github.io/appfeedback-docs/>. For security
issues, follow [SECURITY.md](SECURITY.md) — do not open a public issue.
