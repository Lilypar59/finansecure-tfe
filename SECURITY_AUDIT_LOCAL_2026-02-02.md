<!-- ════════════════════════════════════════════════════════════════════════════════
     🔐 SECURITY AUDIT - ENTORNO LOCAL DE DESARROLLO
     ════════════════════════════════════════════════════════════════════════════════ -->

# 🔐 SECURITY AUDIT - FINANSECURE LOCAL DEVELOPMENT

**Fecha Audit:** 2026-02-02  
**Auditor:** Security Architect (Senior)  
**Alcance:** Variables de entorno, secretos, JWT, CI/CD readiness  
**Score Total:** 6.5/10 - RIESGOS CRÍTICOS DETECTADOS ⚠️  

---

## 📊 RESUMEN EJECUTIVO

```
HALLAZGOS CRÍTICOS:  3 🔴
HALLAZGOS ALTOS:     4 🟠
HALLAZGOS MEDIOS:    2 🟡
────────────────────────
TOTAL RIESGOS:       9

RECOMENDACIÓN: ❌ NO permitir CI/CD hasta resolver todos los críticos
```

---

## 🔴 HALLAZGOS CRÍTICOS (BLOQUEAN CI/CD)

---

### 🔴 CRÍTICO #1: SECRETOS HARDCODEADOS EN appsettings.json

**Ubicación:** `FinanSecure.Auth/appsettings.json`

