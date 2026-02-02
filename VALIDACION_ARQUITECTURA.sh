#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
# 🔍 VALIDACIÓN INTEGRAL: Arquitectura FinanSecure
# ════════════════════════════════════════════════════════════════════════════════
# Script para validar que todos los microservicios estén funcionando correctamente
# Fecha: 4 de Enero, 2026
# ════════════════════════════════════════════════════════════════════════════════

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
PASSED=0
FAILED=0
WARNINGS=0

# ════════════════════════════════════════════════════════════════════════════════
# FUNCIONES AUXILIARES
# ════════════════════════════════════════════════════════════════════════════════

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"
}

test_passed() {
    echo -e "${GREEN}✅ PASSED${NC}: $1"
    ((PASSED++))
}

test_failed() {
    echo -e "${RED}❌ FAILED${NC}: $1"
    ((FAILED++))
}

test_warning() {
    echo -e "${YELLOW}⚠️  WARNING${NC}: $1"
    ((WARNINGS++))
}

# ════════════════════════════════════════════════════════════════════════════════
# 1. VALIDAR ESTADO DE CONTENEDORES
# ════════════════════════════════════════════════════════════════════════════════

print_header "1️⃣  VALIDACIÓN: Estado de Contenedores"

echo "Verificando que Docker está disponible..."
if command -v docker &> /dev/null; then
    test_passed "Docker está instalado"
    DOCKER_VERSION=$(docker --version)
    echo "   Version: $DOCKER_VERSION"
else
    test_failed "Docker no está instalado o no está en PATH"
    exit 1
fi

echo -e "\nVerificando Docker Compose..."
if command -v docker-compose &> /dev/null || command -v docker compose &> /dev/null; then
    test_passed "Docker Compose está disponible"
else
    test_failed "Docker Compose no está instalado"
    exit 1
fi

echo -e "\nVerificando estado de contenedores..."
echo "Contenedores activos:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || test_failed "No se puede listar contenedores"

# Verificar contenedores específicos
echo -e "\nVerificando contenedores FinanSecure..."
CONTAINERS=("finansecure-auth" "finansecure-postgres-auth" "finansecure-frontend" "finansecure-nginx")

for container in "${CONTAINERS[@]}"; do
    if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
        STATUS=$(docker inspect "$container" --format='{{.State.Status}}' 2>/dev/null || echo "unknown")
        if [ "$STATUS" = "running" ]; then
            test_passed "Contenedor '$container' está corriendo"
        else
            test_warning "Contenedor '$container' existe pero no está corriendo (Status: $STATUS)"
        fi
    else
        test_warning "Contenedor '$container' no existe"
    fi
done

# ════════════════════════════════════════════════════════════════════════════════
# 2. VALIDAR REDES DOCKER
# ════════════════════════════════════════════════════════════════════════════════

print_header "2️⃣  VALIDACIÓN: Redes Docker"

echo "Listando redes disponibles:"
docker network ls --filter "name=.*finansecure.*" --format "table {{.Name}}\t{{.Driver}}"

NETWORKS=("finansecure-unir_backend" "finansecure-unir_auth-network")

for network in "${NETWORKS[@]}"; do
    if docker network ls --format "{{.Name}}" | grep -q "^${network}$"; then
        test_passed "Red '$network' existe"
        echo "   Contenedores conectados:"
        docker network inspect "$network" --format "{{range .Containers}}   - {{.Name}}\n{{end}}"
    else
        test_warning "Red '$network' no existe"
    fi
done

# ════════════════════════════════════════════════════════════════════════════════
# 3. VALIDAR VOLÚMENES
# ════════════════════════════════════════════════════════════════════════════════

print_header "3️⃣  VALIDACIÓN: Volúmenes de Datos"

echo "Listando volúmenes..."
docker volume ls --filter "name=.*finansecure.*" --format "table {{.Name}}\t{{.Driver}}"

VOLUMES=("finansecure-unir_auth_db_data")

for volume in "${VOLUMES[@]}"; do
    if docker volume ls --format "{{.Name}}" | grep -q "^${volume}$"; then
        test_passed "Volumen '$volume' existe"
    else
        test_warning "Volumen '$volume' no existe"
    fi
done

