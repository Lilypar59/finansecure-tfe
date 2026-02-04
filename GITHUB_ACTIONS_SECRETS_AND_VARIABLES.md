# 🔐 SECRETOS Y VARIABLES - GitHub Actions Pipeline

## 📋 RESUMEN EJECUTIVO

El pipeline `build-and-push.yml` requiere:
- **2 Secretos** (credenciales AWS)
- **1 Variable** (región AWS)

---

## 🔑 SECRETOS REQUERIDOS

### 1. `AWS_ACCESS_KEY_ID`

**Descripción:** ID de la clave de acceso de AWS  
**Tipo:** Secreto (encriptado en GitHub)  
**Dónde se usa:**
```yaml
- name: Configure AWS credentials
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
```

**Cómo obtenerlo:**

1. Ve a **AWS Console** → **IAM** → **Users**
2. Selecciona tu usuario (o crea uno nuevo)
3. **Access keys** → **Create access key**
4. Copia el valor de **Access Key ID**
   ```
   AKIAIOSFODNN7EXAMPLE
   ```

**Restricciones recomendadas:**
```
Servicio: EC2 Container Registry (ECR)
Permisos:
  - ecr:BatchGetImage
  - ecr:GetDownloadUrlForLayer
  - ecr:PutImage
  - ecr:InitiateLayerUpload
  - ecr:UploadLayerPart
  - ecr:CompleteLayerUpload
  - ecr:DescribeRepositories
```

**⚠️ SEGURIDAD:**
- ❌ Nunca lo commits en el código
- ❌ Nunca lo pongas en plain text
- ✅ Guárdalo en GitHub Secrets
- ✅ Rótalo cada 90 días

---

### 2. `AWS_SECRET_ACCESS_KEY`

**Descripción:** Clave secreta de acceso de AWS  
**Tipo:** Secreto (encriptado en GitHub)  
**Dónde se usa:**
```yaml
- name: Configure AWS credentials
  with:
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

**Cómo obtenerlo:**

1. **AWS Console** → **IAM** → **Users**
2. **Access keys** → **Create access key**
3. Copia el valor de **Secret Access Key**
   ```
   wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   ```

**⚠️ IMPORTANTE:**
- Esta es la ÚNICA vez que ves esta clave
- Descárgala o cópiala AHORA
- Si la pierdes, debes crear una nueva access key

**Restricciones recomendadas:** Igual que `AWS_ACCESS_KEY_ID`

---

## 🌍 VARIABLES DE ENTORNO

### `AWS_REGION`

**Descripción:** Región de AWS donde están los recursos (ECR)  
**Tipo:** Variable de entorno (no encriptada, visible)  
**Dónde se usa:**
```yaml
env:
  AWS_REGION: us-east-1
```

**Valores comunes:**
| Región | Código | Ubicación |
|--------|--------|-----------|
| N. Virginia | `us-east-1` | Este USA |
| Ohio | `us-east-2` | Medio USA |
| N. California | `us-west-1` | Oeste USA |
| Oregon | `us-west-2` | Noroeste USA |
| Irlanda | `eu-west-1` | Europa |
| Fráncfort | `eu-central-1` | Centro Europa |
| Sídney | `ap-southeast-2` | Asia-Pacífico |

**Cómo verificar tu región:**
```bash
# En AWS Console
1. Mira esquina superior derecha → Región actual
2. O ve a AWS CloudShell y ejecuta:
   aws sts get-caller-identity

   # Output incluye:
   "Region": "us-east-1"
```

---

## 📝 CONFIGURACIÓN EN GITHUB

### Paso 1: Ir a Repository Settings

```
GitHub → Tu Repositorio → Settings
```

### Paso 2: Crear Secretos

**Ruta:** Settings → Secrets and variables → Actions

```
1. Click "New repository secret"
2. Name: AWS_ACCESS_KEY_ID
   Secret: (pega tu AWS_ACCESS_KEY_ID)
   Click "Add secret"

3. Click "New repository secret" nuevamente
4. Name: AWS_SECRET_ACCESS_KEY
   Secret: (pega tu AWS_SECRET_ACCESS_KEY)
   Click "Add secret"
```

**Resultado esperado:**
```
✓ AWS_ACCESS_KEY_ID
✓ AWS_SECRET_ACCESS_KEY
```

### Paso 3: Configurar Variables (opcional pero recomendado)

**Ruta:** Settings → Secrets and variables → Variables

```
1. Click "New repository variable"
2. Name: AWS_REGION
   Value: us-east-1
   Click "Add variable"
```

**O deja el valor hardcodeado en el YAML** (actual):
```yaml
env:
  AWS_REGION: us-east-1
```

---

## 📐 VARIABLES AUTOMÁTICAS DE GITHUB (no necesitas configurar)

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `github.sha` | `a1b2c3d4e5f6...` | Commit SHA completo (40 caracteres) |
| `github.ref_name` | `main` o `develop` | Rama actual |
| `github.ref` | `refs/heads/main` | Referencia Git completa |
| `github.event_name` | `push` | Tipo de evento que trigger el workflow |

**Cómo se usan en el pipeline:**
```yaml
- name: Set build variables
  run: |
    SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)
    BRANCH_NAME=${{ github.ref_name }}
    TIMESTAMP=$(date -u +'%Y%m%d-%H%M%S')
    
    echo "short_sha=${SHORT_SHA}" >> $GITHUB_OUTPUT
    echo "branch_name=${BRANCH_NAME}" >> $GITHUB_OUTPUT
    echo "timestamp=${TIMESTAMP}" >> $GITHUB_OUTPUT
