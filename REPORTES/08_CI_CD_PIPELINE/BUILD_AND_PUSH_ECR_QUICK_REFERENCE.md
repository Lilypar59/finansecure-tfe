# GitHub Actions → AWS ECR Build & Push - Quick Reference

**Estado:** ✅ Workflow Listo  
**Ubicación:** `.github/workflows/build-and-push.yml`  
**Trigger:** Push a rama `main`  
**Duración:** ~40 minutos  

---

## ⚡ Setup en 5 Minutos

### 1️⃣ Agregar GitHub Secrets (2 min)

**GitHub → Settings → Secrets and variables → Actions → New Repository Secret**

| Secret | Valor |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | Tu AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | Tu AWS Secret Key |
| `AWS_ACCOUNT_ID` | Tu Account ID (12 dígitos) |
| `AWS_REGION` | `us-east-1` |

```bash
# Obtener AWS Account ID
aws sts get-caller-identity --query Account --output text

# Obtener Access Keys
# AWS IAM Console → Users → Security Credentials → Create access key
```

### 2️⃣ Verificar Dockerfiles (1 min)

```bash
# ✓ Estos deben existir
ls -la FinanSecure.Auth/Dockerfile
ls -la finansecure-web/Dockerfile.prod
ls -la website/Dockerfile

# ✓ Estos NO deben tener secretos
grep -i "PASSWORD\|SECRET\|CHANGE_ME" FinanSecure.Auth/Dockerfile || echo "✓ OK"
```

### 3️⃣ Test Local (1 min - Recomendado)

```bash
# Ejecutar script de verificación
bash verify-ecr-builds.sh

# Resultado esperado: "✅ All local verification checks passed!"
```

### 4️⃣ Push a GitHub (30 seg)

```bash
git add .github/workflows/build-and-push.yml
git commit -m "feat: add ECR build and push workflow"
git push origin main
```

### 5️⃣ Monitorear Workflow (10 min)

```
GitHub → Actions → "Build and Push to AWS ECR" → Ver ejecución

Estado esperado después de 40 min:
  ✅ security-check
  ✅ build-and-push
  ✅ verify-images
  ✅ build-summary
```

---

## 📊 Estructura del Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ TRIGGER: push a main                                            │
└────────────────────────────────────┬────────────────────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │                                 │
            ┌───────▼─────────┐          ┌───────────▼──────────┐
            │ security-check  │          │ (espera security)    │
            │ (5 min)         │          │                      │
            └───────┬─────────┘          │                      │
                    │                    │                      │
                    └────────────────────┼─ build-and-push ─────┤
                                         │ (30 min)             │
                                         │ • Auth (10m)         │
                                         │ • Frontend (8m)      │
                                         │ • Website (7m)       │
                                         │ • Verify push (5m)   │
                                         └───────┬──────────────┘
                                                 │
                              ┌──────────────────┴──────────────────┐
                              │                                     │
                    ┌─────────▼────────┐              ┌────────────▼──┐
                    │ verify-images    │              │ build-summary │
                    │ (5 min)          │              │ (2 min)       │
                    └─────────┬────────┘              └────────┬──────┘
                              │                               │
                              └───────────────┬───────────────┘
                                              │
                                    ┌─────────▼──────────┐
                                    │ ✅ WORKFLOW DONE   │
                                    │ Imágenes en ECR    │
                                    └────────────────────┘
```

---

## 🐳 Imágenes Generadas

Después de cada push a `main`, se generan 3 imágenes en AWS ECR:

### Format: `account-id.dkr.ecr.region.amazonaws.com/repo-name:tag`

**Ejemplo (tuyo será diferente):**

```
123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:a1b2c3d
123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:main
123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:20260202-143022

123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-frontend:a1b2c3d
123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-frontend:main
123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-frontend:20260202-143022

