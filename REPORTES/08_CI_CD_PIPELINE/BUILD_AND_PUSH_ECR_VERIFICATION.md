# Verificación de Setup - Build & Push ECR Workflow

**Objetivo:** Validar que el workflow está correctamente configurado antes de ejecutar  
**Duración:** 10 minutos  
**Requisitos:** Git, Docker, AWS CLI (opcional)

---

## ✅ Checklist de Verificación

### 1. Archivo Workflow Existe

```powershell
# PowerShell
Test-Path ".github/workflows/build-and-push.yml"

# Resultado esperado: True
```

**Si es False:** El archivo no existe, crear en: `.github/workflows/build-and-push.yml`

### 2. Dockerfiles Existen

```powershell
Test-Path "FinanSecure.Auth/Dockerfile"
Test-Path "finansecure-web/Dockerfile.prod"
Test-Path "website/Dockerfile"

# Resultado esperado: True, True, True
```

**Si alguno es False:** El archivo no existe en esa ubicación

### 3. GitHub Secrets Configurados

```powershell
# No puedes verlos directamente, pero verifica en:
# GitHub → Settings → Secrets and variables → Actions

# Debería ver 4 secrets:
# ✓ AWS_ACCESS_KEY_ID
# ✓ AWS_SECRET_ACCESS_KEY
# ✓ AWS_ACCOUNT_ID
# ✓ AWS_REGION
```

**Verificación programática (si tienes GitHub CLI):**

```powershell
gh secret list --repo usuario/finansecure-tfe

# Resultado esperado:
# AWS_ACCESS_KEY_ID         Updated 2026-02-02
# AWS_SECRET_ACCESS_KEY     Updated 2026-02-02
# AWS_ACCOUNT_ID            Updated 2026-02-02
# AWS_REGION                Updated 2026-02-02
```

### 4. No hay .env files Commiteados

```powershell
# Verificar git history
git ls-files | Select-String "^\.env"

# Resultado esperado: (sin output - significa que no hay .env files)
```

**Si hay output:** Hay .env files en git, ejecutar:
```powershell
git rm --cached .env
git commit -m "remove .env from git tracking"
git push
```

### 5. Verificar Sintaxis del Workflow YAML

```powershell
# Usar un validador online:
# https://www.yamllint.com/

# O con Python:
python -m pip install pyyaml
python -c "import yaml; yaml.safe_load(open('.github/workflows/build-and-push.yml'))"

# Resultado esperado: (sin error)
```

### 6. No hay Secretos en Dockerfiles

```powershell
# Buscar patrones sospechosos
Select-String -Path @(
    "FinanSecure.Auth/Dockerfile",
    "finansecure-web/Dockerfile.prod",
    "website/Dockerfile"
) -Pattern "(PASSWORD|SECRET|TOKEN|APIKEY|CHANGE_ME)" -NotMatch

# Resultado esperado: (sin output = sin secretos)

# Si hay output, revisar y remover los secretos encontrados
```

### 7. Base Images Tienen Versión Pinned

```powershell
# Verificar que no hay :latest tags
Select-String -Path @(
    "FinanSecure.Auth/Dockerfile",
    "finansecure-web/Dockerfile.prod",
    "website/Dockerfile"
) -Pattern "FROM.*:latest"

# Resultado esperado: (sin output = sin :latest tags)

# Si hay output, actualizar:
# FROM mcr.microsoft.com/dotnet/aspnet:latest
# a:
# FROM mcr.microsoft.com/dotnet/aspnet:8.0
```

### 8. Script de Verificación Local Funciona

```powershell
# Ejecutar script
bash verify-ecr-builds.sh

# Resultado esperado:
# ════════════════════════════════════════════════════════════════════════════════
# ✅ All local verification checks passed!
```

**Si falla:** Revisar output del script y corregir problemas identificados

### 9. Credenciales AWS Locales Funcionan

```powershell
# Verificar AWS CLI está configurado
aws sts get-caller-identity

# Resultado esperado:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/github-actions"
# }
```

