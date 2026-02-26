# Action Plan

> Living document - updated every session. Shows current progress and next steps.

**Project:** My Personal Tech Blog on AWS EKS
**Start Date:** 2026-02-20
**Deadline:** ~4 weeks (mid-March 2026)
**Current Phase:** CI/CD Pipeline complete, security triage done, next: Terraform Apply (Wave 1-3)
**Last Updated:** 2026-02-26 (Session 9)

---

## Progress Overview

| Phase | Status | Target |
|-------|--------|--------|
| 1. Project Setup | Done | Week 1 |
| 2. Backend API | ~95% Done (S3 upload open) | Week 1-2 |
| 3. Frontend | ~95% Done (S3 image uploads open) | Week 1-2 |
| 4. Terraform Infrastructure | Done | Week 2 |
| 5. Kubernetes + CI/CD | ~90% Done (CI/CD pipeline written) | Week 3 |
| 6. ML Integration (Comprehend) | Not Started | Week 3-4 |
| 7. Polish + Presentation | Not Started | Week 4 |

---

## Phase 1: Project Setup (Done)

- [x] Finalize tech stack decisions
- [x] Create GitHub repository
- [x] Set up project structure (backend/, frontend/, terraform/, k8s/)
- [x] Configure ESLint + Prettier (code quality)
- [x] Configure Husky + lint-staged (pre-commit hooks)
- [x] Set up security scanning workflows (tfsec, Checkov, Trufflehog)
- [x] EditorConfig + LICENSE
- [x] Branch strategy (main + develop)
- [x] Backend skeleton (Express + TypeScript + health endpoint + 3 tests)
- [x] Frontend skeleton (Tailwind + Tabler Icons + Dark Mode)
- [x] Docker setup (Dockerfiles for backend + frontend, docker-compose.yml)
- [x] Podman als Docker-Alternative validiert

## Phase 2: Backend API (~90% Done)

- [x] PostgreSQL schema design (6 tables: users, categories, posts, tags, post_tags, comments)
- [x] Express routes: CRUD posts, comments, categories (11 endpoints)
- [x] Search + filter query params (?search, ?category, ?tag with dynamic SQL WHERE)
- [x] Auth middleware (Cognito JWT validation + dev bypass)
- [ ] S3 image upload service (pre-signed URLs)
- [x] Unit tests (31 tests: health, posts, comments, categories, auth)
- [x] Seed data (12 articles, 6 categories, 28 tags from old blog)
- [x] Admin list endpoints (GET /api/admin/posts, posts/:id, comments)

## Phase 3: Frontend (~85% Done)

- [x] Blog homepage (post list with demo data, category badges, reading time)
- [x] Single post view (Markdown rendered via marked.js + highlight.js)
- [x] Dark mode toggle (localStorage, dark default)
- [x] Mobile responsive (all pages, mobile menu)
- [x] Impressum + Datenschutz (German legal requirement)
- [x] Scroll position memory (sessionStorage)
- [x] Animations (slide-in hero, scale-up badges, fade-in cards, hover effects)
- [x] Category color system (colored badges, borders, tags, glows per category)
- [x] Visual polish (magnifying glass hover, gradient titles, glowing stat badges)
- [x] Connect to real API via Docker Compose (12 articles from PostgreSQL)
- [x] About page (personal journey, timeline, quote block, animated counters, Quick Facts)
- [x] Skills page (7 skill cards with priority labels, skill-item rows, cert split, Current Progress counters)
- [x] counter.js (Intersection Observer scroll-triggered animated counters)
- [x] Design upgrade v3 (hero gradients, alternating BGs, proficiency icons, priority labels)
- [x] Search and category filtering (search bar + category pills + debounced API filtering)
- [x] Admin dashboard overview (stat cards, recent posts/comments)
- [x] Admin post management (list, create, edit, delete with Markdown editor)
- [x] Admin comment moderation (list, approve, flag, delete with status filter)
- [ ] Admin S3 image uploads (needs EKS deployment)

## Phase 4: Terraform Infrastructure (Done)