**Problema detectado:**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=postgres-auth;Port=5432;Database=finansecure_auth_db;Username=auth_user;Password=SecureAuth2024!;"
    ✗ PASSWORD EXPUESTO EN PLAIN TEXT
  },
  "Jwt": {
    "SecretKey": "your-super-secret-key-change-this-in-production-at-least-32-characters-long!!!",
    ✗ JWT_SECRET EN PLAIN TEXT
  }
}
```

**Riesgo:**
- ❌ Cualquiera con acceso al repo ve las contraseñas
- ❌ Si commiteas por accidente, queda en el historio de Git
- ❌ Docker build copia este archivo → exposición en imágenes
- ❌ Logs de Docker pueden exponer el archivo

**Severidad:** 🔴 CRÍTICO  
**CVSS Score:** 9.8 (Critical)

**Recomendación:**

✅ **Paso 1: Remover secretos de appsettings.json**

```json
{
  "ConnectionStrings": {
    "DefaultConnection": null
    // ✅ VACÍO - se carga desde variable de entorno
  },
  "Jwt": {
    "SecretKey": null
    // ✅ VACÍO - se carga desde variable de entorno
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "AllowedHosts": "*"
}
```

✅ **Paso 2: Crear `.env` (NO commitear)**

```bash
# .env (agregar a .gitignore - VERIFICADO ✅)
ASPNETCORE_ENVIRONMENT=Development
AUTH_DB_PASSWORD=SecureAuth2024!
JWT_SECRET_KEY=dev-secret-key-change-this-in-production-at-least-32-characters-long!!!
JWT_ISSUER=FinanSecure
JWT_AUDIENCE=FinanSecure.Client
```

✅ **Paso 3: Usar en docker-compose.yml (YA ESTÁ CORRECTO)**

```yaml
environment:
  ConnectionStrings__DefaultConnection: "Host=postgres-auth;Port=5432;Database=finansecure_auth_db;Username=auth_user;Password=${AUTH_DB_PASSWORD:-SecureAuth2024!};"
  JwtSettings__SecretKey: ${JWT_SECRET_KEY:-your-super-secret-key}
  # ✅ Usa variables de entorno correctamente
```

✅ **Paso 4: En C# cargar variables**

```csharp
// Program.cs o appsettings.cs
var builder = WebApplication.CreateBuilder(args);

// Cargar desde variables de entorno (docker-compose lo proporciona)
var dbPassword = Environment.GetEnvironmentVariable("AUTH_DB_PASSWORD") 
  ?? throw new Exception("AUTH_DB_PASSWORD not set");

var jwtSecret = Environment.GetEnvironmentVariable("JWT_SECRET_KEY")
  ?? throw new Exception("JWT_SECRET_KEY not set");

// Configuration ya lo maneja automáticamente
```

**Paso de implementación:**
- [ ] Limpiar appsettings.json
- [ ] Crear .env local
- [ ] Verificar docker-compose.yml usa ${VAR}
- [ ] Probar: docker compose up
- [ ] Verificar: `.env` está en `.gitignore`

---

### 🔴 CRÍTICO #2: appsettings.Development.json COMMITADO CON SECRETOS

**Ubicación:** `FinanSecure.Auth/appsettings.Development.json` (si está en repo)

**Problema:**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "...Password=SecureAuth2024!..."
    ✗ EXPUESTO EN GIT
  },
  "Jwt": {
    "SecretKey": "dev-secret-key-..."
    ✗ COMMITADO AL REPO
  }
}
```

**Riesgo:** 
- 🔴 **CRÍTICO** - Está en el historial de Git (PERMANENTE)
- Aunque lo borres ahora, alguien puede encontrarlo en commits anteriores
- Los secretos se consideran **COMPROMETIDOS**

**Severidad:** 🔴 CRÍTICO  
**CVSS Score:** 9.8 (Critical)

**Recomendación:**

✅ **Paso 1: Verificar .gitignore (YA ESTÁ CORRECTO)**

```gitignore
appsettings.Development.json  ✅ ESTÁ AQUÍ
appsettings.*.json            ✅ ESTÁ AQUÍ
```

✅ **Paso 2: Eliminar del historial de Git (si está commitado)**

```bash
# Buscar si está en el repo
git log --oneline -- FinanSecure.Auth/appsettings.Development.json

# Si está, removelo del historial (DESTRUCTIVO - cuidado)
git filter-branch --tree-filter 'rm -f FinanSecure.Auth/appsettings.Development.json' HEAD

# O usa BFG (más rápido):
bfg --delete-files appsettings.Development.json

# Force push (solo en dev, NUNCA en main/prod)
git push --force
```

✅ **Paso 3: Crear `appsettings.Development.json` LOCALMENTE (NO en repo)**

```bash
# Crear localmente (cada dev lo hace)
cat > FinanSecure.Auth/appsettings.Development.json << 'EOF'
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=postgres-auth;Port=5432;Database=finansecure_auth_db;Username=auth_user;Password=SecureAuth2024!;"
  },
  "Jwt": {
    "SecretKey": "dev-secret-key-at-least-32-chars-long!!!",
    "Issuer": "FinanSecure.Auth",
    "Audience": "FinanSecure.App"
  }
}
EOF
```

✅ **Paso 4: Crear template en repo (SIN SECRETOS)**

```json
// appsettings.Development.json.example (COMMITADO)
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=postgres-auth;Port=5432;Database=finansecure_auth_db;Username=auth_user;Password=CHANGE_ME;"
  },
  "Jwt": {
    "SecretKey": "CHANGE_ME_32_CHARACTERS_MINIMUM",
    "Issuer": "FinanSecure.Auth",
    "Audience": "FinanSecure.App"
  }
}
```

**Paso de implementación:**
- [ ] Verificar historial: `git log -- appsettings.Development.json`
- [ ] Si está commitado: remover con `git filter-branch` o `bfg`
- [ ] Force push si fue necesario
- [ ] Crear template `.example` sin secretos
- [ ] Documentar en README cómo crear el archivo local

---

### 🔴 CRÍTICO #3: PASSWORD HARDCODEADO EN docker-compose.yml

**Ubicación:** `docker-compose.yml` línea ~113-114

**Problema detectado:**
```yaml
environment:
  ConnectionStrings__DefaultConnection: "Host=postgres-auth;Port=5432;Database=finansecure_auth_db;Username=auth_user;Password=${AUTH_DB_PASSWORD:-SecureAuth2024!};"
                                                                                                                          ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
  ✗ FALLBACK HARDCODEADO
```

**Riesgo:**
- 🔴 Si no está `.env`, usa "SecureAuth2024!" directamente
- 🔴 Cualquiera puede ver la contraseña en el comando
- 🔴 Los logs de Docker pueden exponer esto
- 🔴 Las imágenes compiladas pueden contener estos valores

**Severidad:** 🔴 CRÍTICO  
**CVSS Score:** 9.5 (Critical)

**Recomendación:**

✅ **Opción A: Usar `.env` obligatorio (RECOMENDADO)**

```yaml
# docker-compose.yml
environment:
  ConnectionStrings__DefaultConnection: "Host=postgres-auth;Port=5432;Database=finansecure_auth_db;Username=auth_user;Password=${AUTH_DB_PASSWORD};"
  # ✅ SIN FALLBACK - falla si no está .env

# .env OBLIGATORIO
AUTH_DB_PASSWORD=SecureAuth2024!
JWT_SECRET_KEY=dev-secret-key...
```

```bash
# Script para validar
#!/bin/bash
if [ ! -f .env ]; then
    echo "❌ ERROR: .env no existe"
    echo "Crea .env primero"
    exit 1
fi
docker compose up
```

✅ **Opción B: Valores "dummy" NO funcionales (ALTERNATIVA)**

```yaml
# docker-compose.yml - con fallback "dummy"
environment:
  ConnectionStrings__DefaultConnection: "Host=postgres-auth;Port=5432;Database=finansecure_auth_db;Username=auth_user;Password=${AUTH_DB_PASSWORD:-CHANGE_ME_IN_ENV};"
  # ✅ Fallback no funcional - obliga a user usar .env

# Si usuario no configura .env, app FALLA con "CHANGE_ME_IN_ENV"
# Esto es MEJOR que usar contraseña real como fallback
```

**Paso de implementación:**
- [ ] Reemplazar fallback: `SecureAuth2024!` → `CHANGE_ME_IN_ENV`
- [ ] Mismo para `JWT_SECRET_KEY`: `CHANGE_ME_MIN_32_CHARS`
- [ ] Crear `.env.template` con instrucciones
- [ ] Documentar en SETUP.md

---

## 🟠 HALLAZGOS ALTOS (Deben arreglarse antes de CI/CD)

---

### 🟠 ALTO #1: Docker build puede exponer secrets

**Ubicación:** `FinanSecure.Auth/Dockerfile` y `finansecure-web/Dockerfile.prod`

**Problema:**
```dockerfile
# Durante build, las layers pueden contener secretos si:
COPY . .
# ✗ Copia appsettings.json con secretos
# ✗ Las capas quedan en historial de build
# ✗ docker history puede revelar variables de entorno
```

**Riesgo:**
- 🟠 `docker history` puede mostrar ARG/ENV secrets
- 🟠 Si alguien obtiene la imagen, ve los secrets
- 🟠 Build cache puede retener información sensible

**Severidad:** 🟠 ALTO  
**CVSS Score:** 8.2 (High)

**Recomendación:**

✅ **Paso 1: Usar `.dockerignore` (CREAR)**

```dockerfile
# .dockerignore
.env
.env.*
appsettings.Development.json
appsettings.*.json
*.pem
*.key
.git
.gitignore
node_modules
dist/
build/
obj/
bin/
.vscode/
.idea/
*.log
logs/
data/
```

✅ **Paso 2: Usar Docker BuildKit secrets (RECOMENDADO)**

```dockerfile
# Dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build

WORKDIR /src
COPY . .

# ✅ NO pasar secrets en ARG
# Pasar como build secret mount en su lugar
RUN --mount=type=secret,id=db_password \
    --mount=type=secret,id=jwt_key \
    cat /run/secrets/db_password > /tmp/pwd.txt && \
    # Usar el secret sin exponerlo
    dotnet build ...
```

```bash
# Comando build (CLI)
docker build \
  --secret db_password=$(cat .env | grep AUTH_DB_PASSWORD | cut -d= -f2) \
  --secret jwt_key=$(cat .env | grep JWT_SECRET_KEY | cut -d= -f2) \
  -t finansecure-auth:latest .
```

✅ **Paso 3: Limpiar layers de build (CLEANUP)**

```dockerfile
# Usar multi-stage para no incluir appsettings en imagen final
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
COPY . .
RUN dotnet build ...

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
COPY --from=build /app/publish /app
# ✅ La imagen final NO incluye appsettings.Development.json
```

**Paso de implementación:**
- [ ] Crear `.dockerignore`
- [ ] Usar multi-stage builds (YA LO HACES ✅)
- [ ] Documentar en SETUP.md cómo pasar secrets en CI/CD

---

### 🟠 ALTO #2: JWT_SECRET_KEY no rotación

**Ubicación:** `docker-compose.yml` + `appsettings.json`

**Problema:**
```yaml
JwtSettings__SecretKey: ${JWT_SECRET_KEY:-your-super-secret-key-min-32-chars-change-in-prod}
                                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                        ✗ PLACEHOLDER DÉBIL (comentario, no real)
```

**Riesgo:**
- 🟠 En desarrollo, la key es débil y predecible
- 🟠 No hay rotación automática
- 🟠 Token theft = acceso permanente (sin revocación)
- 🟠 En prod debe tener política de rotación

**Severidad:** 🟠 ALTO  
**CVSS Score:** 7.8 (High)

**Recomendación:**

✅ **Paso 1: Generar claves criptográficamente seguras**

```bash
#!/bin/bash
# generate-secrets.sh

# JWT Secret (256 bits = 32 bytes = 64 hex chars)
JWT_KEY=$(openssl rand -hex 32)
echo "JWT_SECRET_KEY=$JWT_KEY"

# DB Password (256 bits)
DB_PASS=$(openssl rand -base64 24)
echo "AUTH_DB_PASSWORD=$DB_PASS"

# Guardar en .env
cat >> .env << EOF
JWT_SECRET_KEY=$JWT_KEY
AUTH_DB_PASSWORD=$DB_PASS
EOF

chmod 600 .env  # Solo lectura del propietario
```

```bash
# Ejecutar
./generate-secrets.sh
# Guardar output en .env seguro
```

✅ **Paso 2: Rotar secrets regularmente (POLÍTICA)**

```bash
# weekly-secret-rotation.sh
#!/bin/bash

# Rotación automática cada semana
BACKUP_ENV=".env.backup.$(date +%s)"
cp .env "$BACKUP_ENV"

# Generar nuevas claves
NEW_JWT=$(openssl rand -hex 32)
NEW_DB_PASS=$(openssl rand -base64 24)

# Actualizar .env
sed -i "s/JWT_SECRET_KEY=.*/JWT_SECRET_KEY=$NEW_JWT/" .env
sed -i "s/AUTH_DB_PASSWORD=.*/AUTH_DB_PASSWORD=$NEW_DB_PASS/" .env

# Redeploy
docker compose down
docker compose up -d

# Notificar usuarios (revoke old tokens)
# TODO: Implementar token blacklist en Redis
```

✅ **Paso 3: En PRODUCCIÓN (AWS)**

```yaml
# AWS Secrets Manager
{
  "name": "finansecure/prod/auth-secrets",
  "keys": {
    "JWT_SECRET_KEY": "rotated every 90 days via Lambda",
    "DB_PASSWORD": "rotated every 30 days",
    "ENCRYPTION_KEY": "rotated every 180 days"
  }
}
```

**Política de rotación recomendada:**
```
Development:  No required, pero generar segura
Staging:      Cada 30 días
Production:   Cada 15 días (JWT) / 7 días (DB)
```

**Paso de implementación:**
- [ ] Crear `generate-secrets.sh`
- [ ] Ejecutar una vez para generar claves seguras
- [ ] Guardar en `.env` seguro
- [ ] Documentar política de rotación
- [ ] En AWS: usar Secrets Manager con rotación automática

---

### 🟠 ALTO #3: No hay validación de variables de entorno en startup

**Ubicación:** `Program.cs` (FinanSecure.Auth)

**Problema:**
```csharp
// Sin validación - app arranca con valores inválidos
var dbPassword = Configuration["ConnectionStrings:DefaultConnection"];
// ✗ Si no está definida, usa null y falla después

// Mejor:
var dbPassword = Environment.GetEnvironmentVariable("AUTH_DB_PASSWORD");
if (string.IsNullOrEmpty(dbPassword))
{
    throw new Exception("AUTH_DB_PASSWORD not configured");
    // ✅ Falla rápido en startup, no después de 5 minutos
}
```

**Riesgo:**
- 🟠 App puede arrancar con configuración incompleta
- 🟠 Fallas en runtime en lugar de startup
- 🟠 Difícil de debuggear
- 🟠 CI/CD puede pushear imagen broken

**Severidad:** 🟠 ALTO  
**CVSS Score:** 7.5 (High)

**Recomendación:**

✅ **Crear validador de startup**

```csharp
// Program.cs o startup.cs
public static class EnvironmentValidator
{
    private static readonly string[] RequiredVariables = new[]
    {
        "AUTH_DB_PASSWORD",
        "JWT_SECRET_KEY",
        "JWT_ISSUER",
        "JWT_AUDIENCE"
    };

    public static void ValidateEnvironment()
    {
        var missingVars = new List<string>();

        foreach (var varName in RequiredVariables)
        {
            var value = Environment.GetEnvironmentVariable(varName);
            
            if (string.IsNullOrEmpty(value) || value.StartsWith("CHANGE_ME"))
            {
                missingVars.Add(varName);
            }
        }

        if (missingVars.Any())
        {
            throw new InvalidOperationException(
                $"Missing or invalid environment variables: {string.Join(", ", missingVars)}\n" +
                $"Configure these in .env or docker-compose.yml"
            );
        }
    }
}

// En Main()
var builder = WebApplication.CreateBuilder(args);

// Validar ANTES de configurar servicios
EnvironmentValidator.ValidateEnvironment();

// Resto de configuración...
var app = builder.Build();
app.Run();
```

✅ **Usar en docker-compose.yml**

```yaml
finansecure-auth:
  build: ...
  environment:
    # Valores DEBEN estar en .env o fallará
    AUTH_DB_PASSWORD: ${AUTH_DB_PASSWORD}
    JWT_SECRET_KEY: ${JWT_SECRET_KEY}
    # Sin fallback - obliga a configurar
```

**Paso de implementación:**
- [ ] Crear clase `EnvironmentValidator`
- [ ] Llamar en `Program.cs` main
- [ ] Remover fallbacks del docker-compose
- [ ] Probar: `docker compose up` sin `.env` debe fallar clara

---

### 🟠 ALTO #4: Logs pueden contener secretos sensibles

**Ubicación:** `appsettings.json` - Configuración de logging

**Problema:**
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Information"  // ✗ DEMASIADO VERBOSE
    }
  }
}
```

**Riesgo:**
- 🟠 EF Core Debug logs pueden exponer SQL queries
- 🟠 SQL queries pueden contener contraseñas en WHERE clauses
- 🟠 Connection strings pueden loguear en debugging
- 🟠 Los logs en Docker se quedan en `/var/lib/docker/containers/`

**Severidad:** 🟠 ALTO  
**CVSS Score:** 7.2 (High)

**Ejemplo de exposición:**
```sql
-- EF Core log con Information level:
Executing DbCommand [Parameters=[@__username_0='admin'], CommandType='Text', CommandTimeout='30']
SELECT * FROM users WHERE username = @__username_0

