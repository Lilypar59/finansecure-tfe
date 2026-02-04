# ✅ DOCKER HARDENING: PRINTABLE CHECKLIST

**Date:** February 2, 2026  
**Project:** FinanSecure  
**Goal:** 52 minutes to production-ready security  

---

## 🚨 CRITICAL FIXES (Priority 1)

```
PHASE 1: IMAGE TAGGING (15 minutes)
═════════════════════════════════════════════════════════════

File: docker-compose.yml

☐ Line ~34:    postgres:15-alpine        → postgres:15.3-alpine
☐ Line ~34:    Add: pull_policy: if_not_present

☐ Line ~260:   nginx:alpine              → nginx:1.25.4-alpine
☐ Line ~260:   Add: pull_policy: if_not_present

☐ Line ~301:   pgadmin4:latest           → pgadmin4:8.4-alpine
☐ Line ~301:   Add: pull_policy: if_not_present

VERIFICATION:
☐ docker compose pull --no-parallel
☐ Confirm all images pulled with explicit versions


PHASE 2: REMOVE HARDCODED JWT SECRET (5 minutes)
═════════════════════════════════════════════════════════════

File: FinanSecure.Auth/Dockerfile

☐ Line 136: DELETE this line:
   ENV JWT_SECRET_KEY="your-secret-key-change-in-production"

☐ KEEP these lines:
   ENV JWT_ISSUER="FinanSecure"
   ENV JWT_AUDIENCE="FinanSecure.Client"

VERIFICATION:
☐ docker build -f FinanSecure.Auth/Dockerfile .
☐ docker history [image] | grep JWT_SECRET_KEY
☐ Result: (nothing should appear)


PHASE 3: REMOVE HARDCODED DB PASSWORD (5 minutes)
═════════════════════════════════════════════════════════════

File: FinanSecure.Transactions/Dockerfile

☐ Lines 98-102: DELETE:
   ENV DB_HOST="postgres"
   ENV DB_PORT="5432"
   ENV DB_DATABASE="..."
   ENV DB_USER="postgres"
   ENV DB_PASSWORD="postgres"

☐ REPLACE with:
   ENV DB_HOST="postgres"
   ENV DB_PORT="5432"
   ENV DB_DATABASE="finansecure_transactions_db_dev"
   ENV DB_USER="postgres"
   # DB_PASSWORD: Set in docker-compose.yml only

VERIFICATION:
☐ docker build -f FinanSecure.Transactions/Dockerfile .
☐ docker history [image] | grep DB_PASSWORD
☐ Result: (nothing should appear)


PHASE 4: FIX localhost → SERVICE NAME (2 minutes)
═════════════════════════════════════════════════════════════

File: FinanSecure.Transactions/Dockerfile

☐ Line 107: CHANGE:
   FROM: ENV AUTH_SERVICE_URL="http://localhost:8080"
   TO:   ENV AUTH_SERVICE_URL="http://finansecure-auth:8080"

VERIFICATION:
☐ docker-compose exec transactions curl http://finansecure-auth:8080/health
☐ Result: HTTP 200 OK


PHASE 5: CREATE .dockerignore (5 minutes)
═════════════════════════════════════════════════════════════

New file: .dockerignore (at repo root)

☐ Create file with contents from CODE_FIXES document
☐ Include:
   ☐ .env
   ☐ .env.*
   ☐ .git
   ☐ node_modules
   ☐ bin
   ☐ obj
   ☐ dist

VERIFICATION:
☐ ls -la .dockerignore
☐ file size should be ~1 KB


TESTING & VALIDATION (10 minutes)
═════════════════════════════════════════════════════════════

☐ docker compose down -v
☐ docker compose build --no-cache
☐ docker compose up -d

☐ docker compose ps
   Expected: All containers "Up" and "healthy"

☐ docker history finansecure-auth | grep -i secret
   Expected: (nothing - no secrets visible)

☐ docker history finansecure-transactions | grep -i password
   Expected: (nothing - no secrets visible)

☐ docker inspect finansecure-auth | jq '.[] | .HostConfig.SecurityOpt'
   Expected: Empty or minimal (we'll add security opts next)
```

---