- [x] Remote state (S3 + DynamoDB locking, bootstrap-state.sh)
- [x] Root config (versions.tf, providers.tf, backend.tf)
- [x] VPC module (public + private subnets, 2 AZs, conditional NAT GW)
- [x] Security Groups module (ALB, EKS nodes, RDS -- layered defense)
- [x] ECR module (frontend + backend repos, lifecycle policies)
- [x] S3 module (assets bucket, OAC-only access, CORS, lifecycle to IA)
- [x] Cognito module (admin pool, OAuth code flow, optional TOTP MFA)
- [x] RDS module (PostgreSQL 16, db.t3.micro, private subnets only)
- [x] EKS module (cluster, spot nodes, KMS encryption, OIDC/IRSA)
- [x] CloudFront module (CDN, ACM cert, OAC, Route 53 DNS)
- [x] Root module wiring (main.tf with Wave 1/2/3 structure)
- [x] Detailed learning-oriented comments in all 32 files
- [x] GitHub OIDC module (github-oidc: OIDC provider, IAM role, least-privilege policy)
- [x] terraform validate + terraform fmt = clean
- [ ] Bootstrap remote state (run bootstrap-state.sh)
- [ ] Wave 1 apply (VPC, SGs, ECR, S3, Cognito)
- [ ] Wave 2 apply (RDS)
- [ ] Wave 3 apply (EKS + NAT GW + CloudFront)
- [x] tfsec + Checkov CI integration (soft_fail=false, all 42 findings triaged)

## Phase 5: Kubernetes + CI/CD (~90% Done)

- [x] Kubernetes manifests (namespace, deployments, services, ingress, db-init job)
- [x] ConfigMap + Secrets (PORT, CORS, NODE_ENV, DB URL, Cognito IDs with REPLACE_ME placeholders)
- [x] Liveness + Readiness probes (HTTP /health for backend, TCP + HTTP / for frontend)
- [x] Schema.sql made idempotent (IF NOT EXISTS for safe re-runs)
- [x] DB initialization (Job + ConfigMap with embedded schema + seed SQL)
- [x] k8s/README.md deploy guide (prerequisites, placeholder replacement, troubleshooting)
- [x] GitHub Actions deploy pipeline (workflow_dispatch: test -> build -> push ECR -> deploy EKS)
- [x] OIDC authentication (github-oidc Terraform module, no AWS keys in GitHub)
- [ ] ALB Ingress controller setup (Helm chart, documented in k8s/README.md)

## Phase 6: ML Integration

- [ ] Comprehend service (detectKeyPhrases for auto-tags)
- [ ] Comprehend service (detectSentiment for comments)
- [ ] IRSA role for Comprehend access (pod-level IAM)
- [ ] Admin dashboard: ML results display

## Phase 7: Polish + Presentation

- [ ] Final README (ecokart-style with screenshots)
- [ ] Architecture diagram
- [ ] Demo data (3-5 polished articles)
- [ ] Presentation slides (20-30 min)
- [ ] Cost documentation

---

## Wave Deployment Strategy (Terraform)

| Wave | What | Monthly Cost | Status |
|------|------|-------------|--------|
| **0** | Bootstrap (S3 state + DynamoDB) | $0 | Ready (script written) |
| **1** | VPC, Security Groups, ECR, S3, Cognito, GitHub OIDC | ~$0.50 | Code done |
| **2** | RDS (db.t3.micro) | ~$13 (stoppable) | Code done |
| **3** | EKS + NAT GW + CloudFront | ~$126 | Code done |

After sprint: `terraform destroy -target=module.eks`, NAT GW off, RDS stop -> back to ~$0.65/month.

---

## What's Next? (Priority Order)

### Option A: Bootstrap + Wave 1 Apply (Infrastructure focus)
Run bootstrap-state.sh, then apply Wave 1 (VPC, SGs, ECR, S3, Cognito, GitHub OIDC).
Pro: Validates Terraform code against real AWS, costs almost nothing (~$0.50/month).

### Option B: Wave 2-3 Apply + First Deploy (Full deployment)
Apply RDS (Wave 2), then EKS + CloudFront (Wave 3).
Set up GitHub Secrets, run `workflow_dispatch` deploy.
Pro: Blog goes live on EKS.

### Option C: S3 Image Uploads (Frontend/Backend focus)
Add image upload support to the post editor. Requires S3 bucket to be
deployed (Wave 1) for pre-signed URL generation.

Recommended: **Option A** (Bootstrap + Wave 1) -> then B -> then C.
Reason: CI/CD pipeline is written, now validate infrastructure against real AWS.

---

## Decisions Log

