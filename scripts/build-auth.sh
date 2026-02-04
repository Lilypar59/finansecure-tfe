#!/bin/bash

# ════════════════════════════════════════════════════════════════════════════════
# Script: Diagnóstico y Build de FinanSecure.Auth en Docker
# Autor: FinanSecure Team
# Descripción: Automatiza diagnóstico y construcción de imagen Docker
# ════════════════════════════════════════════════════════════════════════════════

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ════════════════════════════════════════════════════════════════════════════════
# FUNCIONES
# ════════════════════════════════════════════════════════════════════════════════

print_header() {
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
}

print_ok() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# ════════════════════════════════════════════════════════════════════════════════
# DIAGNÓSTICO
# ════════════════════════════════════════════════════════════════════════════════

diagnose() {
    print_header "DIAGNÓSTICO: Verificando Estructura del Proyecto"
    
    local errors=0
    
    # Verificar carpeta base
    if [ -d "FinanSecure.Auth" ]; then
        print_ok "Carpeta FinanSecure.Auth existe"
    else
        print_error "Carpeta FinanSecure.Auth NO EXISTE"
        ((errors++))
    fi
    
    # Verificar archivo .csproj
    if [ -f "FinanSecure.Auth/FinanSecure.Auth.csproj" ]; then
        print_ok "Archivo .csproj existe"
    else
        print_error "Archivo .csproj NO EXISTE"
        ((errors++))
    fi
    
    # Verificar directorios críticos
    local dirs=("Controllers" "Data" "DTOs" "Interfaces" "Repositories" "Services")
    for dir in "${dirs[@]}"; do
        if [ -d "FinanSecure.Auth/$dir" ]; then
            print_ok "Directorio $dir existe"
        else
            print_error "Directorio $dir NO EXISTE"
            ((errors++))
        fi
    done
    
    # Verificar archivos .cs principales
    local files=("Program.cs" "Controllers/AuthController.cs" "Data/AuthContext.cs")
    for file in "${files[@]}"; do
        if [ -f "FinanSecure.Auth/$file" ]; then
            print_ok "Archivo $file existe"
        else
            print_error "Archivo $file NO EXISTE"
            ((errors++))
        fi
    done
    
    # Contar archivos .cs
    local cs_count=$(find FinanSecure.Auth -name "*.cs" -type f | wc -l)
    print_info "Encontrados $cs_count archivos .cs"
    
    if [ $cs_count -lt 10 ]; then
        print_warning "Solo se encontraron $cs_count archivos .cs (esperado >15)"
        ((errors++))
    else
        print_ok "Cantidad de archivos .cs es suficiente"
    fi
    
    # Verificar Dockerfile
    if [ -f "FinanSecure.Auth/Dockerfile" ]; then
        print_ok "Dockerfile existe"
        if grep -q "dotnet build" "FinanSecure.Auth/Dockerfile"; then
            print_ok "Dockerfile contiene comando 'dotnet build'"
        fi
    else
        print_error "Dockerfile NO EXISTE"
        ((errors++))
    fi
    
    # Verificar .dockerignore
    if [ -f ".dockerignore" ]; then
        print_ok ".dockerignore existe"
    else
        print_warning ".dockerignore NO EXISTE (no crítico)"
    fi
    
    # Resumen
    echo ""
    if [ $errors -eq 0 ]; then
        print_ok "DIAGNÓSTICO OK - Estructura válida"
        return 0
    else
        print_error "DIAGNÓSTICO FALLÓ - Se encontraron $errors problemas"
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
# BUILD
# ════════════════════════════════════════════════════════════════════════════════

build_docker() {
    print_header "BUILD: Construyendo imagen Docker"
    
    local tag="${1:-finansecure-auth:latest}"
    
    print_info "Etiqueta: $tag"
    print_info "Contexto: $(pwd)"
    print_info "Dockerfile: FinanSecure.Auth/Dockerfile"
    echo ""
    
    if docker build \
        -f FinanSecure.Auth/Dockerfile \
        . \
        -t "$tag" \
        --progress=plain; then
        print_ok "BUILD EXITOSO"
        print_info "Imagen creada: $tag"
        
        # Mostrar tamaño de la imagen
        local size=$(docker images "$tag" --format "{{.Size}}")
        print_info "Tamaño de imagen: $size"
        
        return 0
    else
        print_error "BUILD FALLÓ"
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
# TEST
# ════════════════════════════════════════════════════════════════════════════════

test_image() {
    print_header "TEST: Verificando imagen Docker"
    
    local tag="${1:-finansecure-auth:latest}"
    
    # Verificar que la imagen existe
    if docker images "$tag" --format "{{.Repository}}" &>/dev/null; then
        print_ok "Imagen $tag existe"
    else
        print_error "Imagen $tag NO EXISTE"
        return 1
    fi
    
    # Mostrar información de la imagen
    print_info "Información de la imagen:"
    docker images "$tag" --format "  ID: {{.ID}}\n  Tamaño: {{.Size}}\n  Creada: {{.CreatedAt}}"
    
    echo ""
    print_info "Para probar la imagen, ejecuta:"
    echo "  docker run --rm -p 8080:8080 $tag"
    
    return 0
}

# ════════════════════════════════════════════════════════════════════════════════
# LIMPIAR
# ════════════════════════════════════════════════════════════════════════════════

clean_docker() {
    print_header "CLEAN: Limpiando Docker"
    
    print_info "Removiendo imágenes finansecure-auth..."
    docker image rm finansecure-auth:* 2>/dev/null || true
    
    print_info "Limpiando sistema Docker..."
    docker system prune -f --filter "label!=keep"
    
    print_ok "Limpieza completada"
}

# ════════════════════════════════════════════════════════════════════════════════
# MAIN
# ════════════════════════════════════════════════════════════════════════════════

main() {
    echo ""
    print_header "FinanSecure.Auth - Docker Build Helper"
    echo ""
    
    case "${1:-diagnose}" in
        diagnose)
            diagnose
            ;;
        build)
            diagnose && build_docker "${2:-finansecure-auth:latest}"
            ;;
        test)
            test_image "${2:-finansecure-auth:latest}"
            ;;
        clean)
            clean_docker
            ;;
        full)
            diagnose && clean_docker && build_docker "${2:-finansecure-auth:latest}" && test_image "${2:-finansecure-auth:latest}"
            ;;
        *)
            echo "Uso: $0 {diagnose|build|test|clean|full} [tag]"
            echo ""
            echo "Comandos:"
            echo "  diagnose     - Verificar estructura del proyecto"
            echo "  build [tag]  - Construir imagen Docker (default: finansecure-auth:latest)"
            echo "  test [tag]   - Verificar que la imagen se creó correctamente"
            echo "  clean        - Limpiar imágenes y contenedores previos"
            echo "  full [tag]   - Ejecutar: diagnose + clean + build + test"
            echo ""
            echo "Ejemplos:"
            echo "  $0 diagnose"
            echo "  $0 build"
            echo "  $0 full finansecure-auth:v1.0"
            ;;
    esac
    
    echo ""
}

main "$@"

