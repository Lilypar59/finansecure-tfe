# 🔐 SECURITY ARCHITECTURE - Diagrama de flujos

---

## 📊 FLUJO 1: DESARROLLO LOCAL

```
┌─────────────────────────────────────────────────────────────────────┐
│ DEVELOPER MACHINE                                                   │
└─────────────────────────────────────────────────────────────────────┘

  1. git clone repo
         │
         ▼
  ┌─────────────────────────┐
  │ .env.template (en repo) │  ← Plantilla sin secretos
  │ - JWT_SECRET_KEY=CHANGE │
  │ - AUTH_DB_PASSWORD=CHG  │
  │ - PGADMIN_PASSWORD=CHG  │
  └─────────────────────────┘
         │
         ▼
  2. ./generate-secrets.sh
         │
         ├─→ openssl rand -hex 32     ← JWT_SECRET_KEY (256 bits)
         ├─→ openssl rand -base64 24  ← AUTH_DB_PASSWORD (192 bits)
         └─→ openssl rand -base64 18  ← PGADMIN_PASSWORD
         │
         ▼
  ┌─────────────────────────┐
  │ .env (LOCAL ONLY)       │
  │ - JWT_SECRET_KEY=abc... │
  │ - AUTH_DB_PASSWORD=xyz  │
  │ - PGADMIN_PASSWORD=123  │
  │                         │
  │ 🔒 chmod 600           │
  │ 🚫 En .gitignore       │
  └─────────────────────────┘
         │
         ▼
  3. docker compose up -d
         │
         ├─→ Lee .env (env file)
         │
         ▼
  ┌─────────────────────────────────────────────────────────┐
  │ CONTENEDORES                                            │
  ├─────────────────────────────────────────────────────────┤
  │                                                         │
  │  postgres-auth                                          │
  │  ├─ POSTGRES_PASSWORD=${AUTH_DB_PASSWORD}  ✓ (de .env) │
  │  │                                                     │
  │  └─→ postgres:15-alpine                               │
  │                                                         │
  │  finansecure-auth                                       │
  │  ├─ ConnectionStrings__DefaultConnection=...           │
  │  │  Password=${AUTH_DB_PASSWORD}  ✓ (de .env)         │
  │  │                                                     │
  │  ├─ JwtSettings__SecretKey=${JWT_SECRET_KEY} ✓         │
  │  │                                                     │
  │  └─→ Program.cs ValidateEnvironmentVariables()        │
  │      ├─ if (JWT_SECRET_KEY == null) throw Exception  │
  │      ├─ if (ConnectionString == null) throw Exception│
  │      └─ Falla EN STARTUP si faltan vars              │
  │                                                         │
  │  finansecure-frontend (NGINX)                           │
  │  └─→ Sirve Angular SPA + proxy a /api → auth service  │
  │                                                         │
  │  finansecure-website (static)                           │
  │  └─→ Sirve contenido HTML/CSS/JS                      │
  │                                                         │
  │  pgadmin                                                │
  │  └─→ Gestión visual de PostgreSQL                     │
  │                                                         │
  └─────────────────────────────────────────────────────────┘
         │
         ▼
  4. Todos servicios HEALTHY ✅


PUNTOS CRÍTICOS DE SEGURIDAD:
✓ .env generado con openssl (criptográficamente seguro)
✓ .env NO va al repo (.gitignore)
✓ docker-compose.yml sin secrets hardcodeados
✓ appsettings.json valores null (carga desde env)
✓ Program.cs valida env vars en startup (fail fast)
✓ Fallbacks no funcionales (CHANGE_ME) - obliga .env
```

---

## 📊 FLUJO 2: VALIDACIÓN PRE-DEPLOYMENT

```
┌─────────────────────────────────────────────────────────────────────┐
│ ./security-check.sh (PRE-DEPLOYMENT)                                │
└─────────────────────────────────────────────────────────────────────┘

  START
    │
    ▼
  ┌─────────────────────────────────┐
  │ 1. Check appsettings.json       │
  │    Busca: Password= (no null)   │
  │    ❌ Si tiene hardcoded        │
  │    ✅ Si está null              │
  └─────────────────────────────────┘
    │
    ▼
  ┌─────────────────────────────────┐
  │ 2. Check .gitignore             │
  │    Busca: ^\.env$               │
  │    ❌ Si no está                │
  │    ✅ Si está                   │
  └─────────────────────────────────┘
    │
    ▼
  ┌─────────────────────────────────┐
  │ 3. Check docker-compose.yml     │
  │    Busca: SecureAuth2024        │
  │    ❌ Si tiene hardcoded        │
  │    ✅ Si usa CHANGE_ME fallback │
  └─────────────────────────────────┘
    │
    ▼
  ┌─────────────────────────────────┐
  │ 4. Check .env.template          │
  │    Existe? ✅                   │
  │    Tiene CHANGE_ME? ✅          │
  └─────────────────────────────────┘
    │
    ▼
  ┌─────────────────────────────────┐
  │ 5. Check .dockerignore          │
  │    Excluye .env? ✅             │
  │    Excluye appsettings? ✅      │
  └─────────────────────────────────┘
    │
    ▼
  ┌─────────────────────────────────┐
  │ 6. Check .env permisos          │
  │    chmod 600? ✅                │
  │    Solo owner puede leer? ✅    │
  └─────────────────────────────────┘
    │
    ▼
  ┌─────────────────────────────────┐
  │ 7. Check Git history            │
  │    Busca: SecureAuth2024        │
  │    En commits? ❌               │
  │    Historia limpia? ✅          │
  └─────────────────────────────────┘
    │
    ▼
  ┌─────────────────────────────────┐
  │ RESULTADO                       │
  ├─────────────────────────────────┤
  │ Todos OK?                       │
  │ exit code = 0 ✅               │
  │ "Ready for deployment"          │
  │                                 │
  │ Alguno falla?                   │
  │ exit code = 1 ❌               │
  │ "Fix errors before deploy"      │
  └─────────────────────────────────┘
```

