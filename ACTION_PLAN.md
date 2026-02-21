# Action Plan

> Living document - updated every session. Shows current progress and next steps.

**Project:** My Personal Tech Blog on AWS EKS
**Start Date:** 2026-02-20
**Deadline:** ~4 weeks (mid-March 2026)
**Current Phase:** Backend API + Frontend
**Last Updated:** 2026-02-21 (Session 3)

---

## Progress Overview

| Phase | Status | Target |
|-------|--------|--------|
| 1. Project Setup | Done | Week 1 |
| 2. Backend API | In Progress | Week 1-2 |
| 3. Frontend | In Progress | Week 1-2 |
| 4. Terraform Infrastructure | Not Started | Week 2-3 |
| 5. Kubernetes + CI/CD | Not Started | Week 3 |
| 6. ML Integration (Comprehend) | Not Started | Week 3-4 |
| 7. Polish + Presentation | Not Started | Week 4 |

---

## Phase 1: Project Setup (Current)

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

## Phase 2: Backend API

- [x] PostgreSQL schema design (6 tables: users, categories, posts, tags, post_tags, comments)
- [x] Express routes: CRUD posts, comments, categories (11 endpoints)
- [ ] Auth middleware (Cognito JWT validation)
- [ ] S3 image upload service
- [x] Unit tests (19 tests: health, posts, comments, categories)
- [x] Seed data (12 articles, 6 categories, 28 tags from old blog)

## Phase 3: Frontend

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
- [ ] About page (personal journey timeline)
- [ ] Admin dashboard (post editor, comment moderation)
- [ ] Search and category filtering

## Phase 4: Terraform Infrastructure

- [ ] VPC module (public + private subnets, 2 AZs)
- [ ] EKS module (cluster + node group)
- [ ] RDS module (PostgreSQL db.t3.micro)
- [ ] ECR module (frontend + backend repos)
- [ ] Cognito module (user pool + admin group)
- [ ] CloudFront module (CDN)
- [ ] S3 module (blog assets)
- [ ] Security Groups module
- [ ] Remote state (S3 + DynamoDB locking)

## Phase 5: Kubernetes + CI/CD

- [ ] Kubernetes manifests (deployments, services, ingress, HPA)
- [ ] GitHub Actions pipeline (test -> build -> push ECR -> deploy EKS)
- [ ] OIDC authentication (no AWS keys)
- [ ] ConfigMap + Secrets
- [ ] Liveness + Readiness probes

## Phase 6: ML Integration

- [ ] Comprehend service (detectKeyPhrases for auto-tags)
- [ ] Comprehend service (detectSentiment for comments)
- [ ] Admin dashboard: ML results display

## Phase 7: Polish + Presentation

- [ ] Final README (ecokart-style with screenshots)
- [ ] Architecture diagram
- [ ] Demo data (3-5 polished articles)
- [ ] Presentation slides (20-30 min)
- [ ] Cost documentation

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
