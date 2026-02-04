# ✅ CHECKLIST DE VERIFICACIÓN - Workflow Simplificado

**Fecha de Generación:** 2 Feb 2026  
**Versión:** 1.0 - Simplificada (Fase 4)

---

## 📋 Checklist Pre-Ejecución

- [ ] Archivo `.github/workflows/build-and-push.yml` existe
- [ ] El workflow contiene solo 1 job: `build-and-push`
- [ ] No hay referencias a `security-check` job
- [ ] No hay referencias a `verify-images` job
- [ ] No hay referencias a `build-summary` job
- [ ] No hay `actions/upload-artifact` en el workflow
- [ ] No hay `actions/download-artifact` en el workflow
- [ ] No hay referencias a `image-manifest`

### Verificar contenido del workflow:

```bash
cd c:\LProyectos\Unir\finansecure-tfe

# Ver el archivo
type .github\workflows\build-and-push.yml

# Confirmar que solo tiene 1 job
findstr /C:"jobs:" .github\workflows\build-and-push.yml | find /C "build-and-push"
# Debe mostrar: 1

# Verificar que NO tiene ciertos jobs
findstr "security-check verify-images build-summary" .github\workflows\build-and-push.yml
# Debe mostrar: 0 resultados
```

---

## 🔐 Checklist de Secretos

### Verificar que los 3 secretos existan en GitHub:

- [ ] `AWS_ACCESS_KEY_ID` configurado
- [ ] `AWS_SECRET_ACCESS_KEY` configurado
- [ ] `AWS_ACCOUNT_ID` configurado

**Cómo verificar:**
1. GitHub.com → tu repo → Settings
2. Secrets and variables → Actions
3. Deberías ver 3 secretos listados

**CLI (si tienes gh instalado):**
```bash
gh secret list
```

Debe mostrar:
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACCOUNT_ID
```

---

## 🐳 Checklist de Dockerfiles

Verifica que los 3 Dockerfiles existen:

- [ ] `FinanSecure.Auth/Dockerfile` existe
- [ ] `finansecure-web/Dockerfile.prod` existe
- [ ] `website/Dockerfile` existe

**Verificar:**
```bash
# Verificar que existen
test -f FinanSecure.Auth\Dockerfile && echo "✅ Auth Dockerfile found" || echo "❌ Not found"
test -f finansecure-web\Dockerfile.prod && echo "✅ Frontend Dockerfile found" || echo "❌ Not found"
test -f website\Dockerfile && echo "✅ Website Dockerfile found" || echo "❌ Not found"
```

---

## 🚀 Checklist de Ejecución

### Antes de hacer push:

- [ ] Código está committed: `git status` debe estar limpio
- [ ] Rama correcta: `git branch` debe mostrar `main` o `*main`
- [ ] Remote correcto: `git remote -v` debe mostrar tu repositorio

```bash
# Verificar estado
git status
git branch
git remote -v
```

### Hacer push:

- [ ] `git push origin main` completado exitosamente
- [ ] GitHub muestra el nuevo commit en la rama main
- [ ] GitHub Actions → Actions → ves el workflow ejecutándose

**Ejecutar:**
```bash
git push origin main
```

---

## 📊 Checklist de Monitoreo

Durante la ejecución (20-25 min):

- [ ] Workflow apareció en GitHub Actions
- [ ] Status: In progress (amarillo)
- [ ] Logs visibles en GitHub Actions
- [ ] Paso 1 (Checkout) completado
- [ ] Paso 2 (Variables) completado
- [ ] Paso 3 (AWS config) completado
- [ ] Paso 4 (ECR login) completado
- [ ] Paso 5 (Set registry) completado
- [ ] Paso 6 (Build Auth) completado (8 min)
- [ ] Paso 7 (Build Frontend) completado (8 min)
- [ ] Paso 8 (Build Website) completado (3 min)
- [ ] Paso 9 (Summary) completado

**Cómo monitorear:**
1. GitHub.com → Actions
2. Ver "Build and Push to AWS ECR"
3. Click en la ejecución más reciente
4. Ver logs en vivo

---

## ✅ Checklist de Finalización

Cuando el workflow se complete:

### En GitHub Actions:
- [ ] Status: ✅ Completed (verde)
- [ ] Duration: 20-25 minutos
- [ ] All steps passed
- [ ] Logs muestran "✅ Build complete"

### En AWS ECR:
- [ ] Repositorio: `finansecure-auth` existe
- [ ] Repositorio: `finansecure-frontend` existe
- [ ] Repositorio: `finansecure-website` existe
- [ ] Cada repo tiene 2 imágenes:
  - [ ] Tag con SHA corto (ej: `a1b2c3d`)
  - [ ] Tag con nombre de rama (ej: `main`)

**Verificar en AWS:**
```bash
# Listar repositorios
aws ecr describe-repositories --region us-east-1