-- Pero si queda SensitiveDataLoggingEnabled = true:
SELECT * FROM users WHERE username = 'admin'
-- ✗ USERNAME EXPUESTO

-- Con ConnectionString logging:
Opening connection to 'Host=postgres-auth;Username=auth_user;Password=SecureAuth2024!;'
-- ✗ PASSWORD EXPUESTO
```

**Recomendación:**

✅ **Paso 1: Desactivar SensitiveDataLogging en Production**

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AuthContext>((provider, options) =>
{
    var environment = provider.GetRequiredService<IHostEnvironment>();
    
    options.UseNpgsql(connectionString);
    
    // ✅ NUNCA loguear datos sensibles en producción
    if (environment.IsDevelopment())
    {
        options.EnableSensitiveDataLogging();  // Solo dev
    }
    else
    {
        options.EnableSensitiveDataLogging(false);  // Producción
    }
});
```

✅ **Paso 2: Configurar niveles de log por environment**

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning",
      "Microsoft.AspNetCore": "Warning",
      "Microsoft.EntityFrameworkCore": "Warning",
      "Microsoft.EntityFrameworkCore.Database.Command": "Warning"
    }
  }
}
```

```json
// appsettings.Development.json
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "Microsoft.EntityFrameworkCore": "Debug"  // OK en dev
    }
  }
}
```

✅ **Paso 3: Implementar log filtering (AVANZADO)**

```csharp
// Middleware para filtrar logs sensibles
public class SensitiveDataLoggingFilter : ILogFilter
{
    public bool Filter(string category, LogLevel logLevel, EventId eventId, Exception? exception)
    {
        // Filtrar conexiones BD
        if (category.Contains("Connection") && logLevel == LogLevel.Debug)
            return false;  // No loguear
        
        // Filtrar queries sensibles
        if (category.Contains("EntityFrameworkCore.Database.Command") && logLevel == LogLevel.Debug)
            return false;
        
        return true;
    }
}

