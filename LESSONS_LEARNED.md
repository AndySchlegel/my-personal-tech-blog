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

## #23 - EKS Managed Nodes Use a Different Security Group Than Expected

**Date:** 2026-03-06
**Phase:** EKS Deployment

**Context:**
The first deploy to EKS succeeded -- pods were running, services were up -- but the database initialization job timed out with `psql: connection to server ... timed out`. The RDS security group only allowed inbound traffic from our custom EKS nodes security group (created in the `security-groups` module). Pods should be running on EKS nodes, so the SG rule should have matched. But it didn't.

**Root Cause:**
EKS automatically creates its own "cluster security group" and attaches it to all managed node group instances. Our custom EKS nodes security group (`security_group_ids` in `vpc_config`) is applied to the EKS control plane ENIs, but NOT to the managed node group instances. So when a pod on a managed node tries to connect to RDS, the outbound traffic uses the EKS-managed cluster SG -- not our custom SG. The RDS ingress rule only referenced our custom SG, so the traffic was denied.

Two different security groups:
- **Custom SG** (from `security-groups` module): applied to EKS control plane ENIs
- **Cluster SG** (auto-created by EKS): applied to managed node group instances (where pods run)

**Decision:**
Added a cross-module security group rule in `terraform/main.tf` that allows ingress on port 5432 from the EKS-managed cluster SG to the RDS SG. Also added a new output (`cluster_security_group_id`) to the EKS module to expose this auto-created SG ID.

```hcl
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks_cluster_sg" {
  security_group_id            = module.security_groups.rds_sg_id
  referenced_security_group_id = module.eks.cluster_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
```

The rule lives in root `main.tf` (not in either module) because it connects two modules -- this is the standard Terraform pattern for cross-module references.

**Takeaway:**
EKS managed node groups do NOT use the security groups you pass to the cluster's `vpc_config`. EKS creates its own cluster security group and attaches it to all managed nodes. Any SG rules that need to allow traffic FROM pods must reference this auto-created cluster SG (available via `aws_eks_cluster.main.vpc_config[0].cluster_security_group_id`), not your custom SG. This is a well-documented AWS behavior but easy to miss because the `security_group_ids` parameter name suggests it applies to nodes. Always verify which SG is actually attached to the instances.

---

## #24 - Terraform -target Skips Root-Level Resources

**Date:** 2026-03-06
**Phase:** Terraform Pipeline

**Context:**
PR #28 added a cross-module security group rule (`aws_vpc_security_group_ingress_rule.rds_from_eks_cluster_sg`) to root `main.tf` to allow EKS pods to reach RDS. The `terraform.yml` workflow was run with `action=apply`, `wave=wave-3`. Result: "Apply complete! Resources: 0 added, 0 changed, 0 destroyed." The SG rule was never created, and the DB init job timed out again with `connection timed out`.

**Root Cause:**
Wave 3 targets were `-target=module.vpc -target=module.eks -target=module.cloudfront`. The new SG rule is a ROOT-LEVEL resource (not inside any module). Terraform's `-target` flag only includes resources that match the target or are dependencies of the target. A root-level resource that DEPENDS ON modules is not included when you target those modules -- the dependency goes the wrong direction.

**Decision:**
Added `-target=aws_vpc_security_group_ingress_rule.rds_from_eks_cluster_sg` to Wave 3 targets in all three workflows: `terraform.yml`, `infra-provision.yml`, `infra-destroy.yml`.

**Takeaway:**
When using Terraform's `-target` flag for wave deployments, root-level resources are invisible unless explicitly targeted. Module-level targeting (`-target=module.eks`) only includes resources INSIDE that module and their dependencies -- not resources that depend ON the module. Any cross-module "glue" resource in root `main.tf` must be added as its own `-target` entry. This is easy to forget because `terraform apply` without targets works fine (it sees everything).

---

## #25 - SSL Toggle: Use NODE_ENV, Not Hostname Detection

**Date:** 2026-03-07
**Phase:** Backend / Local Development

