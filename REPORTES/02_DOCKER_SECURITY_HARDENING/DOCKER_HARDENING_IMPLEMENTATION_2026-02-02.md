# 🔧 Docker Hardening: Implementation Guide
## Step-by-Step Corrections for FinanSecure

---

## ✅ REMEDIATION #1: Fix Image Tagging

### Current Problem (docker-compose.yml)
```yaml
services:
  postgres-auth:
    image: postgres:15-alpine  # ❌ Will pull ANY 15.x version
  
  pgadmin:
    image: dpage/pgadmin4:latest  # ❌ EXPLICITLY latest
```

### Solution: Pin to Specific Versions

```bash
# Step 1: Find exact versions currently in use
docker compose ps -a

# Step 2: Get full image digest
docker inspect postgres:15-alpine | grep -i digest
# Output example: "Digest": "sha256:abc123..."

# Step 3: Update docker-compose.yml with exact versions
```

### Commands to Execute

```bash
# Get current versions
docker image ls | grep -E "postgres|nginx|pgadmin"

# Pull exact versions
docker pull postgres:15.3-alpine
docker pull nginx:1.25.4-alpine
docker pull dpage/pgadmin4:8.4-alpine

# Verify
docker image inspect postgres:15.3-alpine --format='{{.RepoDigests}}'
```

---

## ✅ REMEDIATION #2: Remove Hardcoded JWT_SECRET_KEY from Dockerfile

### Current Problem
**File:** `FinanSecure.Auth/Dockerfile` (Line 136)
```dockerfile
ENV JWT_SECRET_KEY="your-secret-key-change-in-production"
```

**Risk:** Visible in `docker history` and image layers

### Solution: Delete from Dockerfile, rely on docker-compose

**Changes needed:**

```diff
FILE: FinanSecure.Auth/Dockerfile

- ENV JWT_SECRET_KEY="your-secret-key-change-in-production" \
-     JWT_ISSUER="FinanSecure" \
-     JWT_AUDIENCE="FinanSecure.Client" \
-     JWT_EXPIRATION_MINUTES="15" \
-     JWT_REFRESH_EXPIRATION_DAYS="7"

+ ENV JWT_ISSUER="FinanSecure" \
+     JWT_AUDIENCE="FinanSecure.Client" \
+     JWT_EXPIRATION_MINUTES="15" \
+     JWT_REFRESH_EXPIRATION_DAYS="7"
```

**Verification after change:**
```bash
docker build -f FinanSecure.Auth/Dockerfile -t test:latest .
docker history test:latest | grep JWT_SECRET_KEY
# Should return nothing ✅
```

---

## ✅ REMEDIATION #3: Remove Hardcoded DB_PASSWORD from Transactions Dockerfile

### Current Problem
**File:** `FinanSecure.Transactions/Dockerfile` (Line 102)
```dockerfile
ENV DB_PASSWORD="postgres"  # ❌ CRITICAL!
```

### Solution: Delete from Dockerfile

```diff
FILE: FinanSecure.Transactions/Dockerfile

- ENV DB_HOST="postgres" \
-     DB_PORT="5432" \
-     DB_DATABASE="finansecure_transactions_db_dev" \
-     DB_USER="postgres" \
-     DB_PASSWORD="postgres"

+ ENV DB_HOST="postgres" \
+     DB_PORT="5432" \
+     DB_DATABASE="finansecure_transactions_db_dev" \
+     DB_USER="postgres"
+     # DB_PASSWORD: Set only in docker-compose.yml
```

**Verification:**
```bash
docker build -f FinanSecure.Transactions/Dockerfile -t test:latest .
docker history test:latest | grep DB_PASSWORD
# Should return nothing ✅
```

---

## ✅ REMEDIATION #4: Fix AUTH_SERVICE_URL for Distributed Environments

### Current Problem
**File:** `FinanSecure.Transactions/Dockerfile` (Line 107)
```dockerfile
ENV AUTH_SERVICE_URL="http://localhost:8080"  # ❌ Won't work in K8s/ECS
```

**Why it fails:**
- Local Docker: `localhost` = container itself ❌
- Kubernetes: `localhost` = pod itself ❌
- AWS ECS: `localhost` = task itself ❌
- Docker Compose: `localhost` = WRONG ❌

**Correct in Docker Compose:**
- Service name = DNS name automatically
- `postgres-auth` → `postgres-auth:5432`
- `finansecure-auth` → `finansecure-auth:8080`