## 🟠 HIGH PRIORITY FIXES (Priority 2)

```
PHASE 6: ADD SECURITY OPTIONS (15 minutes)
═════════════════════════════════════════════════════════════

File: docker-compose.yml

For SERVICE: finansecure-auth

☐ Add after "volumes:" section:

    security_opt:
      - no-new-privileges:true
    
    cap_drop:
      - ALL
    
    cap_add:
      - NET_BIND_SERVICE
    
    tmpfs:
      - /tmp
      - /app/logs


For SERVICE: finansecure-frontend

☐ Add after "healthcheck:" section:

    security_opt:
      - no-new-privileges:true
    
    cap_drop:
      - ALL
    
    cap_add:
      - NET_BIND_SERVICE
    
    read_only: true
    
    tmpfs:
      - /var/cache/nginx
      - /var/log/nginx
      - /var/run


VERIFICATION:
☐ docker compose up -d
☐ docker inspect finansecure-auth | jq '.[] | .HostConfig.SecurityOpt'
   Expected: ["no-new-privileges:true"]

☐ docker inspect finansecure-auth | jq '.[] | .HostConfig.CapDrop'
   Expected: ["ALL"]

☐ docker inspect finansecure-auth | jq '.[] | .HostConfig.CapAdd'
   Expected: ["NET_BIND_SERVICE"]


PHASE 7: CREATE .env.template (2 minutes)
═════════════════════════════════════════════════════════════

New file: .env.template (at repo root)

☐ Create file with contents from CODE_FIXES document
☐ Include all variable names with CHANGE_ME placeholders
☐ Example:
   JWT_SECRET_KEY=CHANGE_ME_MIN_32_CHARS
   AUTH_DB_PASSWORD=CHANGE_ME_STRONG_PASSWORD


PHASE 8: FINAL VALIDATION (10 minutes)
═════════════════════════════════════════════════════════════

Test 1: Services Start Correctly
☐ docker compose down -v
☐ docker compose up -d
☐ docker compose ps
   Expected: All containers "healthy" or "Up"

Test 2: No Secrets in Dockerfile History
☐ docker history finansecure-auth:latest | wc -l
☐ docker history finansecure-auth:latest | grep -iE "secret|password|key"
   Expected: (no output)

Test 3: Security Options Applied
☐ docker inspect finansecure-auth | grep -i "privilege"
   Expected: "no-new-privileges:true"

Test 4: Services Communicate
☐ docker compose exec finansecure-transactions \
    curl http://finansecure-auth:8080/health
   Expected: 200 OK response

Test 5: Build Context Reduced
☐ docker compose build --no-cache 2>&1 | grep "Sending build context"
   Expected: Size should be < 100 MB (was 500+ MB)
```

---

## 📝 FILES CHANGED SUMMARY

```
Files Modified: 5
Lines Added:    ~200
Lines Removed:  ~15
Total Time:     52 minutes

BREAKDOWN:

✅ FinanSecure.Auth/Dockerfile
   └─ Removed 1 line (JWT_SECRET_KEY)
   └─ Time: 5 minutes

✅ FinanSecure.Transactions/Dockerfile
   └─ Removed 5 lines (DB credentials)
   └─ Changed 1 line (localhost → service name)
   └─ Time: 7 minutes

✅ docker-compose.yml
   └─ Changed 3 lines (pin versions)
   └─ Added 30+ lines (security options)
   └─ Time: 25 minutes

✅ .dockerignore (NEW FILE)
   └─ Created: 52 lines
   └─ Time: 5 minutes

✅ .env.template (NEW FILE)
   └─ Created: 60 lines
   └─ Time: 2 minutes

TOTAL DEVELOPMENT TIME: 44 minutes
TESTING TIME: 8 minutes
GRAND TOTAL: 52 minutes
```

---

## ✅ GIT WORKFLOW

