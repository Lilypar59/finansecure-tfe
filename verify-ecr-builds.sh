#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════════
# AWS ECR Build & Push - Quick Setup Script
# ════════════════════════════════════════════════════════════════════════════════
# Purpose: Verify local Docker builds match what GitHub Actions will do
# Usage: bash verify-ecr-builds.sh
# ════════════════════════════════════════════════════════════════════════════════

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}AWS ECR Build & Push - Local Verification${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

# ════════════════════════════════════════════════════════════════════════════════
# STEP 1: Check prerequisites
# ════════════════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[1/5] Checking prerequisites...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is installed${NC}"

if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ Git is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Git is installed${NC}"

if ! command -v aws &> /dev/null; then
    echo -e "${YELLOW}⚠ AWS CLI is not installed (optional for local verification)${NC}"
else
    echo -e "${GREEN}✓ AWS CLI is installed${NC}"
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# STEP 2: Security checks
# ════════════════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[2/5] Running security checks...${NC}"

# Check for .env files
if git ls-files | grep -E "^\.env"; then
    echo -e "${RED}✗ ERROR: .env files found in git history!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ No .env files in git history${NC}"

# Check Dockerfiles for hardcoded secrets
FOUND_SECRETS=0
for dockerfile in FinanSecure.Auth/Dockerfile finansecure-web/Dockerfile.prod website/Dockerfile; do
    if [ -f "$dockerfile" ]; then
        if grep -iE "PASSWORD|SECRET|TOKEN|APIKEY|CHANGE_ME" "$dockerfile" | grep -v "^#"; then
            echo -e "${RED}✗ Found potential secret in $dockerfile${NC}"
            FOUND_SECRETS=1
        fi
    fi
done

if [ $FOUND_SECRETS -eq 1 ]; then
    exit 1
fi
echo -e "${GREEN}✓ No hardcoded secrets in Dockerfiles${NC}"

# Check for unpinned base images
FOUND_LATEST=0
for dockerfile in FinanSecure.Auth/Dockerfile finansecure-web/Dockerfile.prod website/Dockerfile; do
    if [ -f "$dockerfile" ]; then
        if grep "^FROM.*:latest" "$dockerfile"; then
            echo -e "${RED}✗ Found :latest tag in $dockerfile${NC}"
            FOUND_LATEST=1
        fi
    fi
done

if [ $FOUND_LATEST -eq 1 ]; then
    exit 1
fi
echo -e "${GREEN}✓ All base images have pinned versions${NC}"

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# STEP 3: Build Docker images locally
# ════════════════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[3/5] Building Docker images locally...${NC}"

COMMIT_SHA=$(git rev-parse --short HEAD)
TIMESTAMP=$(date -u +'%Y%m%d-%H%M%S')

echo "Build parameters:"
echo "  Commit SHA: ${COMMIT_SHA}"
echo "  Timestamp: ${TIMESTAMP}"
echo ""

# Build Auth Service
echo -e "${BLUE}Building Auth Service...${NC}"
if docker build \
    -f FinanSecure.Auth/Dockerfile \
    -t finansecure-auth:${COMMIT_SHA} \
    --build-arg BUILD_DATE=${TIMESTAMP} \
    --build-arg VCS_REF=$(git rev-parse HEAD) \
    . > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Auth Service built successfully${NC}"
    IMAGE_SIZE=$(docker images finansecure-auth:${COMMIT_SHA} --format "{{.Size}}")
    echo "  Size: ${IMAGE_SIZE}"
else
    echo -e "${RED}✗ Auth Service build failed${NC}"
    exit 1
fi

# Build Frontend Service
echo -e "${BLUE}Building Frontend Service...${NC}"
if docker build \
    -f finansecure-web/Dockerfile.prod \
    -t finansecure-frontend:${COMMIT_SHA} \
    --build-arg BUILD_DATE=${TIMESTAMP} \
    --build-arg VCS_REF=$(git rev-parse HEAD) \
    ./finansecure-web > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Frontend Service built successfully${NC}"
    IMAGE_SIZE=$(docker images finansecure-frontend:${COMMIT_SHA} --format "{{.Size}}")
    echo "  Size: ${IMAGE_SIZE}"
else
    echo -e "${RED}✗ Frontend Service build failed${NC}"
    exit 1
fi

# Build Website Service
echo -e "${BLUE}Building Website Service...${NC}"
if docker build \
    -f website/Dockerfile \
    -t finansecure-website:${COMMIT_SHA} \
    --build-arg BUILD_DATE=${TIMESTAMP} \
    --build-arg VCS_REF=$(git rev-parse HEAD) \
    ./website > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Website Service built successfully${NC}"
    IMAGE_SIZE=$(docker images finansecure-website:${COMMIT_SHA} --format "{{.Size}}")
    echo "  Size: ${IMAGE_SIZE}"
else
    echo -e "${RED}✗ Website Service build failed${NC}"
    exit 1
fi

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# STEP 4: Scan images for secrets
# ════════════════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[4/5] Scanning images for secrets...${NC}"

FOUND_IMAGE_SECRETS=0
for service in auth frontend website; do
    image_name="finansecure-${service}:${COMMIT_SHA}"
    if docker history --no-trunc ${image_name} | grep -iE "JWT_SECRET|DB_PASSWORD|CHANGE_ME|PASSWORD=|SECRET="; then
        echo -e "${RED}✗ Found potential secret in ${image_name} history${NC}"
        FOUND_IMAGE_SECRETS=1
    fi
done

if [ $FOUND_IMAGE_SECRETS -eq 1 ]; then
    echo -e "${RED}✗ Security scan failed - remove secrets from images${NC}"
    exit 1
fi
echo -e "${GREEN}✓ No secrets found in image history${NC}"

echo ""

# ════════════════════════════════════════════════════════════════════════════════
# STEP 5: Display summary
# ════════════════════════════════════════════════════════════════════════════════
echo -e "${YELLOW}[5/5] Summary${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ All local verification checks passed!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "Built Images:"
echo ""
docker images --filter "reference=finansecure-*" --format "  {{.Repository}}:{{.Tag}} ({{.Size}})" || true

echo ""
echo "Next steps:"
echo "  1. Review GitHub workflow in: .github/workflows/build-and-push.yml"
echo "  2. Configure GitHub Secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ACCOUNT_ID, AWS_REGION)"
echo "  3. Push to main branch to trigger the workflow"
echo "  4. Monitor GitHub Actions: Actions → Build and Push to AWS ECR"
echo ""

echo "To clean up local images:"
echo "  docker rmi finansecure-auth:${COMMIT_SHA}"
echo "  docker rmi finansecure-frontend:${COMMIT_SHA}"
echo "  docker rmi finansecure-website:${COMMIT_SHA}"
echo ""