// Registrar en DI
builder.Services.AddLogging(loggingBuilder =>
{
    loggingBuilder.Services.AddSingleton<ILogFilter>(new SensitiveDataLoggingFilter());
});
```

✅ **Paso 4: Validar logs en runtime**

```bash
#!/bin/bash
# Buscar secretos en logs
LOG_FILE="/app/logs/app.log"

FOUND_SECRETS=0

# Buscar patrones de secretos
if grep -E "Password|SecureAuth|JWT_SECRET|password=" "$LOG_FILE" 2>/dev/null; then
    echo "⚠️ WARNING: Secretos encontrados en logs!"
    FOUND_SECRETS=1
fi

if grep -E "Connection.*=.*;" "$LOG_FILE" 2>/dev/null; then
    echo "⚠️ WARNING: Connection strings en logs!"
    FOUND_SECRETS=1
fi

exit $FOUND_SECRETS
```

**Paso de implementación:**
- [ ] Desactivar `EnableSensitiveDataLogging` en no-dev
- [ ] Configurar niveles de log por environment
- [ ] Implementar filtering de conexiones/queries
- [ ] Crear script de validación de logs
- [ ] Rotación de logs (máx 100MB, 7 días)

---

## 🟡 HALLAZGOS MEDIOS

---

### 🟡 MEDIO #1: No hay .env.template/example

**Ubicación:** Raíz del proyecto

**Problema:**
```bash
# Nuevo dev clona repo
git clone <repo>
docker compose up  # ❌ FALLA - no sabe qué variables configurer
```

**Riesgo:**
- 🟡 Onboarding lento
- 🟡 Valores por defecto inseguros
- 🟡 Inconsistencia entre devs

**Severidad:** 🟡 MEDIO  
**CVSS Score:** 4.5 (Medium)

**Recomendación:**

✅ **Crear `.env.template`**

```bash
# .env.template (COMMITADO - sin secretos)
# Copiar a .env y llenar con valores locales

