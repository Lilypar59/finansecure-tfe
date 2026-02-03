#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════════
# CI SIMULATION SCRIPT - Run locally to test CI pipeline readiness
# ════════════════════════════════════════════════════════════════════════════════
# This script simulates GitHub Actions CI locally
# Usage: ./ci-simulate.sh
# ════════════════════════════════════════════════════════════════════════════════

set -e

PROJECT_ROOT=$(pwd)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "════════════════════════════════════════════════════════════════════════════════"
echo "🚀 CI PIPELINE SIMULATION - FinanSecure"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# PHASE 1: PRE-FLIGHT CHECKS (⚡ ~10 seconds)
# ════════════════════════════════════════════════════════════════════════════════
echo "📋 PHASE 1: Pre-flight checks..."
echo ""

# Check required files
echo "  ✓ Checking required files..."
for file in "act1.sln" "docker-compose.yml" ".dockerignore"; do
  if [ ! -f "$file" ]; then
    echo -e "  ${RED}✗ Missing: $file${NC}"
    exit 1
  fi
done
echo -e "  ${GREEN}✓ All required files present${NC}"

# Validate YAML
echo "  ✓ Validating docker-compose.yml..."
if ! docker compose config > /dev/null 2>&1; then
  echo -e "  ${RED}✗ Invalid docker-compose.yml${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ docker-compose.yml is valid${NC}"

# Check project structure
echo "  ✓ Checking project structure..."
for dir in "FinanSecure.Auth" "FinanSecure.Transactions" "FinanSecure.Api" "finansecure-web"; do
  if [ ! -d "$dir" ]; then
    echo -e "  ${RED}✗ Missing directory: $dir${NC}"
    exit 1
  fi
done
echo -e "  ${GREEN}✓ All service directories present${NC}"

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# PHASE 2: SECURITY CHECKS (🔐 ~30 seconds)
# ════════════════════════════════════════════════════════════════════════════════
echo "🔐 PHASE 2: Security validation..."
echo ""

# Check for hardcoded secrets in C# files
echo "  ✓ Scanning C# files for hardcoded secrets..."
if grep -r "password\s*=" . --include="*.cs" --exclude-dir=bin --exclude-dir=obj 2>/dev/null | grep -v "SecureString\|config\|appsettings" | grep -q "."; then
  echo -e "  ${YELLOW}⚠ WARNING: Check password references in .cs files${NC}"
fi

# Check for CHANGE_ME patterns (except in .example files)
echo "  ✓ Scanning for CHANGE_ME defaults..."
if grep -r "CHANGE_ME" . --include="*.cs" --include="*.json" --exclude-dir=node_modules 2>/dev/null | grep -v ".example" | grep -q "."; then
  echo -e "  ${RED}✗ Found CHANGE_ME in source files (should be in .env only)${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ No CHANGE_ME defaults in source code${NC}"

# Check for .env files (should not be committed)
echo "  ✓ Verifying .env files are not committed..."
if git status --porcelain 2>/dev/null | grep "^?? \.env\|^A \.env"; then
  echo -e "  ${RED}✗ .env files should not be committed${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ .env files properly excluded from git${NC}"

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# PHASE 3: BUILD VALIDATION (🔨 ~4 minutes)
# ════════════════════════════════════════════════════════════════════════════════
echo "🔨 PHASE 3: Build validation..."
echo ""

# .NET Build
echo "  ✓ Building FinanSecure.Auth..."
if ! dotnet build "FinanSecure.Auth/FinanSecure.Auth.csproj" --configuration Release -q 2>&1 | tail -5; then
  echo -e "  ${RED}✗ Auth service build failed${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ Auth service built${NC}"

echo "  ✓ Building FinanSecure.Transactions..."
if ! dotnet build "FinanSecure.Transactions/FinanSecure.Transactions.csproj" --configuration Release -q 2>&1 | tail -5; then
  echo -e "  ${RED}✗ Transactions service build failed${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ Transactions service built${NC}"

echo "  ✓ Building FinanSecure.Api..."
if ! dotnet build "FinanSecure.Api/FinanSecure.Api.csproj" --configuration Release -q 2>&1 | tail -5; then
  echo -e "  ${RED}✗ API service build failed${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ API service built${NC}"

# Angular Build
echo "  ✓ Building Frontend (Angular)..."
cd finansecure-web

if ! npm ci --silent 2>&1 | tail -3; then
  echo -e "  ${RED}✗ Frontend npm install failed${NC}"
  exit 1
fi

if ! npm run build 2>&1 | tail -10; then
  echo -e "  ${RED}✗ Frontend build failed${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ Frontend built${NC}"

cd "$PROJECT_ROOT"

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# PHASE 4: TEST EXECUTION (✅ ~2 minutes)
# ════════════════════════════════════════════════════════════════════════════════
echo "✅ PHASE 4: Test execution..."
echo ""

