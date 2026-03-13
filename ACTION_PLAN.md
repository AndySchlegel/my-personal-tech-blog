# Action Plan

> Living document - updated every session. Shows current progress and next steps.

**Project:** My Personal Tech Blog on AWS EKS
**Start Date:** 2026-02-20
**Deadline:** ~4 weeks (mid-March 2026)
**Current Phase:** Session 29 complete (Blog post titles, GitHub Foundations badge, footer bilingual, reading progress bar, view counts)
**Last Updated:** 2026-03-13 (Session 29)

---

## Progress Overview

| Phase | Status | Target |
|-------|--------|--------|
| 1. Project Setup | Done | Week 1 |
| 2. Backend API | Done | Week 1-2 |
| 3. Frontend | Done (about photo fixed, CV dropped) | Week 1-2 |
| 4. Terraform Infrastructure | Done | Week 2 |
| 5. Kubernetes + CI/CD | Done (first deploy verified, full repro cycle tested) | Week 3 |
| 6. Blog Content + Seed Script | Done | Week 3 |
| 7. ML Integration (Comprehend) | Done (IRSA, auto-tags, sentiment, auto-moderation) | Week 3-4 |
| 8. Polish + Presentation | Done (README, screenshots, status badges, Grafana/Prometheus, HPA demo) | Week 4 |
| 9. Lightsail Permanent Hosting | Planned | Post-course |

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

## Phase 2: Backend API (Done)

- [x] PostgreSQL schema design (6 tables: users, categories, posts, tags, post_tags, comments)
- [x] Express routes: CRUD posts, comments, categories (11 endpoints)
- [x] Search + filter query params (?search, ?category, ?tag with dynamic SQL WHERE)
- [x] Auth middleware (Cognito JWT validation + dev bypass)
- [x] Telegram bot notification service (native fetch, non-blocking, @my_tech_blog_bot)
- [x] Unit tests (31 tests: health, posts, comments, categories, auth)
- [x] Seed data (11 articles, 7 categories, 32 tags -- real content from blog project)
- [x] Admin list endpoints (GET /api/admin/posts, posts/:id, comments)

## Phase 3: Frontend (Done)

