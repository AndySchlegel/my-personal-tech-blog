# My Personal Tech Blog

> **Cloud-native tech blog on AWS EKS -- built from scratch with Terraform, Kubernetes, and CI/CD. Final project for a cloud engineering course.**

[![EKS Status](https://github.com/AndySchlegel/my-personal-tech-blog/actions/workflows/status-eks.yml/badge.svg)](https://blog.aws.his4irness23.de)
[![Lightsail Status](https://github.com/AndySchlegel/my-personal-tech-blog/actions/workflows/status-lightsail.yml/badge.svg)](https://blog.his4irness23.de)
[![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20RDS%20%7C%20Cognito%20%7C%20Comprehend%20%7C%20Translate%20%7C%20Polly-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-9%20Modules%20%7C%2025%2B%20across%20projects-blue)](https://www.terraform.io/)
[![TypeScript](https://img.shields.io/badge/TypeScript-Express.js-blue)](https://www.typescriptlang.org/)
[![Security](https://img.shields.io/badge/Security-tfsec%20%7C%20Checkov%20%7C%20Trufflehog-green)](https://github.com/AndySchlegel/my-personal-tech-blog/security)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Infrastructure](#infrastructure)
- [Screenshots](#screenshots)
- [Security](#security)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Cost Analysis](#cost-analysis)
- [Lessons Learned](#lessons-learned)
- [Project Statistics](#project-statistics)
- [Author](#author)

---

## Overview

A cloud-native tech blog built from scratch in under 4 weeks -- from Express API to production EKS deployment with full CI/CD, monitoring, and ML integration. Designed as a reproducible showcase: spin up the entire stack in ~25 minutes, demonstrate it, tear it down.

### Why This Project?

1. **Real portfolio piece** -- 12 German blog articles documenting an authentic learning journey (11 seeded + 1 added live via admin dashboard as proof-of-concept)
2. **Full AWS integration** -- EKS, RDS, Cognito, Comprehend, Translate, Polly, S3, CloudFront -- all wired together with Terraform and OIDC
3. **100% reproducible lifecycle** -- Provision, deploy, destroy, repeat. No manual secret updates, no leftover resources
4. **Monitoring built-in** -- Prometheus + Grafana on EKS with HPA auto-scaling, live-demonstrable in presentations
5. **Natural ML integration** -- Amazon Comprehend (auto-tags + sentiment), Amazon Translate (bilingual DE/EN), Amazon Polly (text-to-speech with playback speed control)
6. **Cost-conscious architecture** -- EKS for showcase demos (~$4.80/day), Lightsail ($5.50/month) planned for permanent hosting

---

## Architecture

![Architecture Diagram](docs/architecture.svg)

<details>
<summary>Text version (click to expand)</summary>

```
Route 53 (DNS: blog.aws.his4irness23.de)
    |
ALB (AWS Load Balancer Controller, managed via IRSA)
    |
EKS Cluster (eu-central-1, 2 AZs)
    |--- Frontend Pod (nginx + Tailwind CSS) -- HPA 1-3 replicas
    |--- Backend Pod (Express + TypeScript) -- HPA 1-4 replicas
    |--- Monitoring (Prometheus + Grafana, kube-prometheus-stack)
    |
    +-- Private Subnets (10.0.10.0/24, 10.0.11.0/24)
    |       |--- EKS Nodes (Spot: t3.medium + t3a.medium)
    |       |--- RDS PostgreSQL 16 (db.t3.micro)
    |
    +-- Public Subnets (10.0.1.0/24, 10.0.2.0/24)
            |--- ALB
            |--- NAT Gateway (conditional)

Managed Services (outside VPC):
    |--- Cognito (Admin JWT authentication, Hosted UI)
    |--- Amazon Comprehend (ML: auto-tags + sentiment, IRSA)
    |--- Amazon Translate (bilingual DE/EN blog content, IRSA)
    |--- Amazon Polly (text-to-speech audio, IRSA)
    |--- S3 (Polly audio cache + prepared for image hosting)
    |--- CloudFront (deployed, prepared for future CDN)
    |--- Telegram Bot API (comment notifications)

Monitoring (in-cluster, namespace: monitoring):
    |--- Prometheus (metrics collection, 7-day retention)
    |--- Grafana (dashboards, port-forward access)
    |--- kube-state-metrics + node-exporter (cluster metrics)
```

> **Traffic flow:** Route 53 -> ALB -> EKS Pods. CloudFront and S3 are deployed as Terraform modules and prepared for future image hosting (OAC, encryption, CORS configured), but all current traffic is served directly through the ALB.

</details>

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Node.js, Express, TypeScript |
| Frontend | Tailwind CSS, Tabler Icons, Devicon, nginx |
| Database | PostgreSQL 16 (RDS) |
| Content | Markdown (stored in DB, rendered in frontend) |
| Auth | AWS Cognito (OAuth 2.0 code flow, Hosted UI) |
| ML | Amazon Comprehend (key phrase extraction + sentiment analysis) |
| Translation | Amazon Translate (bilingual DE/EN with PostgreSQL cache) |
| Text-to-Speech | Amazon Polly (neural voices: Vicki DE, Joanna EN) + S3 audio cache |
| CDN/Storage | CloudFront + S3 (deployed, prepared for image hosting) |
| IaC | Terraform (9 modules, all from scratch) |
| CI/CD | GitHub Actions with OIDC (no long-lived AWS credentials) |
| Notifications | Telegram Bot API (native fetch, non-blocking) |
| Monitoring | Prometheus + Grafana (kube-prometheus-stack via Helm) |
| Container | Podman (multi-stage builds), EKS (Spot instances) |
| Security | tfsec, Checkov, Trufflehog, ESLint, Husky |

---

## Features

### Public

- Blog posts with Markdown rendering, syntax highlighting, and reading progress bar
- View count displayed on blog overview cards
- Search and category filtering (debounced, server-side SQL)
- Auto-generated tags via Amazon Comprehend
- Comment system with sentiment analysis and Telegram notifications
- Bilingual DE/EN language toggle on all pages (static HTML + Amazon Translate for blog posts)
- Text-to-speech audio playback with speed controls (0.5x - 2x) via Amazon Polly
- Like button with animated heart icon (localStorage deduplication)
- About page ("Sales DNA meets Cloud Architecture") with story sections, roadmap timeline, and quote blocks
- Skills page with badge labels (AWS CERTIFIED, PRODUKTIV, HANDS-ON, LIVE), Credly cert links, and project highlights
- Impressum, Datenschutz, and Haftungsausschluss (bilingual DE/EN legal pages, DSGVO-compliant)
- Dark mode (default) with light mode toggle
- Fully responsive (mobile-first)
- Scroll-reveal animations and hover effects on all interactive elements

### Admin Dashboard (Cognito-protected)

- Login via Cognito Hosted UI (OAuth 2.0 code flow) with dev mode bypass
- Dashboard overview with 6 stat cards (posts, published, pending, views, likes, flagged)
- Comprehend sentiment overview (visual bar + legend)
- Recent posts and comments activity feed
- Post management: create, edit, delete with side-by-side Markdown editor + live preview
- Comment moderation: approve, flag, delete with status filtering
- Auto-moderation: NEGATIVE comments (>= 70% confidence) get auto-flagged
- Telegram bot notifications for new comments
- Sidebar navigation with responsive mobile layout

### Monitoring and Observability

- Prometheus + Grafana deployed via Helm (kube-prometheus-stack)
- HPA live scaling: backend 1-4 replicas, frontend 1-3 replicas (70% CPU target)
- Grafana dashboards for cluster health, pod metrics, and node resources
- Full lifecycle integration: monitoring deploys with app, cleans up on destroy
- Zero additional cost (runs on existing EKS Spot nodes)

---

## Infrastructure

### Terraform Modules (9 modules, all written from scratch)

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| **VPC** | Network foundation | VPC, 2 public + 2 private subnets, IGW, conditional NAT GW |
| **Security Groups** | Layered firewall | ALB SG, EKS Node SG, RDS SG (defense in depth) |
| **ECR** | Container registry | 2 repos (frontend + backend), lifecycle policies |
| **S3** | Asset storage (prepared) | Assets bucket, versioning, encryption, CORS, all public access blocked |
| **Cognito** | Admin auth | User pool, OAuth code flow, app client, admin group |
| **GitHub OIDC** | CI/CD auth | OIDC provider, IAM role, 2 policies (deploy + terraform) |
| **RDS** | Database | PostgreSQL 16, db.t3.micro, private subnets, 7-day backups |
| **EKS** | Kubernetes | Cluster, spot node group, KMS encryption, OIDC/IRSA, add-ons |
| **CloudFront** | CDN (prepared) | Distribution, ACM cert (us-east-1), OAC for S3, Route 53 DNS |

### Wave Deployment Strategy

Infrastructure is deployed in cost-controlled waves to avoid unnecessary charges:

| Wave | Resources | Monthly Cost | When |
|------|-----------|-------------|------|
| 0 | Bootstrap (S3 state + DynamoDB) | $0 | One-time setup |
| 1 | VPC, SGs, ECR, S3, Cognito, GitHub OIDC | ~$0.50 | Anytime |
| 2 | RDS | ~$13 (stoppable) | When DB needed |
| 3 | EKS + NAT GW + CloudFront | ~$126 | Sprint only |

After sprint: destroy Waves 2-3 -> back to ~$0.50/month.

---

## Screenshots

### Blog

| Homepage | About Page |
|----------|-----------|
| ![Homepage](frontend/src/img/blog/homepage.png) | ![About](frontend/src/img/blog/about-page.png) |

| About Roadmap | Skills Page |
|---------------|-------------|
| ![Roadmap](frontend/src/img/blog/about-roadmap.png) | ![Skills](frontend/src/img/blog/skills-page.png) |

| Blog Overview | Post Detail |
|---------------|-------------|
| ![Blog Overview](frontend/src/img/blog/blog-overview.png) | ![Post Detail](frontend/src/img/blog/post-detail.png) |

### Admin Dashboard

| Login (Cognito Hosted UI) | Dashboard with Comprehend Sentiment |
|---------------------------|-------------------------------------|
| ![Login](frontend/src/img/admin/login-admin.png) | ![Dashboard](frontend/src/img/admin/dashboard-overview.png) |

| Markdown Post Editor | Comment Moderation with Sentiment Badges |
|---------------------|------------------------------------------|
| ![Post Editor](frontend/src/img/admin/post-editor.png) | ![Comments](frontend/src/img/admin/comments-sentiment.png) |

### CI/CD Pipelines

| Infrastructure Provision | Deploy to EKS | Infrastructure Teardown |
|-------------------------|---------------|------------------------|
| ![Provision](frontend/src/img/pipeline/provision-complete.png) | ![Deploy](frontend/src/img/pipeline/deploy-complete.png) | ![Teardown](frontend/src/img/pipeline/teardown-complete.png) |

### Monitoring (Prometheus + Grafana)

| HPA Stresstest (Terminal) | HPA Scaling (1 -> 4 Replicas) |
|--------------------------|------------------------------|
| ![HPA Stresstest](frontend/src/img/monitoring/hpa-stresstest-terminal.png) | ![HPA Scaling](frontend/src/img/monitoring/hpa-scaling-terminal.png) |

| Grafana Pod Metrics (before load) | Grafana Pod Metrics (under load) |
|-----------------------------------|----------------------------------|
| ![Grafana Metrics](frontend/src/img/monitoring/grafana-pod-metrics.png) | ![Grafana Load](frontend/src/img/monitoring/grafana-pod-metrics-load.png) |

| Grafana Network Dashboard (kube-system) |
|-----------------------------------------|
| ![Grafana Network](frontend/src/img/monitoring/grafana-network.png) |

### Telegram Notifications

| Real-time Comment Alerts |
|--------------------------|
| ![Telegram](frontend/src/img/telegram/bot-notifications.png) |

---

## Security

### DevSecOps Pipeline

Automated security scanning on every push -- set up before the first line of application code.

| Tool | What it does | Runs on |
|------|-------------|---------|
| **tfsec** | Scans Terraform for security misconfigurations | Push/PR to main/develop + Terraform pipeline validate |
| **Checkov** | Validates AWS infrastructure against best practices | Push/PR to main/develop + Terraform pipeline validate |
| **Trufflehog** | Detects accidentally committed secrets | Push/PR to main/develop |
| **ESLint** | Catches code errors and bad patterns | Push to main/develop (when backend/ changes) |
| **Prettier** | Enforces consistent code formatting | Push to main/develop (when backend/ changes) |
| **Husky** | Pre-commit hooks -- blocks bad commits locally | Before every commit |

All security findings are logged in the workflow output for review.

### Infrastructure Security

- RDS in private subnets, accessible only from EKS nodes (SG-to-SG rules)
- EKS secrets encrypted at rest via KMS
- IRSA for pod-level IAM (least privilege: backend for Comprehend + Translate + Polly + S3, Grafana for CloudWatch, ALB Controller for load balancing)
- S3 all public access blocked, CloudFront OAC-only access (prepared for image hosting)
- TLS 1.2+ enforced on ALB and CloudFront
- Cognito with strong password policy
- No AWS credentials in CI/CD (OIDC federation)

---

## Getting Started

### Prerequisites

- **Node.js** 22.x
- **Podman** (for containerized development)
- **Terraform** 1.9+ (for infrastructure)
- **AWS CLI** v2 (configured with credentials)

### Local Development

```bash
# Option 1: Podman Compose (recommended - runs everything)
podman machine start
podman-compose up --build

# Frontend:        http://localhost:8080
# Admin Dashboard: http://localhost:8080/admin/login.html
# Backend API:     http://localhost:3000/api
# PostgreSQL:      localhost:5432

# Option 2: Frontend only (just open in browser)
open frontend/src/index.html
# Shows demo posts when backend is not running

# Option 3: Backend only
cd backend
npm install
npm run dev
```

---

## Deployment

### Terraform Setup

```bash
# 1. Bootstrap remote state (one-time)
chmod +x terraform/bootstrap-state.sh
./terraform/bootstrap-state.sh

# 2. Initialize Terraform
cd terraform
terraform init

# 3. Deploy in waves
# Wave 1: Free/cheap resources
terraform apply -target=module.vpc -target=module.security_groups \
  -target=module.ecr -target=module.s3 -target=module.cognito \
  -target=module.github_oidc

# Wave 2: Database (~$13/month)
terraform apply -target=module.rds

# Wave 3: Kubernetes + CDN (~$126/month)
# First: set enable_nat_gateway = true in terraform.tfvars
terraform apply
```

### CI/CD Pipelines

Eight workflows (6 core + 2 status monitors), all using OIDC federation (no long-lived AWS credentials):

**Deploy workflow** (`deploy.yml` -- manual trigger):

```
Manual Trigger (GitHub UI "Run workflow")
    |
    Job 1: TEST (skippable for hotfixes)
    +-- ESLint + Prettier + Jest unit tests (31 tests)
    |
    Job 2: BUILD
    +-- OIDC auth (short-lived AWS credentials)
    +-- Build Docker images (backend + frontend)
    +-- Push to ECR (tagged: sha-<hash> + latest)
    |
    Job 3: DEPLOY
    +-- OIDC auth
    +-- Read infra values from Terraform state (fully dynamic, no manual secrets)
    +-- Install metrics-server + ALB Controller (Helm)
    +-- Install Prometheus + Grafana monitoring stack (Helm)
    +-- kubectl apply K8s manifests (12 files)
    +-- Create secrets, update images, apply ingress
    +-- Wait for rollout + print status
```

**Infrastructure Provision** (`infra-provision.yml` -- manual trigger):

```
Manual Trigger (optional: include Wave 3 checkbox)
    |
    Job 1: VALIDATE -> Job 2: SECURITY SCAN -> Job 3: PROVISION
    +-- Wave 0: IAM policies (ensures permissions are current)
    +-- Wave 1: VPC, SGs, ECR, S3, Cognito, OIDC
    +-- Wave 2: RDS
    +-- Wave 3: EKS + CloudFront + NAT GW (checkbox)
```

**Infrastructure Teardown** (`infra-destroy.yml` -- manual trigger):

```
Manual Trigger (type "DESTROY" to confirm)
    +-- Clean up Helm releases (monitoring stack)
    +-- Clean up ALB Controller resources (prevents orphaned ALBs)
    +-- Destroy Wave 3 -> Wave 2 -> Wave 1
    +-- OIDC excluded (keeps pipeline auth alive)
    +-- Verify: only OIDC resources remain in state
```

**Terraform workflow** (`terraform.yml`), **Security scanning** (`security-scan.yml`), and **Lint** (`lint.yml`) provide granular wave control, automatic PR security gates, and code quality checks respectively.

Only 4 GitHub Secrets required for the entire lifecycle: `AWS_ROLE_ARN`, `DB_PASSWORD`, `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`.

---

## Cost Analysis

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| EKS Control Plane | ~$73 | Destroy after sprint |
| EKS Nodes (2x spot) | ~$19 | Spot = 70% savings |
| NAT Gateway | ~$35 | Conditional, off in Wave 1-2 |
| RDS db.t3.micro | ~$13 | Stop when not needed (up to 7 days) |
| CloudFront | ~$1-5 | Based on traffic |
| Route 53 | ~$0.50 | Hosted zone |
| S3 | ~$0.05 | Static assets |
| Cognito | Free | <50K MAUs |
| KMS | ~$1 | EKS secrets key |
| **Full deployment** | **~$143** | **All services running** |
| **After sprint** | **~$0.50** | **Only Route 53 + S3** |

**EKS Strategy:** Deploy for sprints (~$4.80/day with all services running), destroy after. Full lifecycle (provision -> deploy -> destroy) takes ~25 minutes and is 100% reproducible.

### Dual-Track Hosting

| Track | Purpose | Monthly Cost | Infrastructure |
|-------|---------|-------------|----------------|
| **EKS** | Showcase for demos and interviews | ~$143 (sprint only) | Full AWS stack (EKS, RDS, ALB, Cognito, Comprehend, Translate, Polly) at `blog.aws.his4irness23.de` |
| **Lightsail** | Permanent hosting | ~$5.50 | Single instance, PostgreSQL on-instance, Let's Encrypt SSL at `blog.his4irness23.de` |

Same codebase, separate deployment configs. EKS demonstrates Kubernetes expertise, Lightsail keeps the blog online permanently at minimal cost. Cognito and Comprehend stay as managed AWS services on both tracks.

---

## Lessons Learned

Documented continuously in [LESSONS_LEARNED.md](LESSONS_LEARNED.md) -- 42 lessons and counting.

Key highlights:

- **#1** Security scanning from day 1 costs nothing but catches issues early
- **#4** Separate app from server for testability (Express pattern)
- **#10** Write IaC first, deploy later -- iterate for free
- **#17** Deploy pipeline reads infra values from Terraform state -- no manual secret updates after destroy+apply
- **#21** Circular dependency deadlock -- self-referential IAM module fixed with `lifecycle { ignore_changes }` + Wave 0
- **#26** ALB Controller creates resources outside Terraform -- must clean up before EKS destroy
- **#30** Full lifecycle reproducibility verified -- provision, deploy, destroy, repeat
- **#32** Dual-track hosting: EKS for showcase, Lightsail for permanent
- **#35** Amazon Comprehend misclassifies German sarcasm -- manual moderation still required
- **#36** Helm-based observability: kube-prometheus-stack gives 27 dashboards at zero extra cost
- **#37** HPA live demo: busybox load generator scales backend 1->4 pods in 60 seconds
- **#38** Amazon Translate: PostgreSQL cache over Redis -- $0.01/deploy cycle, <5ms reads, "Kanonen auf Spatzen"
- **#39** Checkov skip comments must go INSIDE the resource block, not above it
- **#40** Polly S3_BUCKET_NAME must be explicitly read from Terraform outputs in deploy.yml -- missing output read = empty env var

---

## Project Statistics

| Metric | Value |
|--------|-------|
| Development Duration | ~3.5 weeks (Feb 20 - Mar 14, 2026) |
| Terraform Modules | 9 in this project (25+ across all projects) |
| AWS Services | 14 (VPC, EKS, RDS, S3, CloudFront, Cognito, ECR, Route 53, KMS, Comprehend, Translate, Polly, ALB, IAM) |
| Blog Articles | 11 (German, real content) + 1 added live as proof-of-concept |
| Categories | 7 (each with unique color system) |
| Tags | 32 |
| Unit Tests | 31 (health, posts, comments, categories, auth) |
| K8s Manifests | 12 (namespace, config, secrets, services, deployments, ingress, HPA, db-init, Grafana dashboard) |
| CI/CD Workflows | 8 (deploy, provision, destroy, terraform, security-scan, lint, 2x status monitors) |
| Commits | 165+ |
| Lessons Learned | 42 documented |

---

## Author

**Andy Schlegel**
Cloud & DevOps Engineer

- GitHub: [@AndySchlegel](https://github.com/AndySchlegel)

---

**Project Status:** Feature-complete. EKS showcase stack fully operational, Lightsail permanent hosting planned.
**Last Updated:** 2026-03-14
**AWS Region:** eu-central-1 (Frankfurt)
