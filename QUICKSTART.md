# ⚡ INICIO RÁPIDO - Ejecuta el Workflow Ahora

## 1️⃣ Commit y Push (1 minuto)

```powershell
cd C:\LProyectos\Unir\finansecure-tfe

# Ver cambios
git status

# Agregar cambios
git add .github/workflows/build-and-push.yml

# Commit
git commit -m "simplify: remove artifacts from workflow - phase 4"

# Push
git push origin main
```

---

## 2️⃣ Configura GitHub Secrets (2 minutos)

### En tu navegador:
1. Ve a: **GitHub.com** → tu repositorio
2. **Settings** → **Secrets and variables** → **Actions**
3. Click en **"New repository secret"**

### Agrega estos 3 secrets:

#### Secret 1: `AWS_ACCESS_KEY_ID`
```
Value: <tu access key de AWS>
Ejemplo: AKIAIOSFODNN7EXAMPLE
```

#### Secret 2: `AWS_SECRET_ACCESS_KEY`
```
Value: <tu secret access key de AWS>
Ejemplo: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

#### Secret 3: `AWS_ACCOUNT_ID`
```
Value: <tu AWS account ID>
Ejemplo: 123456789012
```

---

## 3️⃣ Monitorea la Ejecución (20-25 minutos)

### Ver el workflow:

1. **GitHub.com** → tu repo → **Actions**
2. Click en el workflow: **"Build and Push to AWS ECR"**
3. Ver logs en vivo

### Tiempo esperado:
```
Checkout        ~1 min
AWS Config      ~1 min
Build Auth      ~8 min
Build Frontend  ~8 min
Build Website   ~3 min
Total           ~20-25 min
```

---

## 4️⃣ Verifica las Imágenes en AWS ECR (2 minutos)

### Opción A: AWS Console
1. Ve a: https://console.aws.amazon.com/ecr/
2. Selecciona región: **us-east-1**
3. Deberías ver 3 repositorios:
   - `finansecure-auth`
   - `finansecure-frontend`
   - `finansecure-website`

### Opción B: AWS CLI
```powershell
# Listar repos
aws ecr describe-repositories --region us-east-1

# Ver imágenes del auth service
aws ecr describe-images `
  --repository-name finansecure-auth `
  --region us-east-1
```

---

## ✅ Verificación Exitosa

Si todo funciona, deberías ver:

### En GitHub Actions:
```
✅ build-and-push job completed successfully
✅ 3 images pushed to ECR
✅ Execution time: 20-25 minutes
```

### En AWS ECR:
```
Repository: finansecure-auth
├── Image: a1b2c3d (short SHA)
└── Image: main (branch)

Repository: finansecure-frontend
├── Image: a1b2c3d
└── Image: main

Repository: finansecure-website
├── Image: a1b2c3d
└── Image: main
```

### Ejemplo de URIs:
```
123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:a1b2c3d
123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-frontend:a1b2c3d
123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-website:a1b2c3d
```

---

## ❌ Si Algo Falla

### Error: "AWS auth failed"
```
❌ Causa: Secrets no configurados correctamente
✅ Solución: Verifica que los 3 secrets están en GitHub
✅ Verificar que los valores son exactos (sin espacios)
```

### Error: "Dockerfile not found"
```
❌ Causa: Path incorrecto en workflow
✅ Solución: Verifica paths en .github/workflows/build-and-push.yml
```

### Error: "ECR login failed"
```
❌ Causa: AWS_ACCOUNT_ID inválido
✅ Solución: Verifica tu AWS Account ID en AWS Console
```

### Logs completos:
GitHub → Actions → [tu workflow] → [tu ejecución] → Logs

---

## 📋 Checklist Final

- [ ] Commit y push completado
- [ ] 3 secrets configurados en GitHub
- [ ] Workflow iniciado (visible en Actions)
- [ ] Workflow completado sin errores
- [ ] 3 repositorios visibles en ECR
- [ ] 6 imágenes creadas (2 por repo: SHA + main)

---

## 🎯 Próximas Acciones

Una vez que el workflow se complete exitosamente:

1. **Toma nota de las URIs de las imágenes** (necesarias para deployment)
2. **Actualiza tu deployment script** si es necesario
3. **Deploy a EC2** usando estas imágenes

Ejemplo de uso:
```bash
docker run -d \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:a1b2c3d
```

---

**¿Necesitas ayuda?** Revisa:
- `WORKFLOW_SIMPLIFIED.md` - Guía completa
- `WORKFLOW_BEFORE_AFTER.md` - Comparación detallada
- `WORKFLOW_CHANGES_SUMMARY.md` - Resumen de cambios
