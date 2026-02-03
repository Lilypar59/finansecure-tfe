# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  Dockerfile Multi-Stage: FinanSecure.Auth Microservice                      ║
# ║  .NET 8.0 | ASP.NET Core 8.0 | PostgreSQL                                  ║
# ║  Producción-Ready | EC2 | ECS | Kubernetes | CORREGIDO                     ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# ⚠️  NOTA IMPORTANTE:
# Si encuentras error "RUN dotnet build" falla:
#   1. Asegúrate de que FinanSecure.Auth/FinanSecure.Auth.csproj existe
#   2. Verifica que todos los archivos .cs estén presentes
#   3. Revisa que no hay caracteres especiales en rutas
#   4. Intenta: docker build --progress=plain para ver detalles completos

# ════════════════════════════════════════════════════════════════════════════════
# STAGE 1: BUILD (Compilación)
# ════════════════════════════════════════════════════════════════════════════════
# Propósito: Compilar la aplicación .NET 8
# Imagen base: mcr.microsoft.com/dotnet/sdk:8.0
# Tamaño: ~900 MB (se descarta en imagen final)

FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build

# Establecer directorio de trabajo
WORKDIR /src

# PASO 1: Copiar archivos de solución (.sln) si existen
COPY *.sln ./

# PASO 2: Copiar archivos de proyecto (.csproj) de todos los servicios
COPY FinanSecure.Auth/*.csproj ./FinanSecure.Auth/
COPY FinanSecure.Api/*.csproj ./FinanSecure.Api/
COPY FinanSecure.Transactions/*.csproj ./FinanSecure.Transactions/

# PASO 3: Restaurar dependencias NuGet (solo dependencias, sin código)
# Usa capas de Docker para cachear (mejora tiempo de compilación)
RUN dotnet restore "FinanSecure.Auth/FinanSecure.Auth.csproj" || \
    (echo "Error restaurando dependencias" && exit 1)

# PASO 4: Copiar código fuente completo
COPY . .

# PASO 5: Compilar en modo Release (optimizado)
# -c Release: Modo release (sin debug symbols)
# -o /app/build: Output a /app/build
# Agregar verbose para debugging si falla
RUN dotnet build "FinanSecure.Auth/FinanSecure.Auth.csproj" \
    -c Release \
    -o /app/build \
    --no-restore || \
    (echo "Error compilando FinanSecure.Auth" && exit 1)

# ════════════════════════════════════════════════════════════════════════════════
# STAGE 1B: PUBLISH (Preparar para Runtime)
# ════════════════════════════════════════════════════════════════════════════════
# Propósito: Publicar aplicación (self-contained files)
# Se hace en mismo stage para aprovechar caché

FROM build AS publish

# Publicar en modo Release
# -c Release: Modo release
# -o /app/publish: Output a /app/publish
# --self-contained false: Usar runtime shared (más pequeño)
# ⚠️  IMPORTANTE: NO usar --no-build con -o personalizado en build anterior
#     dotnet publish regenerará los artefactos correctamente
RUN dotnet publish "FinanSecure.Auth/FinanSecure.Auth.csproj" \
    -c Release \
    -o /app/publish \
    --self-contained false || \
    (echo "Error publicando FinanSecure.Auth" && exit 1)

# ════════════════════════════════════════════════════════════════════════════════
# STAGE 2: RUNTIME (Ejecución)
# ════════════════════════════════════════════════════════════════════════════════
# Propósito: Imagen final minimalista para producción
# Imagen base: mcr.microsoft.com/dotnet/aspnet:8.0
# Tamaño: ~200 MB (muy pequeño, solo runtime)

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime

# Establecer labels para metadata
LABEL maintainer="FinanSecure Team"
LABEL version="1.0"
LABEL description="FinanSecure Auth Microservice - ASP.NET Core 8.0"

# ════════════════════════════════════════════════════════════════════════════════
# SEGURIDAD: Usuario Non-Root
# ════════════════════════════════════════════════════════════════════════════════
# Crear usuario 'appuser' con UID 1001 (evita root privileges)
# -u: Especificar UID
# -g: Crear grupo 'appgroup'
# --no-create-home: No crear home directory (más seguro)

RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# ════════════════════════════════════════════════════════════════════════════════
# DIRECTORIO DE TRABAJO
# ════════════════════════════════════════════════════════════════════════════════

WORKDIR /app

# ════════════════════════════════════════════════════════════════════════════════
# COPIAR APLICACIÓN PUBLICADA
# ════════════════════════════════════════════════════════════════════════════════
# Copiar archivos compilados desde stage publish

COPY --from=publish --chown=appuser:appgroup /app/publish .

# ════════════════════════════════════════════════════════════════════════════════
# VARIABLES DE ENTORNO (Configuración)
# ════════════════════════════════════════════════════════════════════════════════
# Estas variables pueden sobrescribirse en runtime

# ASP.NET Core
ENV ASPNETCORE_ENVIRONMENT=Production \
    ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_LOGGING__CONSOLE__INCLUDERESPAWNING=true

# Aplicación
ENV APP_NAME="FinanSecure.Auth" \
    APP_VERSION="1.0.0" \
    APP_ENVIRONMENT="docker"

# JWT (Token security)
ENV JWT_ISSUER="FinanSecure" \
    JWT_AUDIENCE="FinanSecure.Client" \
    JWT_EXPIRATION_MINUTES="15" \
    JWT_REFRESH_EXPIRATION_DAYS="7"

# Logging
ENV LOG_LEVEL="Information"

# ⚠️  IMPORTANTE: NO definir DB_HOST, DB_PORT, DB_DATABASE, DB_USER, DB_PASSWORD aquí
# La conexión a BD se configura EXCLUSIVAMENTE a través de:
# - appsettings.json / appsettings.Development.json
# - Variable de entorno ConnectionStrings__DefaultConnection en docker-compose.yml
# Esto evita confusión y garantiza una única fuente de verdad.

# ════════════════════════════════════════════════════════════════════════════════
# PUERTO
# ════════════════════════════════════════════════════════════════════════════════
# Exponer puerto 8080 (no root, < 1024)

EXPOSE 8080

# ════════════════════════════════════════════════════════════════════════════════
# HEALTHCHECK
# ════════════════════════════════════════════════════════════════════════════════
# Verificar que la aplicación está respondiendo HTTP
# Usamos un endpoint simple que siempre está disponible
# --interval: Cada 30 segundos
# --timeout: Timeout de 10 segundos
# --retries: Fallar después de 3 intentos
# --start-period: Esperar 40 segundos antes de empezar a chequear

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
    CMD curl -f http://localhost:8080/ || exit 1

# ════════════════════════════════════════════════════════════════════════════════
# INSTALAR CURL
# ════════════════════════════════════════════════════════════════════════════════
# Necesario para healthcheck con CMD curl
# Usando apk porque es una imagen Alpine

RUN apk add --no-cache curl

# ════════════════════════════════════════════════════════════════════════════════
# USUARIO ACTUAL
# ════════════════════════════════════════════════════════════════════════════════
# Cambiar a usuario non-root (seguridad)

USER appuser

# ════════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ════════════════════════════════════════════════════════════════════════════════
# Ejecutar la aplicación
# ENTRYPOINT: Comando que siempre se ejecuta
# CMD: Argumentos por defecto (pueden sobrescribirse)

ENTRYPOINT ["dotnet", "FinanSecure.Auth.dll"]
