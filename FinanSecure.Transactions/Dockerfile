# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  Dockerfile Multi-Stage: FinanSecure.Transactions Microservice               ║
# ║  .NET 8.0 | ASP.NET Core 8.0 | PostgreSQL                                  ║
# ║  Producción-Ready | Standalone | Docker | Linux-Compatible                 ║
# ║  CORREGIDO: Sin dependencias de .sln | Rutas Linux-safe | Sin || true      ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# ════════════════════════════════════════════════════════════════════════════════
# ⚙️  ARQUITECTURA DE BUILD
# ════════════════════════════════════════════════════════════════════════════════
# Este Dockerfile compila FinanSecure.Transactions de forma TOTALMENTE AISLADA.
# 
# CAMBIOS PRINCIPALES (vs versión anterior):
# 1. ❌ NO copia .sln → El servicio es independiente
# 2. ✅ Copia explícitamente SOLO FinanSecure.Transactions.csproj
# 3. ✅ Restaura dependencias EXPLÍCITAMENTE (sin asumir)
# 4. ✅ Copia código DESPUÉS de restore (optimiza Docker layers)
# 5. ❌ ELIMINADO: || true (errores silenciosos)
# 6. ✅ Rutas case-sensitive (Linux-safe)
#
# VENTAJAS:
# - Compatible con CI/CD (GitHub Actions en Linux)
# - Funciona en entornos Docker limpio (sin cache local)
# - Microservicio verdaderamente aislado
# - Layer caching óptimo en Docker
# - Errores explícitos, NO silenciosos

# ════════════════════════════════════════════════════════════════════════════════
# STAGE 1: BUILD (Compilación en SDK)
# ════════════════════════════════════════════════════════════════════════════════
# Base: SDK de .NET 8.0 (contiene compiladores, herramientas, etc.)
# Tamaño: ~900 MB (se descarta - no va en imagen final)
# Alpine: Imagen ultra-compacta (~250 MB base)

FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build

# Configurar directorio de trabajo
WORKDIR /src

# ════════════════════════════════════════════════════════════════════════════════
# PASO 1: COPIAR .CSPROJ (EXPLÍCITAMENTE, SIN DEPENDENCIAS)
# ════════════════════════════════════════════════════════════════════════════════
# ✅ SOLO copia FinanSecure.Transactions.csproj
# ❌ NO copia .sln (innecesario para microservicio independiente)
# ❌ NO copia otros servicios (.csproj de Auth, Api, etc.)
#
# POR QUÉ:
# - dotnet restore puede funcionar sin .sln (v8.0+)
# - Copiar otros proyectos sería falso acoplamiento
# - Linux es case-sensitive: "FinanSecure.Transactions" ≠ "finansecure.transactions"
#
# CAPA DOCKER: Muy pequeña (~1 KB) → Rápida de descargar/cachear

COPY FinanSecure.Transactions/FinanSecure.Transactions.csproj ./FinanSecure.Transactions/

# ════════════════════════════════════════════════════════════════════════════════
# PASO 2: RESTAURAR DEPENDENCIAS NUGET
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Se ejecuta INMEDIATAMENTE después de copiar .csproj
# ✅ Sin --no-restore (lo haría explícitamente)
#
# POR QUÉ:
# - NuGet leerá FinanSecure.Transactions.csproj (ya disponible)
# - Descargará SOLO las dependencias necesarias
# - Cacheará las dependencias en Docker layer
# - Siguiente build (sin cambios en .csproj) será INSTANTÁNEO
#
# CAPA DOCKER: Grande (~500 MB) pero se cachea → Build rápido en CI
# FLAGS:
# - --no-cache: Siempre descarga versiones más recientes (CI-safe)
# - --verbosity normal: Output detallado para debugging en CI

RUN dotnet restore "FinanSecure.Transactions/FinanSecure.Transactions.csproj" \
    --no-cache \
    --verbosity normal