```

**Resultado de estas variables:**
```
short_sha: a1b2c3d  (primeros 7 caracteres del SHA)
branch_name: main
timestamp: 20260203-143022
```

---

## 🎯 FLUJO COMPLETO DE VARIABLES

```
1. Usuario hace: git push origin main

2. GitHub Actions detecta:
   - github.sha = "a1b2c3d4e5f6..."
   - github.ref_name = "main"

3. Pipeline obtiene secretos de GitHub:
   - secrets.AWS_ACCESS_KEY_ID
   - secrets.AWS_SECRET_ACCESS_KEY

4. Pipeline usa variables:
   - env.AWS_REGION = "us-east-1"

5. Pipeline construye tags:
   - finansecure-auth:a1b2c3d
   - finansecure-auth:main
   - finansecure-frontend:a1b2c3d
   - finansecure-frontend:main
   - finansecure-website:a1b2c3d
   - finansecure-website:main

6. Empuja a ECR:
   123456789.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:a1b2c3d
   123456789.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:main
   (y los demás servicios)
```

---

## 🔍 VERIFICACIÓN

### ¿Cómo verificar que todo está configurado?

1. **Ve a tu repositorio en GitHub**
2. **Settings → Secrets and variables → Actions**
3. Deberías ver:
   ```
   ✓ AWS_ACCESS_KEY_ID (updated 3 hours ago)
   ✓ AWS_SECRET_ACCESS_KEY (updated 3 hours ago)
   ✓ AWS_REGION (updated 3 hours ago)
   ```

4. **Haz un push** a la rama main:
   ```bash
   git add .
   git commit -m "test: Trigger pipeline"
   git push origin main
   ```

5. **Ve a GitHub → Actions** y mira el workflow ejecutarse

---

## 🧪 TESTING DEL PIPELINE

### Opción 1: Trigger manual (workflow_dispatch)

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch:  ← Permite ejecutar manualmente
```

**Pasos:**
1. GitHub → Actions
2. Click "Build and Push to AWS ECR"
3. Click "Run workflow"
4. Click "Run workflow" (confirmar)

### Opción 2: Push a la rama main

```bash
git push origin main
```

El workflow se ejecutará automáticamente.

---

## ❌ ERRORES COMUNES

### Error: "Access Denied to AWS ECR"

```
Error: Access Denied (Service: AmazonECR)
```

**Causa:** Credenciales AWS insuficientes o inválidas

**Solución:**
1. Verifica que AWS_ACCESS_KEY_ID y AWS_SECRET_ACCESS_KEY sean correctos
2. Verifica permisos en AWS IAM (debe tener acceso a ECR)
3. Verifica que los repositorios ECR existan:
   ```bash
   aws ecr describe-repositories --region us-east-1
   ```

### Error: "Secrets not found"

```
Error: Unexpected input 'secrets', valid inputs are ['action', 'input']
```

**Causa:** Secreto no está configurado en GitHub

**Solución:**
1. Ve a Settings → Secrets and variables → Actions
2. Verifica que `AWS_ACCESS_KEY_ID` existe
3. Verifica que `AWS_SECRET_ACCESS_KEY` existe
4. Si no existen, créalos

### Error: "Repository not found in ECR"

```
Error: ImageNotFound: Requested image not found
```

**Causa:** ECR repository no existe en AWS

**Solución:** Crea los repositorios en ECR:
```bash
aws ecr create-repository \
  --repository-name finansecure-auth \
  --region us-east-1

aws ecr create-repository \
  --repository-name finansecure-frontend \
  --region us-east-1

aws ecr create-repository \
  --repository-name finansecure-website \
  --region us-east-1
```

---

## 📊 CHECKLIST DE CONFIGURACIÓN

- [ ] Crear Access Key en AWS IAM
- [ ] Copiar `AWS_ACCESS_KEY_ID`
- [ ] Copiar `AWS_SECRET_ACCESS_KEY`
- [ ] Ir a GitHub Settings → Secrets and variables → Actions
- [ ] Crear secreto: `AWS_ACCESS_KEY_ID`
- [ ] Crear secreto: `AWS_SECRET_ACCESS_KEY`
- [ ] Verificar variable: `AWS_REGION` (o dejar hardcodeada)
- [ ] Crear repositorios ECR en AWS (si no existen)
- [ ] Hacer un push a main
- [ ] Monitorear Actions tab
- [ ] Verificar que las imágenes llegaron a ECR

---

## 🔒 SEGURIDAD

### Mejores prácticas:

1. **Rotar credenciales regularmente**
   - AWS recomienda cada 90 días
   - GitHub te notifica si detecta exposición

2. **Usar IAM roles si es posible**
   - Mejor que Access Keys en producción
   - Usa `aws-actions/configure-aws-credentials@v4` con role ARN

3. **Limitar permisos**
   - Solo ECR, no todos los servicios
   - Crear IAM policy específica

4. **Monitorear logs**
   - Revisar GitHub Actions logs
   - Revisar AWS CloudTrail

5. **No compartir secretos**
   - Nunca en Slack, email, etc.
   - Si se exponen, rótaos inmediatamente

---

## 📚 REFERENCIAS

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [AWS IAM Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/latest/userguide/)
- [docker/build-push-action](https://github.com/docker/build-push-action)

---

**Documento:** Secretos y Variables - GitHub Actions Pipeline  
**Fecha:** 3 Febrero 2026  
**Estado:** ✅ Completo
