#!/bin/bash
# Script para compilar el frontend Angular
# Ejecutar ANTES de start-frontend.sh

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="$PROJECT_DIR/finansecure-web"

echo "════════════════════════════════════════════════════════"
echo "  FinanSecure Frontend - Build Script"
echo "════════════════════════════════════════════════════════"
echo ""

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Error: Node.js no está instalado"
    exit 1
fi

echo "✅ Node.js $(node --version) encontrado"
echo "✅ npm $(npm --version) encontrado"
echo ""

# Ir al directorio del frontend
cd "$FRONTEND_DIR"

# Instalar dependencias
echo "📦 Instalando dependencias (esto toma 3-5 minutos)..."
npm install

echo ""
echo "🔨 Compilando Angular en modo Production..."
echo "   (esto toma 2-5 minutos)..."
npm run build

echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✅ BUILD COMPLETADO"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📁 Archivos compilados en:"
echo "   $FRONTEND_DIR/dist/finansecure-web/browser"
echo ""
echo "🚀 Próximo paso:"
echo "   ./start-frontend.sh"
echo ""
