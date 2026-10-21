# Security Policy

Snapbolt handles screen contents and storage credentials, so security reports are taken seriously.

## Supported versions

Only the latest release receives security fixes.

## Reporting a vulnerability

**Do not open a public issue.** Use GitHub's private vulnerability reporting:
**Security → Report a vulnerability** on the repository page.

Please include:

- What the issue is and what an attacker could do with it
- Steps to reproduce, or a proof of concept
- Affected version and macOS version

You can expect an acknowledgement within 7 days. Once a fix is released, the report is published
as a GitHub Security Advisory with credit to the reporter unless you prefer otherwise.

## Scope

In scope: credential storage and handling, request signing, anything that could send captures or
credentials somewhere other than the user's configured bucket, and local privilege or permission
issues.

Out of scope: the security of the user's own bucket configuration (e.g. a bucket made public on
purpose).