### Solution: Use Service Name

```diff
FILE: FinanSecure.Transactions/Dockerfile

- ENV AUTH_SERVICE_URL="http://localhost:8080"
+ ENV AUTH_SERVICE_URL="http://finansecure-auth:8080"
```

**Why this works:**
- Docker Compose: DNS resolves `finansecure-auth` to container IP ✅
- Kubernetes: DNS resolves `finansecure-auth` to service IP ✅
- ECS: Task networking works with service names ✅

---

## ✅ REMEDIATION #5: Create .dockerignore

### File to Create: `.dockerignore`

```dockerfile
# Git
.git/
.gitignore
.gitattributes
.github/

# Secrets & Environment
.env
.env.*
*.key
*.pem
*.pke
secrets.txt
appsettings.*.json
**/appsettings.Development.json

# Node (Frontend build)
node_modules/
npm-debug.log*
yarn-error.log*
yarn-debug.log*
dist/
.angular/

# .NET build artifacts
bin/
obj/
*.user
*.suo
*.sln.docstates
.vs/
.vscode/

# OS files
.DS_Store
Thumbs.db
*.swp
*.swo
*~

# CI/CD
.gitlab-ci.yml
.github/

# Build artifacts
docker-compose.override.yml

# Database
*.db
*.sqlite
*.sqlite3
```

**Impact:**
- Reduces build context from ~500MB to ~50MB
- Prevents secrets from accidentally being copied
- Speeds up builds

---

## ✅ REMEDIATION #6: Pin Base Image Versions (docker-compose.yml)

### Changes Required

```yaml
# ❌ BEFORE
version: '3.9'
services:
  postgres-auth:
    image: postgres:15-alpine
  
  finansecure-frontend:
    build:
      context: .
      dockerfile: finansecure-web/Dockerfile.prod
  
  pgadmin:
    image: dpage/pgadmin4:latest

# ✅ AFTER
version: '3.9'
services:
  postgres-auth:
    image: postgres:15.3-alpine  # ← Explicit version
    pull_policy: if_not_present   # ← Don't auto-pull
  
  finansecure-frontend:
    build:
      context: .
      dockerfile: finansecure-web/Dockerfile.prod
    image: finansecure-frontend:v1.0.0  # ← Tag your builds
  
  pgadmin:
    image: dpage/pgadmin4:8.4-alpine  # ← Explicit version + Alpine
    pull_policy: if_not_present
```

**Version Selection Guide:**

| Image | Current | Recommended | Why |
|-------|---------|-------------|-----|
| postgres | 15-alpine | 15.3-alpine | Latest stable patch |
| nginx | alpine | 1.25.4-alpine | Explicit full version |
| pgadmin | latest | 8.4-alpine | Alpine = smaller, latest stable |

**Commands to find versions:**

```bash
# PostgreSQL stable versions
curl -s https://www.postgresql.org/versions.json | jq '.[].minor'

# NGINX stable versions
curl -s https://nginx.org/download/ | grep -oP 'nginx-[\d\.]+' | sort -V

# pgAdmin versions
curl -s https://hub.docker.com/v2/repositories/dpage/pgadmin4/tags | jq '.results[] | select(.name | startswith("8.")) | .name'
```

---

## ✅ REMEDIATION #7: Add Security Options to docker-compose.yml

### Add to each service:

```yaml
services:
  finansecure-auth:
    # ... existing config ...
    
    # Security hardening
    security_opt:
      - no-new-privileges:true  # Prevent privilege escalation
    
    cap_drop:
      - ALL  # Drop ALL capabilities
    cap_add:
      - NET_BIND_SERVICE  # Only needed one
    
    # Optional: Read-only filesystem
    read_only: true  # May fail - test first!
    tmpfs:
      - /tmp
      - /app/logs
```

**Effect:**
- `no-new-privileges`: Prevents SUID/SGID abuse
- `cap_drop: ALL`: Removes dangerous capabilities
- `cap_add: NET_BIND_SERVICE`: Allows binding to port 8080
- `read_only: true`: Filesystem cannot be modified

---

## ✅ REMEDIATION #8: Update .env Configuration

### Current Issue
```bash
# .env currently has:
JWT_SECRET_KEY=change_me_in_production!  # ❌ Could be too short
AUTH_DB_PASSWORD=ChangeMe2024!            # ❌ Easy to guess
```