**Context:**
The backend's `database.ts` toggled SSL for PostgreSQL connections by checking if the `DATABASE_URL` contained `localhost`. In Docker Compose, the hostname is `db` (the service name), not `localhost`. So the SSL check `!process.env.DATABASE_URL.includes('localhost')` evaluated to `true`, enabling SSL for the local PostgreSQL container -- which doesn't support SSL. Result: `ECONNREFUSED` on every database connection.

**Decision:**
Changed the SSL toggle to `process.env.NODE_ENV === 'production'`. The K8s ConfigMap sets `NODE_ENV=production` for EKS, and Docker Compose does not set it (defaults to undefined). This cleanly separates production (SSL required for RDS) from local development (no SSL for container DB).

**Takeaway:**
Environment detection should use explicit environment variables, not infrastructure-specific assumptions (hostnames, ports, IPs). Hostnames change between Docker Compose (`db`), Kubernetes (`backend`), and local development (`localhost`). `NODE_ENV` is a single source of truth that works everywhere.

---

## #26 - ALB Controller Creates Resources Outside Terraform

**Date:** 2026-03-07
**Phase:** Infrastructure Teardown

**Context:**
After destroying EKS via `terraform destroy`, orphaned ALBs and their associated security groups, target groups, and listeners remained in AWS. These resources were created by the AWS Load Balancer Controller (a Kubernetes add-on) in response to Kubernetes Ingress resources -- not by Terraform. Terraform had no knowledge of them and could not destroy them.

The orphaned ALBs blocked subsequent VPC destruction (`DependencyViolation`) because ENIs from the ALB were still attached to the subnets.

**Decision:**
Added ALB cleanup steps to `infra-destroy.yml` and `terraform.yml` that run BEFORE EKS destruction: find ALBs by VPC tag, delete listeners, target groups, and finally the ALBs themselves using AWS CLI. Then wait for ENIs to release before proceeding with Terraform destroy.

**Takeaway:**
When using Kubernetes controllers that create AWS resources (ALB Controller, External DNS, etc.), those resources exist outside Terraform's state. A clean teardown must delete controller-managed resources BEFORE destroying the cluster that manages them. Otherwise you get orphaned resources that block the rest of the teardown and accumulate costs.

---

## #27 - CloudFront and ALB Need Separate ACM Certificates

**Date:** 2026-03-07
**Phase:** EKS Deployment

**Context:**
After deploying to EKS, the ALB Ingress needed an ACM certificate for HTTPS termination. The project already had an ACM certificate for CloudFront, but it was in `us-east-1` (CloudFront requirement). The ALB runs in `eu-central-1` and can only use certificates from the same region. Using the CloudFront cert ARN in the ALB Ingress annotation resulted in `certificate not found`.

**Decision:**
Created a second ACM certificate in `eu-central-1` for the ALB. Both certificates cover `blog.aws.his4irness23.de`, both are free (AWS ACM public certs have no cost), and both validate via the same Route 53 DNS record. Added the ALB cert ARN as a Terraform output so the deploy pipeline can reference it.

**Takeaway:**
CloudFront requires ACM certificates in `us-east-1` regardless of where your infrastructure runs. ALBs require certificates in the same region as the ALB. For a single domain, you need TWO certificates in different regions. This is a well-documented AWS constraint but easy to miss when you already have "a certificate" and assume it works everywhere. Both certs are free and auto-renew independently.

---

## #28 - Cognito OAuth Callback URLs Must Match Exactly

**Date:** 2026-03-08
**Phase:** EKS Deployment

**Context:**
After deploying the admin dashboard to EKS, the Cognito Hosted UI login flow failed with a `redirect_mismatch` error. The admin dashboard's `auth.js` was sending `redirect_uri` with `/admin/callback.html`, but the Terraform Cognito configuration had the callback URL set to `/admin/callback` (without the `.html` extension). Cognito validates the `redirect_uri` parameter against its configured callback URLs using exact string matching -- no pattern matching, no trailing slash normalization, no extension inference.

**Decision:**
Aligned the Terraform `callback_urls` and `logout_urls` with what `auth.js` actually sends. The client code is the source of truth for redirect URIs because it constructs the authorization URL that the browser follows to Cognito. The server-side configuration must match exactly.

