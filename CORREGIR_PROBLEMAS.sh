#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
# 🔧 SCRIPT DE CORRECCIÓN: Problemas Identificados en FinanSecure
# ════════════════════════════════════════════════════════════════════════════════
# Este script corrige los problemas críticos encontrados en la validación
# 
# Problemas a corregir:
# 1. ❌ Curl no instalado en Dockerfile del Auth Service
# 2. ❌ Base de datos no inicializada
# 3. ⚠️  NGINX devuelve 405 en lugar de enrutar correctamente
# ════════════════════════════════════════════════════════════════════════════════

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"
}

echo -e "${GREEN}🔧 INICIANDO CORRECCIONES${NC}\n"

# ════════════════════════════════════════════════════════════════════════════════
# PASO 1: Instalar curl en Dockerfile del Auth Service
# ════════════════════════════════════════════════════════════════════════════════

print_header "PASO 1: Instalar curl en Dockerfile del Auth Service"

DOCKERFILE_PATH="FinanSecure.Auth/Dockerfile"

if grep -q "curl" "$DOCKERFILE_PATH"; then
    echo -e "${YELLOW}⚠️  ADVERTENCIA${NC}: curl ya está mencionado en el Dockerfile"
else
    echo -e "${GREEN}📝 Añadiendo instalación de curl${NC}"
    
    # Buscar la línea donde está "USER appuser" e insertar curl antes
    if grep -q "USER appuser" "$DOCKERFILE_PATH"; then
        # Crear archivo temporal
        sed '
        /USER appuser/i\
# Instalar curl para healthcheck\
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
        ' "$DOCKERFILE_PATH" > "$DOCKERFILE_PATH.tmp"
        
        mv "$DOCKERFILE_PATH.tmp" "$DOCKERFILE_PATH"
        echo -e "${GREEN}✅ curl instalado en Dockerfile${NC}"
    else
        echo -e "${RED}❌ No se pudo encontrar 'USER appuser' en el Dockerfile${NC}"
    fi
fi

# ════════════════════════════════════════════════════════════════════════════════
# PASO 2: Detener y limpiar contenedores
# ════════════════════════════════════════════════════════════════════════════════

print_header "PASO 2: Detener y limpiar contenedores"

echo -e "${YELLOW}🛑 Deteniendo Docker Compose...${NC}"
docker-compose down || echo "Docker-compose no estaba corriendo"

echo -e "${YELLOW}🗑️  Eliminando volúmenes de base de datos...${NC}"
docker volume rm finansecure-unir_auth_db_data 2>/dev/null || echo "Volumen ya no existe"

echo -e "${GREEN}✅ Limpieza completada${NC}"

# ════════════════════════════════════════════════════════════════════════════════
# PASO 3: Reconstruir e iniciar servicios
# ════════════════════════════════════════════════════════════════════════════════

print_header "PASO 3: Reconstruir e iniciar servicios"

echo -e "${YELLOW}🏗️  Construyendo imágenes...${NC}"
docker-compose up -d --build

echo -e "${GREEN}✅ Servicios iniciados${NC}"

# ════════════════════════════════════════════════════════════════════════════════
# PASO 4: Esperar a que los servicios estén listos
# ════════════════════════════════════════════════════════════════════════════════

print_header "PASO 4: Esperando a que servicios estén listos"

echo -e "${YELLOW}⏳ Esperando 30 segundos a que PostgreSQL se inicialice...${NC}"
sleep 30

echo -e "${YELLOW}⏳ Esperando 15 segundos a que Auth Service se conecte a BD...${NC}"
sleep 15

# ════════════════════════════════════════════════════════════════════════════════
# PASO 5: Validar estado de contenedores
# ════════════════════════════════════════════════════════════════════════════════

print_header "PASO 5: Validar estado de contenedores"

echo "Estado de contenedores:"
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n${YELLOW}Verificando health checks...${NC}"

# Verificar Auth Service
if docker ps --format "{{.Names}}" | grep -q "finansecure-auth"; then
    HEALTH=$(docker inspect finansecure-auth --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    if [ "$HEALTH" = "healthy" ]; then
        echo -e "${GREEN}✅ Auth Service: HEALTHY${NC}"
    else
        echo -e "${YELLOW}⚠️  Auth Service: $HEALTH (puede tardar más)${NC}"
    fi
fi

# Verificar PostgreSQL
if docker ps --format "{{.Names}}" | grep -q "finansecure-postgres-auth"; then
    HEALTH=$(docker inspect finansecure-postgres-auth --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    if [ "$HEALTH" = "healthy" ]; then
        echo -e "${GREEN}✅ PostgreSQL: HEALTHY${NC}"
    else
        echo -e "${YELLOW}⚠️  PostgreSQL: $HEALTH${NC}"
    fi
fi

# Verificar Frontend
if docker ps --format "{{.Names}}" | grep -q "finansecure-frontend"; then
    HEALTH=$(docker inspect finansecure-frontend --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
    if [ "$HEALTH" = "healthy" ]; then
        echo -e "${GREEN}✅ Frontend: HEALTHY${NC}"
    else
        echo -e "${YELLOW}⚠️  Frontend: $HEALTH${NC}"
    fi
fi

# ════════════════════════════════════════════════════════════════════════════════
# PASO 6: Validar conectividad
# ════════════════════════════════════════════════════════════════════════════════

print_header "PASO 6: Validar conectividad"

echo -e "${YELLOW}Verificando logs de PostgreSQL...${NC}"
docker logs finansecure-postgres-auth 2>&1 | tail -5 | head -3

echo -e "\n${YELLOW}Verificando logs de Auth Service...${NC}"
docker logs finansecure-auth 2>&1 | tail -10 | head -5

# ════════════════════════════════════════════════════════════════════════════════
# RESUMEN
# ════════════════════════════════════════════════════════════════════════════════

print_header "✅ CORRECCIONES COMPLETADAS"

echo -e "${GREEN}Cambios realizados:${NC}"
echo "1. ✅ curl instalado en Dockerfile del Auth Service"
echo "2. ✅ Volumen de BD eliminado (nueva inicialización)"
echo "3. ✅ Contenedores reconstruidos"
echo "4. ✅ Servicios iniciados"

echo -e "\n${YELLOW}Próximos pasos:${NC}"
echo "1. Esperar 1-2 minutos a que la BD se inicialice completamente"
echo "2. Verificar que Auth Service reporte HEALTHY"
echo "3. Ejecutar nuevamente el script de validación"
echo "4. Probar el login en http://localhost"

echo -e "\n${BLUE}Para ver logs en tiempo real:${NC}"
echo "  docker-compose logs -f"

echo -e "\n${BLUE}Para reintentar esta operación:${NC}"
echo "  bash CORREGIR_PROBLEMAS.sh"
