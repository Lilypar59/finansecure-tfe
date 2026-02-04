# GitHub Actions + AWS ECR - Diagrama de Arquitectura

## 🏗️ Flujo Completo: Desde git push hasta EC2

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                          DEVELOPER WORKFLOW                                  │
│                                                                              │
│  ┌─────────────┐       ┌──────────────┐        ┌───────────────────────┐  │
│  │             │       │              │        │                       │  │
│  │  Local Repo │──────▶│ Git Checkout │───────▶│ Build & Test          │  │
│  │  (Terminal) │       │  Branch: main│        │ (CI Pipeline)         │  │
│  │             │       │              │        │                       │  │
│  └─────────────┘       └──────────────┘        └───────┬───────────────┘  │
│                                                         │                   │
│                                                         │                   │
│                                                         ▼                   │
│                    ┌──────────────────────────────────────────────────┐   │
│                    │                                                  │   │
│                    │        GITHUB ACTIONS WORKFLOW                   │   │
│                    │     build-and-push.yml                           │   │
│                    │                                                  │   │
│                    └──────────────────┬───────────────────────────────┘   │
│                                       │                                    │
└───────────────────────────────────────┼────────────────────────────────────┘
                                        │
                                        │ TRIGGER: push to main
                                        │
                ┌───────────────────────┴────────────────────┐
                │                                            │
                ▼                                            ▼
        ┌──────────────────┐                        ┌──────────────────┐
        │                  │                        │                  │
        │  AWS ACCOUNT ID  │                        │   GITHUB SECRETS │
        │  us-east-1       │                        │                  │
        │                  │                        │ • AWS_ACCESS_KEY │
        │  ECR:            │                        │ • AWS_SECRET_KEY │
        │  ├─ Auth repo    │◀───────────────────────│ • AWS_ACCOUNT_ID │
        │  ├─ Frontend     │   AWS Credentials      │ • AWS_REGION     │
        │  └─ Website      │   (configured)         │                  │
        │                  │                        │                  │
        └──────────────────┘                        └──────────────────┘
```

---

## 📊 Fases del Workflow

```
GitHub Push to main
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                   SECURITY PRE-FLIGHT                        │
│                   (5 minutes)                                │
│                                                              │
│  ✓ Check no .env in git                                    │
│  ✓ Check no hardcoded secrets in Dockerfiles               │
│  ✓ Verify base images pinned (no :latest)                  │
│  ✓ AWS credentials validation                              │
│                                                              │
│  Result: PASS or FAIL (fail-fast)                           │
└──────────────────────────┬──────────────────────────────────┘
                           │ success
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   AWS AUTHENTICATION                         │
│                                                              │
│  1. Configure AWS credentials (from GitHub Secrets)         │
│  2. Login to Amazon ECR                                     │
│  3. Create ECR repositories (if not exist)                 │
└──────────────────────────┬──────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐  ┌──────────────┐
│ BUILD AUTH   │   │ BUILD        │  │ BUILD        │
│ SERVICE      │   │ FRONTEND     │  │ WEBSITE      │
│              │   │              │  │              │
│ 10 minutes   │   │ 8 minutes    │  │ 7 minutes    │
│              │   │              │  │              │
│ Dockerfile:  │   │ Dockerfile:  │  │ Dockerfile:  │
│ FinanSecure  │   │ finansecure- │  │ website/     │
│ .Auth/       │   │ web/         │  │              │
│              │   │ Dockerfile   │  │              │
│ Push to ECR: │   │ .prod        │  │ Push to ECR: │
│ finansecure- │   │              │  │ finansecure- │
│ auth:        │   │ Push to ECR: │  │ website:     │
│ • SHA        │   │ finansecure- │  │ • SHA        │
│ • branch     │   │ frontend:    │  │ • branch     │
│ • timestamp  │   │ • SHA        │  │ • timestamp  │
└──────────────┘   │ • branch     │  └──────────────┘
                   │ • timestamp  │
                   └──────────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────────┐
        │   VERIFY IMAGES IN ECR                   │
        │   (5 minutes)                            │
        │                                          │
        │   • Check finansecure-auth exists       │
        │   • Check finansecure-frontend exists   │
        │   • Check finansecure-website exists    │
        │   • Verify image sizes are reasonable   │
        │                                          │
        │   Result: Images in ECR ready to deploy │
        └──────────────────┬─────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────────┐
        │   CREATE DEPLOYMENT MANIFEST             │
        │                                          │
        │   image-manifest.json contains:          │
        │   {                                      │
        │     "commit_sha": "abc1234...",          │
        │     "branch": "main",                    │
        │     "images": {                          │
        │       "auth": "123...amazonaws.com/...", │
        │       "frontend": "123...amazonaws.com/..", │
        │       "website": "123...amazonaws.com/.."  │
        │     }                                    │
        │   }                                      │
        └──────────────────┬─────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────────┐
        │   WORKFLOW SUMMARY & NOTIFICATION        │
        │   (2 minutes)                            │
        │                                          │
        │   ✅ Build Complete                      │
        │   ✅ All images pushed to ECR            │
        │   ✅ Ready for deployment                │
        │                                          │
        │   GitHub comment added to commit         │
        └──────────────────┬─────────────────────┘
                           │
                           ▼
                    WORKFLOW COMPLETE
                    ~40 minutes total