**Takeaway:**
Cognito OAuth callback URL validation is an exact string match -- not a prefix match, not case-insensitive, not extension-agnostic. When debugging `redirect_mismatch` errors, always check both sides: what the client code sends as `redirect_uri` and what the identity provider has configured as allowed callbacks. A single character difference (like `.html`) is enough to break the entire login flow.

---

## #29 - Tailscale DNS Blocks External Domain Resolution

**Date:** 2026-03-08
**Phase:** EKS Deployment

**Context:**
After deploying the blog to EKS and confirming the ALB was healthy, the blog was unreachable from the local browser with `ERR_NAME_NOT_RESOLVED`. Running `dig blog.aws.his4irness23.de +short` returned empty results. The domain resolved correctly from other networks and from `dig @8.8.8.8`.

**Root Cause:**
Tailscale's "Use Tailscale DNS settings" option was enabled on macOS. This replaces the system DNS resolver with `100.100.100.100` (Tailscale's MagicDNS resolver). MagicDNS resolves Tailscale machine names and configured split DNS domains, but does NOT resolve arbitrary external domains like `blog.aws.his4irness23.de`. All external lookups silently failed.

**Decision:**
Disabled "Use Tailscale DNS settings" in the Tailscale macOS app. This restored the system's default DNS resolver (router-provided or manually configured) while keeping Tailscale connectivity for machine-to-machine traffic intact. Alternative fix: set a manual DNS server (e.g., `8.8.8.8`) in macOS network settings, which takes precedence.

**Takeaway:**
When DNS resolution fails for external domains but works when querying a public resolver directly (`dig @8.8.8.8`), the problem is your local DNS resolver. Tailscale's DNS override is a common culprit on developer machines -- it intercepts all DNS queries but only resolves Tailscale-known names. Quick diagnostic: `dig domain @8.8.8.8 +short` bypasses local DNS and confirms whether the domain exists. If that works but normal `dig` doesn't, your local resolver is the problem.

---

## #30 - Full Lifecycle Reproducibility Verified

**Date:** 2026-03-08
**Phase:** CI/CD

**Context:**
The project's core promise is full reproducibility: destroy all infrastructure, re-provision from scratch, deploy the application, and have everything working -- without manual secret updates or configuration drift. This was tested end-to-end with a complete destroy + provision + deploy + destroy cycle.

**Decision:**
The full lifecycle was verified successfully. Only 2 GitHub Secrets are needed: `AWS_ROLE_ARN` (OIDC-protected, survives destroy cycles) and `DB_PASSWORD` (user-chosen). All other infrastructure values (RDS endpoint, Cognito IDs, ECR URLs, subnet IDs, ALB security group, ACM cert ARN) are read dynamically from Terraform remote state at deploy time. Cognito users are deleted on teardown and must re-register via the Hosted UI after re-provision. The ALB cleanup step in destroy workflows prevents orphaned resources from blocking subsequent operations. Full teardown completes in approximately 13 minutes.

**Takeaway:**
Reproducibility is not a feature you claim -- it's a property you prove by running the full cycle. Each iteration uncovered edge cases (IAM eventual consistency #22, ALB orphans #26, Cognito callback mismatch #28) that only surface during destroy + recreate. A pipeline that has survived a full lifecycle test is fundamentally more trustworthy than one that has only ever applied to existing infrastructure. The 2-secret design (OIDC role + database password) is the minimum viable secret surface -- everything else is derived from infrastructure state.

---

## #31 - Telegram Bot: Native Fetch Over NPM Packages

**Date:** 2026-03-10
**Phase:** Backend

**Context:**
The blog needed notifications when new comments are posted for moderation. AWS SES was ruled out because of sandbox issues encountered in a previous project (EcoKart) -- getting production SES access required support tickets and domain verification that took days. Email notifications also feel heavy for a simple "new comment" alert.

**Decision:**
Implemented Telegram Bot notifications using Node 18+ native `fetch()` -- no npm packages needed. The service (`backend/src/services/telegram.ts`) uses a fire-and-forget pattern: `notifyNewComment(...).catch(() => {})`. If Telegram is down or env vars are missing, the comment creation still succeeds. The bot (@my_tech_blog_bot) sends HTML-formatted messages with post title, author name, and comment preview.