```
Step 1: Create Branch
☐ git checkout -b security/docker-hardening

Step 2: Make Changes
☐ Edit FinanSecure.Auth/Dockerfile
☐ Edit FinanSecure.Transactions/Dockerfile
☐ Edit docker-compose.yml
☐ Create .dockerignore
☐ Create .env.template

Step 3: Commit
☐ git add -A
☐ git commit -m "🔐 Security: Docker hardening (image tagging, secrets, options)"

Step 4: Verify Commit
☐ git log --oneline -n 1
☐ git show --stat

Step 5: Push & Create PR
☐ git push origin security/docker-hardening
☐ Create Pull Request on GitHub/GitLab
☐ Request review from security team

Step 6: Merge
☐ Code review passed
☐ All CI checks green
☐ Merge to main/develop
```

---

## 🔍 CODE REVIEW CHECKLIST

**For Reviewer:**

```
DOCKERFILES:
☐ FinanSecure.Auth/Dockerfile
   ☐ JWT_SECRET_KEY removed
   ☐ Other ENV vars intact
   ☐ No other secrets visible

☐ FinanSecure.Transactions/Dockerfile
   ☐ DB_PASSWORD removed
   ☐ JWT_SECRET_KEY removed
   ☐ localhost:8080 → finansecure-auth:8080
   ☐ No other secrets visible

DOCKER-COMPOSE:
☐ Image versions pinned (not implicit latest)
☐ pull_policy set to if_not_present
☐ Security options added (cap_drop, cap_add, security_opt)
☐ Secrets use ${VAR} syntax

NEW FILES:
☐ .dockerignore exists and excludes secrets
☐ .env.template exists with all variables documented
☐ Both files properly formatted

OVERALL:
☐ No hardcoded secrets in any file
☐ All changes aligned with security audit
☐ Code follows team standards
☐ Documentation updated if needed
```

---

## 🚀 POST-IMPLEMENTATION

```
After Merging (Next Steps):

Week 1:
☐ Confirm all tests pass
☐ Deploy to staging environment
☐ Monitor logs for any issues

Week 2:
☐ Add image scanning (Trivy)
☐ Setup Docker Content Trust
☐ Configure GitHub Actions secrets

Week 3:
☐ Test AWS EC2/ECS deployment
☐ Setup Secrets Manager integration

Week 4:
☐ Production rollout
☐ Team training
☐ Documentation updates
```

---

## 📞 TROUBLESHOOTING QUICK FIXES

```
Problem: "docker compose up fails with JWT_SECRET_KEY error"
Solution: Check .env file exists and JWT_SECRET_KEY is set
Command: echo $JWT_SECRET_KEY

Problem: "Services can't communicate (localhost:8080 error)"
Solution: Use service names instead (finansecure-auth:8080)
Command: docker compose exec [service] curl http://finansecure-auth:8080

Problem: "docker history still shows passwords"
Solution: Old cached layers, need full rebuild
Command: docker system prune -a && docker compose build --no-cache

Problem: "Build is still slow (not using .dockerignore)"
Solution: Verify .dockerignore exists in repo root
Command: ls -la .dockerignore && wc -l .dockerignore

Problem: "Security options not applied"
Solution: Restart containers for changes to take effect
Command: docker compose restart
```

---

## ⏱️ TIME TRACKING

```
PHASE 1: Image Tagging              │ ░░░░░░░░░░░░░░░░░░░ 15 min
PHASE 2: Remove JWT Secret          │ ░░░░ 5 min
PHASE 3: Remove DB Password         │ ░░░░ 5 min
PHASE 4: Fix localhost              │ ░░ 2 min
PHASE 5: Create .dockerignore       │ ░░░░ 5 min
─────────────────────────────────────┼─────────────
CRITICAL TOTAL                      │ 32 minutes

PHASE 6: Security Options           │ ░░░░░░░░░░░░░░░░░░░ 15 min
PHASE 7: Create .env.template       │ ░░ 2 min
─────────────────────────────────────┼─────────────
HIGH PRIORITY TOTAL                 │ 17 minutes

TESTING & VALIDATION                │ ░░░░░░░░░░ 10 min
─────────────────────────────────────┼─────────────
GRAND TOTAL                         │ 59 minutes

Buffer (if needed)                  │ ±10 minutes
─────────────────────────────────────┴─────────────
ESTIMATED COMPLETION                52 minutes ✅
```

---

**PRINT THIS PAGE AND TRACK YOUR PROGRESS!** 📋

Print & Pin on Your Monitor! 📌
