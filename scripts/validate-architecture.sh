#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
# 🔍 VALIDACIÓN: Arquitectura Correcta de Docker Compose
# ════════════════════════════════════════════════════════════════════════════════
# 
# Este script valida que la arquitectura de Docker sigue las mejores prácticas:
#  ✓ NGINX como API Gateway (único punto de entrada)
#  ✓ Backend PRIVADO (no accesible directamente desde navegador)
#  ✓ Database PRIVADA (solo accesible desde Auth Service)
#  ✓ Redes segregadas (Zero Trust)
#  ✓ Health checks configurados
#  ✓ Logging centralizado
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNINGS=0

# ════════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE VALIDACIÓN
# ════════════════════════════════════════════════════════════════════════════════

check_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((CHECKS_PASSED++))
}

check_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((CHECKS_FAILED++))
}

check_warning() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    ((CHECKS_WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

section() {
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════"
    echo "🔍 $1"
    echo "════════════════════════════════════════════════════════════════════════════"
}

# ════════════════════════════════════════════════════════════════════════════════
# VALIDACIONES
# ════════════════════════════════════════════════════════════════════════════════

section "1. VALIDAR SYNTAX DE docker-compose.yml"

if docker-compose config --quiet 2>/dev/null; then
    check_pass "docker-compose.yml es válido (sintaxis correcta)"
else
    check_fail "docker-compose.yml tiene errores de sintaxis"
    exit 1
fi

# ────────────────────────────────────────────────────────────────────────────────

section "2. VALIDAR ESTRUCTURA DE SERVICIOS"

# Verificar que NGINX esté presente
if grep -q "finansecure-frontend:" docker-compose.yml; then
    check_pass "Servicio NGINX (finansecure-frontend) está definido"
else
    check_fail "Servicio NGINX no encontrado en docker-compose.yml"
fi

# Verificar que Auth Service esté presente
if grep -q "finansecure-auth:" docker-compose.yml; then
    check_pass "Servicio Auth (finansecure-auth) está definido"
else
    check_fail "Servicio Auth no encontrado en docker-compose.yml"
fi

# Verificar que PostgreSQL esté presente
if grep -q "postgres-auth:" docker-compose.yml; then
    check_pass "Servicio PostgreSQL (postgres-auth) está definido"
else
    check_fail "Servicio PostgreSQL no encontrado en docker-compose.yml"
fi

# ────────────────────────────────────────────────────────────────────────────────

section "3. VALIDAR PUERTOS EXPUESTOS"

# NGINX debe estar expuesto en puerto 80 (es el gateway)
if grep -A 2 "finansecure-frontend:" docker-compose.yml | grep -q "80:80\|3000:80"; then
    check_pass "NGINX está expuesto en puerto 80 (API Gateway)"
else
    check_fail "NGINX no está configurado correctamente en puerto 80"
fi

# Auth Service debe estar expuesto para DEBUG (pero con advertencia)
if grep -A 5 "finansecure-auth:" docker-compose.yml | grep -q "8080:8080"; then
    check_warning "Auth Service está expuesto en puerto 8080 (solo para debug, comentar en producción)"
else
    check_pass "Auth Service NO está expuesto (correcto para producción)"
fi

# PostgreSQL puede estar expuesto en DEV (pero NO debe en PROD)
if grep -A 5 "postgres-auth:" docker-compose.yml | grep -q "5432:5432"; then
    check_warning "PostgreSQL está expuesto en puerto 5432 (solo para desarrollo, comentar en producción)"
else
    check_pass "PostgreSQL NO está expuesto (correcto para producción)"
fi

# ────────────────────────────────────────────────────────────────────────────────

section "4. VALIDAR DEPENDENCIAS"

# NGINX debe depender de Auth Service
if grep -A 10 "finansecure-frontend:" docker-compose.yml | grep -q "finansecure-auth"; then
    check_pass "NGINX depende de Auth Service (espera que esté listo)"
else
    check_fail "NGINX no depende de Auth Service"
fi

# Auth Service debe depender de PostgreSQL
if grep -A 10 "finansecure-auth:" docker-compose.yml | grep -q "postgres-auth"; then
    check_pass "Auth Service depende de PostgreSQL (espera que esté listo)"
else
    check_fail "Auth Service no depende de PostgreSQL"
fi

# ────────────────────────────────────────────────────────────────────────────────

section "5. VALIDAR HEALTH CHECKS"

# NGINX debe tener health check
if grep -A 50 "finansecure-frontend:" docker-compose.yml | grep -q "healthcheck:"; then
    check_pass "NGINX tiene health check configurado"
else
    check_fail "NGINX no tiene health check"
fi

# Auth Service debe tener health check
if grep -A 50 "finansecure-auth:" docker-compose.yml | grep -q "healthcheck:"; then
    check_pass "Auth Service tiene health check configurado"
else
    check_fail "Auth Service no tiene health check"
fi

# PostgreSQL debe tener health check
if grep -A 50 "postgres-auth:" docker-compose.yml | grep -q "healthcheck:"; then
    check_pass "PostgreSQL tiene health check configurado"
else
    check_fail "PostgreSQL no tiene health check"
fi

# ────────────────────────────────────────────────────────────────────────────────

section "6. VALIDAR REDES (SEGREGACIÓN - ZERO TRUST)"

# Debe tener red auth-network
if grep -q "auth-network:" docker-compose.yml; then
    check_pass "Red 'auth-network' está definida (PostgreSQL + Auth Service)"
else
    check_fail "Red 'auth-network' no encontrada"
fi

# Debe tener red backend
if grep -q "backend:" docker-compose.yml; then
    check_pass "Red 'backend' está definida (NGINX + Auth Service)"
else
    check_fail "Red 'backend' no encontrada"
fi

# PostgreSQL SOLO debe estar en auth-network (NO en backend)
if grep -B 5 "postgres-auth:" docker-compose.yml | grep -A 20 "networks:" | grep -q "backend:"; then
    check_fail "PostgreSQL está en la red 'backend' (debería estar SOLO en 'auth-network')"
else
    check_pass "PostgreSQL está aislado en 'auth-network' (no expuesto a NGINX)"
fi

# NGINX debe estar en backend (NO en auth-network)
if grep -A 50 "finansecure-frontend:" docker-compose.yml | grep -A 10 "networks:" | grep -q "auth-network"; then
    check_fail "NGINX está en la red 'auth-network' (debería estar SOLO en 'backend')"
else
    check_pass "NGINX está en 'backend' (no puede acceder a DB directamente)"
fi

# ────────────────────────────────────────────────────────────────────────────────

section "7. VALIDAR VOLÚMENES"

# auth_db_data debe existir
if grep -q "auth_db_data:" docker-compose.yml; then
    check_pass "Volumen 'auth_db_data' está definido (persistencia BD)"
else
    check_fail "Volumen 'auth_db_data' no encontrado"
fi

# auth_logs debe existir
if grep -q "auth_logs:" docker-compose.yml; then
    check_pass "Volumen 'auth_logs' está definido (logs del servicio)"
else
    check_fail "Volumen 'auth_logs' no encontrado"
fi

# pgadmin_data debe existir
if grep -q "pgadmin_data:" docker-compose.yml; then
    check_pass "Volumen 'pgadmin_data' está definido (configuración PgAdmin)"
else
    check_fail "Volumen 'pgadmin_data' no encontrado"
fi

# NO debe tener transactions_logs (deshabilitado)
if grep -q "transactions_logs:" docker-compose.yml; then
    check_warning "Volumen 'transactions_logs' aún existe (puede ser removido si no se usa)"
else
    check_pass "Volumen 'transactions_logs' removido (no se usa)"
fi

# NO debe tener rutas bind problemáticas
if grep -q "./data/pgadmin" docker-compose.yml || grep -q "./logs/transactions" docker-compose.yml; then
    check_fail "Existen rutas bind que podrían no existir (./data/pgadmin, ./logs/transactions)"
else
    check_pass "No hay rutas bind problemáticas"
fi

# ────────────────────────────────────────────────────────────────────────────────

section "8. VALIDAR VARIABLES DE ENTORNO"

# Debe tener JWT_SECRET_KEY
if grep -q "JWT_SECRET_KEY" docker-compose.yml; then
    check_pass "Variable JWT_SECRET_KEY está configurada"
else
    check_fail "Variable JWT_SECRET_KEY no encontrada"
fi

# Debe tener ENVIRONMENT
if grep -q "ASPNETCORE_ENVIRONMENT" docker-compose.yml; then
    check_pass "Variable ASPNETCORE_ENVIRONMENT está configurada"
else
    check_fail "Variable ASPNETCORE_ENVIRONMENT no encontrada"
fi

# ────────────────────────────────────────────────────────────────────────────────

section "9. VALIDAR LOGGING"

# Servicios deben tener logging configurado
for service in "finansecure-frontend" "finansecure-auth" "postgres-auth" "pgadmin"; do
    if grep -A 100 "$service:" docker-compose.yml | grep -q "logging:"; then
        check_pass "Servicio '$service' tiene logging configurado"
    else
        check_warning "Servicio '$service' NO tiene logging configurado"
    fi
done

# ════════════════════════════════════════════════════════════════════════════════
# RESUMEN
# ════════════════════════════════════════════════════════════════════════════════

section "📊 RESUMEN DE VALIDACIÓN"

echo ""
echo "Resultados:"
echo "  ${GREEN}✅ PASS: $CHECKS_PASSED${NC}"
echo "  ${YELLOW}⚠️  WARN: $CHECKS_WARNINGS${NC}"
echo "  ${RED}❌ FAIL: $CHECKS_FAILED${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ VALIDACIÓN EXITOSA: Arquitectura correcta implementada${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════${NC}"
    exit 0
else
    echo -e "${RED}════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}❌ VALIDACIÓN FALLIDA: Se encontraron $CHECKS_FAILED errores${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════════════════════${NC}"
    exit 1
fi
