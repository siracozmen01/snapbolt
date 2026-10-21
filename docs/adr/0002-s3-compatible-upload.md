# 0002. S3-compatible upload with an in-house SigV4 client

- **Status:** Accepted
- **Date:** 2026-10-21

## Context

Users bring their own storage. Cloudflare R2 is the main target: it has no egress fees and a free
tier, which suits public screenshot links. R2, AWS S3, MinIO, Backblaze B2 and others all speak the
S3 API. Snapbolt only needs four operations: `PUT`, `GET` (connection test), `DELETE` (connection
test) and request signing.

## Decision

Implement a small S3 client in `SnapboltUpload`: AWS Signature Version 4 with CryptoKit,
path-style URLs, and `URLSession`. R2 is the reference provider for documentation and testing.

## Alternatives considered

- **AWS SDK for Swift** — large dependency tree and long build times for four requests.
- **R2-specific API (Workers, Cloudflare API tokens)** — locks users into one provider.

## Consequences

- One protocol covers R2, S3, MinIO and similar providers; switching provider is a settings change.
- We own the signing code, so it must be tested against AWS's published SigV4 test vectors.
- Provider quirks (e.g. R2 ignoring ACLs, region `auto`) are documented in the README setup guide.
