# AppFeedback wire format

The contract between any AppFeedback SDK (writer) and the AppFeedback inbox
(reader). A submission becomes one GitHub issue: a **title**, a **body**, and a
set of **labels**.

## Labels

`[<type>, "user-submitted"]` where `<type>` is one of:

- `bug`
- `feature-request`

## Title

The submission's one-line summary, used verbatim as the GitHub issue title.

## Body

Sections are joined by a blank line (`\n\n`). Lines within the device block are
joined by single newlines (`\n`). Order is fixed:

```
<description>

---
**Device Information:**
App: <appName>
App Version: <appVersion> (<buildNumber>)
Device: <model>
<osName> Version: <osVersion>

**Contact Email:**          ← only when a non-empty contact email is supplied
<email>

**<key>:**                  ← one block per extra field, keys ordered (see below)
<value>

<!-- attachments-v1 -->     ← only when there is at least one uploaded attachment
## Attachments

<prefix>[<filename>](<url>) — <mimeType>, <size>   ← one line per attachment

<!-- /attachments-v1 -->

---
👍 Votes: 0
```

### Field rules

- **description** — free-form text, emitted verbatim at the top.
- **Device block** — always present, in the order shown.
- **osName** — must be one of the recognised names so the inbox can populate the
  OS column: `OS`, `macOS`, `iOS`, `iPadOS`, `watchOS`, `tvOS`, `visionOS`,
  `Android`, `Windows`, `Linux`, `Web`, `ChromeOS`. Non-Apple platforms use
  `Android` / `Web` / `Windows` / `Linux` / `ChromeOS`; use the generic `OS`
  only when the platform is unknown.
- **Contact Email** — emitted only when the email is non-empty.
- **Extra fields** — one `**<key>:**\n<value>` block per entry, **ordered
  ascending by Unicode scalar value (code point)** of the key. This is a hard
  rule: do not rely on a language's default string sort, which can diverge from
  code-point order for non-ASCII keys.
- **Attachments** — only when present, wrapped in the exact HTML-comment markers
  `<!-- attachments-v1 -->` … `<!-- /attachments-v1 -->`, preceded by the
  `## Attachments` header. Each line is:
  - `<prefix>` = `!` when `mimeType` starts with `image/`, otherwise empty
    (Markdown image embed vs. link).
  - separator between url and metadata is a space-padded em-dash `" — "`
    (U+2014). This exact code point is required; the parser keys on it.
  - `<size>` is the **deterministic byte count** (see below).
- **Votes footer** — the literal `👍 Votes: 0` (U+1F44D + ` Votes: 0`), byte for
  byte. Source files must be UTF-8.

### Deterministic byte-count format

Decimal (1000-based) units, to match the parser's tolerant reader:

- `bytes < 1000` → `"<bytes> B"` (integer).
- otherwise pick the largest of `KB` (1e3), `MB` (1e6), `GB` (1e9) with
  `bytes >= factor`; the value is `bytes / factor` rounded **half-up to one
  decimal place**; a trailing `.0` is dropped; a single ASCII space precedes the
  unit.
- Negative inputs clamp to `0`.
- The unit is chosen by raw magnitude (the largest factor with `bytes >= factor`);
  rounding happens *within* that unit and the result is never re-promoted, so
  `999_999` stays `"1000 KB"` rather than becoming `"1 MB"`.

Examples: `512 → "512 B"`, `1234 → "1.2 KB"`, `4096 → "4.1 KB"`,
`2_000_000 → "2 MB"`, `1_500_000 → "1.5 MB"`, `999_999 → "1000 KB"`.

## Parser resilience (reader side)

The inbox parser is deliberately tolerant of hand-written / legacy bodies:
- **Line endings are normalized**: the parser converts `\r\n` and lone `\r` to
  `\n` before parsing, so CRLF bodies (e.g. issues authored in the GitHub web UI)
  parse identically to LF bodies.
- **Per-line whitespace**: each line is trimmed of leading/trailing whitespace
  AND line-terminator characters (space, tab, VT, FF, LF, CR, LS, PS) before
  marker/field matching, so a stray control character can't hide a marker.
- `**bold**` markers around labels are ignored.
- A `**Contact Email:** foo@bar.com` inline form is accepted, as is the
  label-on-its-own-line-then-value form.
- Standalone `---` lines are stripped from the description.
- Attachment `<size>` is parsed approximately (`B`/`KB`/`MB`/`GB`, 1000-based)
  into a **64-bit** integer; a missing size yields a null size. A size token that
  is **non-finite** (`Infinity`/`NaN`) or whose value **exceeds 100 TB**
  (10^14 bytes) yields a **null** size — implementations MUST reject rather than
  trap, saturate, or wrap. A **missing OR empty** MIME field falls back to
  extension inference (so `… — , 4 KB` and `… —` both infer from the URL);
  extension inference **strips any `?query`/`#fragment`** from the URL first.
- Unknown future marker versions (e.g. `attachments-v2`) are ignored.

## Conformance

`fixtures/format-cases.json` and `fixtures/parse-cases.json` are the executable
form of this document. Implementations MUST pass both. A change here requires a
matching fixture change. Each file is a `{ "version": 1, "cases": [...] }`
envelope; `version` bumps only on a breaking change to the fixture schema.
