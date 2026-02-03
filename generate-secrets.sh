#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
# 🔐 GENERATE SECRETS - Crear claves criptográficamente seguras
# ════════════════════════════════════════════════════════════════════════════════
#
# USO:
#   ./generate-secrets.sh          # Generar nuevas claves
#   ./generate-secrets.sh --force  # Overwrite .env si existe
#
# REQUISITOS:
#   - openssl (instalado en Linux/Mac por defecto)
#   - En Windows: usar Git Bash o WSL
#
# ════════════════════════════════════════════════════════════════════════════════

set -e  # Exit on error

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔐 FinanSecure - Generar Secretos Seguros${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar si openssl está disponible
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}❌ ERROR: openssl no encontrado${NC}"
    echo "Instalar con:"
    echo "  macOS: brew install openssl"
    echo "  Linux: apt-get install openssl"
    echo "  Windows: usar Git Bash o WSL"
    exit 1
fi

# Verificar si .env ya existe
if [ -f .env ] && [ "$1" != "--force" ]; then
    echo -e "${YELLOW}⚠️  .env ya existe${NC}"
    echo "Opciones:"
    echo "  1. Mantener archivo actual"
    echo "  2. Regenerar todo (sobreescribir)"
    read -p "Selecciona (1/2): " choice
    
    if [ "$choice" != "2" ]; then
        echo "✅ Abortado - Usando .env existente"
        exit 0
    fi
fi

# ════════════════════════════════════════════════════════════════════════════════
# GENERAR SECRETOS
# ════════════════════════════════════════════════════════════════════════════════

echo "🔑 Generando secretos criptográficamente seguros..."
echo ""

# JWT Secret (256 bits = 64 caracteres hexadecimales)
echo "  • JWT_SECRET_KEY (256 bits)..."
JWT_KEY=$(openssl rand -hex 32)

# Database Password (192 bits base64)
echo "  • AUTH_DB_PASSWORD (192 bits base64)..."
DB_PASS=$(openssl rand -base64 24)

# PgAdmin Password
echo "  • PGADMIN_PASSWORD..."
PGADMIN_PASS=$(openssl rand -base64 18)

echo -e "${GREEN}✅ Secretos generados exitosamente${NC}"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# CREAR O ACTUALIZAR .env
# ════════════════════════════════════════════════════════════════════════════════

echo "📝 Creando archivo .env..."

cat > .env << EOF
# ════════════════════════════════════════════════════════════════════════════════
# 🔐 FinanSecure Environment - AUTO-GENERADO $(date '+%Y-%m-%d %H:%M:%S')
# ════════════════════════════════════════════════════════════════════════════════
# ⚠️  NUNCA commitear este archivo - Está en .gitignore

# 🔧 ENTORNO
ASPNETCORE_ENVIRONMENT=Development
ENVIRONMENT=Development

# 🗄️  BASE DE DATOS
AUTH_DB_PASSWORD=$DB_PASS
AUTH_DB_PORT=5432
AUTH_DB_USER=auth_user
AUTH_DB_NAME=finansecure_auth_db

# 🔐 JWT - Token Security
JWT_SECRET_KEY=$JWT_KEY
JWT_ISSUER=FinanSecure
JWT_AUDIENCE=FinanSecure.Client
JWT_EXPIRATION_MINUTES=15
JWT_REFRESH_EXPIRATION_DAYS=7

# 🌐 PUERTOS
FRONTEND_PORT=80
AUTH_SERVICE_PORT=8080
WEBSITE_PORT=3000
PGADMIN_PORT=5050

# 📊 PgAdmin
PGADMIN_EMAIL=admin@finansecure.com
PGADMIN_PASSWORD=$PGADMIN_PASS

# 📊 LOGGING
AUTH_LOG_LEVEL=Information
EOF

# Configurar permisos (solo propietario puede leer/escribir)
chmod 600 .env

echo -e "${GREEN}✅ Archivo .env creado${NC}"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# RESUMEN
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ CONFIGURACIÓN COMPLETADA${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "📍 Secretos generados y guardados en: .env"
echo ""
echo "🔐 Valores generados:"
echo "   JWT_SECRET_KEY ........ ${JWT_KEY:0:16}... (256 bits)"
echo "   AUTH_DB_PASSWORD ..... ${DB_PASS:0:10}... (base64)"
echo "   PGADMIN_PASSWORD ..... ${PGADMIN_PASS:0:10}... (base64)"
echo ""
echo "🚀 Próximos pasos:"
echo "   1. Revisar .env si es necesario"
echo "   2. Levantar servicios: docker compose up -d"
echo "   3. Verificar: docker ps"
echo ""
echo "⚠️  IMPORTANTE:"
echo "   • .env está en .gitignore (NUNCA será commitado)"
echo "   • Cada dev ejecuta generate-secrets.sh para su ambiente"
echo "   • En CI/CD, usar GitHub Secrets + AWS Secrets Manager"
echo ""