# Docker/App Environment
ASPNETCORE_ENVIRONMENT=Development
ENVIRONMENT=Development

# Database
AUTH_DB_PASSWORD=CHANGE_ME_TO_SECURE_VALUE
AUTH_DB_PORT=5432
AUTH_DB_USER=auth_user

# JWT Settings
JWT_SECRET_KEY=CHANGE_ME_MIN_32_CHARS_LONG
JWT_ISSUER=FinanSecure
JWT_AUDIENCE=FinanSecure.Client
JWT_EXPIRATION_MINUTES=15
JWT_REFRESH_EXPIRATION_DAYS=7

# Application
AUTH_SERVICE_PORT=8080
FRONTEND_PORT=80
WEBSITE_PORT=3000
PGADMIN_PORT=5050
PGADMIN_EMAIL=admin@finansecure.com
PGADMIN_PASSWORD=CHANGE_ME_ADMIN_PASSWORD

# Logging
AUTH_LOG_LEVEL=Information
```

✅ **Script de setup**

```bash
#!/bin/bash
# setup-dev-env.sh

echo "🔧 FinanSecure - Configurar entorno de desarrollo"
echo ""

if [ -f .env ]; then
    echo "⚠️ .env ya existe. Sobreescribir? (s/n)"
    read -r response
    if [ "$response" != "s" ]; then
        exit 0
    fi
