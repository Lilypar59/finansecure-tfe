# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  Dockerfile Multi-Stage: FinanSecure.Auth Microservice                      ║
# ║  .NET 8.0 | ASP.NET Core 8.0 | PostgreSQL                                  ║
# ║  Producción-Ready | Standalone | Docker | Linux-Compatible                 ║
# ║  CORREGIDO: Sin dependencias de .sln | Rutas Linux-safe                    ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# ════════════════════════════════════════════════════════════════════════════════
# ⚙️  ARQUITECTURA DE BUILD
# ════════════════════════════════════════════════════════════════════════════════
# Este Dockerfile compila FinanSecure.Auth de forma TOTALMENTE AISLADA.
# 
# CAMBIOS PRINCIPALES (vs versión anterior):
# 1. ❌ NO copia .sln → El servicio es independiente
# 2. ❌ NO copia otros .csproj → Solo FinanSecure.Auth
# 3. ✅ Restaura dependencias EXPLÍCITAMENTE
# 4. ✅ Rutas case-sensitive (Linux-safe)
# 5. ✅ COPY ordenado: .csproj → restore → código → build
#
# VENTAJAS:
# - Compatible con CI/CD (GitHub Actions en Linux)
# - Funciona en entornos Docker limpio (sin cache local)
# - Microservicio verdaderamente aislado
# - Layer caching óptimo en Docker

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
# ✅ SOLO copia FinanSecure.Auth.csproj
# ❌ NO copia .sln (innecesario para microservicio independiente)
# ❌ NO copia otros servicios (.csproj de Api, Transactions, etc.)
#
# POR QUÉ:
# - dotnet restore puede funcionar sin .sln (v8.0+)
# - El .sln en este repo SOLO contiene Api (incompleto)
# - Copiar otros proyectos sería falso acoplamiento
# - Linux es case-sensitive: "FinanSecure.Auth" ≠ "finansecure.auth"
#
# CAPA DOCKER: Muy pequeña (~1 KB) → Rápida de descargar/cachear

COPY FinanSecure.Auth/FinanSecure.Auth.csproj ./FinanSecure.Auth/

# ════════════════════════════════════════════════════════════════════════════════
# PASO 2: RESTAURAR DEPENDENCIAS NUGET
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Se ejecuta INMEDIATAMENTE después de copiar .csproj
# ✅ Sin --no-restore (lo haría explícitamente)
#
# POR QUÉ:
# - NuGet leerá FinanSecure.Auth.csproj (ya disponible)
# - Descargará SOLO las dependencias necesarias
# - Cacheará las dependencias en Docker layer
# - Siguiente build (sin cambios en .csproj) será INSTANTÁNEO
#
# CAPA DOCKER: Grande (~500 MB) pero se cachea → Build rápido en CI
#
# FLAGS:
# - No incluimos rutas a otros .csproj (no existen)
# - No asumimos .sln (podría no estar, o ser incompleto)
# - --no-cache: Siempre descarga versiones más recientes (CI-safe)
# - --verbosity normal: Output detallado para debugging en CI

RUN dotnet restore "FinanSecure.Auth/FinanSecure.Auth.csproj" \
    --no-cache \
    --verbosity normal

# ════════════════════════════════════════════════════════════════════════════════
# PASO 3: COPIAR CÓDIGO FUENTE COMPLETO
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Se hace DESPUÉS de restore
# ✅ COPY . . copia SOLO el código de FinanSecure.Auth
#
# POR QUÉ ESTÁ DESPUÉS:
# - Si ponemos COPY primero → cualquier cambio de código invalida cache
# - Si restauramos primero → solo cambia si .csproj cambia (raro)
# - Docker reutiliza layers: cambios frecuentes (código) van al final
#
# NOTA IMPORTANTE:
# - .dockerignore (en raíz) filtra qué se copia
# - Excluye: .git, node_modules, logs, REPORTES, *.md, .venv, etc.
# - Solo entra código de FinanSecure.Auth/ (Controllers, Models, Services, etc.)

COPY FinanSecure.Auth/ ./FinanSecure.Auth/

# ════════════════════════════════════════════════════════════════════════════════
# PASO 4: COMPILAR EN MODO RELEASE
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Todas las dependencias ya están restauradas
# ✅ TODO el código fuente está disponible
# ✅ SE EJECUTA dotnet build (sin --no-restore)
#
# POR QUÉ SIN --no-restore:
# - Ya restauramos explícitamente en PASO 2
# - dotnet build verá que NuGet packages existen
# - No re-descargará (usa caché del PASO 2)
# - Si falla → ERROR visible (no silencioso)
#
# FLAGS:
# -c Release: Compilar en modo Release (optimizado, sin debug symbols)
# -o /app/build: Output en /app/build (será copiado a runtime stage)
# --verbosity normal: Output detallado para debugging en CI
# --no-incremental: Fuerza compilación limpia (CI-safe)
# --no-restore: Las dependencias ya se restauraron en paso anterior
#
# CAPA DOCKER: Mediano (~100-200 MB) pero no se cachea (código siempre cambia)