---

## 📊 FLUJO 3: VERSIONING & GIT

```
┌─────────────────────────────────────────────────────────────────────┐
│ GIT REPOSITORY                                                      │
└─────────────────────────────────────────────────────────────────────┘

  REPO ROOT (what gets committed)
  │
  ├─ appsettings.json ✅
  │  └─ "DefaultConnection": null
  │     (valores null, carga desde env)
  │
  ├─ appsettings.json.example ✅
  │  └─ Estructura correcta sin secretos
  │
  ├─ .env.template ✅
  │  └─ Plantilla con estructura completa
  │
  ├─ docker-compose.yml ✅
  │  └─ ${VAR:-CHANGE_ME} fallbacks
  │
  ├─ generate-secrets.sh ✅
  │  └─ Script para generar claves
  │
  ├─ setup-dev-env.sh ✅
  │  └─ Script de setup automático
  │
  ├─ security-check.sh ✅
  │  └─ Validación pre-deployment
  │
  ├─ .gitignore ✅
  │  ├─ .env
  │  ├─ .env.*
  │  └─ appsettings.*.json
  │
  └─ Program.cs ✅
     └─ ValidateEnvironmentVariables()
        └─ Valida en startup


  LOCAL .git (NO commiteado)
  │
  └─ .env ❌ NUNCA
     ├─ JWT_SECRET_KEY=abc...
     ├─ AUTH_DB_PASSWORD=xyz...
     └─ En .gitignore ✓


  PUSHED TO GITHUB:
  ✅ Plantillas (template)
  ✅ Scripts (ejecutables)
  ✅ Código limpio (sin secrets)
  ❌ .env NUNCA


PROTECCIÓN:
- Si alguien accidentally hace git add .env
  → Git lo rechaza (.gitignore)
- Si .env llegó a quedar commiteado
  → ./security-check.sh lo detecta
  → bfg --delete-files .env (limpiar historial)
```

---

## 📊 FLUJO 4: DIFERENCIAS - ANTES vs DESPUÉS

```
┌─────────────────────────────────────────────────────────────────────┐
│ ANTES (VULNERABLE ❌)                                               │
└─────────────────────────────────────────────────────────────────────┘

  appsettings.json
  {
    "ConnectionStrings": {
      "DefaultConnection": "Host=...;Password=SecureAuth2024!;"  ❌
    },
    "Jwt": {
      "SecretKey": "your-super-secret-key..."  ❌
    }
  }
  │
  ├─→ En repo (commiteado)
  ├─→ Secretos expuestos
  ├─→ Cualquiera con acceso al repo ve las contraseñas
  └─→ Si alguien clona la rama, tiene los secrets

  docker-compose.yml
  ConnectionStrings__DefaultConnection: "...Password=${AUTH_DB_PASSWORD:-SecureAuth2024!};"  ❌
  │
  ├─→ Fallback funcional
  ├─→ Si no hay .env, usa contraseña real
  ├─→ No obliga a developer a configurar
  └─→ Contraseña por defecto en el código


┌─────────────────────────────────────────────────────────────────────┐
│ DESPUÉS (SEGURO ✅)                                                 │
└─────────────────────────────────────────────────────────────────────┘

  appsettings.json
  {
    "ConnectionStrings": {
      "DefaultConnection": null  ✅
    },
    "Jwt": {
      "SecretKey": null  ✅
    }
  }
  │
  ├─→ En repo (commiteado)
  ├─→ Sin secretos expuestos
  ├─→ Valores null, carga desde env vars
  └─→ Seguro para compartir

  .env.template (en repo)
  JWT_SECRET_KEY=CHANGE_ME_MIN_32_CHARS  ✅
  AUTH_DB_PASSWORD=CHANGE_ME_SECURE      ✅
  │
  ├─→ Documentación para setup
  ├─→ Sin secretos reales
  ├─→ Cada dev genera los suyos
  └─→ Reproducible y seguro

  .env (LOCAL, NO EN REPO) ✅
  JWT_SECRET_KEY=abc123...  (generado con openssl)
  AUTH_DB_PASSWORD=xyz789...
  │
  ├─→ En .gitignore
  ├─→ Secretos únicos para ese dev
  ├─→ chmod 600 (solo propietario)
  └─→ Jamás va al repo

  docker-compose.yml
  ConnectionStrings__DefaultConnection: "...Password=${AUTH_DB_PASSWORD:-CHANGE_ME_IN_ENV_FILE};"  ✅
  │
  ├─→ Fallback NO funcional
  ├─→ Si no hay .env, falla con error claro
  ├─→ Obliga a developer a configurar
  └─→ No hay defaults inseguros

  Program.cs (validador)
  if (jwt_secret == null || jwt_secret.StartsWith("CHANGE_ME"))
    throw new Exception("JWT_SECRET_KEY not configured");  ✅
  │
  ├─→ Falla en STARTUP
  ├─→ No en runtime (fail fast)
  ├─→ Mensaje claro de qué falta
  └─→ Previene deployments rotos


RESULTADO:
  Antes: Cualquiera con acceso al repo puede ver las contraseñas ❌
  Después: Secretos únicos por dev, generados localmente, jamás en repo ✅
```

