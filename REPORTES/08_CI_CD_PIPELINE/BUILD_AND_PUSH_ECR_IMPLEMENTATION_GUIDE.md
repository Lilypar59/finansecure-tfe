# AWS ECR Build & Push Workflow - Guía de Implementación

**Documento:** Configuración de GitHub Actions para build y push a AWS ECR  
**Versión:** 1.0  
**Fecha:** 2026-02-02  
**Autor:** DevOps Engineer  
**Proyecto:** FinanSecure  

---

## 📋 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Requisitos Previos](#requisitos-previos)
3. [Pasos de Implementación](#pasos-de-implementación)
4. [Variables de Entorno (Secrets)](#variables-de-entorno-secrets)
5. [Validación y Testing](#validación-y-testing)
6. [Solución de Problemas](#solución-de-problemas)
7. [Referencias](#referencias)

---

## 📌 Resumen Ejecutivo

### ¿Qué hace este workflow?

El workflow `build-and-push.yml` automatiza el proceso de construir imágenes Docker y publicarlas en AWS ECR cuando se hace push a la rama `main`.

### Características principales

- ✅ **Build automático** de 3 servicios Docker
- ✅ **Push a AWS ECR** con etiquetado inteligente
- ✅ **Seguridad DevSecOps** - validaciones previa al build
- ✅ **Sin secretos expuestos** en logs
- ✅ **Fail-fast** - detiene si algo falla
- ✅ **Verificación de imágenes** post-push
- ✅ **Manifest de deployment** para referencia

### Timeline del workflow

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Security Check (5 min)                                        │
│    ↓                                                              │
│ 2. Build & Push (25 min)                                         │
│    ├─ Setup AWS credentials                                     │
│    ├─ ECR Login                                                 │
│    ├─ Build Auth Service (10 min)                               │
│    ├─ Build Frontend (8 min)                                    │
│    └─ Build Website (7 min)                                     │
│    ↓                                                              │
│ 3. Verify (5 min)                                                │
│    └─ Confirmar imágenes en ECR                                │
│    ↓                                                              │
│ 4. Summary (2 min)                                               │
└─────────────────────────────────────────────────────────────────┘
   Total: ~40 minutos
```

---

## 🔧 Requisitos Previos

### 1. Dockerfiles deben existir en su ubicación

```
✓ FinanSecure.Auth/Dockerfile          (ASP.NET Core 8)
✓ finansecure-web/Dockerfile.prod      (Angular)
✓ website/Dockerfile                   (NGINX - HTML estático)
```

**Verificación:**
```powershell
Test-Path "FinanSecure.Auth/Dockerfile"
Test-Path "finansecure-web/Dockerfile.prod"
Test-Path "website/Dockerfile"
```

### 2. AWS Account y Credenciales

Necesitas:
- AWS Account ID (12 dígitos)
- AWS Access Key ID
- AWS Secret Access Key
- Permisos en ECR (crear repos, push images)

### 3. GitHub Repository (ya completado)

El archivo `.github/workflows/build-and-push.yml` ya existe en el repositorio.

### 4. Docker Compose configurado (opcional pero recomendado)

Para testing local antes de push.

---

## 🚀 Pasos de Implementación

### PASO 1: Configurar GitHub Secrets

Los secrets se usan para mantener credenciales fuera de los logs.

#### 1.1 Ir a GitHub Repository Settings

```
GitHub → Tu Repositorio → Settings → Secrets and variables → Actions
```

#### 1.2 Agregar los siguientes Secrets

| Secret Name | Valor | Donde obtenerlo |
|------------|-------|-----------------|
| `AWS_ACCESS_KEY_ID` | Clave de acceso AWS | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | Clave secreta AWS | AWS IAM Console |
| `AWS_ACCOUNT_ID` | Tu AWS Account ID | AWS Console (top-right) |
| `AWS_REGION` | `us-east-1` | Región donde está tu ECR |

**Instrucciones para obtener credenciales AWS:**

1. Ir a **AWS IAM Console** → Users → Tu usuario
2. Click en **Security Credentials** → **Create access key**
3. Seleccionar **Application running on an AWS compute service**
4. Copiar `Access Key ID` y `Secret Access Key`
5. Guardar en lugar seguro (contraseña manager)

**En GitHub:**
1. Click en **New Repository Secret**
2. Nombre: `AWS_ACCESS_KEY_ID`
3. Valor: Tu Access Key ID
4. Click **Add Secret**
5. Repetir para cada secret

**Screenshot esperado después:**
```
✓ AWS_ACCESS_KEY_ID           [Updated 2 minutes ago]
✓ AWS_SECRET_ACCESS_KEY       [Updated 2 minutes ago]
✓ AWS_ACCOUNT_ID              [Updated 2 minutes ago]
✓ AWS_REGION                  [Updated 2 minutes ago]
```

### PASO 2: Verificar Dockerfiles (Local)

Asegúrate de que los Dockerfiles no tengan secretos hardcodeados:

```bash
# Buscar patrones sospechosos
grep -i "PASSWORD\|SECRET\|TOKEN\|APIKEY\|CHANGE_ME" \
  FinanSecure.Auth/Dockerfile \
  finansecure-web/Dockerfile.prod \
  website/Dockerfile

# Si no hay output, está bien ✓
```

### PASO 3: Verificar .env no esté commiteado

```bash
# Esto DEBE fallar (no encontrar nada)
git ls-files | grep -E "^\.env"

# Si no hay output, está bien ✓
```

### PASO 4: Test Local (Recomendado)

Antes de confiar en CI/CD, prueba localmente:

```bash
# 1. Verificar Docker builds
docker build -f FinanSecure.Auth/Dockerfile -t test-auth .
docker build -f finansecure-web/Dockerfile.prod -t test-frontend ./finansecure-web
docker build -f website/Dockerfile -t test-website ./website

# 2. Verificar no hay secretos en imágenes
docker history test-auth | grep -i "CHANGE_ME" || echo "✓ No secrets found"
```

### PASO 5: Push a GitHub y Trigger Workflow

```bash
# 1. Hacer commit y push a main
git add .
git commit -m "Enable ECR build and push workflow"
git push origin main

# 2. Ver workflow en GitHub
GitHub → Actions → "Build and Push to AWS ECR" → Click en el run
```

**Expected Output:**
```
✓ security-check           PASSED  (5 min)
✓ build-and-push           PASSED  (30 min)
  ├─ Build Auth Service    PASSED  (10 min)
  ├─ Build Frontend        PASSED  (8 min)
  └─ Build Website         PASSED  (7 min)
✓ verify-images            PASSED  (5 min)
✓ build-summary            PASSED  (2 min)
```

---

## 🔐 Variables de Entorno (Secrets)

### Estructura esperada

```yaml
# En GitHub Actions Context
secrets:
  AWS_ACCESS_KEY_ID: "AKIA..."        # 20 caracteres
  AWS_SECRET_ACCESS_KEY: "wJal..."    # 40 caracteres
  AWS_ACCOUNT_ID: "123456789012"      # 12 dígitos
  AWS_REGION: "us-east-1"             # Region AWS
```

### Dónde se usan

1. **AWS Authentication:**
   ```yaml
   - name: Configure AWS credentials
     uses: aws-actions/configure-aws-credentials@v4
     with:
       aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
       aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
   ```

2. **ECR Login:**
   ```yaml
   - name: Login to Amazon ECR
     uses: aws-actions/amazon-ecr-login@v2
   ```

3. **Account ID (para construir URIs):**
   ```yaml
   images:
     auth: "${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ env.AWS_REGION }}.amazonaws.com/finansecure-auth:tag"
   ```

### Validación de Secrets

```bash
# Desde terminal local
aws sts get-caller-identity \
  --access-key-id $AWS_ACCESS_KEY_ID \
  --secret-access-key $AWS_SECRET_ACCESS_KEY

# Salida esperada
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/github-actions"
}
```

---

## ✅ Validación y Testing

### 1. Test de Seguridad Pre-build

El workflow valida automáticamente:

```
✓ No .env files in repository
✓ No hardcoded secrets in Dockerfiles
✓ Base images have pinned versions (not :latest)
✓ AWS credentials are valid
```

### 2. Test de Build

Verifica que los Dockerfiles se construyen:

```
✓ FinanSecure.Auth builds successfully
✓ finansecure-web builds successfully
✓ website builds successfully
```

### 3. Test de Push

Confirma que las imágenes se subieron a ECR:

```
✓ finansecure-auth:abc1234 pushed
✓ finansecure-frontend:abc1234 pushed
✓ finansecure-website:abc1234 pushed
```

### 4. Verificación Manual en AWS

```bash
# Ver repositorios ECR
aws ecr describe-repositories --region us-east-1

# Ver imágenes en un repo
aws ecr describe-images \
  --repository-name finansecure-auth \
  --region us-east-1 \
  --query 'imageDetails[].{Tag:imageTags,Size:imageSizeInBytes,Pushed:imagePushedAt}' \
  --output table

# Resultado esperado
# financesecure-auth | ['abc1234', 'main', '20260202-143022'] | 450MB | 2026-02-02 14:30:22
```

### 5. Test de Artifact

El workflow genera un `image-manifest.json`:

```bash
# Descargar desde GitHub Actions
# GitHub → Actions → Latest Run → Artifacts → image-manifest

# Contenido esperado
{
  "commit_sha_short": "abc1234",
  "branch": "main",
  "images": {
    "auth": "123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:abc1234",
    "frontend": "123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-frontend:abc1234",
    "website": "123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-website:abc1234"
  }
}
```

---

## 🔧 Solución de Problemas

### Error 1: "Unable to locate credentials"

**Síntoma:**
```
Error: Unable to locate credentials
```

**Solución:**
1. Verificar que AWS_ACCESS_KEY_ID está en GitHub Secrets
2. Verificar que AWS_SECRET_ACCESS_KEY está en GitHub Secrets
3. Verificar que las credenciales son válidas localmente:
   ```bash
   aws sts get-caller-identity
   ```

### Error 2: "Repository not found"

**Síntoma:**
```
Error: ImageNotFound: Requested image not found
```

**Solución:**
El workflow crea el repositorio automáticamente, pero si falla:
```bash
# Crear manualmente
aws ecr create-repository \
  --repository-name finansecure-auth \
  --region us-east-1 \
  --image-scanning-configuration scanOnPush=true
```

### Error 3: "Hardcoded secrets in Dockerfile"

**Síntoma:**
```
Found potential secret in FinanSecure.Auth/Dockerfile
```

**Solución:**
Remover secretos del Dockerfile. Usar:
- Variables de entorno en runtime
- AWS Secrets Manager
- GitHub Secrets (no en Docker images)

### Error 4: "docker build fails"

**Síntoma:**
```
Step X/Y: ERROR: ...
```

**Solución:**
1. Test local:
   ```bash
   docker build -f FinanSecure.Auth/Dockerfile -t test .
   docker run test --version
   ```
2. Revisar output del workflow en GitHub Actions
3. Verificar Dockerfile está sintácticamente correcto

### Error 5: "Base image :latest tag"

**Síntoma:**
```
Found :latest tag in Dockerfile - must use specific version
```

**Solución:**
Cambiar en Dockerfile:
```dockerfile
# ❌ Antes
FROM mcr.microsoft.com/dotnet/aspnet:latest

# ✅ Después
FROM mcr.microsoft.com/dotnet/aspnet:8.0
```

---

## 📊 Monitoreo y Logs

### Ver logs del workflow

1. **GitHub Actions UI:**
   ```
   GitHub → Actions → Build and Push to AWS ECR → [Latest Run]
   ```

2. **Por terminal:**
   ```bash
   # Descargar logs (requiere GitHub CLI)
   gh run view [run-id] --log > workflow.log
   ```

3. **En los logs buscar:**
   ```
   "✓ Auth Service image pushed successfully"
   "✓ Frontend Service image pushed successfully"
   "✓ Website Service image pushed successfully"
   ```

### Métricas a monitorear

| Métrica | Ideal | Alerta |
|---------|-------|--------|
| Tiempo total | < 45 min | > 60 min |
| Build time Auth | < 12 min | > 15 min |
| Build time Frontend | < 10 min | > 12 min |
| Build time Website | < 8 min | > 10 min |
| Push time | < 5 min | > 10 min |
| Image size Auth | < 600 MB | > 800 MB |
| Image size Frontend | < 100 MB | > 150 MB |
| Image size Website | < 50 MB | > 75 MB |

---

## 🎯 Próximos Pasos

Una vez que el workflow funcione:

1. ✅ **Workflow de Deploy:** Crear `deploy.yml` para EC2
2. ✅ **Monitoring:** Configurar CloudWatch para las imágenes
3. ✅ **Security:** Habilitar ECR image scanning automático
4. ✅ **Rollback:** Implementar estrategia de rollback

### Deploy a EC2 (Próximo paso)

```bash
# En tu instancia EC2
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# Pull de la imagen
docker pull 123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:abc1234

# Run del contenedor
docker run -d \
  --name finansecure-auth \
  -p 5000:5000 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:abc1234
```

---

## 📚 Referencias

### Documentación Oficial

- [GitHub Actions - AWS Setup](https://github.com/aws-actions/configure-aws-credentials)
- [AWS ECR - Docker Push](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html)
- [Docker Buildx - Advanced Builds](https://docs.docker.com/build/buildx/)

### Archivos Relacionados

- `.github/workflows/build-and-push.yml` - Este workflow
- `.github/workflows/ci.yml` - Workflow de CI (testing)
- `FinanSecure.Auth/Dockerfile` - Dockerfile de Auth
- `finansecure-web/Dockerfile.prod` - Dockerfile Frontend
- `website/Dockerfile` - Dockerfile Website

### Scripts de Ayuda

```bash
# Limpiar imágenes locales
docker image prune -a --force

# Ver tamaño de imágenes
docker images --format "table {{.Repository}}\t{{.Size}}"

# Test local de build
docker build -f FinanSecure.Auth/Dockerfile --no-cache -t test:latest .
```

---

## ✨ Checklist Final

- [ ] GitHub Secrets configurados (4 secrets)
- [ ] Dockerfiles sin secretos hardcodeados
- [ ] .env no está commiteado
- [ ] Workflow build-and-push.yml existe
- [ ] Push a main dispara el workflow
- [ ] Imágenes aparecen en AWS ECR
- [ ] Imágenes tienen 3 tags (SHA, branch, timestamp)
- [ ] Logs no muestran secretos

---

**Documento versión:** 1.0  
**Última actualización:** 2026-02-02  
**Estado:** ✅ Implementación lista para producción