RUN dotnet build "FinanSecure.Auth/FinanSecure.Auth.csproj" \
    -c Release \
    -o /app/build \
    --verbosity normal \
    --no-incremental

# ════════════════════════════════════════════════════════════════════════════════
# STAGE 1B: PUBLISH (Preparar para Runtime)
# ════════════════════════════════════════════════════════════════════════════════
# Propósito: Generar artefacto publicado listo para ASP.NET runtime
# Hereda del stage "build" (reutiliza compilación)
#
# ✅ Se hace en el MISMO stage para aprovechar build cache
# ✅ Genera archivos .dll, .json, etc. listos para ejecutar

FROM build AS publish

# ════════════════════════════════════════════════════════════════════════════════
# PUBLICAR APLICACIÓN
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Publica los binarios compilados
#
# FLAGS:
# -c Release: Modo Release (mismo que build)
# -o /app/publish: Directorio de output (será copiado a runtime)
# --self-contained false: Usa runtime shared (más pequeño)
# --verbosity normal: Output detallado para debugging
# ❌ SIN --no-build: publish NECESITA generar runtimeconfig.json y otros archivos
#    que build NO genera (ejemplo: .json de configuración, .runtimeconfig.json, etc)
#
# CAPA DOCKER: Pequeño (~50-100 MB) - solo archivos publicados

RUN dotnet publish "FinanSecure.Auth/FinanSecure.Auth.csproj" \
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
LABEL description="FinanSecure Auth Microservice - ASP.NET Core 8.0"

# ════════════════════════════════════════════════════════════════════════════════
# SEGURIDAD: Usuario No-Root
# ════════════════════════════════════════════════════════════════════════════════
# ✅ CRITICIDAD: ALTA (seguridad en producción)
#
# POR QUÉ NO USAR root:
# - Si la app tiene vulnerabilidad XSS/RCE → atacante puede ser root
# - Con usuario regular → atacante tiene permisos limitados
# - Mejor práctica: CIS Docker Benchmark, OWASP, etc.
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
# Ubicación donde se copiará la aplicación publicada

WORKDIR /app

# ════════════════════════════════════════════════════════════════════════════════
# COPIAR APLICACIÓN PUBLICADA DESDE BUILD STAGE
# ════════════════════════════════════════════════════════════════════════════════
# ✅ COPY --from=publish: Copia SOLO los artefactos publicados
# ✅ --chown=appuser:appgroup: Cambia propietario (no será root)
#
# QUÉ SE COPIA:
# - /app/publish/FinanSecure.Auth.dll (binario principal)
# - /app/publish/*.dll (dependencias)
# - /app/publish/appsettings.json (configuración)
# - /app/publish/... (todos los archivos necesarios)
#
# QUÉ NO SE COPIA:
# - ❌ /src (código fuente - no necesario en producción)
# - ❌ FinanSecure.Api, FinanSecure.Transactions (otros servicios)
# - ❌ node_modules, .git, logs, documentación
# - ❌ El SDK de .NET (~900 MB) - quedó en stage build
#
# TAMAÑO FINAL:
# - Imagen: ~200 MB (aspnet:8.0 alpine: 150 MB + app: 50 MB)
# - vs: 900 MB (si incluyéramos SDK)

COPY --from=publish --chown=appuser:appgroup /app/publish .

# ════════════════════════════════════════════════════════════════════════════════
# VARIABLES DE ENTORNO
# ════════════════════════════════════════════════════════════════════════════════
# Configuración por defecto para la aplicación
# ✅ SOBRESCRIBIBLES en runtime (docker run -e VAR=value)
#
# CATEGORÍAS:
# 1. ASP.NET Core (runtime)
# 2. Aplicación (metadata)
# 3. JWT (autenticación)
# 4. Logging (diagnostics)
# 5. ❌ BD NO incluida (ver explicación abajo)

# ASP.NET Core Runtime
ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_LOGGING__CONSOLE__INCLUDERESPAWNING=true

# Metadata de la Aplicación
ENV APP_NAME="FinanSecure.Auth" \
    APP_VERSION="1.0.0" \
    APP_ENVIRONMENT="docker"

