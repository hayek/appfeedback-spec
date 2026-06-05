# AppFeedback relay contract (Web)

A browser cannot safely hold a writable GitHub token, so the Web SDK never calls
GitHub directly in production. It POSTs a feedback submission to an
**adopter-operated relay** that holds the GitHub credential server-side, creates
the issue, and returns its number. This document is the contract between the Web
SDK and any relay implementation (Cloudflare/Vercel/Netlify, Firebase, Appwrite,
or a custom backend).

## Endpoint

The adopter configures a single absolute URL. The SDK issues:

`POST <relayEndpoint>`  ·  `Content-Type: application/json`

## Request body

```json
{
  "type": "bug | feature-request",
  "title": "string (issue title)",
  "description": "string",
  "contactEmail": "string | null",
  "extraFields": { "key": "value" },
  "deviceInfo": {
    "appName": "string",
    "appVersion": "string",
    "buildNumber": "string",
    "model": "string",
    "osName": "Web | Windows | Linux | ChromeOS | ...",
    "osVersion": "string"
  },
  "attachments": [
    { "filename": "string", "mimeType": "string", "dataBase64": "string" }
  ],
  "captchaToken": "string | null"
}
```

`attachments` and `extraFields` may be omitted/empty. `captchaToken` carries a
bot-mitigation token (e.g. Cloudflare Turnstile / hCaptcha) when the relay
requires one.

## Response

`200 OK`:

```json
{ "issueNumber": 123, "issueUrl": "https://github.com/owner/repo/issues/123" }
```

Error responses use the matching HTTP status and a JSON `{ "error": "string" }`
body:

| Status | Meaning |
|--------|---------|
| `400` | malformed/invalid submission |
| `401` / `403` | missing/failed CAPTCHA or auth |
| `413` | payload too large |
| `429` | rate-limited |
| `502` | GitHub upstream error |

## Relay responsibilities

The relay — not the browser — performs privileged work and owns final body
assembly per `wire-format.md`:

1. Verify the CAPTCHA token (if configured).
2. Enforce per-IP and global rate limits, payload caps, and basic dedupe.
3. Optionally upload each attachment to the repo's `feedback-attachments` branch
   (GitHub contents API; use the Git blobs API or an external store for large
   files) and collect the resulting URLs.
4. Format the issue body and labels from the structured fields + uploaded URLs.
5. Create the issue with a server-held credential (GitHub App installation token
   recommended; a fine-grained PAT scoped to Issues+Contents on one repo is the
   simplest setup). The credential lives only in the relay's environment.
6. Return `{ issueNumber, issueUrl }`.