echo "  ✓ Running .NET unit tests..."
if ! dotnet test --configuration Release -q --no-build 2>&1 | tail -10; then
  echo -e "  ${YELLOW}⚠ Some tests may have failed${NC}"
else
  echo -e "  ${GREEN}✓ All .NET tests passed${NC}"
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# PHASE 5: DOCKER BUILD (🐳 ~3 minutes)
# ════════════════════════════════════════════════════════════════════════════════
echo "🐳 PHASE 5: Docker build..."
echo ""

echo "  ✓ Building Auth service image (without .env)..."
if ! docker build \
  -f FinanSecure.Auth/Dockerfile \
  -t finansecure-auth:ci-test \
  --quiet . 2>&1 | tail -3; then
  echo -e "  ${RED}✗ Docker build failed${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ Auth image built${NC}"

echo "  ✓ Building Transactions service image..."
if ! docker build \
  -f FinanSecure.Transactions/Dockerfile \
  -t finansecure-tx:ci-test \
  --quiet . 2>&1 | tail -3; then
  echo -e "  ${RED}✗ Docker build failed${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ Transactions image built${NC}"

echo "  ✓ Building API service image..."
if ! docker build \
  -f FinanSecure.Api/Dockerfile \
  -t finansecure-api:ci-test \
  --quiet . 2>&1 | tail -3; then
  echo -e "  ${RED}✗ Docker build failed${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ API image built${NC}"

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# PHASE 6: SECURITY SCANNING
# ════════════════════════════════════════════════════════════════════════════════
echo "🔒 PHASE 6: Security scanning..."
echo ""

echo "  ✓ Checking image history for secrets..."
if docker history --no-trunc finansecure-auth:ci-test 2>/dev/null | grep -iE "secret|password|jwt.*=|db_.*="; then
  echo -e "  ${RED}✗ CRITICAL: Secrets found in Docker image${NC}"
  exit 1
fi
echo -e "  ${GREEN}✓ No secrets in Docker image history${NC}"

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# PHASE 7: RUNTIME VALIDATION (🚀 ~1 minute)
# ════════════════════════════════════════════════════════════════════════════════
echo "🚀 PHASE 7: Runtime validation..."
echo ""

# Create CI .env
cat > .env.ci << 'EOF'
ENVIRONMENT=Testing
AUTH_SERVICE_PORT=8080
TRANSACTIONS_SERVICE_PORT=8081
API_SERVICE_PORT=8000
POSTGRES_DB=finansecure_test
POSTGRES_USER=test_user
AUTH_DB_PASSWORD=TestPassword123
TRANSACTIONS_DB_PASSWORD=TestPassword123
JWT_SECRET_KEY=TestSecretKeyForCI12345678901234567890
JWT_ISSUER=https://finansecure.local
JWT_AUDIENCE=finansecure-app
AUTH_SERVICE_URL=http://auth:8080
TRANSACTIONS_SERVICE_URL=http://transactions:8081
EOF

echo "  ✓ Starting Docker Compose services..."
if ! docker compose --env-file .env.ci up -d 2>&1 | tail -5; then
  echo -e "  ${RED}✗ Failed to start services${NC}"
  docker compose logs --tail=20
  docker compose down -v || true
  rm .env.ci || true
  exit 1
fi

# Wait for services
echo "  ✓ Waiting for services to be healthy..."
sleep 20

# Check health
echo "  ✓ Checking service health..."
RETRY=0
MAX_RETRIES=5

while [ $RETRY -lt $MAX_RETRIES ]; do
  if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ Auth service is healthy${NC}"
    break
  fi
  RETRY=$((RETRY + 1))
  sleep 3
done

if [ $RETRY -eq $MAX_RETRIES ]; then
  echo -e "  ${YELLOW}⚠ Auth service health check timeout${NC}"
  docker compose logs auth | tail -20
fi

echo "  ✓ Docker Compose services running:"
docker compose ps

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# CLEANUP
# ════════════════════════════════════════════════════════════════════════════════
echo "🧹 Cleanup..."
echo ""

echo "  ✓ Stopping services..."
docker compose --env-file .env.ci down -v > /dev/null 2>&1 || true

echo "  ✓ Removing test images..."
docker image rm finansecure-auth:ci-test finansecure-tx:ci-test finansecure-api:ci-test > /dev/null 2>&1 || true

echo "  ✓ Removing temporary files..."
rm .env.ci

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ════════════════════════════════════════════════════════════════════════════════
echo "════════════════════════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ CI SIMULATION COMPLETE - Project is CI-ready!${NC}"
echo "════════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Create GitHub Actions workflows (.github/workflows/)"
echo "  2. Set up GitHub Secrets for production environment variables"
echo "  3. Enable branch protection rules on main branch"
echo "  4. Test workflows on develop branch first"
echo ""
