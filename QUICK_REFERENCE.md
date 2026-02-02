# 📇 Quick Reference Card - FinanSecure Database

**Una página con todos los comandos y queries esenciales.**

---

## 🗄️ Instalación Rápida

### PostgreSQL en Docker

```bash
# Iniciar
docker-compose up -d

# Verificar
docker ps | grep postgres

# Conectar
psql -U postgres -h localhost
```

### Crear Bases de Datos

```sql
CREATE DATABASE finansecure_auth_db_dev;
CREATE DATABASE finansecure_transactions_db_dev;
```

### Ejecutar Scripts

```bash
psql -U postgres -d finansecure_auth_db_dev -f auth_service_schema.sql
psql -U postgres -d finansecure_transactions_db_dev -f transactions_service_schema.sql
```

---

## 🔍 Verificación Rápida

### ¿La BD está creada?
```sql
\l  -- Listar BDs
```

### ¿El schema está creado?
```sql
\dt auth.*
\dt transactions.*
```

### ¿Los índices están creados?
```sql
\di auth.*
\di transactions.*
```

### ¿Puedo conectarme desde .NET?
```csharp
// En Program.cs
builder.Services.AddDbContext<AuthContext>(options =>
    options.UseNpgsql("Host=localhost;Port=5432;Database=finansecure_auth_db_dev;Username=postgres;Password=postgres")
);
```

---

## 👤 Auth Service - Queries Frecuentes

### Login
```sql
SELECT id, username, email, password_hash, is_active
FROM auth.users
WHERE username = 'alice' AND deleted_at IS NULL;
```

### Crear token
```sql
INSERT INTO auth.refresh_tokens (user_id, token_value, expires_at)
VALUES ('550e8400-...'::UUID, 'eyJ...', CURRENT_TIMESTAMP + INTERVAL '7 days')
RETURNING id, expires_at;
```

### Validar token
```sql
SELECT * FROM auth.refresh_tokens
WHERE token_value = 'eyJ...'
  AND revoked_at IS NULL
  AND expires_at > CURRENT_TIMESTAMP;
```

### Logout
```sql
UPDATE auth.refresh_tokens
SET revoked_at = CURRENT_TIMESTAMP
WHERE id = '660e8400-...';
```

### Listar sesiones activas
```sql
SELECT * FROM auth.active_sessions WHERE user_id = '550e8400-...';
```

---

## 💰 Transactions Service - Queries Frecuentes

### Crear transacción
```sql
INSERT INTO transactions.transactions (
    user_id, category_id, type, amount, description, 
    transaction_date, status
) VALUES (
    '550e8400-...'::UUID,
    '660e8400-...'::UUID,
    'EXPENSE'::transactions.transaction_type,
    150.50,
    'Grocery shopping',
    CURRENT_TIMESTAMP,
    'COMPLETED'::transactions.transaction_status
) RETURNING id, created_at;
```

### Obtener transacciones del usuario
```sql
SELECT id, amount, description, type, transaction_date
FROM transactions.transactions
WHERE user_id = '550e8400-...' AND deleted_at IS NULL
ORDER BY transaction_date DESC LIMIT 50;
```

### Transacciones por fecha
```sql
SELECT * FROM transactions.transactions
WHERE user_id = '550e8400-...'
  AND transaction_date >= '2025-01-01'::DATE
  AND transaction_date < '2025-02-01'::DATE
  AND deleted_at IS NULL;
```

### Resumen mensual
```sql
SELECT * FROM transactions.transaction_summary
WHERE user_id = '550e8400-...'
  AND month = DATE_TRUNC('month', CURRENT_DATE);
```

### Estado de presupuestos
```sql
SELECT * FROM transactions.budget_status
WHERE user_id = '550e8400-...'
  AND status != 'OK';  -- Mostrar solo alertas
```

### Balance del usuario
```sql
SELECT * FROM transactions.get_user_balance_summary(
    '550e8400-...'::UUID,
    '2025-01-01'::DATE,
    CURRENT_DATE
);
```

### Ver auditoría de una transacción
```sql
SELECT action, old_values, new_values, created_at
FROM transactions.audit_logs
WHERE transaction_id = '770e8400-...'
ORDER BY created_at DESC;
```

---

## 🔐 Seguridad - Puntos Clave

### Validación en el código
```csharp
// ✅ CORRECTO: UserId del JWT
var userId = User.GetUserIdOrThrow();  // De JWT.sub
var transactions = await _repo.GetUserTransactions(userId);

// ❌ INCORRECTO: UserId del body
var userId = request.UserId;  // Potencial security hole
```

### WHERE clause obligatorio
```sql
-- ✅ CORRECTO
WHERE user_id = @userId AND deleted_at IS NULL

-- ❌ INCORRECTO (expone todos los datos)
WHERE deleted_at IS NULL

-- ❌ INCORRECTO (fácil de bypasear)
WHERE user_id = req.UserId  -- El usuario podría cambiar
```

### Soft delete siempre
```sql
-- ✅ CORRECTO
UPDATE transactions SET deleted_at = NOW() WHERE id = ?

-- ❌ INCORRECTO
DELETE FROM transactions WHERE id = ?
```

---

## 🚀 Mantenimiento Diario

### Limpiar tokens expirados
```sql
SELECT auth.cleanup_expired_refresh_tokens();
```

