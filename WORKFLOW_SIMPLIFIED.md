# GitHub Actions Workflow - Versión Simplificada

## Resumen

El workflow de GitHub Actions ha sido simplificado para cumplir con los requisitos de **CI/CD Fase 4**.

### ✅ Cambios Realizados

**Eliminado:**
- ❌ `security-check` job (validaciones pre-build)
- ❌ `verify-images` job (verificación en ECR)
- ❌ `build-summary` job (notificaciones)
- ❌ Artifact uploads/downloads (`image-manifest.json`)
- ❌ SLSA provenance
- ❌ Docker BuildKit cache
- ❌ Escaneos de seguridad

**Mantenido:**
- ✅ Trigger en `main` branch solamente
- ✅ AWS credentials configuration
- ✅ ECR login
- ✅ Build de 3 servicios (Auth, Frontend, Website)
- ✅ Push a ECR con tags: `short_sha` y `branch_name`

---

## Estructura del Workflow

```
build-and-push (single job)
├── Checkout code
├── Set build variables (SHA, branch, timestamp)
├── Configure AWS credentials
├── Login to Amazon ECR
├── Set ECR registry
├── Build and Push Auth Service
├── Build and Push Frontend Service
├── Build and Push Website Service
└── Summary
```

---

## Requisitos Previos

### GitHub Secrets (OBLIGATORIO)
Debes configurar 3 secrets en tu repositorio:

```
AWS_ACCESS_KEY_ID          → Tu access key de AWS
AWS_SECRET_ACCESS_KEY      → Tu secret key de AWS
AWS_ACCOUNT_ID             → Tu account ID (ej: 123456789012)
```

**Cómo agregar:**
1. GitHub → Settings → Secrets and variables → Actions
2. Click en "New repository secret"
3. Agrega los 3 secrets

---

## Ejecución

### Trigger Automático
```bash
git push origin main
```
El workflow se ejecuta automáticamente.

### Trigger Manual
En GitHub: Actions → "Build and Push to AWS ECR" → "Run workflow"

---

## Tiempo de Ejecución

- **Total:** ~20-25 minutos
- Checkout: ~1 min
- AWS config + ECR login: ~1 min
- Build Auth: ~8 min
- Build Frontend: ~8 min
- Build Website: ~3 min

---

## Resultado

### Imágenes en ECR

Después de completarse, encontrarás 3 repositorios en AWS ECR:

```
finansecure-auth:<SHORT_SHA>           → última build
finansecure-auth:main                   → rama actual

finansecure-frontend:<SHORT_SHA>        → última build
finansecure-frontend:main               → rama actual

finansecure-website:<SHORT_SHA>         → última build
finansecure-website:main                → rama actual
```

**Ejemplo:**
```
483412.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:a1b2c3d
483412.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:main
```

---

## Verificación en AWS

### CLI
```bash
aws ecr describe-images \
  --repository-name finansecure-auth \
  --region us-east-1
```

### Console
https://console.aws.amazon.com/ecr/repositories/

---

## Solución de Problemas

| Problema | Causa | Solución |
|----------|-------|----------|
| ❌ AWS auth failed | Secrets no configurados | Agregar 3 secrets en GitHub |
| ❌ Dockerfile not found | Ruta incorrecta | Verificar paths en workflow |
| ❌ ECR login failed | Account ID inválido | Confirmar AWS_ACCOUNT_ID |
| ❌ Build timeout | Imagen muy grande | Revisar Dockerfile |

---

## Próximos Pasos

1. ✅ Configura los 3 GitHub Secrets
2. ✅ Push a main: `git push origin main`
3. ✅ Monitorea: GitHub → Actions
4. ✅ Verifica en AWS ECR Console
5. ⏭️ Usa las imágenes para deployment en EC2

---

**Última actualización:** 2 Feb 2026
**Estado:** ✅ Producción - Fase 4
