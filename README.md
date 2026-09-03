# microservices-demo — DevSecOps platform scaffold

Infrastructure and CI/CD pipeline for 5 microservices (`auth-service`,
`user-service`, `order-service`, `inventory-service`, `api-gateway`) on AWS
EKS. This repo intentionally holds no application source — each `services/*`
directory is a placeholder the app teams fill in (see the README inside
each). What's here is everything around that code: provisioning, deployment,
and the security gates every change has to pass through.

## Layout

```
terraform/          AWS infra as code (VPC, EKS, ECR x5, GitHub OIDC + IRSA)
k8s/                 Kustomize base + dev/prod overlays for all 5 services
.github/workflows/   Reusable CI/CD pipeline + one caller workflow per service
security/            Config for every scanning/policy tool the pipeline runs
services/*/          Placeholder — app source + Dockerfile land here
docker-compose.yml   Local multi-service orchestration (once Dockerfiles exist)
```

## Stack

| Layer | Tool |
|---|---|
| Cloud / IaC | AWS, Terraform |
| Container platform | EKS (Kubernetes), Kustomize |
| CI/CD | GitHub Actions, OIDC (no long-lived AWS keys) |
| Secret scanning | gitleaks |
| SAST | Semgrep |
| SCA / container / IaC scanning | Trivy |
| Terraform-specific IaC scanning | tfsec, Checkov |
| SBOM | Syft (CycloneDX) |
| Image signing & attestation | cosign (keyless, via GitHub OIDC) |
| Policy-as-code gate on manifests | OPA / Conftest |
| Dependency updates | Dependabot |
| Runtime secrets | AWS Secrets Manager via Secrets Store CSI Driver |

## Pipeline flow (per service, per push)

```
secret scan ─┬─ SAST ──▶ build & test ──▶ SCA (Trivy fs) ──▶ build image
             │                                                     │
             └── (parallel) ───────────────────────────────────────┤
                                                                     ▼
                                          image scan ──▶ SBOM ──▶ sign ──▶ push to ECR
                                                                     │
                                                                     ▼
                                       policy gate (Conftest on rendered k8s manifests)
                                                                     │
                                                                     ▼
                                              deploy to EKS (dev auto, prod on release tag)
```

Any HIGH/CRITICAL finding from gitleaks, Semgrep, or Trivy fails the job —
see `security/*` for each tool's config and how to record an accepted-risk
exception instead of silently disabling a check. Deploy is by **image
digest**, not tag, so what's running is exactly what was scanned and signed.

## Getting started

1. **Bootstrap Terraform state** (one-time, out of band — see the comment in
   `terraform/environments/dev/backend.tf`): create the S3 bucket + DynamoDB
   lock table, then `terraform init` in `terraform/environments/dev`.
2. Copy `terraform/environments/dev/terraform.tfvars.example` to
   `terraform.tfvars`, fill in your GitHub org/repo, and `terraform apply`.
   This creates the VPC, EKS cluster, 5 ECR repos, and the GitHub Actions
   OIDC role.
3. Take the `github_actions_role_arn` Terraform output and add it as the
   `AWS_ROLE_ARN` **repository** secret (Settings → Secrets and variables →
   Actions — not an Environment secret; the caller workflows forward it from
   a job with no `environment:` set, so an Environment-scoped secret
   wouldn't resolve there). Separately, add required reviewers to the
   `production` GitHub Environment (Settings → Environments) — that's what
   actually gates `terraform apply` and prod deploys behind a human
   approval, independent of where the secret lives.
4. Replace every `CHANGE_ME*` placeholder in `k8s/overlays/dev` and
   `k8s/overlays/prod` with the real account ID / ECR registry / IRSA role
   ARNs (also from Terraform outputs).
5. Drop application source + a `Dockerfile` into a `services/<name>/`
   directory per its README, then push — the matching workflow in
   `.github/workflows/<name>.yml` picks it up automatically.
6. To promote to production, push a tag matching `release-*` (or run
   `promote-prod.yml` manually) — this is deliberately separate from the
   automatic dev pipeline.

## Local development

Once at least one service has a `Dockerfile`:

```
JWT_SECRET=local-dev-secret docker compose up --build
```