| Date | Decision | Reason |
|------|----------|--------|
| 2026-02-20 | TypeScript over JavaScript | Stronger portfolio, better IDE support |
| 2026-02-20 | Tailwind over Bootstrap | More design freedom, modern look |
| 2026-02-20 | Tabler Icons | No standard icons, 4900+ modern icons |
| 2026-02-20 | Dark Mode default | Tech blog standard, wow factor |
| 2026-02-20 | Terraform from scratch | Shows deeper understanding vs copying |
| 2026-02-20 | OIDC for CI/CD | No long-lived credentials, best practice |
| 2026-02-20 | Markdown in DB | Dev-friendly, portable, simple |
| 2026-02-20 | S3 + CloudFront for images | Professional, scalable, shows S3 integration |
| 2026-02-20 | Husky pre-commit hooks | Security from day 1, prevents secret leaks |
| 2026-02-20 | 3 docs only | README + ACTION_PLAN + LESSONS_LEARNED, nothing else |
| 2026-02-21 | Relative paths | All HTML uses `./` paths for file:// dev compatibility |
| 2026-02-21 | marked.js + highlight.js | Client-side Markdown rendering, no SSR needed |
| 2026-02-21 | Impressum + Datenschutz | German legal pages added from day 1 |
| 2026-02-21 | Podman over Docker | Validated as Docker alternative on dev machine |
| 2026-02-21 | Category color system | Each category gets unique badge, border, glow, and gradient colors |
| 2026-02-21 | podman cp hot-reload | Copy files into running containers for instant feedback |
| 2026-02-22 | Animated counters via Intersection Observer | Scroll-triggered number animation, no dependencies |
| 2026-02-22 | Priority labels on skill cards | CRITICAL, HIGH DEMAND, GROWING, SUPPORTING for recruiter scanning |
| 2026-02-22 | Cert split: Earned vs Roadmap | Separates achievements from goals, clearer hierarchy |
| 2026-02-23 | Server-side filtering via query params | Portfolio-worthy: demonstrates SQL query building, scales properly |
| 2026-02-23 | Debounced search (300ms) | Prevents API hammering, smooth UX while typing |
| 2026-02-23 | Wave-based Terraform deployment | Apply in stages to control costs: free -> $13 -> $126/month |
| 2026-02-23 | Spot instances for EKS | t3.medium + t3a.medium, ~70% cheaper than on-demand |
| 2026-02-23 | Conditional NAT Gateway | $35/month toggle via variable, off in Wave 1-2 |
| 2026-02-23 | OAC over OAI for CloudFront | Newer, more secure S3 access pattern (SigV4 signing) |
| 2026-02-23 | IRSA for pod-level IAM | Fine-grained permissions per pod, not per node |
| 2026-02-23 | Detailed Terraform comments | Learning-oriented code for better understanding |
| 2026-02-24 | Side-by-side Markdown editor | Write left, preview right, stacks on mobile -- best UX for content creation |
| 2026-02-24 | Tailwind classes over custom CSS | Tailwind CDN overrides custom CSS classes -- use utility classes directly on elements |
| 2026-02-24 | Admin endpoints separate from public | GET /api/admin/posts returns all statuses, GET /api/posts only published |
| 2026-02-24 | Backend Service named "backend" | Matches nginx proxy_pass http://backend:3000 -- zero code changes needed |
| 2026-02-24 | ALB target-type: ip | More efficient than NodePort, VPC CNI routes directly to pod IPs |
| 2026-02-24 | All traffic through frontend nginx | ALB -> nginx -> /api/* proxy to backend (mirrors docker-compose) |
| 2026-02-24 | DB init via K8s Job | postgres:16-alpine runs psql against RDS, idempotent schema + seed |
| 2026-02-24 | Numbered K8s file prefixes | 00- to 09- for self-documenting apply order |
| 2026-02-24 | workflow_dispatch only | Manual deploy trigger, nothing deploys automatically |
| 2026-02-24 | OIDC federation (no keys) | Short-lived credentials, no secrets rotation needed |
| 2026-02-24 | Separate github-oidc module | Different from EKS OIDC (IRSA), belongs in Wave 1 (free) |
| 2026-02-24 | sha-<hash> + latest tags | Traceability to exact commit, ECR lifecycle matches sha-* prefix |
| 2026-02-24 | kubectl create secret --dry-run | Real values from GitHub Secrets, never hardcoded in manifests |
| 2026-02-24 | DB init job NOT in workflow | One-time manual step, not every deploy |
| 2026-02-26 | Checkov triage: 3 fix, 39 suppress, 0 defer | Every finding explicitly answered with inline skip comments |
| 2026-02-26 | security-scan.yml soft_fail=false | Strict PR guardrail after triage, new findings block PRs |