# ════════════════════════════════════════════════════════════════════════════════
# PASO 3: COPIAR CÓDIGO FUENTE COMPLETO
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Se hace DESPUÉS de restore
#
# POR QUÉ ESTÁ DESPUÉS:
# - Si ponemos COPY primero → cualquier cambio de código invalida cache
# - Si restauramos primero → solo cambia si .csproj cambia (raro)
# - Docker reutiliza layers: cambios frecuentes (código) van al final
#
# NOTA IMPORTANTE:
# - .dockerignore (en raíz) filtra qué se copia
# - Excluye: .git, node_modules, logs, REPORTES, *.md, .venv, etc.

COPY FinanSecure.Transactions/ ./FinanSecure.Transactions/

# ════════════════════════════════════════════════════════════════════════════════
# PASO 4: COMPILAR EN MODO RELEASE
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Todas las dependencias ya están restauradas
# ✅ TODO el código fuente está disponible
# ✅ SE EJECUTA dotnet build (SIN -- no-restore, SIN || true)
#
# POR QUÉ SIN || true:
# - Los errores DEBEN ser visibles
# - Si la compilación falla → el build FALLA (no se ignora)
# - En CI, esto es CRÍTICO para detectar problemas
#
# POR QUÉ SIN --no-restore:
# - Ya restauramos explícitamente en PASO 2
# - dotnet build verá que NuGet packages existen
# - No re-descargará (usa caché del PASO 2)
#
# FLAGS:
# -c Release: Compilar en modo Release (optimizado, sin debug symbols)
# -o /app/build: Output en /app/build (será copiado a runtime stage)
# --verbosity normal: Output detallado para debugging en CI
# --no-incremental: Fuerza compilación limpia (CI-safe)
# --no-restore: Las dependencias ya se restauraron en paso anterior

RUN dotnet build "FinanSecure.Transactions/FinanSecure.Transactions.csproj" \
    -c Release \
    -o /app/build \
    --no-restore \
    --verbosity normal \
    --no-incremental

# ════════════════════════════════════════════════════════════════════════════════
# STAGE 1B: PUBLISH (Preparar para Runtime)
# ════════════════════════════════════════════════════════════════════════════════
# Propósito: Generar artefacto publicado listo para ASP.NET runtime
# Hereda del stage "build" (reutiliza compilación)
#
# ✅ Se hace en el MISMO stage para aprovechar build cache

FROM build AS publish

# ════════════════════════════════════════════════════════════════════════════════
# PUBLICAR APLICACIÓN
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Publica los binarios compilados (SIN || true)
#
# FLAGS:
# -c Release: Modo Release (mismo que build)
# -o /app/publish: Directorio de output (será copiado a runtime)
# --self-contained false: Usa runtime shared (más pequeño)
#   → Runtime se trae de la imagen aspnet:8.0 (runtime stage)
#   → No incluir todo el runtime en la imagen (ahorraría ~300 MB)
#
# POR QUÉ SIN || true:
# - Si publish falla → el error DEBE ser visible
# - En CI, esto es CRÍTICO para detectar problemas
#
# FLAGS:
# -c Release: Modo Release (mismo que build)
# -o /app/publish: Directorio de output (será copiado a runtime)
# --self-contained false: Usa runtime shared (más pequeño)
# --verbosity normal: Output detallado para debugging
# ❌ SIN --no-build: publish NECESITA generar runtimeconfig.json y otros archivos

RUN dotnet publish "FinanSecure.Transactions/FinanSecure.Transactions.csproj" \
    -c Release \
    -o /app/publish \
    --self-contained false \
    --verbosity normal

# ════════════════════════════════════════════════════════════════════════════════
# STAGE 2: RUNTIME (Ejecución en Producción)
# ════════════════════════════════════════════════════════════════════════════════
# Propósito: Imagen final MINIMALISTA para producción
# Base: Solo runtime ASP.NET Core (sin compiladores, sin SDK)
# Tamaño: ~200 MB (vs 900 MB del SDK)
#
# ✅ VENTAJAS:
# - Imagen pequeña → Descargas rápidas
# - Sin herramientas de compilación → Menor surface attack
# - Compatible con Kubernetes, ECS, etc.
# - Build y runtime separados (best practice)

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime

# ════════════════════════════════════════════════════════════════════════════════
# METADATA
# ════════════════════════════════════════════════════════════════════════════════
# Etiquetas para documentar la imagen

LABEL maintainer="FinanSecure Team"
LABEL version="1.0"
LABEL description="FinanSecure Transactions Microservice - ASP.NET Core 8.0"

# ════════════════════════════════════════════════════════════════════════════════
# SEGURIDAD: Usuario No-Root
# ════════════════════════════════════════════════════════════════════════════════
# ✅ CRITICIDAD: ALTA (seguridad en producción)
#
# COMANDO:
# - addgroup: Crear grupo "appgroup" con GID 1001
# - adduser: Crear usuario "appuser" con UID 1001
#   - -S: Sistema user (sin login shell)
#   - -G appgroup: Asignar al grupo
#
# RESULTADO:
# - Usuario: appuser (UID 1001)
# - Grupo: appgroup (GID 1001)
# - Sin home directory (no necesario en contenedor)

RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# ════════════════════════════════════════════════════════════════════════════════
# DIRECTORIO DE TRABAJO
# ════════════════════════════════════════════════════════════════════════════════

WORKDIR /app

# ════════════════════════════════════════════════════════════════════════════════
# COPIAR APLICACIÓN PUBLICADA DESDE BUILD STAGE
# ════════════════════════════════════════════════════════════════════════════════
# ✅ COPY --from=publish: Copia SOLO los artefactos publicados
# ✅ --chown=appuser:appgroup: Cambia propietario (no será root)

COPY --from=publish --chown=appuser:appgroup /app/publish .

# ════════════════════════════════════════════════════════════════════════════════
# VARIABLES DE ENTORNO
# ════════════════════════════════════════════════════════════════════════════════
# Configuración por defecto para la aplicación
# ✅ SOBRESCRIBIBLES en runtime (docker run -e VAR=value)

# ASP.NET Core Runtime
ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_LOGGING__CONSOLE__INCLUDERESPAWNING=true

# Metadata de la Aplicación
ENV APP_NAME="FinanSecure.Transactions" \
    APP_VERSION="1.0.0" \
    APP_ENVIRONMENT="docker"

# JWT (Defaults - pueden sobrescribirse)
ENV JWT_ISSUER="FinanSecure" \
    JWT_AUDIENCE="FinanSecure.Client"

# Logging
ENV LOG_LEVEL="Information"

# ════════════════════════════════════════════════════════════════════════════════
# PUERTO EXPUESTO
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Puerto 8080 (no requiere root, > 1024)

EXPOSE 8080

# ════════════════════════════════════════════════════════════════════════════════
# INSTALAR CURL (para HEALTHCHECK)
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Necesario para verificar salud del contenedor
# ✅ apk = Alpine Package Manager (porque usamos alpine)

RUN apk add --no-cache curl

# ════════════════════════════════════════════════════════════════════════════════
# HEALTHCHECK
# ════════════════════════════════════════════════════════════════════════════════
# ✅ CRITICIDAD: ALTA (DevOps/Kubernetes lo necesita)
#
# Verifica que la aplicación responde HTTP cada 30 segundos

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
    CMD curl -f http://localhost:8080/ || exit 1

# ════════════════════════════════════════════════════════════════════════════════
# CAMBIAR A USUARIO NO-ROOT
# ════════════════════════════════════════════════════════════════════════════════
# ✅ CRITICIDAD: ALTA (seguridad)

USER appuser

# ════════════════════════════════════════════════════════════════════════════════
# ENTRYPOINT
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Comando principal que se ejecuta

ENTRYPOINT ["dotnet", "FinanSecure.Transactions.dll"]