### Best Practice

```bash
# .env - Better approach
JWT_SECRET_KEY=$(openssl rand -base64 32)  # ← 256-bit entropy
AUTH_DB_PASSWORD=$(openssl rand -base64 24) # ← 192-bit entropy

# Or manually:
JWT_SECRET_KEY=aF8kL@pQ#9xM2vR5!jH7nS4dW6bE3cT1y0uIoA9sZ8xL5r2Q4w
AUTH_DB_PASSWORD=P@ssW0rd!kL9mN3xQ5rS2tU7vW8yZ1aB4cD6eF9gH0jK3lM
```

### Validation Script

```bash
#!/bin/bash
# Validate .env variables

check_var() {
    local var=$1
    local min_length=$2
    
    if [ ${#!var} -lt $min_length ]; then
        echo "❌ $var too short (min $min_length chars)"
        return 1
    fi
    echo "✅ $var length OK"
}

check_var JWT_SECRET_KEY 32
check_var AUTH_DB_PASSWORD 20
```

---

## 🔄 IMPLEMENTATION ORDER

### Day 1 (2-3 hours)
```bash
# 1. Update Dockerfiles - Remove hardcoded secrets
# Files to edit:
#   - FinanSecure.Auth/Dockerfile (line 136)
#   - FinanSecure.Transactions/Dockerfile (line 102-107)

# 2. Create .dockerignore
# New file at repo root

# 3. Test locally
docker compose down
docker compose up -d
docker compose ps
```

### Day 2 (1-2 hours)
```bash
# 4. Update docker-compose.yml - Pin versions, add security options
# 5. Test with new configuration
docker compose down
rm -rf data/  # Clear volumes for clean test
docker compose pull
docker compose up -d
docker compose ps  # Verify all healthy
```

### Day 3 (1 hour)
```bash
# 6. Verify no secrets in images
docker history finansecure-auth:latest | grep -i secret
docker history finansecure-transactions:latest | grep -i password
# Should return nothing ✅

# 7. Test image scanning
# (Once in CI/CD pipeline)
```

---

## 🧪 VALIDATION TESTS

### Test 1: No Secrets in Docker History
```bash
#!/bin/bash
echo "Testing for secrets in Docker history..."

for image in finansecure-auth finansecure-transactions; do
    echo "Checking $image..."
    if docker history $image:latest | grep -iE "secret|password|jwt"; then
        echo "❌ FAILED: Found secrets in $image"
        exit 1
    fi
    echo "✅ PASSED: No secrets in $image"
done
```

### Test 2: Correct Service URLs
```bash
#!/bin/bash
echo "Testing service URL resolution..."

docker compose exec finansecure-transactions curl -s http://finansecure-auth:8080/health
# Should return 200 OK
```

### Test 3: Image Tagging
```bash
#!/bin/bash
echo "Checking image tags..."

docker image ls | grep finansecure | grep -v latest
# Should show v1.0.0, not <none>
```

### Test 4: Non-Root User
```bash
#!/bin/bash
docker compose exec finansecure-auth id
# Should return: uid=1001(appuser) gid=1001(appgroup)
```

### Test 5: Health Checks
```bash
#!/bin/bash
docker compose ps
# All containers should show: healthy or Up (with status)
```

---

## ⚠️ ROLLBACK PLAN

If something breaks:

```bash
# Keep current working version
git tag backup-before-hardening

# Make changes
# ... apply fixes ...

# If something breaks:
git reset --hard backup-before-hardening
docker compose down -v
docker compose up -d

# Or restore specific file:
git checkout HEAD -- docker-compose.yml
```

---

## 📋 SIGN-OFF CHECKLIST

After implementing all changes:

```bash
☐ [ ] All Dockerfiles updated (no hardcoded secrets)
☐ [ ] .dockerignore created and working
☐ [ ] docker-compose.yml uses pinned versions
☐ [ ] docker-compose.yml adds security_opt, cap_drop
☐ [ ] All services start correctly
☐ [ ] All services show as healthy
☐ [ ] docker history shows no secrets
☐ [ ] SERVICE_URL uses service names, not localhost
☐ [ ] .env has strong credentials
☐ [ ] All health checks pass
☐ [ ] No errors in docker compose logs
```

---

**Ready to implement? Start with Day 1 steps above! 🚀**
