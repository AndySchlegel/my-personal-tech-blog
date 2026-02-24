# My Personal Tech Blog

> **Cloud-native tech blog on AWS EKS, documenting my journey from zero to cloud engineer in one year.**

[![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20RDS%20%7C%20Cognito%20%7C%20Comprehend-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-8%20Modules%20IaC-blue)](https://www.terraform.io/)
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

This blog tells a real story: starting with a Synology NAS and a basic router, building up to a multi-server infrastructure with 4 certifications, surviving security incidents, and deploying production workloads on AWS.

### Why This Project?

1. **Real portfolio piece** - Documents an authentic learning journey, stays online permanently
2. **Security incident recovery** - MongoDB crypto mining + server compromise as motivation
3. **On-prem to cloud migration** - Demonstrates enterprise-relevant skills
4. **EKS complements serverless** - Together with a previous serverless project, covers both cloud paradigms
5. **Natural ML integration** - Comprehend for auto-tags and comment sentiment analysis
6. **Built to last** - Migration to self-hosted infrastructure planned after course

---

## Architecture

```
Route 53 (DNS: blog.his4irness23.de)
    |
CloudFront (CDN + TLS via ACM, PriceClass_100)
    |
    +-- S3 Origin (blog images, OAC-signed requests)
    +-- ALB Origin (dynamic content, added after EKS deploy)
    |
ALB (AWS Load Balancer Controller, managed via IRSA)
    |
EKS Cluster (eu-central-1, 2 AZs)
    |--- Frontend Pod (nginx + Tailwind CSS)
    |--- Backend Pod (Express + TypeScript)
    |--- HPA (auto-scaling)
    |
    +-- Private Subnets (10.0.10.0/24, 10.0.11.0/24)
    |       |--- EKS Nodes (Spot: t3.medium + t3a.medium)
    |       |--- RDS PostgreSQL 16 (db.t3.micro)
    |
    +-- Public Subnets (10.0.1.0/24, 10.0.2.0/24)
            |--- ALB
            |--- NAT Gateway (conditional)
    |
Cognito (Admin JWT authentication)
    |
Amazon Comprehend (ML: auto-tags + sentiment)
```

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Node.js, Express, TypeScript |
| Frontend | Tailwind CSS, Tabler Icons, nginx |
| Database | PostgreSQL 16 (RDS) |
| Content | Markdown (stored in DB, rendered in frontend) |
| Auth | AWS Cognito (OAuth 2.0, SRP, optional TOTP MFA) |
| ML | Amazon Comprehend (key phrases + sentiment) |
| Images | S3 upload (pre-signed URLs) + CloudFront CDN (OAC) |
| IaC | Terraform (8 modules, from scratch, 2,600+ lines) |
| CI/CD | GitHub Actions with OIDC |
| Container | Podman (multi-stage builds), EKS (Spot instances) |
| Security | tfsec, Checkov, Trufflehog, ESLint, Husky |

---

## Features

### Public
- Blog posts with Markdown rendering and syntax highlighting
- Search and category filtering (debounced, server-side SQL filtering)
- Auto-generated tags via Amazon Comprehend
- Comment system with sentiment analysis
- About page with personal journey timeline, animated counters, and quote block
- Skills page with priority labels, proficiency-based skill rows, cert roadmap, and animated progress stats
- Dark mode (default) with light mode toggle
- Fully responsive (mobile-first)

### Admin Dashboard (Cognito-protected)
- Login via Cognito Hosted UI (OAuth 2.0 code flow) with dev mode bypass
- Dashboard overview with stat cards (posts, published, pending comments, views)
- Recent posts and comments activity feed
- Post management: create, edit, delete with side-by-side Markdown editor + live preview
- Comment moderation: approve, flag, delete with status filtering
- Sidebar navigation with responsive mobile layout
- *Coming later:* S3 image uploads (needs EKS deployment)

---

## Infrastructure

### Terraform Modules (8 modules, all written from scratch)

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| **VPC** | Network foundation | VPC, 2 public + 2 private subnets, IGW, conditional NAT GW |
| **Security Groups** | Layered firewall | ALB SG, EKS Node SG, RDS SG (defense in depth) |
| **ECR** | Docker registry | 2 repos (frontend + backend), lifecycle policies |
| **S3** | Image storage | Assets bucket, versioning, encryption, CORS, all public access blocked |
| **Cognito** | Admin auth | User pool, OAuth code flow, app client, admin group |
| **RDS** | Database | PostgreSQL 16, db.t3.micro, private subnets, 7-day backups |
| **EKS** | Kubernetes | Cluster, spot node group, KMS encryption, OIDC/IRSA, add-ons |
| **CloudFront** | CDN | Distribution, ACM cert, OAC for S3, Route 53 DNS |

### Wave Deployment Strategy

Infrastructure is deployed in cost-controlled waves to avoid unnecessary charges:

| Wave | Resources | Monthly Cost | When |
|------|-----------|-------------|------|
| 0 | Bootstrap (S3 state + DynamoDB) | $0 | One-time setup |
| 1 | VPC, SGs, ECR, S3, Cognito | ~$0.50 | Anytime |
| 2 | RDS | ~$13 (stoppable) | When DB needed |
| 3 | EKS + NAT GW + CloudFront | ~$126 | Sprint only |

After sprint: destroy EKS, disable NAT GW, stop RDS -> back to ~$0.65/month.

---

## Screenshots

*Coming soon - screenshots will be added as features are completed.*

---

## Security

### DevSecOps Pipeline

Automated security scanning on every push - set up before the first line of application code.

| Tool | What it does | Runs on |
|------|-------------|---------|
| **tfsec** | Scans Terraform for security misconfigurations | Push to main/develop (when terraform/ changes) |
| **Checkov** | Validates AWS infrastructure against best practices | Push to main/develop (when terraform/ changes) |
| **Trufflehog** | Detects accidentally committed secrets | Every push |
| **ESLint** | Catches code errors and bad patterns | Push to main/develop (when backend/ changes) |
| **Prettier** | Enforces consistent code formatting | Push to main/develop (when backend/ changes) |
| **Husky** | Pre-commit hooks - blocks bad commits locally | Before every commit |

All security findings are uploaded to the GitHub Security tab via SARIF format.

### Infrastructure Security

- All S3 public access blocked (CloudFront OAC only)
- RDS in private subnets, accessible only from EKS nodes (SG-to-SG rules)
- EKS secrets encrypted at rest via KMS
- IRSA for pod-level IAM (least privilege per service)
- TLS 1.2+ enforced on CloudFront
- Cognito with strong password policy + optional TOTP MFA
- No AWS credentials in CI/CD (OIDC federation)

**Cost:** $0.00/month (GitHub Actions free tier + AWS free tier for security features)

---

## Getting Started

### Prerequisites

- **Node.js** 22.x
- **Podman** (for containerized development)
- **Terraform** 1.5+ (for infrastructure)
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
  -target=module.ecr -target=module.s3 -target=module.cognito

# Wave 2: Database (~$13/month)
terraform apply -target=module.rds

# Wave 3: Kubernetes + CDN (~$126/month)
# First: set enable_nat_gateway = true in terraform.tfvars
terraform apply
```

### CI/CD Pipeline

```
Push to develop
    |
    +-- Code Quality (ESLint + Prettier)
    +-- Security Scanning (tfsec + Checkov + Trufflehog)
    +-- Backend Tests (Jest)
    |
    +-- Build Docker Images (tagged with git SHA)
    +-- Push to ECR
    +-- Deploy to EKS (kubectl apply + rollout status)
```

Authentication via OIDC - no long-lived AWS credentials stored in GitHub.

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
| S3 | ~$0.05 | Image storage |
| Cognito | Free | <50K MAUs |
| KMS | ~$1 | EKS secrets key |
| **Full deployment** | **~$143** | **All services running** |
| **After sprint** | **~$0.65** | **Only Route 53 + S3** |

**Strategy:** Deploy for sprints (~$4.20 for 8 hours of EKS), destroy after.

---

## Lessons Learned

Documented continuously in [LESSONS_LEARNED.md](LESSONS_LEARNED.md).

Key highlights:
- **#1** Security scanning from day 1 costs nothing but catches issues early
- **#4** Separate app from server for testability (Express pattern)
- **#8** Hot-reload with `podman cp` for visual development
- **#10** Write IaC first, deploy later -- iterate for free
- **#12** Code comments as a learning tool, not just documentation
- **#14** Tailwind CDN overrides custom CSS -- use utility classes directly on elements

---

## Project Statistics

| Metric | Value |
|--------|-------|
| Development Duration | 4 weeks (Feb-Mar 2026) |
| Terraform Modules | 8 (29 files, 2,600+ lines) |
| AWS Services | 10+ (VPC, EKS, RDS, S3, CloudFront, Cognito, ECR, Route 53, KMS, Comprehend) |
| Blog Articles | 12 (migrated from previous project) |
| Unit Tests | 31 (health, posts, comments, categories, auth) |
| Lessons Learned | 14 documented |
| Commits | 10+ |

*Updated as the project progresses.*

---

## Author

**Andy Schlegel**
Cloud Engineer | Full-Stack Developer | DevOps Enthusiast

- GitHub: [@AndySchlegel](https://github.com/AndySchlegel)

---

**Project Status:** In Development (Admin Dashboard complete, next: K8s Manifests + CI/CD)
**Last Updated:** 2026-02-24
**AWS Region:** eu-central-1 (Frankfurt)
