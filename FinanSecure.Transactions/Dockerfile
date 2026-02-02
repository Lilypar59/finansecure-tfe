# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  Dockerfile Multi-Stage: FinanSecure.Transactions Microservice               ║
# ║  .NET 8.0 | ASP.NET Core 8.0 | PostgreSQL                                  ║
# ║  Producción-Ready | EC2 | ECS | Kubernetes                                 ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# ════════════════════════════════════════════════════════════════════════════════
# STAGE 1: BUILD (Compilación)
# ════════════════════════════════════════════════════════════════════════════════
# Propósito: Compilar la aplicación .NET 8
# Imagen base: mcr.microsoft.com/dotnet/sdk:8.0
# Tamaño: ~900 MB (se descarta en imagen final)

FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build

# Establecer directorio de trabajo
WORKDIR /src

# Copiar archivos de proyecto (.csproj)
COPY ["FinanSecure.Transactions/FinanSecure.Transactions.csproj", "FinanSecure.Transactions/"]

# Restaurar dependencias NuGet
# Usa capas de Docker para cachear (mejora tiempo de compilación)
RUN dotnet restore "FinanSecure.Transactions/FinanSecure.Transactions.csproj"

# Copiar código fuente completo
COPY . .

# Compilar en modo Release (optimizado)
# -c Release: Modo release (sin debug symbols)
# -o /app/build: Output a /app/build
RUN dotnet build "FinanSecure.Transactions/FinanSecure.Transactions.csproj" \
    -c Release \
    -o /app/build 2>&1 || true

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
RUN dotnet publish "FinanSecure.Transactions/FinanSecure.Transactions.csproj" \
    -c Release \
    -o /app/publish \
    --self-contained false 2>&1 || true

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
LABEL description="FinanSecure Transactions Microservice - ASP.NET Core 8.0"

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
ENV APP_NAME="FinanSecure.Transactions" \
    APP_VERSION="1.0.0" \
    APP_ENVIRONMENT="docker"

# Base de datos (valores por defecto, sobrescribir en runtime)
ENV DB_HOST="postgres" \
    DB_PORT="5432" \
    DB_DATABASE="finansecure_transactions_db_dev" \
    DB_USER="postgres" \
    DB_PASSWORD="postgres"

# JWT
ENV JWT_SECRET_KEY="your-secret-key-change-in-production" \
    JWT_ISSUER="FinanSecure" \
    JWT_AUDIENCE="FinanSecure.Client"

# Auth Service
#ENV AUTH_SERVICE_URL="http://finansecure-auth:8080"
ENV AUTH_SERVICE_URL="http://localhost:8080"

# Logging
ENV LOG_LEVEL="Information"

# ════════════════════════════════════════════════════════════════════════════════
# PUERTO
# ════════════════════════════════════════════════════════════════════════════════
# Exponer puerto 8080 (no root, < 1024)

EXPOSE 8080

# ════════════════════════════════════════════════════════════════════════════════
# HEALTHCHECK
# ════════════════════════════════════════════════════════════════════════════════
# Verificar que la aplicación está healthy en /health
# --interval: Cada 30 segundos
# --timeout: Timeout de 10 segundos
# --retries: Fallar después de 3 intentos
# --start-period: Esperar 40 segundos antes de empezar a chequear

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
    CMD curl -f http://localhost:8080/health || exit 1

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

ENTRYPOINT ["dotnet", "FinanSecure.Transactions.dll"]
