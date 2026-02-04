## 📌 GUÍA RÁPIDA - PRÓXIMOS 10 MINUTOS

**Objetivo:** Implementar security hardening + levantar servicios

---

### ✅ PASO 1: Hacer ejecutables (30 segundos)

```bash
chmod +x generate-secrets.sh setup-dev-env.sh security-check.sh
```

---

### 🔐 PASO 2: Generar secretos (2 minutos)

```bash
./generate-secrets.sh
```

**Esperado:**
```
🔑 Generando secretos...
✅ JWT_SECRET_KEY (256 bits)...
✅ AUTH_DB_PASSWORD (192 bits)...
✅ PGADMIN_PASSWORD...

📝 Archivo .env creado
✅ CONFIGURACIÓN COMPLETADA
```

---

### ✓ PASO 3: Validar (1 minuto)

```bash
./security-check.sh
```

**Esperado:**
```
1️⃣ Checking appsettings.json... ✅ PASS
2️⃣ Checking .gitignore... ✅ PASS
3️⃣ Checking docker-compose.yml... ✅ PASS
4️⃣ Checking .env.template... ✅ PASS
5️⃣ Checking .dockerignore... ✅ PASS
6️⃣ Checking .env permissions... ✅ PASS
7️⃣ Checking Git history... ✅ PASS

✅ SECURITY CHECK PASSED
✅ Listo para CI/CD deployment
```

---

### 🐳 PASO 4: Levantar servicios (3 minutos)

```bash
docker compose up -d
sleep 30
docker compose ps
```

**Esperado:**
```
NAME                        STATUS
finansecure-postgres-auth   healthy
finansecure-auth            healthy
finansecure-frontend        healthy
finansecure-website         healthy
finansecure-pgadmin         healthy
```

---

### 🌐 PASO 5: Verificar (30 segundos)

```bash
curl http://localhost
```

**Esperado:**
```
<html>...</html>  (200 OK ✅)
```

---

## 🎯 RESULTADO

```
✅ .env generado con secretos seguros
✅ Todos los servicios corriendo
✅ Stack listo para desarrollo
✅ Security checks pasados
✅ Documentación completa
✅ CI/CD ready
```

---

## 📚 MÁS INFORMACIÓN

- **Overview:** START_HERE_2026-02-02.md
- **Detalles:** QUICKSTART_SECURITY_2026-02-02.md
- **Troubleshooting:** IMPLEMENTATION_GUIDE_2026-02-02.md
- **Arquitectura:** SECURITY_ARCHITECTURE_2026-02-02.md

---

**Tiempo total:** 10 minutos ⏱️
