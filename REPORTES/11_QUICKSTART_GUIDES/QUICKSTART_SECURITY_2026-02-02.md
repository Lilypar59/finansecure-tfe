# 🚀 QUICK START - Lo que debes hacer AHORA

**Tiempo:** 10-15 minutos  
**Objetivo:** Implementar cambios de seguridad y levantar servicios

---

## 📋 PASO 1: Preparar Scripts (2 min)

```bash
# Terminal - en la raíz del proyecto
chmod +x generate-secrets.sh
chmod +x setup-dev-env.sh  
chmod +x security-check.sh

# Verificar que son ejecutables
ls -la *.sh
# -rwxr-xr-x  (tienen x)
```

---

## 🔐 PASO 2: Generar Secretos (3 min)

```bash
# Ejecutar script de generación
./generate-secrets.sh

# Output esperado:
# ════════════════════════════════════════
# 🔐 FinanSecure - Generar Secretos Seguros
# ════════════════════════════════════════
# 
# 🔑 Generando secretos...
#   ✅ JWT_SECRET_KEY (256 bits)...
#   ✅ AUTH_DB_PASSWORD (192 bits base64)...
#   ✅ PGADMIN_PASSWORD...
# 
# ✅ Secretos generados
# 📝 Archivo .env creado
# ✅ CONFIGURACIÓN COMPLETADA
```

**Resultado:** Se creó `.env` con valores únicos y seguros

```bash
# Verificar que existe .env
cat .env
# Verás las variables con valores generados
```

---

## ✅ PASO 3: Validar Seguridad (2 min)

```bash
# Ejecutar validación
./security-check.sh

# Output esperado:
# 1️⃣ Checking appsettings.json... ✅ PASS
# 2️⃣ Checking .gitignore... ✅ PASS
# 3️⃣ Checking docker-compose.yml... ✅ PASS
# 4️⃣ Checking .env.template... ✅ PASS
# 5️⃣ Checking .dockerignore... ✅ PASS
# 6️⃣ Checking .env permissions... ✅ PASS
# 7️⃣ Checking Git history... ✅ PASS
#
# ✅ SECURITY CHECK PASSED
# ✅ Listo para CI/CD deployment
```

**IMPORTANTE:** Si algo falla, ve a la sección "TROUBLESHOOTING" al final

---

## 🐳 PASO 4: Levantar Servicios (3 min)

```bash
# Opción A: Manual (si todo está OK)
docker compose up -d

# Opción B: Automático (RECOMENDADO - maneja todo)
./setup-dev-env.sh
# Esto hace: valida, genera secretos, levanta, valida servicios

# Esperar ~30 segundos a que servicios sean healthy
sleep 30

# Verificar estado
docker compose ps
```

**Output esperado:**

```
NAME                        STATUS
finansecure-postgres-auth   healthy ✅
finansecure-auth            healthy ✅
finansecure-frontend        healthy ✅
finansecure-website         healthy ✅
finansecure-pgadmin         healthy ✅
```

---

## 🎯 PASO 5: Verificar que Funciona (2 min)

```bash
# Frontend (NGINX)
curl http://localhost
# <html>... ✅

# Auth API Health
curl http://localhost:8080/health
# {"status":"healthy"} ✅

# Website
curl http://localhost:3000
# <html>... ✅

# O abrir en navegador:
# http://localhost (Frontend)
# http://localhost:3000 (Website)
# http://localhost:5050 (PgAdmin)
```

---

## 📊 PASO 6: Ver Logs (Opcional)

```bash
# Ver logs de Auth service
docker compose logs -f finansecure-auth

# Ver logs de todos
docker compose logs -f

# Ver logs de PostgreSQL
docker compose logs -f postgres-auth

# Salir: Ctrl+C
```

---

## 🔍 PASO 7: Verificar Estructura (Opcional)

```bash
# Ver qué archivos se crearon/modificaron
git status

# Verás:
# Modified files:
#   ✅ FinanSecure.Auth/appsettings.json
#   ✅ FinanSecure.Auth/Program.cs
#   ✅ docker-compose.yml
#   ✅ .dockerignore
# 
# Untracked files:
#   ✅ .env.template (para commitear)
#   ✅ generate-secrets.sh (para commitear)
#   ✅ setup-dev-env.sh (para commitear)
#   ✅ security-check.sh (para commitear)
#   ✅ IMPLEMENTATION_GUIDE_2026-02-02.md
#   ✅ CHANGES_SUMMARY_2026-02-02.md
#   
#   ⚠️ .env (NO en git - en .gitignore) ✅
```

---