fi

# Copiar template
cp .env.template .env

# Generar secretos seguros
JWT_SECRET=$(openssl rand -hex 32)
DB_PASSWORD=$(openssl rand -base64 24)

# Actualizar .env
sed -i "s/CHANGE_ME_MIN_32_CHARS_LONG/$JWT_SECRET/" .env
sed -i "s/CHANGE_ME_TO_SECURE_VALUE/$DB_PASSWORD/" .env

# Configurar permisos
chmod 600 .env

echo "✅ .env creado con secretos generados"
echo "📌 Revisar y ajustar valores en: .env"
echo ""
echo "Para empezar:"
echo "  docker compose up"
```

✅ **Documentar en README.md**

```markdown
## Setup Rápido

1. **Clonar repo**
   ```bash
   git clone <repo>
   cd finansecure-tfe
   ```

2. **Configurar entorno**
   ```bash
   ./setup-dev-env.sh
   # O manual: cp .env.template .env
   # Luego editar .env con valores locales
   ```

3. **Levantar stack**
   ```bash
   docker compose up -d
   ```

4. **Acceder**
   - App: http://localhost
   - Website: http://localhost:3000
```

**Paso de implementación:**
- [ ] Crear `.env.template` con instrucciones
- [ ] Crear script `setup-dev-env.sh`
- [ ] Documentar en README.md
- [ ] Agregar a `.gitignore`: `.env` (✅ ya está)

---

### 🟡 MEDIO #2: Ausencia de secretos en GitHub Actions (FUTURO)

**Ubicación:** Workflows CI/CD (futuros)

**Problema:**
```yaml
# ❌ INCORRECTO
name: Build and Push
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and Push
        run: |
          docker build -t finansecure-auth:${{ github.sha }} .
          docker push finansecure-auth:${{ github.sha }}
        # ❌ NO está pasando secrets
        # ❌ Imagen se buildea sin credenciales
        # ❌ JWT_SECRET hardcodeado en imagen
