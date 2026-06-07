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
- **Per-line whitespace (canonical trim set)**: every place the parser trims a
  line or a field value, it trims **exactly** the ASCII whitespace set
  `{ U+0009 (HT), U+000A (LF), U+000B (VT), U+000C (FF), U+000D (CR), U+0020
  (SPACE) }` from both ends — **and nothing else**. This is a hard
  cross-language rule: implementations MUST NOT defer to a language/runtime
  default trim (Swift `.whitespacesAndNewlines`, Kotlin `String.trim()`,
  JS `String.prototype.trim()`), because those each strip a different,
  locale/Unicode-defined superset (NBSP U+00A0, NEL U+0085, BOM U+FEFF, the
  Unicode space separators, …). Non-ASCII whitespace is therefore **preserved**
  verbatim: a value ending in a no-break space (U+00A0) keeps that trailing
  U+00A0 in all three ports. (This applies to the parse path only; the byte-exact
  output formatter is unaffected.)
- `**bold**` markers around labels are ignored.
- A `**Contact Email:** foo@bar.com` inline form is accepted, as is the
  label-on-its-own-line-then-value form.
- Standalone `---` lines are stripped from the description.
- Attachment `<size>` is parsed approximately (`B`/`KB`/`MB`/`GB`, 1000-based)
  into a **64-bit** integer; a missing size yields a null size.
  - **Numeric grammar (decimal only)**: after trimming (canonical set above), the
    size *magnitude* token MUST match the ASCII-decimal grammar
    `^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$`. Any token that does not match —
    notably non-decimal radix or hex-float forms such as `0x10`, `0b1010`,
    `0o17`, `0xAp2`, `0x1p4` — is treated as an **absent** size (the
    attachment's `sizeBytes` becomes **null**), exactly like any other
    unparseable size. Implementations MUST validate against this grammar before
    handing the token to a native number parser, because the native parsers
    disagree on non-decimal input (Swift `Double` accepts `0x10`/hex-float, JS
    `Number` accepts `0x`/`0b`/`0o`, the JVM accepts hex-float) — so relying on
    them would diverge.
  - A token that is **non-finite** (`Infinity`/`NaN`) likewise yields **null**
    (it fails the decimal grammar above), as does a value whose magnitude
    **exceeds 100 TB** (10^14 bytes). Implementations MUST reject rather than
    trap, saturate, or wrap.
- A **missing OR empty** MIME field falls back to extension inference (so
  `… — , 4 KB` and `… —` both infer from the URL); extension inference **strips
  any `?query`/`#fragment`** from the URL first, then lower-cases the last
  path segment's final extension and looks it up in this **fixed, canonical
  table** (identical across all ports — implementations MUST NOT use a
  platform type database such as `UTType`, which varies by OS):

  | extension      | MIME                       |
  | -------------- | -------------------------- |
  | `png`          | `image/png`                |
  | `jpg`, `jpeg`  | `image/jpeg`               |
  | `gif`          | `image/gif`                |
  | `heic`         | `image/heic`               |
  | `webp`         | `image/webp`               |
  | `pdf`          | `application/pdf`          |
  | `log`, `txt`, `text` | `text/plain`         |
  | `json`         | `application/json`         |
  | `xml`          | `application/xml`          |
  | `csv`          | `text/csv`                 |
  | *(anything else / no extension)* | `application/octet-stream` |

- Unknown future marker versions (e.g. `attachments-v2`) are ignored.

## Conformance

`fixtures/format-cases.json` and `fixtures/parse-cases.json` are the executable
form of this document. Implementations MUST pass both. A change here requires a
matching fixture change. Each file is a `{ "version": 1, "cases": [...] }`
envelope; `version` bumps only on a breaking change to the fixture schema.