### Limpiar logs de auditoría (> 7 años)
```sql
SELECT transactions.cleanup_old_audit_logs();
```

### Analizar tablas
```sql
ANALYZE auth.users;
ANALYZE auth.refresh_tokens;
ANALYZE transactions.transactions;
ANALYZE transactions.audit_logs;
```

### Ver tamaño de BDs
```sql
SELECT datname, pg_size_pretty(pg_database_size(datname))
FROM pg_database
WHERE datname LIKE 'finansecure_%';
```

---

## 📊 Monitoreo

### Conexiones activas
```sql
SELECT datname, count(*) FROM pg_stat_activity
WHERE datname LIKE 'finansecure_%'
GROUP BY datname;
```

### Índices no usados
```sql
SELECT indexname, idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'transactions' AND idx_scan = 0;
```

### Queries lentas
```sql
ALTER SYSTEM SET log_min_duration_statement = 1000;
SELECT pg_reload_conf();
-- Ver logs después en: /var/log/postgresql/postgresql.log
```

### Tabla más grande
```sql
SELECT table_name, 
       pg_size_pretty(pg_total_relation_size(table_name))
FROM information_schema.tables
WHERE table_schema = 'transactions'
ORDER BY pg_total_relation_size(table_name) DESC
LIMIT 1;
```

---

## 🔧 Troubleshooting

### "Connection refused"
```bash
# Verificar PostgreSQL está corriendo
psql --version

# Si Docker:
docker-compose ps
docker logs finansecure-postgres

# Si local:
psql -U postgres  # Probar conexión directa
```

### "Database does not exist"
```sql
-- Verificar
\l

-- Crear si no existe
CREATE DATABASE finansecure_auth_db_dev;
```

### "Permission denied for schema"
```sql
-- Dar permisos
GRANT USAGE ON SCHEMA auth TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO postgres;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA auth TO postgres;
```

### "UUID extension not found"
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### "Index not used"
```sql
-- Verificar estadísticas
ANALYZE transactions;

-- Ejecutar query con EXPLAIN
EXPLAIN ANALYZE
SELECT * FROM transactions
WHERE user_id = '550e8400-...'::UUID
  AND transaction_date >= '2025-01-01'::DATE;

-- Si no usa índice, hacer REINDEX
REINDEX INDEX idx_transactions_user_date;
```

---

## 🎯 Índices Principales

### Auth Service
```
✓ idx_users_username              (login)
✓ idx_users_email                 (registro)
✓ idx_refresh_tokens_user_id      (sesiones)
✓ idx_refresh_tokens_token_value  (validación)
✓ idx_refresh_tokens_expires_at   (limpieza)
```

### Transactions Service
```
✓ idx_transactions_user_id        (CRÍTICO)
✓ idx_transactions_user_date      (rango de fechas)
✓ idx_transactions_category_id    (por categoría)
✓ idx_audit_logs_transaction_id   (historial)
✓ idx_budgets_user_month          (presupuestos)
```

---

## 💾 Backup & Restore

### Backup
```bash
# Backup auth_db
pg_dump -U postgres finansecure_auth_db_dev > auth_backup.sql

# Backup transactions_db
pg_dump -U postgres finansecure_transactions_db_dev > transactions_backup.sql
```

### Restore
```bash
# Restore auth_db
psql -U postgres finansecure_auth_db_dev < auth_backup.sql

# Restore transactions_db
psql -U postgres finansecure_transactions_db_dev < transactions_backup.sql
```

---

## 🔑 Connection Strings

### Development
```
Host=localhost;Port=5432;Database=finansecure_auth_db_dev;Username=postgres;Password=postgres;Pooling=true;MaxPoolSize=20;
```

### Production (ajustar)
```
Host=postgres.prod;Port=5432;Database=finansecure_auth_prod;Username=postgres;Password=<secure_password>;Pooling=true;MaxPoolSize=50;SSL Mode=Require;
```

---

## 📚 Documentos Relacionados

| Necesitas... | Leer |
|-------------|------|
| Instalación completa | DATABASE_SETUP_GUIDE.md |
| Conceptos de diseño | DATABASE_ARCHITECTURE.md |
| 50+ queries útiles | DATABASE_QUERIES.md |
| Diagramas visuales | DATABASE_VISUAL.md |
| Implementar JWT | JWT_IMPLEMENTATION_GUIDE.md |
| Testing API | JWT_TESTING_GUIDE.md |
| Índice general | DATABASE_INDEX.md |

---

## ⚡ TL;DR (Muy Resumido)

```sql
-- 1. Crear BDs
CREATE DATABASE finansecure_auth_db_dev;
CREATE DATABASE finansecure_transactions_db_dev;

-- 2. Ejecutar scripts
psql -U postgres -d finansecure_auth_db_dev -f auth_service_schema.sql
psql -U postgres -d finansecure_transactions_db_dev -f transactions_service_schema.sql

-- 3. Verificar
\dt auth.*
\dt transactions.*

-- 4. Usar en .NET
"DefaultConnection": "Host=localhost;Database=finansecure_auth_db_dev;Username=postgres;Password=postgres"

-- 5. Mantener
SELECT auth.cleanup_expired_refresh_tokens();
SELECT transactions.cleanup_old_audit_logs();
```

---

**Versión:** 1.0  
**Última actualización:** 2025-01-20  
**Imprime esta página y tenla a mano durante desarrollo!** 📄

