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

## #5 - Relative Paths for Local Development

**Date:** 2026-02-21
**Phase:** Frontend

**Context:**
The frontend HTML files used absolute paths (`/js/app.js`, `/css/styles.css`). This works perfectly when served by nginx or any web server. But when opening the files directly via `file://` protocol in a browser (for quick local testing without Docker), absolute paths resolve to the filesystem root - so nothing loads.

**Decision:**
Changed all paths to relative (`./js/app.js`, `./css/styles.css`, `./index.html`). This works with both `file://` and web servers. Navigation links also changed from `href="/"` to `href="./index.html"`.

**Takeaway:**
During development, you want the fastest feedback loop possible. Being able to just double-click an HTML file and see it work is valuable. Relative paths cost nothing but enable this workflow.

---

## #6 - Test Before Commit, Ask Before Removing

**Date:** 2026-02-21
**Phase:** Frontend

**Context:**
During the Markdown rendering implementation, LinkedIn links were removed from footer sections across multiple pages without being asked. The intent was to "clean up" placeholder links, but this removed working functionality that was already correct.

**Decision:**
Two rules established:
1. **Always test changes in the browser before committing** - visual verification catches issues that code review misses
2. **Never remove existing functionality without asking first** - if something seems wrong or temporary, ask whether to fix it or remove it

**Takeaway:**
Removing code feels productive but can destroy working features. The safer default is always to ask: "Should we fix this or remove it?" A quick question saves a multi-file fix later.

---

## #7 - lint-staged and Monorepo Tool Resolution

**Date:** 2026-02-21
**Phase:** Project Setup

**Context:**
lint-staged in the root `package.json` ran `prettier --write` for frontend HTML/CSS files. But Prettier was installed in `backend/node_modules/`, not at the root level. lint-staged could not find the `prettier` binary and failed with ENOENT.

**Decision:**
Changed the lint-staged command from `"prettier --write"` to `"npx --prefix backend prettier --write"`. This tells npx to look for Prettier in the backend directory where it is actually installed.

**Takeaway:**
In a monorepo with tools installed in subdirectories, lint-staged commands at the root level need explicit paths to find the right binaries. `npx --prefix <dir>` is the clean solution.

---

## #8 - Hot-Reload with podman cp

**Date:** 2026-02-21
**Phase:** Frontend

**Context:**
During visual development (hover effects, colors, animations), rebuilding the entire Docker image for every CSS or JS change was painfully slow. Each rebuild took 30+ seconds, killing the feedback loop for iterative design work.

**Decision:**
Used `podman cp` to copy individual files directly into the running container:
```bash
podman cp frontend/src/css/styles.css container_name:/usr/share/nginx/html/css/styles.css
podman exec container_name nginx -s reload
```
Changes are visible after a browser hard-reload - no rebuild, no restart. When satisfied with the result, commit the source files normally.

**Takeaway:**
For visual iteration (CSS, JS, HTML), copy files into running containers instead of rebuilding. Save full rebuilds for structural changes (Dockerfile, dependencies, config). The fastest feedback loop wins during design work.

---

## #9 - Content Ownership: Never Assume, Always Ask

**Date:** 2026-02-22
**Phase:** Frontend

**Context:**
While building the Skills page "Certification Roadmap" section, a "CKA or Security+" card was added as a placeholder for future certifications. This was entirely fabricated -- the user had never mentioned these specific certifications as goals. When confronted, it turned out the actual next step was a Berufsspezialist IHK certification in a completely different direction.

**Decision:**
Two rules established:
1. **Never add content about the user's career plans, certifications, or personal goals without explicit confirmation** -- even if it seems like a logical assumption
2. **Placeholder content must be clearly marked as TODO** -- not filled with made-up data that looks real

**Takeaway:**
A portfolio website represents a real person. Made-up content on a resume-like page is worse than a blank space. When in doubt, ask. A TODO placeholder is honest; a fabricated certification roadmap is misleading.

---

## #10 - Terraform: Write Code First, Deploy Later

**Date:** 2026-02-23
**Phase:** Terraform Infrastructure

**Context:**
EKS is expensive (~$126/month with NAT Gateway). Writing and immediately applying Terraform would mean paying for infrastructure that isn't needed yet -- the application code (admin dashboard, auth) isn't even complete.

