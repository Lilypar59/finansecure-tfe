# 🚀 CI/CD IMPLEMENTATION QUICK REFERENCE
**FinanSecure - Fast Implementation Guide**

---

## 📋 FOR DEVOPS ENGINEERS: 3-STEP SETUP

### Step 1: Validate Locally (10 minutes)
```bash
cd c:\LProyectos\Unir\finansecure-tfe
chmod +x ci-simulate.sh
./ci-simulate.sh

# Expected: All phases complete with ✅ marks
# Takes ~11 minutes on first run, ~5 minutes cached
```

### Step 2: Set Up GitHub Secrets (5 minutes)
Go to **GitHub Repository Settings → Secrets and variables → Actions**

Add these secrets:
```
JWT_SECRET_KEY=<generate-32-char-random-string>
AUTH_DB_PASSWORD=<strong-password>
TRANSACTIONS_DB_PASSWORD=<strong-password>
PROD_AWS_ACCOUNT_ID=<your-aws-account>
PROD_AWS_REGION=us-east-1
PROD_RDS_ENDPOINT=<rds-endpoint>
PROD_ECR_REGISTRY=<account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Step 3: Enable Workflows (5 minutes)
- Push `.github/workflows/ci.yml` to your repository
- GitHub automatically detects and enables the workflow
- Test on **develop** branch first
- After validation, enable branch protection on **main**

---

## ⚡ QUICK COMMANDS

```bash
# Simulate CI locally
./ci-simulate.sh

# Run just Docker build (no .env needed)
docker build -f FinanSecure.Auth/Dockerfile -t test-auth .

# Run .NET build
dotnet build --configuration Release

# Run Angular build
cd finansecure-web && npm ci && npm run build

# Start all services locally
docker compose --env-file .env.ci up -d

# Check service health
curl http://localhost:8080/health
curl http://localhost:8081/health
curl http://localhost:8000/health

# Cleanup
docker compose down -v
```

---

## 🔍 FAILURE DIAGNOSIS

| Error | Fix |
|-------|-----|
| "port 8080 already in use" | `docker compose down -v` then retry |
| "Jwt:SecretKey not found" | Create `.env.ci` with JWT_SECRET_KEY |
| "Image not found" | Run `docker pull postgres:15.3` |
| "Build timeout" | Increase timeout-minutes in workflow |
| "npm ERR! 404" | Check npm registry: `npm config get registry` |

---

## 📊 WHAT GETS TESTED

```
✅ Phase 1: File validation (10s)
✅ Phase 2: Security scanning (30s)
✅ Phase 3: Parallel builds (4m)
   - Auth service
   - Transactions service
   - API gateway
   - Frontend (Angular)
✅ Phase 4: Unit tests (2m)
✅ Phase 5: Docker build (3m)
✅ Phase 6: Security scanning (30s)
✅ Phase 7: Runtime validation (1m)
   - docker-compose startup
   - Health checks
   - Port validation

Total: ~11 minutes (first run), ~5 minutes (cached)
```

---

## 🎯 PRE-MERGE CHECKLIST

Before clicking "Merge" in GitHub:
- [ ] CI pipeline shows all green ✅
- [ ] Code review approved by at least 1 senior engineer
- [ ] No new security warnings
- [ ] Tests passing (green checkmark next to commit)
- [ ] If database changes: migrations tested locally
- [ ] If API changes: backward compatibility verified
- [ ] Documentation updated (README, API docs)

---

## 🔒 SECURITY VALIDATION

CI automatically checks:
1. No hardcoded secrets (grep patterns)
2. No secrets in Docker images (history scan)
3. Dependencies audit (npm/dotnet vulnerability scan)
4. Code quality (linting, formatting)

Manual checks (code review):
1. No SQL injection (parameterized queries)
2. Authentication/authorization correct
3. No new admin endpoints
4. Error messages don't leak information

---

## 📈 EXPECTED BEHAVIOR

### First Push to PR
```
Status: In Progress... (3-5 minutes)
│
├─ Preflight: ✅ (10s)
├─ Security: ✅ (30s)
├─ Build: ✅ (4m)
├─ Test: ✅ (2m)
├─ Docker: ✅ (3m)
└─ Security Scan: ✅ (30s)
│
Status: All checks passed ✅
Comment: "CI Pipeline Complete - Ready for review"
```

### If Tests Fail
```
Status: FAILED ❌
│
├─ Preflight: ✅
├─ Security: ✅
├─ Build: ✅
├─ Test: ❌ (details in logs)
│
Action: Fix code locally, push to same branch, CI re-runs automatically
```

---

## 🚀 DEPLOYMENT (After Merge)

When code is merged to **main**:
1. CI pipeline runs (same as PR validation)
2. If all tests pass ✅
3. Automatically triggers **deploy.yml** workflow
4. Builds Docker images
5. Pushes to AWS ECR
6. Deploys to AWS EC2
7. Automatic rollback if health checks fail

---

## ❓ TROUBLESHOOTING

### Issue: Workflow not running
**Fix:** Push to repository to trigger (not local)
```bash
git push origin feature-branch
```

### Issue: "Can't find workflow file"
**Fix:** File must be at `.github/workflows/ci.yml`
```bash
mkdir -p .github/workflows
# Then create ci.yml in that directory
```

### Issue: "Secrets not available"
**Fix:** Must be set in GitHub repository settings
- Go to Settings → Secrets and variables → Actions
- Add each secret individually
- Workflow can reference via `${{ secrets.SECRET_NAME }}`

### Issue: "Build takes too long"
**Fix:** Enable Docker layer caching
- GitHub Actions automatically caches layers between runs
- First run: ~11 minutes
- Subsequent runs: ~5 minutes (if source unchanged)

---

## 📚 DETAILED DOCUMENTATION

For complete details, see:
1. **CI_READINESS_VALIDATION_GUIDE.md** - 5000+ word comprehensive guide
2. **CI_READINESS_EXECUTIVE_SUMMARY.md** - Management summary
3. **ci-simulate.sh** - Automated testing script

---

## ✅ IMPLEMENTATION TIMELINE

```
📅 Monday: Team review (30 min)
📅 Tuesday: Secrets setup (30 min) + Local validation (1 hour)
📅 Wednesday: Test on develop branch (2 hours) + Adjust as needed
📅 Thursday: Enable branch protection on main (30 min)
📅 Friday: Go live with automated CI/CD ✅

Total: ~1 week for full implementation
```

---

## 🎯 SUCCESS CRITERIA

Project is successfully using CI/CD when:
- ✅ Every PR automatically validates
- ✅ main branch has automated deployment
- ✅ All merges require passing CI checks
- ✅ Team never manually runs `docker build`
- ✅ Secrets secured in GitHub (not in code)
- ✅ Deployments are automated and repeatable

---

**Status:** Ready for implementation  
**Target Date:** Week of 2025-02-04  
**Estimated Effort:** 3-5 developer days  
**Risk Level:** LOW (all infrastructure validated)