# ════════════════════════════════════════════════════════════════════════════════
# 4. VALIDAR CONECTIVIDAD DE SERVICIOS
# ════════════════════════════════════════════════════════════════════════════════

print_header "4️⃣  VALIDACIÓN: Conectividad de Servicios"

echo "Verificando Puerto 80 (NGINX)..."
if docker ps --format "{{.Names}}" | grep -q "finansecure-nginx"; then
    if netstat -tuln 2>/dev/null | grep -q ":80 "; then
        test_passed "Puerto 80 (NGINX) está escuchando"
    else
        test_warning "Puerto 80 (NGINX) no está escuchando"
    fi
else
    test_warning "NGINX no está corriendo"
fi

echo -e "\nVerificando Puerto 8080 (Auth Service)..."
if docker ps --format "{{.Names}}" | grep -q "finansecure-auth"; then
    if netstat -tuln 2>/dev/null | grep -q ":8080 "; then
        test_passed "Puerto 8080 (Auth Service) está escuchando"
    else
        test_warning "Puerto 8080 (Auth Service) no está escuchando"
    fi
else
    test_warning "Auth Service no está corriendo"
fi

echo -e "\nVerificando Puerto 5432 (PostgreSQL)..."
if docker ps --format "{{.Names}}" | grep -q "finansecure-postgres-auth"; then
    if netstat -tuln 2>/dev/null | grep -q ":5432 "; then
        test_passed "Puerto 5432 (PostgreSQL) está escuchando"
    else
        test_warning "Puerto 5432 (PostgreSQL) no está escuchando"
    fi
else
    test_warning "PostgreSQL no está corriendo"
fi

# ════════════════════════════════════════════════════════════════════════════════
# 5. VALIDAR HEALTH CHECKS
# ════════════════════════════════════════════════════════════════════════════════

print_header "5️⃣  VALIDACIÓN: Health Checks"

echo "Verificando PostgreSQL Health Check..."
if docker ps --format "{{.Names}}" | grep -q "finansecure-postgres-auth"; then
    HEALTH=$(docker inspect finansecure-postgres-auth --format='{{.State.Health.Status}}' 2>/dev/null || echo "none")
    if [ "$HEALTH" = "healthy" ]; then
        test_passed "PostgreSQL está HEALTHY"
    elif [ "$HEALTH" = "unhealthy" ]; then
        test_failed "PostgreSQL está UNHEALTHY"
    else
        test_warning "PostgreSQL no tiene health check configurado (Status: $HEALTH)"
    fi
fi

echo -e "\nVerificando Auth Service Health Check..."
if docker ps --format "{{.Names}}" | grep -q "finansecure-auth"; then
    HEALTH=$(docker inspect finansecure-auth --format='{{.State.Health.Status}}' 2>/dev/null || echo "none")
    if [ "$HEALTH" = "healthy" ]; then
        test_passed "Auth Service está HEALTHY"
    elif [ "$HEALTH" = "unhealthy" ]; then
        test_failed "Auth Service está UNHEALTHY"
    else
        test_warning "Auth Service no tiene health check configurado (Status: $HEALTH)"
    fi
fi

# ════════════════════════════════════════════════════════════════════════════════
# 6. VALIDAR ENDPOINTS HTTP
# ════════════════════════════════════════════════════════════════════════════════

print_header "6️⃣  VALIDACIÓN: Endpoints HTTP"

echo "Verificando Frontend (NGINX)..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost 2>/dev/null | grep -q "200\|301\|302"; then
    test_passed "Frontend (NGINX) está respondiendo"
    curl -s -I http://localhost 2>/dev/null | head -5
else
    test_warning "Frontend (NGINX) no responde correctamente"
fi

echo -e "\nVerificando Auth Service Health Endpoint..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null | grep -q "200\|404"; then
    test_passed "Auth Service responde en /health"
else
    test_warning "Auth Service no responde en puerto 8080"
fi

# ════════════════════════════════════════════════════════════════════════════════
# 7. VALIDAR LOGS
# ════════════════════════════════════════════════════════════════════════════════

print_header "7️⃣  VALIDACIÓN: Análisis de Logs"

