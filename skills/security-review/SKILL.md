---
name: security-review
description: >-
  Dedicated data-flow security pass over a diff or a repo — deeper than the
  security dimension of /tech-review. Traces untrusted input to sinks, checks
  authn/authz, secrets, crypto, RBAC, TLS, and supply chain. Use before a
  release, when touching auth/secrets/RBAC/webhooks, or when the operator says
  "security review this".
---

# security-review — data-flow security pass

A focused security review that reasons about the code like a researcher: it **traces data flow** from
untrusted sources to dangerous sinks, rather than pattern-matching keywords. Dispatch the
`tech-reviewer` role in a security-only mode (or, for a Go operator, lean on the repo's own security
gates). Read-only.

## Step 1 — scope
Diff/branch or whole repo? Name the trust boundaries in play (API server, webhook admission, external
sinks/MQ endpoints, secret references, user-supplied CR fields).

## Step 2 — trace (the core of the pass)
For each untrusted input (CR spec fields, webhook payloads, HTTP responses, env), follow it to where
it's used and check the guard at each hop:
- **Injection / unsafe use** — command, path, template, CEL/JSONPath, SQL-ish backends.
- **AuthN/AuthZ** — SAR (`CanI`) pre-checks before privileged reads; RBAC least-privilege, no `*`
  verbs / cluster-admin; tenancy scope enforced.
- **Secrets** — only via `secretRef`; never in `spec`/`status`, logs, or events; short-lived tokens
  preferred.
- **Crypto / transport** — TLS verification on by default; no `InsecureSkipVerify` without an
  explicit, logged opt-in; no weak randomness for security-relevant values.
- **Supply chain** — image signing/SBOM/`govulncheck`/`gosec`/Trivy/pinned deps/gitleaks present and
  green.
- **Resource safety** — no unbounded `List`; deadlines on external calls; no panic path reachable from
  input.

## Step 3 — report
Findings table (ID · Sev P0–P3 · vulnerability class · data-flow `source → sink` · evidence
`path:line` · fix). Verdict: SECURE / FIX-REQUIRED / AT-RISK. Feed P0/P1 to `/write-story` and, for a
diff, note them on the PR. Save the report to `agent-context/inbox/reports/<YYYY-MM-DD>-security-<slug>.md`
and append a **REPORT** line to the INBOX.

## Do not
- Keyword-scan without tracing the flow — a real finding names source→sink.
- Report a theoretical issue you didn't verify against the code.
- Log or paste any secret you find while reviewing.