```

---

## 🗂️ Estructura de Ficheros (Antes y Después)

### Antes (sin CI/CD automático)

```
proyecto/
├── FinanSecure.Auth/
│   └── Dockerfile
├── finansecure-web/
│   └── Dockerfile.prod
├── website/
│   └── Dockerfile
└── docker-compose.yml

❌ Construcción manual
❌ Push manual a ECR
❌ Riesgo de errores humanos
```

### Después (con GitHub Actions)

```
proyecto/
├── .github/
│   └── workflows/
│       ├── ci.yml                      ← Existing: test & validate
│       └── build-and-push.yml          ← NEW: build & push to ECR
│
├── FinanSecure.Auth/
│   └── Dockerfile
├── finansecure-web/
│   └── Dockerfile.prod
├── website/
│   └── Dockerfile
│
├── verify-ecr-builds.sh                ← NEW: Local verification
│
├── REPORTES/08_CI_CD_PIPELINE/
│   ├── BUILD_AND_PUSH_ECR_IMPLEMENTATION_GUIDE.md
│   └── BUILD_AND_PUSH_ECR_QUICK_REFERENCE.md
│
└── docker-compose.yml

✅ Construcción automática
✅ Push automático a ECR
✅ Auditoria en GitHub Actions
✅ Reproducible y seguro
```

---

## 🔐 Security Flow

```
Developer Push to main
         │
         ▼
┌─────────────────────────────┐
│ GitHub Webhook Triggered    │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│  GitHub Secrets (ENCRYPTED)             │
│  • AWS_ACCESS_KEY_ID                    │
│  • AWS_SECRET_ACCESS_KEY                │
│  • AWS_ACCOUNT_ID                       │
│  • AWS_REGION                           │
└────────────┬────────────────────────────┘
             │ (injected into runner)
             ▼
