#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
# 🔧 SETUP-DEV-ENV - Configurar entorno de desarrollo completo
# ════════════════════════════════════════════════════════════════════════════════
#
# USO:
#   ./setup-dev-env.sh
#
# HACE:
#   1. Valida prerequisites (Docker, Docker Compose, git)
#   2. Crea .env con secretos seguros
#   3. Limpia redes/volúmenes antiguos (si es necesario)
#   4. Levanta stack Docker Compose
#   5. Valida que todos los servicios estén healthy
#
# ════════════════════════════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ════════════════════════════════════════════════════════════════════════════════
# FUNCIONES AUXILIARES
# ════════════════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 no encontrado. Por favor instalar e intentar de nuevo."
        exit 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
# INICIO
# ════════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🔧 FinanSecure - Setup Entorno de Desarrollo${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# VALIDAR PREREQUISITES
# ════════════════════════════════════════════════════════════════════════════════

log_info "Validando prerequisites..."
echo ""

check_command "docker"
log_success "Docker instalado"

check_command "docker-compose"
log_success "Docker Compose instalado"

check_command "git"
log_success "Git instalado"

check_command "openssl"
log_success "OpenSSL instalado"

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# CREAR .env CON SECRETOS
# ════════════════════════════════════════════════════════════════════════════════

log_info "Configurando variables de entorno..."
echo ""

if [ -f .env ]; then
    log_warn ".env ya existe"
    read -p "¿Regenerar secretos? (s/n) [n]: " -r regenerate
    regenerate=${regenerate:-n}
    
    if [ "$regenerate" = "s" ] || [ "$regenerate" = "S" ]; then
        ./generate-secrets.sh --force
    else
        log_success "Usando .env existente"
    fi
else
    ./generate-secrets.sh
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# LIMPIAR REDES/VOLÚMENES ANTIGUOS (OPCIONAL)
# ════════════════════════════════════════════════════════════════════════════════

log_info "Limpiando redes/volúmenes huérfanos..."
docker network prune -f > /dev/null 2>&1
docker volume prune -f > /dev/null 2>&1
log_success "Limpieza completada"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# LEVANTAR STACK DOCKER
# ════════════════════════════════════════════════════════════════════════════════

log_info "Levantando servicios Docker Compose..."
echo ""

docker compose up -d

echo ""
sleep 5  # Esperar a que servicios se estabilicen

# ════════════════════════════════════════════════════════════════════════════════
# VALIDAR ESTADO DE SERVICIOS
# ════════════════════════════════════════════════════════════════════════════════

log_info "Validando estado de servicios..."
echo ""

# Obtener estado de contenedores
declare -a SERVICES=("finansecure-postgres-auth" "finansecure-auth" "finansecure-frontend" "finansecure-website" "finansecure-pgadmin")

for service in "${SERVICES[@]}"; do
    if docker ps --filter "name=$service" --format '{{.Names}}' | grep -q "$service"; then
        status=$(docker inspect "$service" --format='{{.State.Health.Status}}' 2>/dev/null || echo "running")
        
        if [ "$status" = "healthy" ] || [ "$status" = "running" ]; then
            log_success "$service está UP ✓"
        else
            log_warn "$service está $status (esperando...)"
        fi
    else
        log_error "$service NO está running"
    fi
done

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# INSTRUCCIONES FINALES
# ════════════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ SETUP COMPLETADO${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "🎯 Servicios disponibles:"
echo ""
echo "   📱 Frontend (NGINX + Angular):"
echo "      URL: http://localhost"
echo ""
echo "   🌍 Website (Marketing):"
echo "      URL: http://localhost:3000"
echo ""
echo "   🔐 Auth Service API:"
echo "      URL: http://localhost:8080"
echo "      Health: http://localhost:8080/health"
echo ""
echo "   📊 PgAdmin (Gestión BD):"
echo "      URL: http://localhost:5050"
echo "      Email: admin@finansecure.com"
echo "      Password: (ver en .env)"
echo ""

echo "💡 Comandos útiles:"
echo ""
echo "   Ver logs:"
echo "      docker compose logs -f finansecure-auth"
echo ""
echo "   Detener servicios:"
echo "      docker compose down"
echo ""
echo "   Reconstruir imágenes:"
echo "      docker compose build"
echo ""
echo "   Ver estado completo:"
echo "      docker compose ps"
echo ""

echo "⚠️  Recordar:"
echo "   • .env está en .gitignore (NUNCA commitear)"
echo "   • Para devs nuevos: copiar .env.template y ejecutar generate-secrets.sh"
echo "   • En CI/CD: usar GitHub Secrets + AWS Secrets Manager"
echo ""
