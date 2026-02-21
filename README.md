# My Personal Tech Blog

> **Cloud-native tech blog on AWS EKS, documenting my journey from zero to cloud engineer in one year.**

[![AWS](https://img.shields.io/badge/AWS-EKS%20%7C%20RDS%20%7C%20Cognito%20%7C%20Comprehend-orange)](https://aws.amazon.com/)
[![Terraform](https://img.shields.io/badge/Terraform-100%25%20IaC-blue)](https://www.terraform.io/)
[![TypeScript](https://img.shields.io/badge/TypeScript-Express.js-blue)](https://www.typescriptlang.org/)
[![Security](https://img.shields.io/badge/Security-tfsec%20%7C%20Checkov%20%7C%20Trufflehog-green)](https://github.com/AndySchlegel/my-personal-tech-blog/security)
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Features](#features)
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
Route 53 (DNS)
    |
CloudFront (CDN + TLS via ACM)
    |
ALB (AWS Load Balancer Controller)
    |
EKS Cluster (eu-central-1)
    |--- Frontend Pod (nginx + Tailwind CSS)
    |--- Backend Pod (Express + TypeScript)
    |--- HPA (auto-scaling)
    |
RDS PostgreSQL (private subnet)
    |
Amazon Comprehend (ML: auto-tags + sentiment)
    |
S3 (image uploads via CloudFront)
```

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Node.js, Express, TypeScript |
| Frontend | Tailwind CSS, Tabler Icons, nginx |
| Database | PostgreSQL (RDS) |
| Content | Markdown (stored in DB, rendered in frontend) |
| Auth | AWS Cognito |
| ML | Amazon Comprehend (key phrases + sentiment) |
| Images | S3 upload + CloudFront CDN |
| IaC | Terraform (modular, from scratch) |
| CI/CD | GitHub Actions with OIDC |
| Container | Docker (multi-stage builds), EKS |
| Security | tfsec, Checkov, Trufflehog, ESLint, Husky |

---

## Features

### Public
- Blog posts with Markdown rendering and syntax highlighting
- Auto-generated tags via Amazon Comprehend
- Comment system with sentiment analysis
- About page with personal journey timeline
- Search and category filtering
- Dark mode (default) with light mode toggle
- Fully responsive (mobile-first)

### Admin Dashboard (Cognito-protected)
- Create and edit posts (Markdown editor with live preview)
- Image uploads to S3
- Comment moderation with sentiment overview
- ML results display (auto-tags, sentiment scores)
- Basic statistics (posts, comments, top tags)

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

**Cost:** $0.00/month (GitHub Actions free tier)

---

## Getting Started

### Prerequisites

- **Node.js** 22.x
- **Docker** (for containerized development)
- **Terraform** 1.5+ (for infrastructure)
- **AWS CLI** v2 (configured with credentials)

### Local Development

```bash
# Option 1: Docker Compose (recommended - runs everything)
docker compose up --build

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

| Service | Estimated Monthly Cost |
|---------|----------------------|
| EKS Control Plane | ~$72 (destroy after work) |
| EKS Nodes (2x t3.medium) | ~$65 (scale to 0 after work) |
| RDS db.t3.micro | ~$12 (stop when not needed) |
| CloudFront | Minimal |
| Route 53 | ~$0.50 |
| S3 | Minimal |
| Cognito | Free (<50K MAUs) |
| **Strategy** | **~$2/day when actively working** |

---

## Lessons Learned

Documented continuously in [LESSONS_LEARNED.md](LESSONS_LEARNED.md).

*Highlights will be added here as the project progresses.*

---

## Project Statistics

| Metric | Value |
|--------|-------|
| Development Duration | 4 weeks (Feb-Mar 2026) |
| Terraform Modules | 8 planned |
| AWS Services | 10+ |
| Blog Articles | 12 (migrated from previous project) |
| Unit Tests | 19 (health, posts, comments, categories) |
| Lessons Learned | 7 documented |

*Updated as the project progresses.*

---

## Author

**Andy Schlegel**
Cloud Engineer | Full-Stack Developer | DevOps Enthusiast

- GitHub: [@AndySchlegel](https://github.com/AndySchlegel)

---

**Project Status:** In Development (Phase 2: Backend API + Phase 3: Frontend)
**Last Updated:** 2026-02-21
**AWS Region:** eu-central-1 (Frankfurt)
