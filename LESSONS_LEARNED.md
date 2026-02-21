# Lessons Learned

> Fortlaufend nummeriert. Jedes Learning dokumentiert ein konkretes Problem und die Loesung.

---

## #1 - Security Scanning from Day 1

**Date:** 2026-02-20
**Phase:** Project Setup

**Context:**
In one of my earlier projects, security scanning (tfsec, Checkov, Trufflehog) was added late in development. This meant potential issues accumulated before being caught.

**Decision:**
Set up all security tools before writing the first line of application code: GitHub Actions security workflows, ESLint, Prettier, and Husky pre-commit hooks.

**Takeaway:**
Security is not a feature you add later - it's a foundation you build on. Adding it from day 1 costs almost nothing. Adding it later means fixing accumulated issues.

---

## #2 - Keep Documentation Lean

**Date:** 2026-02-20
**Phase:** Project Setup

**Context:**
In a previous project, documentation grew to 8+ separate files. Files became outdated quickly and started contradicting each other because too many places needed updating.

**Decision:**
Only 3 documentation files, each with a clear purpose:
- `README.md` - What is this project (for visitors)
- `ACTION_PLAN.md` - Current progress and next steps (updated every session)
- `LESSONS_LEARNED.md` - What I learned (this file, append-only)

**Takeaway:**
More docs does not mean better docs. Three well-maintained files beat ten stale ones.

---

## #3 - ESLint v10 Flat Config

**Date:** 2026-02-21
**Phase:** Project Setup

**Context:**
ESLint v10 was installed but the project used the old `.eslintrc.json` config format. ESLint v9+ requires the new "flat config" format (`eslint.config.mjs`). Husky pre-commit hooks caught this immediately - the commit was blocked until the config was migrated.

**Decision:**
Migrated to flat config with `typescript-eslint` (unified package) instead of the old `@typescript-eslint/parser` + `@typescript-eslint/eslint-plugin` combo.

**Takeaway:**
Always check the major version of your tools. ESLint v8 -> v9/v10 was a breaking change in config format. Pre-commit hooks caught this before it reached the repo - exactly what they're designed for.

---

## #4 - Separate App from Server for Testability

**Date:** 2026-02-21
**Phase:** Project Setup

**Context:**
When Jest imported `server.ts` to test the API, it also started the HTTP server (`app.listen`). This caused Jest to hang after tests completed because the server kept the process alive.

**Decision:**
Split into two files: `app.ts` (Express configuration + routes) and `server.ts` (starts the HTTP server). Tests import `app.ts`, the Docker container runs `server.ts`.

**Takeaway:**
Separate "what your app does" from "how it starts". This is a common pattern in Express/Node.js projects that makes testing cleaner.

---
