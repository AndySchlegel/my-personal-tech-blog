# My Personal Tech Blog

A cloud-native tech blog deployed on AWS EKS, documenting my journey from zero to cloud engineer in one year.

## About

This blog tells a real story: starting with a Synology NAS and a basic router, building up to a multi-server infrastructure with 4 certifications, surviving security incidents, and deploying production workloads on AWS.

**Live:** `https://[name].cloudhelden-projekte.de` (during course)

## Architecture

```
Route 53 (DNS)
    |
CloudFront (CDN + TLS)
    |
ALB (AWS Load Balancer Controller)
    |
EKS Cluster (eu-central-1)
    |--- Frontend Pod (nginx + Tailwind CSS)
    |--- Backend Pod (Express + TypeScript)
    |
RDS PostgreSQL (private subnet)
    |
Amazon Comprehend (ML: auto-tags + sentiment)
    |
S3 (image uploads)
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Node.js, Express, TypeScript |
| Frontend | Tailwind CSS, Tabler Icons, nginx |
| Database | PostgreSQL (RDS) |
| Auth | AWS Cognito |
| ML | Amazon Comprehend |
| IaC | Terraform (modular) |
| CI/CD | GitHub Actions (OIDC) |
| Container | Docker, EKS |

## Features

- Blog posts with Markdown rendering
- Auto-generated tags via Amazon Comprehend
- Comment system with sentiment analysis
- Admin dashboard (Cognito-protected)
- Dark mode (default) with light mode toggle
- Fully responsive (mobile-first)
- Image uploads to S3 + CloudFront CDN

## Getting Started

```bash
# Backend
cd backend
npm install
npm run dev

# Frontend
cd frontend
npm run dev
```

## Project Structure

```
backend/        - Express + TypeScript API
frontend/       - Static frontend (Tailwind CSS + nginx)
terraform/      - Infrastructure as Code (modular)
k8s/            - Kubernetes manifests
.github/        - CI/CD pipeline
```

## License

MIT