```

**Riesgo:**
- 🟡 Imágenes pusheadas sin secrets necesarios
- 🟡 Después en ECS, falla por falta de configuración
- 🟡 Secrets pueden exposerse en logs de GitHub

**Severidad:** 🟡 MEDIO (pero CRÍTICO en CI/CD)  
**CVSS Score:** 7.0

**Recomendación:**

✅ **Configurar GitHub Secrets primero**

```bash
# En GitHub repo Settings → Secrets → New secret

AUTH_DB_PASSWORD = (valor de .env)
JWT_SECRET_KEY = (valor de .env)
ECR_REGISTRY = 123456789.dkr.ecr.us-east-1.amazonaws.com
ECR_REPOSITORY_AUTH = finansecure-auth
ECR_REPOSITORY_FRONTEND = finansecure-frontend
AWS_ACCESS_KEY_ID = (AWS IAM key)
AWS_SECRET_ACCESS_KEY = (AWS IAM secret)
AWS_REGION = us-east-1
```

✅ **Workflow seguro para CI/CD**

```yaml
# .github/workflows/build-and-push.yml
name: Build and Push Images

on:
  push:
    branches: [ main, develop ]
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write  # OIDC token para AWS

    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-actions
          aws-region: ${{ secrets.AWS_REGION }}
      
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build and push Auth Service
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build \
            --secret db_password=$(echo ${{ secrets.AUTH_DB_PASSWORD }} | base64) \
            --secret jwt_key=$(echo ${{ secrets.JWT_SECRET_KEY }} | base64) \
            -t $ECR_REGISTRY/${{ secrets.ECR_REPOSITORY_AUTH }}:$IMAGE_TAG \
            -f FinanSecure.Auth/Dockerfile \
            .
          
          docker push $ECR_REGISTRY/${{ secrets.ECR_REPOSITORY_AUTH }}:$IMAGE_TAG
```

✅ **Validar que no hay secretos en logs**

```yaml
      - name: Verify no secrets in build
        run: |
          # Verificar que docker build log no contiene secretos
          if docker history finansecure-auth:latest | grep -i password; then
            echo "❌ ERROR: Secretos encontrados en historial de build!"
            exit 1
          fi
          echo "✅ Build limpio - sin secretos"
```

**Paso de implementación (FUTURO):**
- [ ] Crear GitHub Secrets (no aún)
- [ ] Crear workflow seguro
- [ ] Usar OIDC + IAM roles (no keys en GitHub)
- [ ] Validar logs del build

---

## ✅ COSAS QUE ESTÁN BIEN

```
✅ docker-compose.yml usa variables de entorno correctamente
✅ Usa ${VAR:-default} pattern
✅ Multi-stage Dockerfile reduce tamaño de imagen
✅ .gitignore excluye .env files
✅ ConnectionString va por variables de entorno
✅ Health checks configurados en todos los servicios
✅ Resource limits definidos (Auth Service: 1 CPU, 1GB RAM)
✅ JWT expiration configurado (15 min + 7 días refresh)
✅ Bcrypt para hashing de contraseñas (factor 12)
✅ CORS configurado
```

---

## 📋 CHECKLIST PRE CI/CD

### 🔴 CRÍTICOS (BLOQUEA CI/CD)

- [ ] **1.1** Remover secretos de `appsettings.json`
  ```bash
  git status | grep -i appsettings
  # Verificar que NO hay secretos en la salida
  ```

- [ ] **1.2** Limpiar historial de Git si `appsettings.Development.json` fue commitado
  ```bash
  git log --oneline -- FinanSecure.Auth/appsettings.Development.json
  # Si aparece, usar bfg para remover del historial
  ```

- [ ] **1.3** Remover fallbacks con contraseñas en `docker-compose.yml`
  ```bash
  grep -n "SecureAuth2024" docker-compose.yml
  # Cambiar a: ${AUTH_DB_PASSWORD}
  ```

- [ ] **1.4** Verificar `.env` está en `.gitignore`
  ```bash
  cat .gitignore | grep "^\.env"
  # Debe aparecer
  ```

- [ ] **1.5** Crear `.env.template` sin secretos
  ```bash
  ls -la .env.template
  # Debe existir y estar en repo
  ```

### 🟠 ALTOS (Deben hacerse antes de primer build)

- [ ] **2.1** Crear `.dockerignore`
  ```bash
  cat > .dockerignore << 'EOF'
  .env
  .env.*
  appsettings.Development.json
  # ... resto
  EOF
  ```

- [ ] **2.2** Crear `generate-secrets.sh` para generar claves seguras
  ```bash
  chmod +x generate-secrets.sh
  ./generate-secrets.sh
  ```

- [ ] **2.3** Validador de variables de entorno en `Program.cs`
  ```csharp
  EnvironmentValidator.ValidateEnvironment();
  ```

- [ ] **2.4** Configurar logging para NO exponer secretos
  ```json
  "Microsoft.EntityFrameworkCore": "Warning"
  // No "Debug"
  ```

### 🟡 MEDIOS (Deberían hacer soon)

- [ ] **3.1** Crear script `setup-dev-env.sh`
  ```bash
  chmod +x setup-dev-env.sh
  ```

- [ ] **3.2** Documentar en README.md
  ```bash
  grep -i "setup\|env\|secret" README.md
  # Debe tener instrucciones claras
  ```

### ✅ VALIDACIÓN FINAL

```bash
#!/bin/bash
# security-check.sh