# JWT (Defaults - pueden sobrescribirse)
ENV JWT_ISSUER="FinanSecure" \
    JWT_AUDIENCE="FinanSecure.Client" \
    JWT_EXPIRATION_MINUTES="15" \
    JWT_REFRESH_EXPIRATION_DAYS="7"

# Logging
ENV LOG_LEVEL="Information"

# ════════════════════════════════════════════════════════════════════════════════
# ⚠️  IMPORTANTE: POR QUÉ NO HAY VARIABLES DE BD AQUÍ
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Las credenciales de BD se configuran en:
#    1. appsettings.json (settings por defecto)
#    2. appsettings.Production.json (sobrescribe en prod)
#    3. docker-compose.yml (ConnectionStrings__DefaultConnection)
#    4. Kubernetes secrets (en K8s)
#
# ❌ NO se definen en Dockerfile porque:
# - Credenciales en Dockerfile = commits de secretos en Git
# - Difícil de cambiar sin rebuild
# - Inseguro para múltiples ambientes
# - Se guarda en imagen (visible en histórico Docker)
#
# ✅ ÚNICO lugar de secretos: docker-compose.yml o secrets manager

# ════════════════════════════════════════════════════════════════════════════════
# PUERTO EXPUESTO
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Puerto 8080 (no requiere root, > 1024)
# ✅ Definido en ASPNETCORE_URLS arriba
#
# NOTA:
# - EXPOSE es documentación (Docker no abre puerto automáticamente)
# - El puerto real se abre con: docker run -p 8080:8080
# - O con ports: en docker-compose.yml

EXPOSE 8080

# ════════════════════════════════════════════════════════════════════════════════
# INSTALAR CURL (para HEALTHCHECK)
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Necesario para verificar salud del contenedor
# ✅ apk = Alpine Package Manager (porque usamos alpine)
# ✅ --no-cache = no guardar índice de paquetes (más pequeño)

RUN apk add --no-cache curl

# ════════════════════════════════════════════════════════════════════════════════
# HEALTHCHECK
# ════════════════════════════════════════════════════════════════════════════════
# ✅ CRITICIDAD: ALTA (DevOps/Kubernetes lo necesita)
#
# QUÉ HACE:
# - Cada 30 segundos: ejecuta "curl -f http://localhost:8080/"
# - Si falla 3 veces consecutivas: marca contenedor como UNHEALTHY
# - Kubernetes matará el pod UNHEALTHY
# - Docker Swarm lo reemplazará automáticamente
#
# FLAGS:
# --interval=30s: Cada cuánto chequear
# --timeout=10s: Máximo tiempo para responder
# --retries=3: Fallos antes de marcar UNHEALTHY
# --start-period=40s: Esperar antes de empezar (app arranca en ~30s)
#
# ENDPOINT:
# - GET /: Raíz de la API (siempre disponible)
# - -f: Falla si HTTP status != 200-399
#
# CAPA: Imagen (no afecta tamaño)

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
    CMD curl -f http://localhost:8080/ || exit 1

# ════════════════════════════════════════════════════════════════════════════════
# CAMBIAR A USUARIO NO-ROOT
# ════════════════════════════════════════════════════════════════════════════════
# ✅ CRITICIDAD: ALTA (seguridad)
#
# ¿Por qué USER debe ir AQUÍ (antes de ENTRYPOINT)?
# - Si va antes de COPY → COPY fallará (appuser no puede copiar)
# - Va después de COPY → cambio de propietario
# - Va antes de ENTRYPOINT → la app corre como appuser
#
# VERIFICAR:
# docker exec <container> whoami
# → Debe devolver: appuser

USER appuser

# ════════════════════════════════════════════════════════════════════════════════
# ENTRYPOINT
# ════════════════════════════════════════════════════════════════════════════════
# ✅ Comando principal que se ejecuta
#
# FORMATO:
# ENTRYPOINT ["dotnet", "FinanSecure.Auth.dll"]
# = dotnet FinanSecure.Auth.dll
#
# FLAGS EN PROGRAMA:
# - Los argumentos de Kubernetes/Docker se pasan a la app
# - Ejemplo: docker run <image> --port=9000
#   → Ejecuta: dotnet FinanSecure.Auth.dll --port=9000
#
# ALTERNATIVA (no usada aquí):
# CMD ["--urls=http://+:8080"]
# → Permite sobrescribir: docker run <image> <otros-args>
#
# POR QUÉ ENTRYPOINT y no CMD:
# - ENTRYPOINT = comando que SIEMPRE se ejecuta
# - CMD = argumentos por defecto (pero se pueden cambiar)
# - Mejor para garantizar que SIEMPRE corre la app

ENTRYPOINT ["dotnet", "FinanSecure.Auth.dll"]