123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-website:a1b2c3d
123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-website:main
123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-website:20260202-143022
```

**Donde:**
- `a1b2c3d` = Commit SHA (short)
- `main` = Nombre de la rama
- `20260202-143022` = Timestamp del build

---

## 🔍 Verificar en AWS

### Ver repositorios ECR

```bash
aws ecr describe-repositories --region us-east-1 --output table
```

### Ver imágenes en un repo

```bash
aws ecr describe-images \
  --repository-name finansecure-auth \
  --region us-east-1 \
  --query 'imageDetails[0:5].{Tags:imageTags,Size:imageSizeInBytes,Pushed:imagePushedAt}' \
  --output table
```

### Descargar imagen localmente

```bash
# 1. Login (en tu máquina local)
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# 2. Pull imagen
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:a1b2c3d

# 3. Verificar
docker image ls | grep finansecure
```

---

## 🚀 Deploy a EC2

Una vez que las imágenes están en ECR:

```bash
# 1. En tu instancia EC2
ssh ec2-user@your-instance

# 2. Login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# 3. Pull de las imágenes
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:a1b2c3d
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-frontend:a1b2c3d
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-website:a1b2c3d

# 4. Run con docker-compose (si tienes docker-compose.yml adaptado para ECR)
docker compose up -d
```

---

## ❌ Troubleshooting

### Problema: Workflow falla en "Configure AWS credentials"

**Causa:** GitHub Secrets no configurados  
**Solución:** Ir a GitHub → Settings → Secrets → Agregar los 4 secrets

### Problema: Workflow falla en "Build Auth Service"

**Causa:** Dockerfile tiene error  
**Solución:**  
```bash
# Test local
docker build -f FinanSecure.Auth/Dockerfile -t test .

# Ver error
docker build -f FinanSecure.Auth/Dockerfile -t test . --no-cache
```

### Problema: Imágenes no aparecen en ECR

**Causa:** Push falló (revisar logs del workflow)  
**Solución:**  
1. Ver logs: GitHub → Actions → Click en run → Ver detalles
2. Buscar: "ERROR", "failed", "not found"
3. Revisar credenciales AWS

### Problema: "Hardcoded secrets found"

**Causa:** Dockerfile tiene contraseñas/secretos  
**Solución:** Remover de Dockerfile, usar env vars en runtime

---

## 📋 Checklist antes de producción

- [ ] GitHub Secrets configurados (4 secretos)
- [ ] Dockerfiles sin secretos hardcodeados
- [ ] `.github/workflows/build-and-push.yml` existe
- [ ] `verify-ecr-builds.sh` pasa correctamente
- [ ] Push a main dispara el workflow
- [ ] Workflow completa exitosamente (40 min)
- [ ] Imágenes aparecen en AWS ECR
- [ ] Imágenes tienen 3 tags (SHA, branch, timestamp)
- [ ] IAM role tiene permisos ECR
- [ ] EC2 instancia puede hacer login a ECR

---

## 📚 Archivos Relacionados

```
.github/
├── workflows/
│   ├── ci.yml                          ← Testing & validation
│   └── build-and-push.yml              ← THIS FILE ✓
│
REPORTES/08_CI_CD_PIPELINE/
├── BUILD_AND_PUSH_ECR_IMPLEMENTATION_GUIDE.md
└── BUILD_AND_PUSH_ECR_QUICK_REFERENCE.md     ← YOU ARE HERE

verify-ecr-builds.sh                    ← Local verification script
```

---

## 🎯 Próximos Pasos

1. **Completar setup** (5 min)
   - Agregar secrets en GitHub
   - Push a main

2. **Monitorear workflow** (40 min)
   - GitHub Actions → ver ejecución
   - Verificar imágenes en ECR

3. **Deploy a EC2** (siguiente fase)
   - Pull imágenes desde ECR
   - Correr contenedores

4. **Monitoring** (después de deploy)
   - CloudWatch logs
   - Container health checks
   - ECR image scanning

---

**Última actualización:** 2026-02-02  
**Estado:** ✅ Listo para usar  
**Soporte:** Ver BUILD_AND_PUSH_ECR_IMPLEMENTATION_GUIDE.md para detalles
