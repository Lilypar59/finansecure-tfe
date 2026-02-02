#!/bin/bash
# Script para iniciar FinanSecure Frontend con Docker Compose
# Asume que el build ya está compilado en: finansecure-web/dist/

set -e  # Exit on error

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════"
echo "  FinanSecure Frontend - Docker Compose Startup"
echo "════════════════════════════════════════════════════════"

# Verificar que el build existe
if [ ! -d "$PROJECT_DIR/finansecure-web/dist/finansecure-web/browser" ]; then
    echo "❌ Error: Build no encontrado"
    echo "   Ruta esperada: $PROJECT_DIR/finansecure-web/dist/finansecure-web/browser"
    echo ""
    echo "✅ Solución: Compila primero con:"
    echo "   cd $PROJECT_DIR/finansecure-web"
    echo "   npm install"
    echo "   npm run build"
    exit 1
fi

echo "✅ Build Angular encontrado"
echo ""

# Crear directorios si no existen
echo "📁 Creando directorios de volúmenes..."
mkdir -p "$PROJECT_DIR/data/auth_db"
mkdir -p "$PROJECT_DIR/data/transactions_db"
mkdir -p "$PROJECT_DIR/data/pgadmin"
mkdir -p "$PROJECT_DIR/logs/auth"
mkdir -p "$PROJECT_DIR/logs/transactions"

# Crear .env si no existe
if [ ! -f "$PROJECT_DIR/.env" ]; then
    echo "📝 Creando archivo .env..."
    cat > "$PROJECT_DIR/.env" << 'EOF'
ENVIRONMENT=Development
AUTH_DB_PASSWORD=SecureAuth2024!
TRANSACTIONS_DB_PASSWORD=SecureTransactions2024!
JWT_SECRET_KEY=your-super-secret-key-min-32-chars-change-in-prod
PGADMIN_EMAIL=admin@finansecure.com
PGADMIN_PASSWORD=AdminPassword2024!
FRONTEND_PORT=3000
AUTH_SERVICE_PORT=8080
TRANSACTIONS_SERVICE_PORT=8081
PGADMIN_PORT=5050
EOF
    echo "✅ Archivo .env creado"
else
    echo "✅ Archivo .env ya existe"
fi

echo ""
echo "🐳 Iniciando servicios con Docker Compose..."
echo ""

cd "$PROJECT_DIR"

# Construir imagen del frontend (rápido, usa el build compilado)
echo "📦 Construyendo imagen del frontend..."
docker build -f finansecure-web/Dockerfile.prod \
    -t finansecure-frontend:latest \
    . > /dev/null 2>&1

echo "✅ Imagen del frontend lista"
echo ""

# Iniciar todos los servicios
echo "🚀 Iniciando servicios..."
docker-compose up -d

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✨ SERVICIOS INICIADOS"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📋 Acceso a los servicios:"
echo ""
echo "   🌐 Frontend:        http://localhost:3000"
echo "   🔐 Auth API:        http://localhost:8080"
echo "   💳 Transactions:    http://localhost:8081"
echo "   📊 PgAdmin:         http://localhost:5050"
echo ""
echo "📊 Ver estado de contenedores:"
echo "   docker-compose ps"
echo ""
echo "📜 Ver logs:"
echo "   docker-compose logs -f"
echo ""
echo "🛑 Detener servicios:"
echo "   docker-compose down"
echo ""