**Decision:**
Wave-based deployment strategy: write ALL 8 Terraform modules upfront but validate them with `terraform validate` and `terraform fmt` only. Actual `terraform apply` happens in cost-controlled waves:
- Wave 1 (free): VPC, SGs, ECR, S3, Cognito (~$0.50/month)
- Wave 2: RDS (~$13/month, can be stopped)
- Wave 3: EKS + NAT GW + CloudFront (~$126/month, sprint only)

After a deployment sprint (8 hours), destroy EKS and disable NAT GW -> back to ~$0.65/month.

**Takeaway:**
Infrastructure code and infrastructure cost are separate concerns. You can write, review, and validate IaC without deploying anything. This is especially important when learning -- iterate on the code for free, deploy only when ready.

---

## #11 - Terraform: Empty filter Block for Lifecycle Rules

**Date:** 2026-02-23
**Phase:** Terraform Infrastructure

**Context:**
The S3 lifecycle rule for transitioning objects to Infrequent Access did not include a `filter` attribute. `terraform validate` returned a warning:
```
Warning: Attribute "filter" is not specified
```
Without a filter, Terraform implicitly applies the rule to all objects, but newer versions of the AWS provider require the filter to be explicit.

**Decision:**
Added an empty `filter {}` block to the lifecycle rule. An empty filter explicitly means "apply to all objects" -- same behavior, no warning.

**Takeaway:**
Always run `terraform validate` after writing code. Even valid HCL can produce warnings that indicate future breaking changes. An empty block `filter {}` is different from no block at all in Terraform's type system.

---

## #12 - Terraform: Comments as a Learning Tool

**Date:** 2026-02-23
**Phase:** Terraform Infrastructure

**Context:**
The initial Terraform modules had basic header comments but lacked detailed inline explanations. When reviewing the code, it was hard to understand *why* specific values were chosen (e.g., why `cidrsubnet("10.0.0.0/16", 8, 10)`, why `create_before_destroy`, why `signing_behavior = "always"`).

**Decision:**
Enhanced all 29 Terraform files with detailed learning-oriented comments. Each resource explains:
- What it does and why it's needed
- How it connects to other resources
- Cost implications
- Security reasoning
- Practical examples (CLI commands, URLs)

**Takeaway:**
Code comments aren't just for other developers -- they're a learning tool for yourself. Writing "why" comments forces you to understand the reasoning, not just the syntax. When revisiting infrastructure months later, these comments are invaluable. For a portfolio project, well-commented code demonstrates deep understanding, not just copy-paste skills.

---

## #13 - Auth: Dev Mode Bypass for Local Development

**Date:** 2026-02-23
**Phase:** Admin Dashboard

**Context:**
The admin dashboard needs Cognito JWT authentication in production, but Docker Compose has no Cognito instance. Without a bypass mechanism, you can't develop or test the admin UI locally at all.

**Decision:**
The `requireAuth` middleware checks if `COGNITO_USER_POOL_ID` is set. If not, it bypasses all auth checks and attaches a mock admin user to the request. The frontend `auth.js` does the same: when Cognito config is empty, `isAuthenticated()` returns true and `login()` redirects straight to the dashboard.

**Takeaway:**
Design auth with two clear modes from the start: production (real JWT validation) and dev (bypass with mock data). The switch should be based on environment variables, not code changes. This way the same codebase works everywhere -- locally, in CI tests, and on EKS -- without any modifications.

---

## #14 - Tailwind CDN Overrides Custom CSS Classes

**Date:** 2026-02-24
**Phase:** Admin Dashboard

**Context:**
The post editor's form inputs and side-by-side Markdown layout were built with custom CSS classes (`.admin-form-input`, `.admin-editor-layout` with `display: grid`). In the browser, none of the styling applied: inputs had white backgrounds in dark mode (unreadable text), and the grid layout was completely ignored -- Markdown and Preview stacked vertically with a tiny textarea.

**Root Cause:**
Tailwind CSS CDN generates styles at runtime that compete with custom CSS. The Tailwind preflight reset and utility layer override custom properties like `background`, `color`, and `display`. Custom class specificity (`.dark .admin-form-input`) was not high enough to win against Tailwind's generated output.