Two env vars (`TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`) are injected via K8s Secrets in the deploy pipeline. Locally, the backend runs without them -- notifications are silently skipped.

**Takeaway:**
For simple webhook-style notifications, evaluate lightweight alternatives before reaching for managed services. Telegram Bot API is free, instant, requires no approval process, and works with a single HTTP POST. The key architectural decision is making notifications non-blocking: a `.catch(() => {})` wrapper ensures notification failures never affect the user-facing response. This pattern works for any "nice to have" side effect -- logging, analytics, alerts.

---

## #32 - Dual-Track Hosting: Showcase vs Permanent

**Date:** 2026-03-10
**Phase:** Architecture

**Context:**
EKS costs ~$143/month with all services running. This is justified for demonstrating Kubernetes skills in job interviews, but too expensive for keeping a personal blog online permanently. The original plan mentioned "K3s migration" but lacked specifics and would still require managing a Kubernetes cluster.

**Decision:**
Dual-track hosting from a single repository:
- **EKS track** ($143/month, sprint-only): Full AWS stack with Kubernetes, ALB, RDS, CloudFront. Spun up for demos, destroyed after. Demonstrates enterprise-grade cloud skills.
- **Lightsail track** ($5.50/month, permanent): Single instance with PostgreSQL on-instance, nginx + Node.js, Let's Encrypt SSL. Same application code, no containers needed.

Both tracks share the same Git repo. Separate Terraform configs (`terraform/` for EKS, `terraform-lightsail/` for Lightsail) and separate deploy workflows. Cognito and Comprehend remain as managed AWS services on both tracks.

**Takeaway:**
Not every workload needs Kubernetes. The same application can run on a $5.50 Lightsail instance for daily use and on a $143 EKS cluster for demonstrations. The key insight: having both tracks in one repo proves that you understand when to use which tool. Kubernetes expertise is best demonstrated by knowing when NOT to use Kubernetes.

---

## #33 - CSS-Only Icon Workarounds for CDN Libraries

**Date:** 2026-03-10
**Phase:** Frontend

**Context:**
The like button needed a filled heart icon. Tabler Icons provides `ti-heart-filled`, but the CDN-served webfont version did not render this specific icon -- it showed an empty square. The icon exists in the Tabler SVG set but was missing from the webfont build included in the CDN package.

**Decision:**
Replaced the icon with a pure CSS heart shape using `::before` pseudo-element with `width`, `height`, `background`, `transform: rotate(-45deg)`, and two `border-radius` pseudo-circles. The CSS heart renders identically across all browsers without any external dependency.

**Takeaway:**
CDN-hosted icon libraries may not include every icon from the full set. Webfont builds lag behind SVG releases, and specific icons can be missing without any error message -- they simply render as invisible or empty boxes. For critical UI elements, have a CSS fallback ready. Simple shapes (hearts, arrows, checkmarks) are trivial to build in pure CSS and eliminate the external dependency entirely.

---

## #34 - Content Sync Discipline: Single Source of Truth

**Date:** 2026-03-10
**Phase:** Blog Content

**Context:**
Blog post content existed in three places: feedback Markdown files (`feedback/posts_improvements/`), the seed SQL script (`backend/src/models/seed.sql`), and the K8s ConfigMap (`k8s/08-db-init-configmap.yaml`). After multiple editing sessions, the three sources drifted apart -- titles, excerpts, and body sections no longer matched.

A comprehensive comparison revealed 7 out of 11 posts had differences between feedback files and seed SQL: changed titles, rewritten excerpts, updated section headers, and entirely new paragraphs that existed in one source but not the other.

**Decision:**
Performed a full sync across all three sources. Established the rule: seed SQL is the single source of truth for what gets deployed. Feedback files are drafts and review notes -- useful during writing but not authoritative. The ConfigMap must always be an exact copy of seed SQL.

**Takeaway:**
When content exists in multiple files, designate one as the source of truth and sync FROM it, not TO it. Content drift is invisible until you do a systematic comparison. For database-seeded content, the seed script is the canonical source because it is what actually runs in production. Draft files should be treated as input to the seed script, not as parallel truth.

---

## #35 - Amazon Comprehend: German Sarcasm and Irony Detection Limitation