# Ver imágenes de auth
aws ecr describe-images \
  --repository-name finansecure-auth \
  --region us-east-1 \
  --query 'imageDetails[*].[imageTags,imageSizeInBytes]' \
  --output table
```

---

## 🔍 Checklist de Validación de Imágenes

Para cada repositorio, verifica:

### finansecure-auth
- [ ] Imagen con tag `a1b2c3d` existe (SHA corto del último commit)
- [ ] Imagen con tag `main` existe
- [ ] Tamaño es razonable (~200-300 MB)
- [ ] Push date es reciente

### finansecure-frontend
- [ ] Imagen con tag SHA existe
- [ ] Imagen con tag `main` existe
- [ ] Tamaño es razonable (~150-250 MB)
- [ ] Push date es reciente

### finansecure-website
- [ ] Imagen con tag SHA existe
- [ ] Imagen con tag `main` existe
- [ ] Tamaño es razonable (~10-20 MB)
- [ ] Push date es reciente

---

## ❌ Checklist de Problemas Comunes

Si algo falla, verifica:

### Error: "AWS auth failed"
- [ ] `AWS_ACCESS_KEY_ID` está configurado
- [ ] `AWS_SECRET_ACCESS_KEY` está configurado
- [ ] Las claves no tienen espacios extra
- [ ] Las claves son válidas en AWS

### Error: "Dockerfile not found"
- [ ] Ruta en workflow: `./FinanSecure.Auth/Dockerfile`
- [ ] Ruta en workflow: `./finansecure-web/Dockerfile.prod`
- [ ] Ruta en workflow: `./website/Dockerfile`
- [ ] Los archivos existen en esas ubicaciones exactas
- [ ] No hay typos en los nombres

### Error: "ECR login failed"
- [ ] `AWS_ACCOUNT_ID` está correcto
- [ ] Región es `us-east-1`
- [ ] Credenciales de AWS son válidas
- [ ] La cuenta tiene permisos en ECR

### Error: "Build timeout"
- [ ] Timeout es 45 minutos (suficiente)
- [ ] Imágenes no son demasiado grandes
- [ ] Runner tiene suficiente espacio disco
- [ ] No hay proceso bloqueante en Dockerfile

### Error: "Image already exists"
- [ ] Normal - Docker sobrescribe tags
- [ ] Verifica que la nueva imagen se creó

---

## 📈 Checklist de Rendimiento

Después de la ejecución, valida:

- [ ] Tiempo total: 20-25 minutos (si > 30 min, algo está lento)
- [ ] Auth build: ~8 minutos
- [ ] Frontend build: ~8 minutos
- [ ] Website build: ~3 minutos
- [ ] Ningún paso tomó > 15 minutos

Si algo tomó mucho tiempo:
- [ ] Revisa logs para ver dónde se atascó
- [ ] Verifica dependencias de red
- [ ] Comprueba tamaño de Dockerfiles

---

## 🎯 Checklist Final de Éxito

**Si TODOS estos ítems están checked, el workflow es exitoso:**

- ✅ Workflow ejecutado en GitHub Actions
- ✅ Status final: ✅ Completed
- ✅ 3 repositorios en AWS ECR
- ✅ 6 imágenes totales (2 por repo)
- ✅ Tags correctos (SHA + branch)
- ✅ Tamaños razonables
- ✅ Logs limpios sin errores
- ✅ Tiempo dentro de lo esperado

---

## 📋 Resumen Rápido

```
PRE-EJECUCIÓN:
  ✅ Workflow simplificado (1 job)
  ✅ 3 Secretos configurados
  ✅ 3 Dockerfiles existentes
  ✅ Git limpio y en main

DURANTE EJECUCIÓN (20-25 min):
  ✅ Monitorea GitHub Actions
  ✅ Revisa logs en vivo

POST-EJECUCIÓN:
  ✅ Status: ✅ Completed
  ✅ 3 repositorios en ECR
  ✅ 6 imágenes creadas
  ✅ Listo para deployment
```

---

## 🚀 Próximas Acciones

Una vez completado exitosamente:

1. **Anota las URIs de las imágenes:**
   ```
   Auth:     123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:a1b2c3d
   Frontend: 123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-frontend:a1b2c3d
   Website:  123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-website:a1b2c3d
   ```

2. **Usa las imágenes para deployment en EC2**

3. **Actualiza scripts de deployment si es necesario**

4. **Considera agregar security-check en Fase 5**

---

**Checklist versión:** 1.0  
**Fase:** 4 (CI/CD Build + Push)  
**Estado:** ✅ Listo para uso