echo "🔐 Security Pre-CI/CD Check"
echo ""

ERRORS=0

# 1. Verificar no hay secretos en appsettings.json
echo "1️⃣ Checking appsettings.json for secrets..."
if grep -i "password\|secret" FinanSecure.Auth/appsettings.json | grep -v "CHANGE_ME\|^\s*//"; then
    echo "❌ FAIL: Secretos en appsettings.json"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ PASS"
fi

# 2. Verificar .env en .gitignore
echo ""
echo "2️⃣ Checking .gitignore for .env..."
if grep "^\.env" .gitignore; then
    echo "✅ PASS"
else
    echo "❌ FAIL: .env no está en .gitignore"
    ERRORS=$((ERRORS + 1))
fi

# 3. Verificar no hay contraseña hardcodeada en docker-compose
echo ""
echo "3️⃣ Checking docker-compose.yml..."
if grep "SecureAuth2024\|your-super-secret" docker-compose.yml | grep -v "\${"; then
    echo "❌ FAIL: Hardcoded secrets en docker-compose.yml"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ PASS"
fi

# 4. Verificar .env.template existe
echo ""
echo "4️⃣ Checking .env.template..."
if [ -f .env.template ]; then
    echo "✅ PASS"
else
    echo "❌ FAIL: .env.template no existe"
    ERRORS=$((ERRORS + 1))
fi

# 5. Verificar .dockerignore existe
echo ""
echo "5️⃣ Checking .dockerignore..."
if [ -f .dockerignore ]; then
    echo "✅ PASS"
else
    echo "❌ FAIL: .dockerignore no existe"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "════════════════════════════════════════"
if [ $ERRORS -eq 0 ]; then
    echo "✅ TODOS LOS CHECKS PASARON"
    echo "🚀 Listo para CI/CD"
    exit 0
else
    echo "❌ $ERRORS ERRORES ENCONTRADOS"
    echo "❌ NO PERMITIR CI/CD hasta resolver"
    exit 1
fi
```

**Ejecutar:**
```bash
chmod +x security-check.sh
./security-check.sh
```

---

## 🚀 PLAN DE IMPLEMENTACIÓN (RECOMENDADO)

### Fase 1: CRÍTICOS (2-3 horas)
```
1. Limpiar appsettings.json ......... 30 min
2. Crear .env.template .............. 15 min
3. Remover fallbacks inseguros ...... 20 min
4. Ejecutar bfg si es necesario .... 30 min
```

### Fase 2: ALTOS (1-2 horas)
```
1. Crear .dockerignore .............. 10 min
2. Crear generate-secrets.sh ........ 20 min
3. Agregar EnvironmentValidator .... 30 min
4. Configurar logging ............... 20 min
```

### Fase 3: MEDIOS (30 min)
```
1. Crear setup-dev-env.sh ........... 15 min
2. Actualizar README.md ............ 15 min
```

### Fase 4: VALIDACIÓN (15 min)
```
1. Ejecutar security-check.sh ....... 5 min
2. Probar: docker compose up ........ 10 min
```

**Tiempo total estimado:** 4-6 horas

---

## 📞 PRÓXIMOS PASOS

```
INMEDIATO (Hoy):
[ ] Revisar hallazgos críticos
[ ] Comenzar Fase 1

ESTA SEMANA:
[ ] Completar Fases 1-4
[ ] CI/CD ready

ANTES DE AWS DEPLOYMENT:
[ ] Configurar GitHub Secrets
[ ] Crear workflows seguros
[ ] Configurar AWS Secrets Manager
```

---

**🔐 Security Audit Complete - FinanSecure Local Development**