> **IMPORTANT for presentation:** This is a real-world limitation worth showcasing.
> It demonstrates critical thinking about managed AI services -- knowing what they
> can and cannot do is just as valuable as knowing how to integrate them.

**Date:** 2026-03-11
**Phase:** Comprehend Integration (EKS)

**Context:**
After deploying Comprehend sentiment analysis on EKS (via IRSA), we tested it with German comments. Obvious cases worked perfectly: clear insults were flagged as NEGATIVE with high confidence, and genuine praise was detected as POSITIVE. The auto-moderation rule (NEGATIVE >= 70% -> auto-flag) caught truly hostile comments immediately.

However, the comment "Ganz schoen ueberzogen dargestellt!" was classified as **POSITIVE 100%** by Comprehend. This comment is actually critical/negative -- it means "Quite exaggerated!" or "Pretty overblown!". The word "schoen" (nice/pretty) triggered Comprehend's positive sentiment detector, even though it is used sarcastically here as an intensifier, not as a compliment.

**Root Cause:**
Amazon Comprehend uses statistical NLP models that analyze word-level signals. In German, sarcasm and irony often use positive-sounding words in a negative context. Comprehend does not understand this pragmatic layer of language -- it sees "schoen" and scores positively. This is a known limitation of bag-of-words and transformer-based sentiment models, especially for languages with rich sarcastic traditions like German.

**What Comprehend handles well:**
- Direct insults and profanity (NEGATIVE, high confidence)
- Clear praise and gratitude (POSITIVE, high confidence)
- Neutral factual statements (NEUTRAL)
- Mixed reviews with both positive and negative elements (MIXED)

**What Comprehend misses:**
- Sarcasm ("Ganz schoen ueberzogen" -> falsely POSITIVE)
- Irony ("Na toll, super gemacht" -> falsely POSITIVE)
- Understatement ("Nicht gerade ueberzeugend" -> may miss negativity)
- Cultural context and idiomatic expressions

**Decision:**
Kept Comprehend as a first-pass filter but made clear that manual moderation is still required. The auto-flag rule only catches obviously negative comments. Sarcastic or ironic comments slip through and need human review. This is documented as expected behavior, not a bug.

**Takeaway:**
Managed AI services like Comprehend are powerful for obvious cases but have blind spots with nuanced language. German sarcasm is a known weak point. Always combine automated analysis with human moderation. For a blog comment system, this is acceptable -- the admin dashboard shows sentiment badges so the moderator can quickly spot misclassifications. For safety-critical applications (hate speech detection, content policy enforcement), a single-service approach would not be sufficient.

---

## #36 - Helm-Based Observability: kube-prometheus-stack on EKS

**Date:** 2026-03-12
**Phase:** Phase 8 (Polish + Presentation)

**Context:**
Needed monitoring dashboards for the presentation and to understand cluster behavior during HPA scaling. The cluster had metrics-server for HPA but no visualization or history.

**Decision:**
Installed `kube-prometheus-stack` via Helm -- a single chart that bundles Prometheus, Grafana, node-exporter, kube-state-metrics, and Prometheus Operator. Key choices:
- Alertmanager disabled (not needed for a showcase blog)
- 7-day retention (enough for demo cycles)
- Low resource limits (~40m CPU, ~520 MiB memory total)
- Grafana password hardcoded in deploy.yml (reproducible across deploy cycles)
- No persistent volume (data resets on destroy -- acceptable for showcase)
- Integrated into all 3 CI/CD workflows: deploy.yml installs, infra-destroy.yml + terraform.yml clean up

The entire stack costs $0 extra because it runs as pods on the existing Spot instances. From 27 pre-installed dashboards, only 3 are relevant: Namespace (Pods), Node (Pods), and Networking.

**Takeaway:**
Helm is the package manager for Kubernetes -- one command installs 6 pods with 27 dashboards. The key insight is that monitoring pods run alongside application pods on the same nodes at negligible cost. For a production system you would add persistent storage and alerting, but for a showcase demo the ephemeral setup is perfect. The live HPA stresstest (busybox load-generator -> watch CPU spike -> 4 pods spawn -> zero packet loss) is worth more than any slide.