- [x] Blog homepage (post list with demo data, category badges, reading time)
- [x] Single post view (Markdown rendered via marked.js + highlight.js)
- [x] Dark mode toggle (localStorage, dark default)
- [x] Mobile responsive (all pages, mobile menu)
- [x] Impressum + Datenschutz (German legal requirement, real data)
- [x] Scroll position memory (sessionStorage)
- [x] Animations (slide-in hero, scale-up badges, fade-in cards, hover effects)
- [x] Category color system (colored badges, borders, tags, glows per category)
- [x] Visual polish (magnifying glass hover, gradient titles, glowing stat badges)
- [x] Connect to real API via Docker Compose (11 articles from PostgreSQL)
- [x] About page ("Sales DNA meets Cloud Architecture" -- titled story, Roadmap timeline, animated counters)
- [x] Skills page (8 skill cards, badge labels, Credly cert images, project highlights with LIVE badges)
- [x] counter.js (Intersection Observer scroll-triggered animated counters)
- [x] Design upgrade v3 (hero gradients, alternating BGs, proficiency icons, priority labels)
- [x] Search and category filtering (search bar + category pills + debounced API filtering)
- [x] Admin dashboard overview (stat cards, recent posts/comments)
- [x] Admin post management (list, create, edit, delete with Markdown editor)
- [x] Admin comment moderation (list, approve, flag, delete with status filter)
- [x] Frontend overhaul: LP, About, Skills, Blog consistency (PR #37, Sessions 16-19)
- [x] External admin config for Cognito values (EKS-ready, config.js + ConfigMap)
- [x] German locale: date format, search placeholder, section headers
- [x] Nav consistency across all 7 HTML pages
- [x] Like button with CSS heart animation
- [x] Comment section on blog posts
- [x] Haftungsausschluss standalone page (8 sections, DSGVO-compliant)
- [x] Datenschutz 15-section DSGVO rewrite
- [x] Footer links updated across all pages (Haftungsausschluss separated from Impressum)
- [x] Scroll-reveal animations on all sections below the fold
- [x] Blog content sync (K3s -> Lightsail dual-track across all posts)
- [x] About page photo decision (object-position: 70% 20%, no crop)

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
- [x] Bootstrap remote state (S3 bucket + DynamoDB table)
- [x] Wave 1 apply locally (44 resources: VPC, SGs, ECR, S3, Cognito, OIDC)
- [x] Wave 1 pipeline test (validate + plan green after 3 IAM permission iterations)
- [x] Wave 1 destroyed (test complete, no running costs)
- [x] Wave 1 re-apply (infra-provision.yml, green)
- [x] Wave 2 apply (RDS, infra-provision.yml, green)
- [x] Wave 3 apply (EKS + NAT GW + CloudFront, infra-provision.yml with checkbox, green)
- [x] tfsec + Checkov CI integration (soft_fail=false, all 42 findings triaged)

## Phase 5: Kubernetes + CI/CD (Done)

- [x] Kubernetes manifests (namespace, deployments, services, ingress, db-init job)
- [x] ConfigMap + Secrets (PORT, CORS, NODE_ENV, DB URL, Cognito IDs with REPLACE_ME placeholders)
- [x] Liveness + Readiness probes (HTTP /health for backend, TCP + HTTP / for frontend)
- [x] Schema.sql made idempotent (IF NOT EXISTS for safe re-runs)
- [x] DB initialization (Job + ConfigMap with embedded schema + seed SQL)
- [x] k8s/README.md deploy guide (prerequisites, placeholder replacement, troubleshooting)
- [x] GitHub Actions deploy pipeline (workflow_dispatch: test -> build -> push ECR -> deploy EKS)
- [x] OIDC authentication (github-oidc Terraform module, no AWS keys in GitHub)
- [x] Deploy pipeline reads infra values dynamically from Terraform state (PR #8)
- [x] Infrastructure lifecycle workflows: infra-destroy.yml + infra-provision.yml (PR #10)
- [x] First successful EKS deploy (Session 14, blog live at blog.aws.his4irness23.de)
- [x] SSL fix for RDS connections (NODE_ENV toggle, PR #37)
- [x] ALB orphan cleanup in destroy workflow (PR #36)
- [x] Dual ACM certs (us-east-1 for CloudFront, eu-central-1 for ALB, PR #31)
- [x] Full destroy+rebuild+deploy cycle verified (Session 15)
- [x] ConfigMap dates synced with seed.sql (11 posts, Feb 14 - Mar 12)
- [x] Cognito callback URL fix (PR #39/#40)
- [x] Admin auth verified on EKS (Cognito Hosted UI login/logout working)
- [x] Full destroy + deploy lifecycle verified and reproducible
- [x] Teardown verified clean (~13 min, no orphaned ALBs/ENIs/VPCs)

## Phase 6: Blog Content + Seed Script (Done)

- [x] Convert 11 German Markdown posts from project-blog-content into SQL seed script
- [x] Add 7th category "Career & Learning" with teal color system (CSS + JS)
- [x] 32 tags, 53 post-tag links, sequence resets for reproducibility
- [x] Local SQL validation against PostgreSQL 16 Alpine container
- [x] Category slug mismatch fix (DB slugs aligned to frontend JS keys)
- [x] Integrated into k8s/08-db-init-configmap.yaml (schema + seed in one ConfigMap)
- [x] Post 12 reserved as live proof-of-concept via admin dashboard
- [x] Fix tfsec GitHub API rate limiting (github_token in all 3 workflows, PR #15)
- [x] Fix IAM permissions: SetUserPoolMfaConfig + UntagOpenIDConnectProvider (PR #16)
- [x] Fix circular OIDC/IAM dependency: ignore_changes=all + Wave 0 (PRs #17-#20)
- [x] Destroy+rebuild cycle verified (destroy green, provision green)
- [x] Fix IAM eventual consistency: 15s sleep between Wave 0 and Wave 1 (PR #25)
- [x] Wave 3 deployed via infra-provision.yml with optional checkbox (PR #23-#25)

## Phase 7: ML Integration (Done)

- [x] Comprehend service (detectKeyPhrases for auto-tags)
- [x] Comprehend service (detectSentiment for comments)
- [x] IRSA role for Comprehend access (pod-level IAM)
- [x] Admin dashboard: ML results display
- [x] Auto-moderation: NEGATIVE comments >= 70% confidence auto-flagged
- [x] Sentiment overview bar + legend on admin dashboard
- [x] Sentiment badges on comment moderation page

## Phase 8: Polish + Presentation (Done)

- [x] Frontend overhaul: LP, About, Skills, Blog pages (consistency, German locale, real data)
- [x] Credly certification badge images
- [x] External admin config (Cognito values via ConfigMap, EKS-ready)
- [x] Engagement features: like button, comment section, blog card animations
- [x] Legal pages: Impressum lean, Datenschutz DSGVO rewrite, Haftungsausschluss standalone
- [x] Telegram bot for comment notifications (PR #42)
- [x] Blog content sync: 7 posts refined, K3s -> Lightsail across all posts
- [x] Final README with screenshots
- [x] Cost documentation
- [x] Automated status badges (EKS + Lightsail health check workflows)
- [x] 8 screenshots selected, renamed, optimized, and embedded in README
- [x] Documentation consistency pass (README, ACTION_PLAN, LESSONS_LEARNED)
- [ ] Architecture diagram (visual, not ASCII)
- [ ] Presentation slides (20-30 min)
- [x] Grafana + Prometheus dashboards on EKS (Helm) -- Session 26
- [x] Amazon Translate bilingual DE/EN (all 8 pages + blog posts via API) -- Session 27-28
- [x] Amazon Polly text-to-speech with playback speed controls (0.5x-2x) -- Session 28
- [x] Legal pages updated for Translate, Polly, Prometheus/Grafana (Datenschutz + Haftungsausschluss) -- Session 28
- [x] Status badge workflows changed to manual-only (no more 5-min failure emails) -- Session 28
- [x] Blog post titles refined (all 11 posts, storytelling style, no colons) -- Session 29
- [x] GitHub Foundations badge on index.html + skills.html -- Session 29
- [x] Project card consistency across index.html and skills.html -- Session 29
- [x] Footer bilingual (data-de/data-en) on all pages -- Session 29
- [x] DE/EN toggle animation matching dark mode toggle -- Session 29
- [x] Professional photo on blog.html quote block -- Session 29
- [x] Reading progress bar on post pages -- Session 29
- [x] View count display on blog overview cards -- Session 29
- [x] Post 11 content updated with Translate + Polly references -- Session 29

## Phase 9: Lightsail Permanent Hosting (Planned)

- [ ] Terraform config for Lightsail instance ($5/month, 1GB RAM, 1 vCPU)
- [ ] PostgreSQL on-instance (no RDS needed)
- [ ] nginx + Node.js setup (same app, no containers needed)
- [ ] Let's Encrypt SSL (certbot)
- [ ] GitHub Actions deploy workflow (deploy-lightsail.yml)
- [ ] Cognito + Comprehend stay as managed AWS services
- [ ] DNS cutover from EKS ALB to Lightsail instance

---

## Wave Deployment Strategy (Terraform)

| Wave | What | Monthly Cost | Status |
|------|------|-------------|--------|
| **0** | Bootstrap (S3 state + DynamoDB) | $0 | Done |
| **0** | IAM policies (pre-step in provision) | $0 | Applied (ensures permissions before Wave 1) |
| **1** | VPC, Security Groups, ECR, S3, Cognito, GitHub OIDC | ~$0.50 | Destroy+rebuild verified |
| **2** | RDS (db.t3.micro) | ~$13 (stoppable) | Destroy+rebuild verified |
| **3** | EKS + NAT GW + CloudFront | ~$126 | Deployed (optional checkbox in provision workflow) |

After sprint: `terraform destroy -target=module.eks`, NAT GW off, RDS stop -> back to ~$0.50/month.

---

## What's Next? (Priority Order)

1. ~~Grafana + Prometheus via Helm on EKS~~ -- **Done** (Session 26)
2. ~~Deploy to EKS~~ -- **Done** (Session 26, stack live + verified)
3. ~~Amazon Translate~~ -- **Done** (Session 27-28, bilingual DE/EN on all pages)
4. ~~Amazon Polly~~ -- **Done** (Session 28, text-to-speech with speed controls)
5. **Lightsail Terraform setup** -- `terraform-lightsail/` directory + `deploy-lightsail.yml` workflow
6. **Architecture diagram** -- visual diagram for README (replace ASCII)

4 GitHub Secrets needed: `AWS_ROLE_ARN`, `DB_PASSWORD`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`. Pipeline reads all other infra values dynamically from Terraform remote state.

**Current infra state:** EKS stack live (Wave 0-3 deployed, Session 29). Full stack: Monitoring + Translate + Polly active.
**Dual-track plan:** EKS for showcase demos ($143/month sprint), Lightsail for permanent hosting ($5.50/month).

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
| 2026-02-20 | S3 + CloudFront infrastructure | Deployed as modules, prepared for future image hosting (OAC, encryption, CORS) |
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
| 2026-02-26 | Wave 1 test deploy + destroy | Validated all Terraform against real AWS, pipeline green |
| 2026-02-26 | Domain changed to aws.his4irness23.de | Route 53 zone is aws.his4irness23.de, blog at blog.aws.his4irness23.de |
| 2026-02-26 | OIDC provider is per-account, roles per-project | One provider serves blog + ecokart (different accounts though) |
| 2026-02-26 | IAM permissions: add all reads at once | Avoid iteration: add all S3 Get* permissions together, not one at a time |
| 2026-02-27 | Dynamic Terraform outputs in deploy pipeline | Pipeline reads all infra values from Terraform remote state (S3) instead of 9 static GitHub Secrets -- fully reproducible after destroy+apply with only 2 secrets |
| 2026-02-27 | Infrastructure lifecycle workflows | Two purpose-built workflows (infra-destroy + infra-provision) automate full destroy/rebuild cycle instead of 4 manual terraform.yml runs |
| 2026-02-27 | Terraform 1.7.0 -> 1.9.0 | Fix sporadic S3 state save failure (failed to rewind transport stream) during destroy operations |
| 2026-03-06 | 11 real blog posts as seed SQL | German Markdown posts from project-blog-content, stored as TEXT in PostgreSQL, rendered client-side |
| 2026-03-06 | Career & Learning category (teal) | 7th category added with full color system (badge, border, glow, gradient, filter button) |
| 2026-03-06 | Category slugs match frontend JS keys | DB slugs aligned to CATEGORY_COLORS keys (e.g., devops-ci-cd not devops) for zero-mapping lookups |
| 2026-03-06 | Post 12 = live proof-of-concept | Reserved for writing directly through admin dashboard after full deploy |
| 2026-03-06 | github_token for tfsec-action | Prevents GitHub API rate limiting (60/h anonymous -> 5000/h authenticated) |
| 2026-03-06 | IAM permission pairs (Get+Set, Tag+Untag) | Always add both halves to prevent failures on create vs update vs destroy |
| 2026-03-06 | OIDC provider ignore_changes=all | Break circular dependency: OIDC provider is singleton, bootstrapped locally, immutable from pipeline |
| 2026-03-06 | Wave 0 in infra-provision.yml | Apply IAM policies before any other resources to ensure permissions are current |
| 2026-03-06 | Destroy+rebuild cycle verified | infra-destroy (green) -> infra-provision (green) with Wave 0+1+2 |
| 2026-03-06 | Optional Wave 3 checkbox in provision workflow | Single workflow handles Wave 0-2 or Wave 0-3 based on user choice |
| 2026-03-06 | IAM propagation delay (15s sleep) | Eventual consistency: Wave 0 policy update needs time before Wave 1 uses new permissions |
| 2026-03-06 | Wave 3 destroy always runs first | Destroy workflow tries Wave 3 first (no-op if not deployed), then Wave 2, then Wave 1 |
| 2026-03-06 | Dual ACM certificates | CloudFront cert in us-east-1 (requirement), ALB cert in eu-central-1 (same region) -- two free certs for same domain |
| 2026-03-06 | ALB orphan cleanup in destroy | infra-destroy.yml + terraform.yml delete ALBs before EKS destroy (ALB Controller creates ALBs outside Terraform) |
| 2026-03-06 | NODE_ENV for SSL toggle | database.ts uses `NODE_ENV === 'production'` instead of hostname check (Podman hostname `db` broke old logic) |
| 2026-03-08 | External admin config (config.js) | Cognito values via external config file + K8s ConfigMap, not hardcoded in auth.js |
| 2026-03-08 | German locale for public pages | Date format de-DE, German section headers, search placeholder -- blog is a German portfolio |
| 2026-03-08 | Credly badge images for certs | Original Credly badge PNGs in frontend/src/img/certs/ -- visual proof of certifications |
| 2026-03-08 | Badge label system on skill cards | Small pills (AWS CERTIFIED, PRODUKTIV, HANDS-ON, LIVE) for quick scanning by recruiters |
| 2026-03-10 | Telegram over SES for notifications | SES sandbox issues from previous project (EcoKart), Telegram is instant + free + no AWS dependency |
| 2026-03-10 | Dual-track hosting (EKS + Lightsail) | EKS ($143/month) for Kubernetes showcase, Lightsail ($5.50/month) for permanent blog -- same repo, separate configs |
| 2026-03-10 | Haftungsausschluss as standalone page | Separated from Impressum (was 8 subsections embedded), now its own page with dedicated footer link |
| 2026-03-10 | CSS-only heart icon for like button | Tabler ti-heart-filled not rendering in CDN version, pure CSS heart shape works everywhere |
| 2026-03-10 | Non-blocking Telegram notifications | Fire-and-forget pattern (.catch(() => {})), notification failures never block comment creation |
| 2026-03-10 | 4 GitHub Secrets (was 2) | Added TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID to blog-secrets K8s Secret via deploy.yml |
| 2026-03-11 | Remove CloudHelden name from README | Public repo should be vendor-neutral, "cloud engineering course" sufficient |
| 2026-03-11 | Comprehend auto-tags done, S3 uploads dropped | Focus on implemented features, pre-signed URL upload not needed for blog |
| 2026-03-12 | Automated status badges (EKS + Lightsail) | GitHub Actions health check every 5 min, workflow badge shows live/offline |
| 2026-03-12 | Honest S3/CloudFront documentation | S3+CloudFront deployed as infra but traffic goes ALB->pods when EKS live |
| 2026-03-12 | CV download dropped | Blog IS the portfolio; CV stays stellenspezifisch via career-cv repo |
| 2026-03-12 | Grafana + Prometheus via Helm | kube-prometheus-stack: Prometheus, Grafana, node-exporter, kube-state-metrics. $0 extra (runs on Spot instances) |
| 2026-03-12 | Monitoring in deploy.yml | Helm install automated between ALB Controller and kubectl apply -- 100% reproducible |
| 2026-03-12 | Monitoring cleanup in destroy | Helm uninstall before EKS destroy in infra-destroy.yml + terraform.yml -- no orphaned resources |
| 2026-03-12 | HPA stresstest as live demo | busybox load-generator pod for presentation: 1->4 pods in 60s, zero packet loss |
| 2026-03-12 | Presentation content overhaul | All numbers, facts, hover effects, counter animations, umlauts fixed across 8 tabs |
| 2026-03-12 | Blog quote-style intro | andy-professional.jpg avatar + italic quote on blog.html (not skills -- factual statement, not quote) |
| 2026-03-12 | PostgreSQL over Redis for translation cache | Data rarely changes, <5ms reads, saves ~$13/month Redis cost -- "Kanonen auf Spatzen" |
| 2026-03-12 | Amazon Translate + Polly planned | DE/EN toggle (DB cache) + podcast audio (S3/CloudFront MP3). Both use IRSA pattern, Lightsail compatible |
| 2026-03-12 | Amazon Translate for blog posts | DB cache (post_translations table), ~$0.01/deploy, chunked API (5000 byte limit) |
| 2026-03-12 | Amazon Polly for text-to-speech | Neural voices (Vicki DE, Joanna EN), S3 cache, pre-signed URLs (1hr), ~$0.25/deploy |
| 2026-03-12 | Playback speed controls (0.5x-2x) | Browser playbackRate API, purple active state, appears after audio loads |
| 2026-03-12 | Status badges manual-only | Removed 5-min cron from status-eks.yml + status-lightsail.yml to stop failure email spam |
| 2026-03-12 | Legal pages for all AWS services | Datenschutz sections 8.3-8.5 (Translate, Polly, Grafana) + Haftungsausschluss AWS services section |