**Si falla:** Configurar AWS CLI:
```powershell
aws configure
# Ingresar: Access Key ID
# Ingresar: Secret Access Key
# Ingresar: Default region (us-east-1)
# Ingresar: Default output format (json)
```

### 10. Repository Push Funciona

```powershell
# Hacer un test push
git status

# Resultado esperado: (On branch main, nothing to commit)

# Si hay cambios sin commitar
git add .github/workflows/build-and-push.yml
git commit -m "ci: add ECR build and push workflow"
git push origin main

# Resultado esperado: (push successful)
```

---

## 🚀 Ejecutar Test Completo

### Test 1: Verificación Local de Builds (Sin push a AWS)

```powershell
# Este test construye imágenes localmente sin push
bash verify-ecr-builds.sh

# Esperar ~15 minutos
# Resultado esperado: "✅ All local verification checks passed!"
```

**Qué verifica:**
- ✓ Docker instalado
- ✓ No hay .env files
- ✓ No hay secretos en Dockerfiles
- ✓ Base images tienen versión pinned
- ✓ Dockerfiles se construyen exitosamente
- ✓ No hay secretos en historia de imágenes

**Salida esperada:**
```
════════════════════════════════════════════════════════════════════════════════
AWS ECR Build & Push - Local Verification
════════════════════════════════════════════════════════════════════════════════

[1/5] Checking prerequisites...
✓ Docker is installed
✓ Git is installed
✓ AWS CLI is installed

[2/5] Running security checks...
✓ No .env files in git history
✓ No hardcoded secrets in Dockerfiles
✓ All base images have pinned versions

[3/5] Building Docker images locally...
Building Auth Service...
✓ Auth Service built successfully
  Size: 450MB

Building Frontend Service...
✓ Frontend Service built successfully
  Size: 100MB

Building Website Service...
✓ Website Service built successfully
  Size: 50MB

[4/5] Scanning images for secrets...
✓ No secrets found in image history

[5/5] Summary
════════════════════════════════════════════════════════════════════════════════
✅ All local verification checks passed!
════════════════════════════════════════════════════════════════════════════════

Built Images:
  finansecure-auth:a1b2c3d (450MB)
  finansecure-frontend:a1b2c3d (100MB)
  finansecure-website:a1b2c3d (50MB)
```

### Test 2: Ejecutar Workflow en GitHub

```powershell
# Push cambios si no lo hiciste
git push origin main

# Ir a GitHub
# GitHub → Actions → "Build and Push to AWS ECR"

# Esperar resultado
```

**Monitoreo:**

1. **En GitHub:**
   - Ver workflow ejecutándose
   - Revisar logs en tiempo real

2. **En AWS ECR Console:**
   ```powershell
   # Ver repositorios creados
   aws ecr describe-repositories --region us-east-1
   
   # Ver imágenes
   aws ecr describe-images --repository-name finansecure-auth --region us-east-1
   ```

3. **Resultado esperado después de 40 minutos:**
   ```
   ✅ security-check PASSED
   ✅ build-and-push PASSED
     ├─ Build Auth Service PASSED
     ├─ Build Frontend PASSED
     └─ Build Website PASSED
   ✅ verify-images PASSED
   ✅ build-summary PASSED
   ```

---

## 📊 Validación Visual en GitHub

### Ver workflow en ejecución

```
GitHub → Actions Tab
  ↓
Buscar "Build and Push to AWS ECR"
  ↓
Click en latest run
  ↓
Ver timeline de jobs:
  • security-check (amarillo = en progreso, verde = completado)
  • build-and-push (paralelo con 3 subjobs)
  • verify-images
  • build-summary
```

### Ver detalles de cada job

```
Click en job name
  ↓
Ver steps dentro del job
  ↓
Expandir cada step para ver logs
  ↓
Buscar "✓" o "✅" para confirmación
```

### Ver artefactos generados

```
GitHub → Actions
  ↓
Click en latest run
  ↓
Bajar en página → "Artifacts"
  ↓
Ver: image-manifest.json
  ↓
Click download para obtener file
```

---

## 🔍 Validación en AWS Console

### Ver repositorios ECR

1. **Ir a AWS Console:**
   ```
   https://console.aws.amazon.com/ecr/repositories
   ```