**Solution:**
Removed all custom CSS classes for form inputs and the editor layout. Replaced them with Tailwind utility classes directly on the HTML elements:
```html
<!-- Before: custom class, broken in dark mode -->
<input class="admin-form-input w-full" />

<!-- After: Tailwind utilities, works everywhere -->
<input class="w-full px-3 py-2 text-sm rounded-lg border border-slate-200
  dark:border-slate-600 bg-slate-50 dark:bg-slate-900
  text-slate-900 dark:text-slate-100" />
```

For the editor grid, changed from `.admin-editor-layout` with custom CSS to inline Tailwind:
```html
<div class="grid grid-cols-1 lg:grid-cols-2" style="min-height: 500px;">
```

**Takeaway:**
When using Tailwind CDN (not the build tool), custom CSS classes are unreliable for properties that Tailwind also controls. Always use Tailwind utility classes directly on elements for layout, colors, and spacing. Reserve custom CSS only for things Tailwind genuinely cannot do (complex animations, pseudo-elements, scrollbar styling). This is a CDN-specific issue -- with Tailwind's build tool, custom CSS has more predictable specificity.

---

## #15 - Checkov Findings Triage: Fix, Suppress, or Defer

**Date:** 2026-02-26
**Phase:** CI/CD Security

**Context:**
Checkov reported 42 failed checks against our Terraform code (142 passed). The initial reaction was to set `soft_fail: true` in the security-scan pipeline to unblock PRs. But leaving it on `true` indefinitely defeats the purpose of security scanning -- new real issues would slip through unnoticed.

**Decision:**
Triaged all 42 findings into three categories:
1. **Fix (3):** Real improvements that cost nothing -- `copy_tags_to_snapshot` on RDS, `abort_incomplete_multipart_upload` lifecycle rule on S3, deny-all default security group on VPC.
2. **Suppress (39):** Conscious design decisions for a dev/portfolio project. Each finding got a `#checkov:skip=CKV_XXX:reason` comment directly on the resource. Reasons include cost savings (WAF, Multi-AZ, KMS encryption), dev workflow needs (mutable ECR tags, deletion protection off), and architectural constraints (ALB controller needs Resource=*, Terraform needs broad permissions).
3. **Defer (0):** Nothing deferred -- every finding was either fixed or explicitly accepted.

After triage, `soft_fail` was set back to `false` in security-scan.yml. The pipeline is now a strict PR guardrail again: any NEW Checkov finding will block the PR.

**Takeaway:**
Security scanner findings are not bugs -- they are questions. "Did you consider this?" The answer can be "yes, fixed", "yes, accepted the risk", or "not yet, will address later". The key is to answer every question explicitly. Inline `#checkov:skip` comments are documentation: they tell future reviewers (and your future self) that the finding was seen, evaluated, and consciously accepted. A clean scan with 39 suppressions is more secure than 42 ignored warnings on `soft_fail: true`.

---

## #16 - IAM Permissions: Add All Read Permissions at Once

**Date:** 2026-02-26
**Phase:** Terraform Pipeline

**Context:**
The Terraform pipeline's `terraform plan` step kept failing with `AccessDenied` errors. Each failure revealed one missing IAM read permission (e.g., `s3:GetAccelerateConfiguration`). Fixing one permission and re-running the pipeline would reveal the next missing one. This led to 3 iterations (PRs #3, #4, #5) before the pipeline was green.

The root cause: when Terraform refreshes resource state during `plan`, it queries ALL configuration attributes from AWS -- even ones we don't use. For an S3 bucket, this means GetAccelerateConfiguration, GetBucketLogging, GetBucketNotification, etc. Each of these requires its own IAM permission.

**Decision:**
On the third iteration, instead of adding just the one failing permission, we added all remaining S3 `Get*` permissions at once (5 permissions). This broke the cycle of fix-one-fail-on-next.

**Takeaway:**
When building IAM policies for Terraform, anticipate that `terraform plan` needs ALL read permissions for every resource attribute, not just the ones you explicitly configure. For S3 alone, there are 15+ `GetBucket*` permissions. When you hit the first missing permission, add all related read permissions in one go. The alternative -- fixing them one at a time -- means one commit-push-merge-deploy cycle per missing permission. AWS doesn't offer `s3:GetBucket*` wildcards in IAM, so you must list each one explicitly.

---

## #17 - Deploy Pipeline: Dynamic Terraform Outputs for Reproducibility

**Date:** 2026-02-27
**Phase:** CI/CD