---

## #37 - HPA Live Demo: Stresstest as Presentation Wow-Moment

**Date:** 2026-03-12
**Phase:** Phase 8 (Polish + Presentation)

**Context:**
HPA (Horizontal Pod Autoscaler) was configured since Session 23 (backend 1-4 pods, frontend 1-3 pods, 70% CPU target) but never demonstrated under real load.

**Decision:**
Created a simple stresstest approach using a busybox pod that sends continuous GET /api/posts requests to the backend service. The sequence:
1. Backend CPU jumps from 1% to 249% (hitting the 250m limit)
2. HPA scales from 1 to 4 pods within 60 seconds
3. Load distributes across pods (249% -> 90% -> 65%)
4. After stopping load, 5-minute cooldown, then scale-down to 1 pod
5. Zero packets dropped throughout the entire cycle

Key finding: Frontend (nginx) will practically never scale -- it uses 0.18% CPU for static files. Thousands of concurrent visitors would be needed. Backend scales first because every API call triggers a database query.

The stresstest command is always the same regardless of destroy/deploy cycles:
```
kubectl run load-generator --namespace blog --image=busybox --restart=Never \
  -- /bin/sh -c "while true; do wget -q -O- http://backend:3000/api/posts > /dev/null 2>&1; done"
```

**Takeaway:**
A live demo beats any diagram. Watching pods spawn in real-time while Grafana shows the CPU spike is an immediate proof of auto-scaling capability. The approach is deterministic and reproducible -- same command, same result, every time. For presentations: set up Grafana beforehand (port-forward + login), then run one command live. Keep screenshots as backup in case of connectivity issues.

---

## #38 - Amazon Translate: PostgreSQL Cache Beats Redis for Low-Volume Translation

**Date:** 2026-03-12
**Phase:** Phase 8 (Polish + ML Integration)

**Context:**
Adding bilingual DE/EN support to the blog required translating 11 blog posts via Amazon Translate API. Translation results rarely change, so caching was needed.

**Decision:**
Used PostgreSQL (existing RDS) instead of adding Redis (~$13/month). Created `post_translations` table with `(post_id, language)` primary key. Each text is translated once and cached permanently. Cost: ~$0.01 per deploy cycle for 11 posts. Read latency: <5ms from the same RDS instance.

**Takeaway:**
Not every caching problem needs Redis. When data is write-once-read-many and the existing database is fast enough, adding a new service is "Kanonen auf Spatzen" (overkill). Same principle applies to Polly audio: S3 cache with pre-signed URLs, no CDN needed for low-volume audio playback.

---

## #39 - Checkov Skip Comments: Position Matters

**Date:** 2026-03-12
**Phase:** Phase 8 (CI/CD Security)

**Context:**
Needed to suppress Checkov CKV_AWS_355 (IAM wildcard Resource=*) for Comprehend/Translate/Polly APIs that don't support resource-level permissions.

**Decision:**
First attempt: placed `#checkov:skip=CKV_AWS_355:...` comment ABOVE the resource block -- Checkov didn't recognize it and kept failing. Fix: moved the skip comment INSIDE the resource block (after the opening brace), matching the pattern of all other Checkov skips in the codebase.

**Takeaway:**
Checkov skip annotations are position-sensitive. They must be inside the resource block they apply to, not above it. This is different from tfsec which uses `#tfsec:ignore` above the block. When a CI check fails after adding a skip, check the comment position before assuming the skip syntax is wrong.

---

## #40 - Deploy Pipeline: Every Terraform Output Must Be Explicitly Read

**Date:** 2026-03-12
**Phase:** Phase 8 (CI/CD)

**Context:**
Amazon Polly was configured correctly (IRSA, IAM policy, S3 bucket) but the audio button did nothing. Backend logs showed no Polly error -- it silently returned null because `S3_BUCKET_NAME` env var was empty.

**Decision:**
Root cause: deploy.yml referenced `${{ steps.tf.outputs.s3_bucket_name }}` in the kubectl secret creation, but never read the output from Terraform state. The line `echo "s3_bucket_name=$(terraform output -raw s3_bucket_name)" >> "$GITHUB_OUTPUT"` was missing. The Terraform output existed, the K8s secret referenced it, but the bridge between them was missing.