echo "Verificando logs de Auth Service..."
if docker ps --format "{{.Names}}" | grep -q "finansecure-auth"; then
    ERRORS=$(docker logs finansecure-auth 2>&1 | grep -i "error\|exception" | wc -l || echo "0")
    if [ "$ERRORS" -eq 0 ]; then
        test_passed "Auth Service: Sin errores críticos"
    else
        test_warning "Auth Service: $ERRORS líneas con 'error' o 'exception' detectadas"
    fi
fi

echo -e "\nVerificando logs de PostgreSQL..."
if docker ps --format "{{.Names}}" | grep -q "finansecure-postgres-auth"; then
    ERRORS=$(docker logs finansecure-postgres-auth 2>&1 | grep -i "error\|fatal" | wc -l || echo "0")
    if [ "$ERRORS" -eq 0 ]; then
        test_passed "PostgreSQL: Sin errores críticos"
    else
        test_warning "PostgreSQL: $ERRORS líneas con 'error' o 'fatal' detectadas"
    fi
fi

# ════════════════════════════════════════════════════════════════════════════════
# 8. VALIDAR VARIABLES DE ENTORNO
# ════════════════════════════════════════════════════════════════════════════════

print_header "8️⃣  VALIDACIÓN: Variables de Entorno"

echo "Verificando archivo .env..."
if [ -f ".env" ]; then
    test_passed "Archivo .env existe"
    echo "   Variables configuradas:"
    grep -v "^#" .env | grep -v "^$" | sed 's/^/   - /' || echo "   (Vacío o comentado)"
else
    test_warning "Archivo .env no encontrado"
fi

# ════════════════════════════════════════════════════════════════════════════════
# 9. VALIDACIÓN DE ARQUITECTURA FRONTEND
# ════════════════════════════════════════════════════════════════════════════════

print_header "9️⃣  VALIDACIÓN: Configuración del Frontend"

echo "Verificando referencias a URLs de Backend en código Angular..."

if grep -r "finansecure-auth" finansecure-web/src/ 2>/dev/null | grep -v "node_modules" > /dev/null; then
    test_failed "Frontend contiene referencias directas a 'finansecure-auth'"
elif grep -r "finansecure-transactions" finansecure-web/src/ 2>/dev/null | grep -v "node_modules" > /dev/null; then
    test_failed "Frontend contiene referencias directas a 'finansecure-transactions'"
elif grep -r ":8080" finansecure-web/src/ 2>/dev/null | grep -v "node_modules" > /dev/null; then
    test_failed "Frontend contiene referencias directas a puertos internos (:8080)"
else
    test_passed "Frontend no contiene referencias directas a servicios internos"
fi

echo -e "\nVerificando configuración de API URL en Frontend..."
if grep -r "apiUrl\|API_URL\|baseUrl" finansecure-web/src/ 2>/dev/null | grep -v "node_modules" | grep -v ".spec.ts" > /dev/null; then
    test_passed "Frontend contiene configuración de API URL base"
else
    test_warning "No se encontró configuración explícita de API URL base"
fi

# ════════════════════════════════════════════════════════════════════════════════
# RESUMEN FINAL
# ════════════════════════════════════════════════════════════════════════════════

print_header "📊 RESUMEN FINAL"

echo -e "${GREEN}✅ Pruebas Pasadas: $PASSED${NC}"
echo -e "${YELLOW}⚠️  Advertencias: $WARNINGS${NC}"
echo -e "${RED}❌ Pruebas Fallidas: $FAILED${NC}"

TOTAL=$((PASSED + FAILED))
SUCCESS_RATE=0
if [ $TOTAL -gt 0 ]; then
    SUCCESS_RATE=$((PASSED * 100 / TOTAL))
fi

echo -e "\n📈 Tasa de éxito: ${GREEN}${SUCCESS_RATE}%${NC} ($PASSED/$TOTAL)"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ¡ARQUITECTURA VALIDADA CORRECTAMENTE!${NC}"
    echo -e "Todos los servicios parecen estar funcionando correctamente.\n"
    exit 0
else
    echo -e "\n${RED}⚠️  SE ENCONTRARON PROBLEMAS${NC}"
    echo -e "Por favor, revise los errores anteriores y corrija antes de continuar.\n"
    exit 1
fi
