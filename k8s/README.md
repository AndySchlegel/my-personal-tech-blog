# Kubernetes Manifests -- EKS Deployment

Production-ready Kubernetes manifests for deploying the tech blog on AWS EKS.

## Architecture

```
Internet -> ALB (HTTPS) -> Frontend (nginx) -> /api/* proxy -> Backend (Express) -> RDS (PostgreSQL)
```

All traffic enters through the ALB Ingress, hits the frontend nginx pods, which proxy `/api/*` requests to the backend Service. This mirrors the local docker-compose architecture.

## File Overview

| File | Resource | Purpose |
|------|----------|---------|
| `00-namespace.yaml` | Namespace `blog` | Isolates all blog resources |
| `01-configmap.yaml` | ConfigMap `blog-config` | Non-sensitive config (PORT, CORS, NODE_ENV) |
| `02-secrets.yaml` | Secret `blog-secrets` | Sensitive config (DB URL, Cognito IDs) -- placeholders only |
| `03-backend-deployment.yaml` | Deployment `blog-backend` | Express API (2 replicas, health probes) |
| `04-backend-service.yaml` | Service `backend` | Internal ClusterIP -- name matches nginx proxy_pass |
| `05-frontend-deployment.yaml` | Deployment `blog-frontend` | Nginx static files (2 replicas) |
| `06-frontend-service.yaml` | Service `frontend` | ClusterIP for ALB target-type: ip |
| `07-ingress.yaml` | Ingress `blog-ingress` | ALB with HTTPS, HTTP->HTTPS redirect |
| `08-db-init-configmap.yaml` | ConfigMap `db-init-scripts` | Schema + seed SQL embedded |
| `09-db-init-job.yaml` | Job `db-init` | One-time DB initialization against RDS |

## Prerequisites

1. **EKS cluster** running (created by Terraform)
2. **kubectl** configured for the cluster:
   ```bash
   aws eks update-kubeconfig --name blog-eks --region eu-central-1
   ```
3. **AWS Load Balancer Controller** installed via Helm:
   ```bash
   helm repo add eks https://aws.github.io/eks-charts
   helm repo update
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
     -n kube-system \
     --set clusterName=blog-eks \
     --set serviceAccount.create=false \
     --set serviceAccount.name=aws-load-balancer-controller
   ```
4. **ECR images** built and pushed (backend + frontend)

## Placeholder Replacement

Before applying, replace these placeholders with real values from Terraform outputs:

### Secrets (02-secrets.yaml)

Do NOT edit the file -- use kubectl to create the secret with real values:

```bash
kubectl create secret generic blog-secrets --namespace blog \
  --from-literal=DATABASE_URL="postgresql://bloguser:<DB_PASSWORD>@<RDS_ENDPOINT>:5432/techblog" \
  --from-literal=COGNITO_USER_POOL_ID="$(terraform output -raw cognito_user_pool_id)" \
  --from-literal=COGNITO_CLIENT_ID="$(terraform output -raw cognito_client_id)" \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Deployment Images (03, 05)

Replace `ACCOUNT_ID` with your AWS account ID in:
- `03-backend-deployment.yaml` -- backend image URI
- `05-frontend-deployment.yaml` -- frontend image URI

### Ingress Annotations (07-ingress.yaml)

| Placeholder | Source |
|-------------|--------|
| `REPLACE_SUBNET_IDS` | `terraform output -raw public_subnet_ids` |
| `REPLACE_ALB_SG_ID` | `terraform output -raw alb_security_group_id` |
| `REPLACE_ACM_CERT_ARN` | ACM certificate ARN for your domain |

## Deployment

### 1. Apply base resources (namespace, config, secrets)

```bash
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-configmap.yaml
# Apply placeholder secrets first, then overwrite with real values (see above)
kubectl apply -f k8s/02-secrets.yaml
```

### 2. Initialize the database

```bash
kubectl apply -f k8s/08-db-init-configmap.yaml
kubectl apply -f k8s/09-db-init-job.yaml

# Watch job progress
kubectl logs -n blog job/db-init -f
```

### 3. Deploy application

```bash
kubectl apply -f k8s/03-backend-deployment.yaml
kubectl apply -f k8s/04-backend-service.yaml
kubectl apply -f k8s/05-frontend-deployment.yaml
kubectl apply -f k8s/06-frontend-service.yaml
kubectl apply -f k8s/07-ingress.yaml
```

Or apply everything at once (files are numbered for correct ordering):

```bash
kubectl apply -f k8s/
```

## Verification

```bash
# Check all resources in blog namespace
kubectl get all -n blog

# Check pod status (should be Running)
kubectl get pods -n blog

# Check backend logs
kubectl logs -n blog -l app=blog-backend --tail=50

# Check frontend logs
kubectl logs -n blog -l app=blog-frontend --tail=50

# Check ingress (ALB DNS name appears after a few minutes)
kubectl get ingress -n blog

# Check db-init job
kubectl logs -n blog job/db-init

# Test backend health (port-forward for local testing)
kubectl port-forward -n blog svc/backend 3000:3000
# Then: curl http://localhost:3000/health
```

## Troubleshooting

### Pods stuck in CrashLoopBackOff

```bash
kubectl describe pod -n blog <pod-name>
kubectl logs -n blog <pod-name> --previous
```

Common causes:
- `DATABASE_URL` secret not set or RDS not reachable (check security groups)
- Image pull errors (check ECR permissions and image URI)

### ALB not created

```bash
kubectl describe ingress blog-ingress -n blog
```

Common causes:
- AWS Load Balancer Controller not installed
- Subnet IDs or security group ID incorrect
- ACM certificate ARN missing or invalid

### DB init job fails

```bash
kubectl logs -n blog job/db-init
```

Common causes:
- RDS endpoint not reachable from EKS (check VPC peering / security groups)
- Database credentials incorrect

### Re-running DB init

```bash
kubectl delete job db-init -n blog
kubectl apply -f k8s/09-db-init-job.yaml
```

## Resource Budget

| Component | CPU Req | Memory Req | Replicas | Total CPU | Total Mem |
|-----------|---------|------------|----------|-----------|-----------|
| Backend | 100m | 128Mi | 2 | 200m | 256Mi |
| Frontend | 50m | 32Mi | 2 | 100m | 64Mi |
| **Total** | | | | **300m** | **320Mi** |

Fits comfortably on 2x t3.medium nodes (~3600m CPU, ~6.6Gi memory available).

## Clean Teardown

```bash
kubectl delete namespace blog
```

This removes all resources (deployments, services, secrets, jobs) in one command.