2. **Verificar 3 repositorios existen:**
   - finansecure-auth
   - finansecure-frontend
   - finansecure-website

3. **Para cada repositorio, ver "Images" tab:**
   - Debe haber 3 imágenes (mismo SHA con 3 tags)
   - Tags: `abc1234`, `main`, `20260202-143022`

### Ver detalles de imagen

1. **Click en nombre de repositorio:**
   ```
   finansecure-auth
   ```

2. **Click en "Images" tab:**
   ```
   Ver lista de imágenes
   ```

3. **Click en Image ID:**
   ```
   Ver:
   - Image digest (SHA256)
   - Size
   - Pushed date
   - Tags
   - Scanning status
   ```

### Prueba: Pull imagen localmente

```powershell
# 1. Login a ECR (desde tu máquina con AWS CLI)
aws ecr get-login-password --region us-east-1 | `
  docker login --username AWS --password-stdin `
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# 2. Pull imagen
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:abc1234

# 3. Verificar
docker images | Select-String finansecure-auth
docker run --rm 123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:abc1234

# Resultado esperado: Contenedor inicia exitosamente
```

---

## ❌ Errores Comunes y Soluciones

### Error: "Workflow file not found"

**Síntoma:** GitHub no detecta el workflow

**Causa:** Archivo en ubicación incorrecta

**Solución:**
```powershell
# Verificar ruta
Test-Path ".github/workflows/build-and-push.yml"

# Debe ser exactamente:
# C:\LProyectos\Unir\finansecure-tfe\.github\workflows\build-and-push.yml
```

### Error: "Unable to locate credentials"

**Síntoma:** Workflow falla en AWS authentication

**Causa:** GitHub Secrets no configurados

**Solución:**
```
GitHub → Settings → Secrets
  ↓
Agregar 4 secrets
  ↓
Re-run workflow
```

### Error: "docker build failed"

**Síntoma:** Build job falla

**Causa:** Dockerfile tiene error

**Solución:**
```powershell
# Test local
docker build -f FinanSecure.Auth/Dockerfile -t test .

# Ver error específico
docker build -f FinanSecure.Auth/Dockerfile -t test . --no-cache 2>&1 | Select-Object -Last 20
```

### Error: "Image not found in ECR"

**Síntoma:** Verify step falla

**Causa:** Push no completó

**Solución:**
```powershell
# Ver logs del workflow
# GitHub Actions → job build-and-push → step "Build and Push Auth Service"

# Buscar: "ERROR" o "failed"
# Buscar: "denied" (permiso de ECR)
# Buscar: "push complete" (confirmación)
```

---

## 📋 Resumen de Validación

| Componente | Verificación | Estado |
|-----------|-------------|--------|
| Workflow YAML | Test-Path | ✅ |
| Dockerfiles | Test-Path (3) | ✅ |
| GitHub Secrets | gh secret list | ✅ |
| .env files | git ls-files | ✅ |
| YAML syntax | yamllint | ✅ |
| Secretos en Docker | grep pattern | ✅ |
| Base image versions | grep :latest | ✅ |
| Local builds | verify-ecr-builds.sh | ✅ |
| AWS credentials | aws sts | ✅ |
| Git push | git status | ✅ |
| Workflow execution | GitHub Actions | ✅ |
| ECR repositories | aws ecr describe | ✅ |
| Images in ECR | aws ecr describe-images | ✅ |

---

## ✨ Próximos Pasos después de Validación

1. **Documentar configuración:**
   - Guardar image-manifest.json
   - Guardar logs del workflow
   - Documentar URIs de imágenes

2. **Integrar con deploy:**
   - Crear deploy.yml workflow
   - Configurable de staging → production

3. **Monitorear:**
   - CloudWatch logs
   - Container health checks
   - ECR image vulnerability scanning

4. **Automatizar más:**
   - Deploy automático (opcional)
   - Rollback automation
   - Multi-región support

---

**Documento:** Verification Checklist  
**Versión:** 1.0  
**Fecha:** 2026-02-02  
**Estado:** ✅ Listo para validación
