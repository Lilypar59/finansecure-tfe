# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  Dockerfile Multi-Stage: FinanSecure Frontend (Angular)                      ║
# ║  Node.js 18 | Angular 17+ | Production-Ready                                ║
# ║  NOTA: Optimizado para builds rápidos (evita npm install en Docker)         ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# ════════════════════════════════════════════════════════════════════════════════
# OPCIÓN 1: Si el build ESTÁ HECHO LOCALMENTE (RECOMENDADO)
# ════════════════════════════════════════════════════════════════════════════════
# Este Dockerfile solo copia el dist compilado
# Úsalo así: docker build -f finansecure-web/Dockerfile.prod .

# ════════════════════════════════════════════════════════════════════════════════
# STAGE 1: BUILD (Compilación de Angular) - OPCIONAL
# ════════════════════════════════════════════════════════════════════════════════
# Descomentar solo si quieres que Docker compile el Angular
# Esto es LENTO (10+ minutos)

FROM node:18-alpine AS build

WORKDIR /app

# Copiar package.json y package-lock.json
COPY finansecure-web/package*.json ./

# Instalar dependencias (cachea esta capa)
RUN npm ci --omit=dev

# Copiar código fuente
COPY finansecure-web/ .

# Compilar Angular en modo Production
RUN npm run build

# ════════════════════════════════════════════════════════════════════════════════
# STAGE 2: RUNTIME (Servir Angular con Nginx)
# ════════════════════════════════════════════════════════════════════════════════
FROM nginx:alpine

# Establecer labels
LABEL maintainer="FinanSecure Team"
LABEL version="1.0"
LABEL description="FinanSecure Frontend - Angular 17+ Application"

# Copiar configuración de nginx
COPY finansecure-web/nginx.conf /etc/nginx/nginx.conf

# OPCIÓN A: Copiar desde build stage (si usas compilación en Docker)
COPY --from=build /app/dist/finansecure-web/browser /usr/share/nginx/html

# OPCIÓN B: Descomentar si el build está hecho localmente
# COPY finansecure-web/dist/finansecure-web/browser /usr/share/nginx/html

# Crear directorios con permisos correctos para nginx
RUN mkdir -p /var/log/nginx /var/cache/nginx /tmp && \
    chmod -R 777 /var/log/nginx /var/cache/nginx /tmp

# Puerto
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
    CMD wget --no-verbose --tries=1 --spider http://localhost:80/ || exit 1

# Comando para iniciar nginx
CMD ["nginx", "-g", "daemon off;"]