**Context:**
The deploy pipeline originally required 9 static GitHub Secrets for infrastructure values (RDS endpoint, Cognito User Pool ID, Cognito Client ID, ECR URLs, subnet IDs, ALB security group, ACM certificate ARN). After every `terraform destroy` + `terraform apply` cycle, all 9 values changed and had to be manually copied from Terraform output into GitHub Secrets. This broke the "fully reproducible" requirement -- a human had to update secrets every time.

**Decision:**
Refactored the deploy pipeline to read all infrastructure values dynamically from Terraform remote state (S3 backend). The deploy job runs `terraform init` + `terraform output -raw <key>` to fetch each value at deploy time. Only 2 GitHub Secrets remain: `AWS_ROLE_ARN` (OIDC role, protected from destroy) and `DB_PASSWORD` (user-chosen, never in Terraform state). Used `hashicorp/setup-terraform@v3` with `terraform_wrapper: false` because the wrapper adds decoration to output that breaks `-raw` mode.

**Takeaway:**
If your CI/CD pipeline depends on infrastructure values, read them from the source of truth (Terraform state) instead of copying them into a second system (GitHub Secrets). Every manual copy step is a reproducibility risk -- it adds a human to the critical path and creates drift between what's deployed and what the pipeline thinks is deployed. The rule: if Terraform manages it, Terraform should serve it.

---

## #18 - Terraform State Save Failure: Pin a Stable Version

**Date:** 2026-02-27
**Phase:** CI/CD

**Context:**
The first run of `infra-destroy.yml` successfully destroyed all Wave 1+2 resources in AWS. But after the last resource was deleted, Terraform failed to upload the updated state back to S3:
```
Error: Failed to save state
Error saving state: failed to upload state: operation error S3: PutObject,
failed to rewind transport stream for retry, request stream is not seekable
```
All infrastructure was gone, but the state file still listed the destroyed resources. This is a known bug in Terraform 1.7.0 with the S3 backend -- when the state upload needs a retry (e.g., brief network hiccup or session token nearing expiry), it fails because the request body stream cannot be rewound.

**Recovery:**
Running `terraform refresh` locally detected that the resources no longer existed and automatically removed them from state. Quick 30-second fix, but manual intervention that breaks the "fully automated" promise.

**Decision:**
Upgraded Terraform from 1.7.0 to 1.9.0 in all three workflow files (terraform.yml, infra-destroy.yml, infra-provision.yml). The `required_version = ">= 1.5"` constraint in versions.tf already allowed it. Second infra-destroy run with 1.9.0 completed cleanly.

**Takeaway:**
Pin your CI/CD tool versions to a known-stable release, not just any version that works. Terraform 1.7.0 was fine for plan/apply but had a state persistence bug that only surfaced during destroy operations with many resources. When a tool version causes a sporadic failure, upgrade rather than work around it. The fix was a one-line change in 3 files -- far cheaper than debugging state inconsistencies after every destroy cycle.

---

## #19 - tfsec GitHub API Rate Limiting

**Date:** 2026-03-06
**Phase:** CI/CD

**Context:**
The `infra-provision.yml` workflow failed at the Security Scan step. The tfsec-action step crashed with an HTTP 403 error while trying to download its binary from the GitHub Releases API. The error message referenced API rate limiting.

**Root Cause:**
GitHub's REST API limits anonymous requests to 60 per hour per IP address. The `tfsec-action` downloads its binary from GitHub Releases on every run. Without authentication, this counts against the anonymous limit. GitHub Actions runners share IP pools, so other workflows on the same runner can exhaust the limit before our workflow runs. The `terraform.yml` workflow already had `github_token` configured (from initial setup), but `security-scan.yml` and `infra-provision.yml` did not.

**Decision:**
Added `github_token: ${{ secrets.GITHUB_TOKEN }}` to the tfsec-action step in all three workflows that use it: `security-scan.yml`, `infra-provision.yml`, and `terraform.yml`. The `GITHUB_TOKEN` is automatically provided by GitHub Actions -- no new secrets needed. Authenticated requests get 5,000 requests per hour instead of 60.

**Takeaway:**
Any GitHub Action that downloads releases from the GitHub API should use `github_token` for authentication. The free tier anonymous limit (60/h) is easily exhausted on shared runners. This is a one-line fix per workflow, but without it, your pipeline becomes flaky in a way that's hard to debug -- it works fine 9 times, then randomly fails on the 10th.