**Takeaway:**
In GitHub Actions, Terraform outputs don't auto-propagate. Each output needs an explicit `terraform output -raw` -> `GITHUB_OUTPUT` line. When a feature silently fails (returns null instead of erroring), check the env vars on the running pod first: `kubectl exec deployment/blog-backend -- printenv | grep S3`. An empty value is worse than a missing value because the code sees it as "configured but empty" rather than "not configured".

---

## #41 - CSS Animation `forwards` Fill-Mode Overrides Hover Transforms

**Date:** 2026-03-13
**Phase:** Phase 8 (Frontend Polish)

**Context:**
Cards with entrance animations using `animation: scaleUp 0.5s ease forwards` stopped responding to hover transforms like `hover:scale-110`. The hover effect worked fine on elements without the animation.

**Decision:**
Root cause: `animation-fill-mode: forwards` persists the final keyframe values after the animation completes. When `scaleUp` ends at `transform: scale(1)`, that value stays applied and takes precedence over hover pseudo-class transforms. Fix: apply the animation to a wrapper element so the animated `transform` and the hover `transform` live on different DOM nodes. Alternatively, use the `social-link` class which already handles this by separating animation and hover concerns.

**Takeaway:**
`animation-fill-mode: forwards` is a common CSS trap -- it locks the final `transform` value onto the element permanently, blocking any hover/focus transforms from taking effect. When hover stops working on animated elements, check for `forwards` first. The cleanest fix is structural: animate the wrapper, interact with the child. This avoids fighting CSS specificity altogether.

---

## #42 - Self-Hosted Grafana vs Amazon Managed Grafana

**Date:** 2026-03-13
**Phase:** Phase 8 (Monitoring)

**Context:**
AWS offers Amazon Managed Grafana (~$9/editor/month + data fees) and Amazon Managed Prometheus as fully managed observability services. The question was whether to use these managed services or self-host via Helm (kube-prometheus-stack) inside the EKS cluster.

**Decision:**
Chose self-hosted Grafana + Prometheus via Helm. Reasons: (1) Cost -- managed services add $10-20/month on top of existing EKS costs, while self-hosted runs on the existing Spot nodes at $0 extra. (2) Flexibility -- self-hosted allows any plugin, any data source (we added CloudWatch via IRSA for AWS ML metrics alongside the 27 built-in K8s dashboards). Managed Grafana restricts to pre-approved plugins only. (3) Lifecycle -- our stack is temporary (showcase), so monitoring should come and go with `helm install/uninstall`, not require separate managed service provisioning.

**Takeaway:**
Managed services shine for teams that need 24/7 HA, SSO integration, and zero maintenance. For a portfolio/showcase project on Spot instances, self-hosted is the pragmatic choice -- same Grafana, same dashboards, zero extra cost. The architecture decision itself (knowing when NOT to use a managed service) demonstrates more cloud maturity than defaulting to the AWS-managed option. This is a common interview question: "Why didn't you use the managed version?"

---

## #43 - Amazon Polly: 3000-Byte Chunk Limit

**Date:** 2026-03-14
**Phase:** Phase 8 (Presentation)

**Context:**
Amazon Polly's SynthesizeSpeech API has a hard limit of 3000 bytes per request for real-time synthesis. Blog posts easily exceed this -- a typical 800-word German article is 5000-8000 bytes. The first implementation sent the entire post text in one call and silently failed for longer posts.

**Decision:**
Implemented chunking in the Polly service: split text at sentence boundaries (`. `, `! `, `? `), accumulate chunks up to 2800 bytes (safety margin), synthesize each chunk separately, then concatenate the audio buffers before uploading to S3. The cached S3 audio is served via pre-signed URLs, so chunking only happens on first generation.

**Takeaway:**
Always check API limits before implementing integrations. Polly's 3000-byte limit is not prominently documented and the error is not descriptive. The fix (sentence-boundary chunking) is simple but you have to know about the limit first. Same pattern applies to Amazon Translate (5000-byte limit) and Comprehend (5000 UTF-8 bytes). AWS ML APIs consistently have byte limits that real-world text easily exceeds.

---