┌─────────────────────────────────────────┐
│ GitHub Actions Runner (Isolated)        │
│                                         │
│ 1. Checkout code from main              │
│ 2. Run security checks (no secrets)     │
│ 3. Setup Docker BuildKit                │
│ 4. Load AWS credentials from secrets    │
│ 5. Login to ECR                         │
│ 6. Build Docker images                  │
│ 7. Push to ECR                          │
│ 8. Verify push succeeded                │
│                                         │
│ ⚠️ Credentials never printed in logs    │
│ ⚠️ images scanned for secrets           │
│ ⚠️ ECR image scanning enabled           │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ AWS ECR (Private Registry)              │
│                                         │
│ finansecure-auth:abc1234 ✓              │
│ finansecure-frontend:abc1234 ✓          │
│ finansecure-website:abc1234 ✓           │
│                                         │
│ Image scanning: ON                      │
│ Encryption: AES                         │
│ Access: Private (IAM controlled)        │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│ EC2 Instance (Manual Deployment)        │
│                                         │
│ 1. Pull images from ECR                 │
│ 2. Run containers with docker compose   │
│ 3. Monitor container health             │
└─────────────────────────────────────────┘
```

---

## 🎯 Integración con Arquitectura FinanSecure

```
┌────────────────────────────────────────────────────────────────┐
│                    FinanSecure Architecture                     │
└────────────────────────────────────────────────────────────────┘

                            Internet Users
                                  │
                                  ▼
                        ┌──────────────────┐
                        │    AWS Route53   │
                        │   (DNS Routing)  │
                        └────────┬─────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
                    ▼                         ▼
        ┌──────────────────┐      ┌──────────────────┐
        │  EC2 Instance 1  │      │  EC2 Instance 2  │
        │  (Primary)       │      │  (Backup)        │
        │                  │      │                  │
        │ Docker Compose:  │      │ Docker Compose:  │
        │ • Auth           │      │ • Auth           │
        │ • Frontend       │      │ • Frontend       │
        │ • Website        │      │ • Website        │
        │ • NGINX          │      │ • NGINX          │
        │ • PostgreSQL     │      │ • PostgreSQL     │
        │ • PgAdmin        │      │ • PgAdmin        │
        │                  │      │                  │
        │ Images from ECR: │      │ Images from ECR: │
        │ pull & run       │      │ pull & run       │
        └────────┬─────────┘      └────────┬─────────┘
                 │                         │
                 │    ┌────────────────────┘
                 │    │
                 └────┼─────────────────────┐
                      │                     │
                      ▼                     ▼
            ┌──────────────────┐  ┌──────────────────┐
            │   AWS ECR        │  │  RDS PostgreSQL  │
            │                  │  │  (Production DB) │
            │ finansecure-auth │  │                  │
            │ finansecure-fe   │  │ • auth_db        │
            │ finansecure-web  │  │ • transactions_db│
            │                  │  │                  │
            │ Trigger:         │  │ Backups enabled  │
            │ Push to main     │  │ Multi-AZ         │
            │ (GitHub Actions) │  │                  │
            └────────┬─────────┘  └──────────────────┘
                     │
                     │
            ┌────────▼────────┐
            │   GITHUB        │
            │   build-and-    │
            │   push.yml      │
            │                 │
            │ Trigger: PR/    │
            │ push to main    │
            └─────────────────┘
```

---

## 📈 Ventajas de este Workflow

| Aspecto | Antes | Después |
|--------|-------|---------|
| **Build** | Manual, propenso a errores | Automático, consistente |
| **Push** | Manual, riesgo de olvidar | Automático, garantizado |
| **Secretos** | Riesgo en CLI | Seguros en GitHub Secrets |
| **Auditoria** | Difícil de rastrear | Logs en GitHub Actions |
| **Reproducibilidad** | Variable | Exacta (commit SHA) |
| **Escalabilidad** | Manual para cada servicio | Paralelo (3 servicios simultáneamente) |
| **Rollback** | Manual, lento | Tag image anterior, redeploy |
| **Compliance** | Difícil demostrar | Auditables en GitHub |

---

## ⚙️ Configuraciones Clave

### Docker Buildx

Utiliza BuildKit para:
- ✅ Layer caching (reutilizar capas de builds anteriores)
- ✅ Construcciones más rápidas (paralelo)
- ✅ Mejores errores de compilación

### ECR Image Scanning

Habilitado automáticamente:
- ✅ Escanea vulnerabilidades al push
- ✅ CVE scoring automático
- ✅ Reporte en GitHub

### Image Tagging Strategy

Tres tags por imagen:

```
finansecure-auth:abc1234        ← Identificador único (reproduc.)
finansecure-auth:main           ← Última de rama (referencia)
finansecure-auth:20260202-140000 ← Timestamp (auditoría)
```

Esto permite:
- ✅ Pinning exacto para deploy
- ✅ Referencia rápida a última versión
- ✅ Rastreo temporal de cambios

---

## 🚀 Próximo Paso: Deployment Automation

Una vez que `build-and-push.yml` funciona, el siguiente paso es:

```yaml
# .github/workflows/deploy.yml (futuro)

on:
  workflow_run:
    workflows: ["Build and Push to AWS ECR"]
    types: [completed]

jobs:
  deploy-to-ec2:
    runs-on: ubuntu-latest
    steps:
      # 1. Download image manifest
      # 2. SSH to EC2
      # 3. Pull images from ECR
      # 4. Update docker-compose.yml with new image tags
      # 5. Restart containers
      # 6. Verify health checks
      # 7. Rollback if unhealthy
```

---

**Documento Versión:** 1.0  
**Fecha:** 2026-02-02  
**Estado:** ✅ Architectural Design Complete