---

## #20 - IAM Permissions Evolve: Add Permission Pairs

**Date:** 2026-03-06
**Phase:** Terraform Pipeline

**Context:**
After the tfsec rate limit fix (#19), `infra-provision.yml` failed with two `AccessDeniedException` errors: `cognito-idp:SetUserPoolMfaConfig` and `iam:UntagOpenIDConnectProvider`. Both had worked during the original Wave 1 test deploy. Re-applying (vs first-time create) triggers different AWS API calls -- updating an existing resource requires `Untag` + `Tag`, but creating only needs `Tag`.

**Decision:**
Added both missing permissions to `terraform-policy`. Established a rule: for every IAM action with a Get/Set or Tag/Untag pair, always include BOTH halves from the start.

**Takeaway:**
IAM policies for Terraform are not "write once, done forever". Different operation types (create vs update vs destroy) can require different permissions. When you add `Get*`, also add `Set*`. When you add `Tag*`, also add `Untag*`. These pairs cost nothing in IAM but prevent pipeline failures.

---

## #21 - Circular Dependency: OIDC Provider and IAM Policy Deadlock

**Date:** 2026-03-06
**Phase:** Terraform Pipeline

**Context:**
After adding the missing permissions (#20), the pipeline still failed -- 6 consecutive runs. The new permissions were in the Terraform code, but could never be applied. Root cause: a circular dependency.

Terraform's dependency chain: IAM Policy -> IAM Role -> OIDC Provider. The OIDC provider had pending changes (tag drift from `default_tags`, thumbprint drift). Terraform resolves the full dependency chain before applying, so it tried to modify the OIDC provider FIRST -- but modifying it required the permissions that were in the IAM policy being updated. Deadlock.

No workflow ordering or `-target` flags could break this, because Terraform always pulls in dependencies automatically. Targeting just the IAM policy resource still pulled in the IAM role, which pulled in the OIDC provider.

**Decision:**
Two-part fix:
1. `lifecycle { ignore_changes = all }` on the OIDC provider resource. This singleton persists across destroy cycles, was bootstrapped locally, and config changes are extremely rare. Terraform will never try to modify it, breaking the circular dependency.
2. **Wave 0** in `infra-provision.yml` applies only the IAM policy resources before Wave 1. This ensures new permissions are active before other resources need them.

**Takeaway:**
When a Terraform module manages its own IAM permissions (self-referential), any pending change on a resource in the dependency chain creates a deadlock. The fix: use `lifecycle { ignore_changes = all }` on resources that are bootstrapped once and rarely change. This is not a hack -- it's a conscious architectural decision that the resource is managed differently (locally bootstrapped, pipeline-immutable). Document the reasoning in the lifecycle block comment so future readers understand why.

---

## #22 - IAM Eventual Consistency: Sleep Between Policy Update and Usage

**Date:** 2026-03-06
**Phase:** Terraform Pipeline

**Context:**
The `infra-provision.yml` workflow uses a Wave 0 pre-step to apply IAM policy changes before creating infrastructure in Wave 1. After adding new permissions (`ec2:DescribeAddressesAttribute`, `kms:EnableKeyRotation`) in Wave 0, Wave 1 immediately failed with `AccessDenied` on those exact permissions. Logs showed Wave 0 Apply completed at 15:15:33 and Wave 1 Plan started at 15:15:34 -- a 1-second gap.

**Root Cause:**
AWS IAM is eventually consistent. When you update an IAM policy, the change is saved to the IAM control plane but takes 5-15 seconds to propagate to all AWS service endpoints. If Terraform calls `ec2:DescribeAddressesAttribute` within that window, the EC2 endpoint may still see the old policy without that permission.

**Decision:**
Added a `sleep 15` step between Wave 0 Apply and Wave 1 Plan. 15 seconds is generous enough for IAM propagation (AWS says "within seconds", but we add margin for safety). The sleep has a clear comment explaining why it exists.

**Takeaway:**
IAM policy changes are not instant. If your pipeline updates permissions in one step and uses them in the next, add a brief delay between the two. This is a well-documented AWS behavior (IAM eventual consistency model), but easy to miss in automated pipelines where steps execute in rapid succession. A 15-second sleep costs nothing in pipeline time but prevents flaky permission errors that are hard to debug because they only happen sometimes.

---