---

## 📊 FLUJO 5: CI/CD (FUTURO)

```
┌─────────────────────────────────────────────────────────────────────┐
│ GITHUB (PUSH A REPO)                                                │
└─────────────────────────────────────────────────────────────────────┘

  CODE PUSH
    │
    ├─ appsettings.json (null values) ✅
    ├─ docker-compose.yml (no secrets) ✅
    ├─ Program.cs (validador) ✅
    └─ NO .env ✅
    │
    ▼
  ┌─────────────────────────────────┐
  │ GITHUB ACTIONS WORKFLOW         │
  │ .github/workflows/deploy.yml    │
  └─────────────────────────────────┘
    │
    ├─ Checkout code
    │
    ├─ dotnet build
    │  └─ USA: variables de entorno de GitHub Secrets
    │
    ├─ docker build
    │  └─ build de imágenes (sin secretos)
    │
    ├─ AWS Login (OIDC)
    │  └─ Sin usar Access Keys (más seguro)
    │
    ├─ docker push ECR
    │  └─ Pushear imagen a AWS Elastic Container Registry
    │
    ▼
  ┌─────────────────────────────────┐
  │ AWS SERVICES                    │
  ├─────────────────────────────────┤
  │                                 │
  │ ECR (imagen en repositorio)     │
  │ Secrets Manager (credenciales)  │
  │ ECS Task (correr contenedores)  │
  │                                 │
  │ En runtime:                     │
  │ ECS → Lee Secrets Manager       │
  │       → Pasa variables de env   │
  │       → Corre app con secretos  │
  │                                 │
  └─────────────────────────────────┘


SEGURIDAD EN CI/CD:
✓ GitHub Secrets (almacenados seguros)
✓ No hay secrets en el código
✓ No hay secrets en logs de build
✓ AWS OIDC (sin access keys)
✓ AWS Secrets Manager (rotación automática)
✓ Variables de env en runtime (nunca en imagen)
```

---

## 🔐 RESUMEN VISUAL

```
┌──────────────────────────────────────────────────────────────────┐
│ ARQUITECTURA DE SEGURIDAD - FinanSecure 2026                     │
└──────────────────────────────────────────────────────────────────┘

NIVEL 1: REPOSITORIO (GitHub)
├─ 🟢 Código limpio (SIN secrets)
├─ 🟢 Plantillas (.env.template)
├─ 🟢 Scripts (generate-secrets.sh)
├─ 🟢 Validadores (security-check.sh)
└─ 🔒 .gitignore protege .env

NIVEL 2: DESARROLLO LOCAL
├─ 🔐 .env generado con openssl (único por dev)
├─ 🔒 chmod 600 (solo propietario)
├─ 🚫 NO en repo (en .gitignore)
└─ 📦 docker-compose lee de .env

NIVEL 3: CONFIGURACIÓN
├─ ✅ appsettings.json (null values)
├─ ✅ docker-compose.yml (vars de env)
├─ ✅ .dockerignore (excluye secrets)
└─ ✅ Program.cs (valida en startup)

NIVEL 4: VALIDACIÓN
├─ 🛡️ security-check.sh (7 checks)
├─ 🛡️ Git history scanning
├─ 🛡️ Fail-fast en startup
└─ 🛡️ Exit code indica status

NIVEL 5: CI/CD (Futuro)
├─ GitHub Secrets (almacenados)
├─ AWS OIDC (sin keys)
├─ Secrets Manager (rotación)
└─ ECS runtime env vars


FLUJO DE CONFIANZA:
Dev Clone → Generate → Check → Build → Push → Deploy → Run
   │           │         │       │       │        │      │
   └─ .env     └─ openssl└─ 7 checks ─ No secrets ─ AWS Secrets
```

---

**Arquitectura de Seguridad Completada ✅**