## 💾 PASO 8: Commitear Cambios (Opcional - si estás listo)

```bash
# Revisar cambios
git diff FinanSecure.Auth/appsettings.json
git diff docker-compose.yml

# Agregar nuevos archivos (scripts y templates)
git add .env.template generate-secrets.sh setup-dev-env.sh security-check.sh

# Agregar cambios en código
git add FinanSecure.Auth/appsettings.json FinanSecure.Auth/Program.cs docker-compose.yml

# Revisar qué va a commitarse
git status

# Hacer commit
git commit -m "🔐 Security: Harden secrets management

- Remove hardcoded secrets from appsettings.json
- Add environment variable validation in Program.cs
- Replace unsafe fallbacks in docker-compose.yml
- Add .env.template for configuration
- Add generate-secrets.sh for secure key generation
- Add setup-dev-env.sh for automated setup
- Add security-check.sh for pre-deployment validation
- Update .dockerignore to exclude sensitive files

Score: 3.5/10 → 8.5/10 security improvement"

# Ver commit
git log -1 --stat
```

---

## 🐛 TROUBLESHOOTING

### ❌ Error: openssl not found

```bash
# Windows (Git Bash)
# Ya debería estar disponible en Git Bash
# Si no: instalar OpenSSL for Windows

# macOS
brew install openssl

# Linux
sudo apt-get install openssl
```

### ❌ Error: docker compose fails

```bash
# Verificar que Docker está corriendo
docker ps

# Si .env fue deletado
./generate-secrets.sh

# Limpiar volúmenes (CUIDADO - borra datos locales)
docker compose down -v
docker compose up -d
```

### ❌ Error: security-check.sh fails

```bash
# Ver qué check específico falla
./security-check.sh

# Revisar el audit report
cat SECURITY_AUDIT_LOCAL_2026-02-02.md

# Ejemplos de fixes:
# 1. Si falta .env.template:
#    → Ya debería existir, hacer git pull

# 2. Si appsettings.json aún tiene secretos:
#    → Verificar que fue actualizado: git status

# 3. Si .gitignore no tiene .env:
#    → Verificar que está en .gitignore: grep "^\.env$" .gitignore
```

### ❌ Error: servicios no están healthy

```bash
# Ver estado detallado
docker compose ps

# Ver logs del servicio que falla
docker compose logs finansecure-auth

# Buscar errores específicos
docker compose logs finansecure-auth | grep -i error

# Ejemplo: si Auth Service falla con env vars:
# ← Error: Jwt:SecretKey is not configured
# Fix: ./generate-secrets.sh
#      docker compose down && docker compose up -d
```

### ❌ Error: Port already in use

```bash
# Ver qué está usando puerto 80
sudo lsof -i :80

# Opción 1: Matar el proceso
kill -9 <PID>

# Opción 2: Cambiar puertos en docker-compose.yml
# FRONTEND_PORT: 8000  (en lugar de 80)

# Opción 3: Detener otro contenedor
docker stop <container_name>
```

### ⚠️ Warning: Permission denied on scripts

```bash
# Hacer ejecutables
chmod +x generate-secrets.sh setup-dev-env.sh security-check.sh

# En Windows (PowerShell):
# Get-ChildItem *.sh | % { $_.FullName }
# (scripts deberían funcionar en Git Bash)
```

---

## ✨ ¿LISTO?

Si completaste todo arriba:

```bash
# Verificar servicios
docker compose ps

# Verificar seguridad
./security-check.sh

# Todo está ✅?
echo "✅ Ready for development!"
```

---

## 📞 RESUMEN

| Paso | Comando | Tiempo | Output |
|------|---------|--------|--------|
| 1 | `chmod +x *.sh` | 1m | Ejecutables listos |
| 2 | `./generate-secrets.sh` | 2m | .env creado con secretos |
| 3 | `./security-check.sh` | 1m | Todos los checks pasan ✅ |
| 4 | `docker compose up -d` | 5m | Servicios healthy |
| 5 | `curl http://localhost` | 1m | 200 OK |
| **TOTAL** | | **10m** | **Stack running ✅** |

---

## 📚 PRÓXIMOS PASOS

1. **Hoy:**
   - Ejecutar los 5 pasos arriba
   - Testear que todo funciona

2. **Esta semana:**
   - Reviewar archivos modificados
   - Hacer commit a develop
   - Documentar para otros devs

3. **Antes de IR A PRODUCCIÓN:**
   - Crear GitHub Secrets
   - Crear GitHub Actions workflow
   - Configurar AWS
   - Hacer test de deployment

---

**¡Adelante! 🚀**
