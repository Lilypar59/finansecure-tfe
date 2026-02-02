# 📝 Queries SQL Útiles - FinanSecure Database

Colección de queries prácticas para desarrollo, debugging y monitoreo.

---

## 📋 Tabla de Contenidos

1. [Verificación Básica](#verificación-básica)
2. [Auth Service Queries](#auth-service-queries)
3. [Transactions Service Queries](#transactions-service-queries)
4. [Monitoreo y Performance](#monitoreo-y-performance)
5. [Debugging](#debugging)
6. [Mantenimiento](#mantenimiento)

---

## ✅ Verificación Básica

### Verificar que las BDs existen
```sql
-- Conectado como: postgres

SELECT 
    datname AS "Base de Datos",
    pg_size_pretty(pg_database_size(datname)) AS "Tamaño"
FROM pg_database
WHERE datname LIKE 'finansecure_%'
ORDER BY datname;

-- Resultado esperado:
--  Base de Datos               | Tamaño
-- --------------------------------+---------
--  finansecure_auth_db_dev      | 1234 kB
--  finansecure_transactions_db_dev| 2345 kB
```

### Verificar Extensiones
```sql
-- En cualquier BD
SELECT 
    extname AS "Extensión",
    extversion AS "Versión"
FROM pg_extension
WHERE extname IN ('uuid-ossp', 'plpgsql');

-- Resultado esperado:
--  Extensión | Versión
-- -----------+---------
--  uuid-ossp | 1.1
--  plpgsql   | 1.0
```

### Verificar Esquemas
```sql
-- En cualquier BD
SELECT 
    schema_name AS "Schema"
FROM information_schema.schemata
WHERE schema_name IN ('auth', 'transactions', 'public')
ORDER BY schema_name;
```

---

## 🔐 Auth Service Queries

### 1. Búsquedas de Usuarios

#### Encontrar usuario por username
```sql
-- En: finansecure_auth_db_dev

SELECT 
    id,
    username,
    email,
    is_active,
    email_verified,
    created_at,
    last_login_at
FROM auth.users
WHERE username = 'admin'
  AND deleted_at IS NULL;

-- Índice usado: idx_users_username
-- Tiempo esperado: < 1ms
```

#### Encontrar usuario por email
```sql
SELECT 
    id,
    username,
    email,
    is_active,
    email_verified,
    created_at
FROM auth.users
WHERE email = 'user@example.com'
  AND deleted_at IS NULL;

-- Índice usado: idx_users_email
-- Tiempo esperado: < 1ms
```

#### Buscar usuarios por patrón
```sql
SELECT 
    id,
    username,
    email,
    is_active,
    created_at
FROM auth.users
WHERE username ILIKE 'admin%'
  AND deleted_at IS NULL
ORDER BY username;

-- Nota: No usa índice (pattern matching)
-- Para búsquedas frecuentes: considerar full-text search
```

### 2. Gestión de Sesiones

#### Obtener todas las sesiones activas de un usuario
```sql
SELECT 
    id,
    user_id,
    created_at,
    expires_at,
    ip_address,
    user_agent,
    CURRENT_TIMESTAMP < expires_at AS is_valid
FROM auth.refresh_tokens
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND revoked_at IS NULL
  AND expires_at > CURRENT_TIMESTAMP
ORDER BY created_at DESC;

-- Índice usado: idx_refresh_tokens_user_id
-- Tiempo esperado: < 5ms
```

#### Buscar sesión por token
```sql
SELECT 
    id,
    user_id,
    created_at,
    expires_at,
    ip_address,
    revoked_at,
    CURRENT_TIMESTAMP < expires_at AS is_valid
FROM auth.refresh_tokens
WHERE token_value = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
LIMIT 1;

-- Índice usado: idx_refresh_tokens_token_value
-- Tiempo esperado: < 1ms
```

#### Revocar sesión (logout)
```sql
UPDATE auth.refresh_tokens
SET revoked_at = CURRENT_TIMESTAMP
WHERE id = '660e8400-e29b-41d4-a716-446655440000'::UUID
RETURNING id, user_id, revoked_at;
```

#### Revocar TODAS las sesiones de un usuario
```sql
UPDATE auth.refresh_tokens
SET revoked_at = CURRENT_TIMESTAMP
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND revoked_at IS NULL
RETURNING COUNT(*);

-- Caso de uso: Password change, security incident
```

### 3. Estadísticas de Usuarios

#### Usuarios activos
```sql
SELECT COUNT(*) AS "Total usuarios activos"
FROM auth.active_users;

-- Resultado: 125
```

#### Usuarios por estado
```sql
SELECT 
    COUNT(*) AS "Total",
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS "Activos",
    SUM(CASE WHEN NOT is_active THEN 1 ELSE 0 END) AS "Inactivos",
    SUM(CASE WHEN email_verified THEN 1 ELSE 0 END) AS "Email verificado"
FROM auth.users
WHERE deleted_at IS NULL;

-- Resultado:
--  Total | Activos | Inactivos | Email verificado
-- -------+---------+-----------+-----------------
--    125 |     120 |         5 |              118
```

#### Top 10 usuarios por último login
```sql
SELECT 
    id,
    username,
    email,
    last_login_at,
    ROUND((CURRENT_TIMESTAMP - last_login_at) / INTERVAL '1 day') AS "Días desde login"
FROM auth.users
WHERE deleted_at IS NULL
  AND last_login_at IS NOT NULL
ORDER BY last_login_at DESC
LIMIT 10;

-- Índice usado: idx_users_last_login_at
```

#### Usuarios nunca han hecho login
```sql
SELECT 
    id,
    username,
    email,
    created_at,
    ROUND((CURRENT_TIMESTAMP - created_at) / INTERVAL '1 day') AS "Días desde creación"
FROM auth.users
WHERE last_login_at IS NULL
  AND deleted_at IS NULL
ORDER BY created_at DESC;

-- Caso de uso: Enviar email de reminder
```

### 4. Mantenimiento de Auth

#### Tokens expirados para limpiar
```sql
SELECT COUNT(*) AS "Tokens expirados"
FROM auth.refresh_tokens
WHERE expires_at < CURRENT_TIMESTAMP;

-- Ejecutar cleanup:
SELECT auth.cleanup_expired_refresh_tokens();
```

#### Usuarios marcados como eliminados (soft delete)
```sql
SELECT 
    id,
    username,
    email,
    deleted_at,
    ROUND((CURRENT_TIMESTAMP - deleted_at) / INTERVAL '1 day') AS "Días eliminado"
FROM auth.users
WHERE deleted_at IS NOT NULL
ORDER BY deleted_at DESC;

-- Si > 365 días, ejecutar:
SELECT auth.cleanup_deleted_users();
```

#### Sesiones próximas a expirar
```sql
SELECT 
    id,
    user_id,
    expires_at,
    ROUND((expires_at - CURRENT_TIMESTAMP) / INTERVAL '1 hour') AS "Horas hasta expiración"
FROM auth.refresh_tokens
WHERE revoked_at IS NULL
  AND expires_at BETWEEN CURRENT_TIMESTAMP AND CURRENT_TIMESTAMP + INTERVAL '24 hours'
ORDER BY expires_at;

-- Caso de uso: Alertar usuario de re-login
```

---

## 💰 Transactions Service Queries

### 1. Consultas de Transacciones

#### Obtener todas las transacciones de un usuario
```sql
-- En: finansecure_transactions_db_dev

SELECT 
    id,
    user_id,
    category_id,
    type,
    amount,
    description,
    transaction_date,
    status,
    created_at
FROM transactions.transactions
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND deleted_at IS NULL
ORDER BY transaction_date DESC
LIMIT 50;

-- Índice usado: idx_transactions_user_date
-- Tiempo esperado: < 10ms
```

#### Transacciones por rango de fechas
```sql
SELECT 
    id,
    amount,
    description,
    type,
    status,
    transaction_date,
    created_at
FROM transactions.transactions
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND transaction_date >= '2025-01-01'::DATE
  AND transaction_date < '2025-02-01'::DATE
  AND deleted_at IS NULL
ORDER BY transaction_date DESC;

-- Índice usado: idx_transactions_user_date
-- Tiempo esperado: < 5ms
```

#### Transacciones por categoría
```sql
SELECT 
    id,
    amount,
    description,
    transaction_date,
    status
FROM transactions.transactions
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND category_id = '660e8400-e29b-41d4-a716-446655440001'::UUID
  AND deleted_at IS NULL
ORDER BY transaction_date DESC;

-- Índice usado: idx_transactions_category_id
```

#### Transacciones por tipo
```sql
SELECT 
    id,
    amount,
    description,
    type,
    transaction_date
FROM transactions.transactions
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND type = 'EXPENSE'::transactions.transaction_type
  AND deleted_at IS NULL
ORDER BY transaction_date DESC;

-- Índice usado: idx_transactions_type
```

#### Transacciones pendientes
```sql
SELECT 
    id,
    amount,
    description,
    created_at,
    ROUND((CURRENT_TIMESTAMP - created_at) / INTERVAL '1 hour') AS "Horas pendiente"
FROM transactions.transactions
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND status = 'PENDING'::transactions.transaction_status
  AND deleted_at IS NULL
ORDER BY created_at ASC;

-- Caso de uso: Mostrar pendientes en dashboard
```

### 2. Análisis Financiero

#### Resumen por tipo (ingreso vs gasto)
```sql
SELECT 
    type,
    COUNT(*) AS "Cantidad",
    SUM(amount) AS "Total",
    AVG(amount) AS "Promedio",
    MIN(amount) AS "Mínimo",
    MAX(amount) AS "Máximo"
FROM transactions.transactions
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND transaction_date >= '2025-01-01'::DATE
  AND deleted_at IS NULL
GROUP BY type
ORDER BY type;

-- Resultado esperado:
--    type   | Cantidad | Total | Promedio | Mínimo | Máximo
-- -----------+----------+-------+----------+--------+--------
--  EXPENSE   |      45  | 5000  |  111.11  |   10   |  500
--  INCOME    |      12  |12000  | 1000.00  |  500   | 2500
--  TRANSFER  |       3  |  600  |  200.00  |  200   |  200
```

#### Resumen mensual
```sql
SELECT 
    DATE_TRUNC('month', transaction_date)::DATE AS "Mes",
    SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0 END) AS "Ingresos",
    SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0 END) AS "Gastos",
    SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0 END) -
    SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0 END) AS "Neto"
FROM transactions.transactions
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND deleted_at IS NULL
GROUP BY DATE_TRUNC('month', transaction_date)
ORDER BY DATE_TRUNC('month', transaction_date) DESC
LIMIT 12;

-- Resultado: Últimos 12 meses de balance
```

#### Top categorías por gasto
```sql
SELECT 
    c.name AS "Categoría",
    COUNT(t.id) AS "Cantidad",
    SUM(t.amount) AS "Total",
    ROUND(AVG(t.amount), 2) AS "Promedio"
FROM transactions.transactions t
LEFT JOIN transactions.categories c ON t.category_id = c.id
WHERE t.user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND t.type = 'EXPENSE'::transactions.transaction_type
  AND t.transaction_date >= '2025-01-01'::DATE
  AND t.deleted_at IS NULL
GROUP BY c.id, c.name
ORDER BY SUM(t.amount) DESC
LIMIT 10;

-- Caso de uso: Mostrar categorías principales
```

#### Balance actual (función)
```sql
SELECT *
FROM transactions.get_user_balance_summary(
    p_user_id := '550e8400-e29b-41d4-a716-446655440000'::UUID,
    p_start_date := '2025-01-01'::DATE,
    p_end_date := CURRENT_DATE
);

-- Resultado:
--  total_income | total_expenses | net_balance | transaction_count
-- ---------------+----------------+-------------+-------------------
--      12000.00  |     5000.00    |   7000.00   |        60
```

### 3. Auditoría de Transacciones

#### Historial de cambios de una transacción
```sql
SELECT 
    id,
    action,
    changed_fields,
    old_values,
    new_values,
    created_at,
    ip_address,
    user_agent
FROM transactions.audit_logs
WHERE transaction_id = '550e8400-e29b-41d4-a716-446655440002'::UUID
ORDER BY created_at DESC;

-- Índice usado: idx_audit_logs_transaction_id
-- Resultado: Historial completo de cambios
```

#### Qué cambió en una transacción
```sql
SELECT 
    action,
    changed_fields,
    old_values->>'amount' AS "Monto anterior",
    new_values->>'amount' AS "Monto nuevo",
    old_values->>'status' AS "Estado anterior",
    new_values->>'status' AS "Estado nuevo",
    created_at
FROM transactions.audit_logs
WHERE transaction_id = '550e8400-e29b-41d4-a716-446655440002'::UUID
  AND action = 'UPDATE'::transactions.audit_action
ORDER BY created_at DESC;

-- Caso de uso: Mostrar cambios específicos
```

#### Auditoría por usuario (todas sus cambios)
```sql
SELECT 
    transaction_id,
    action,
    changed_fields,
    created_at,
    ip_address
FROM transactions.audit_logs
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
ORDER BY created_at DESC
LIMIT 100;

-- Índice usado: idx_audit_logs_user_created
-- Caso de uso: Mostrar actividad del usuario
```

#### Buscar cambios de un campo específico
```sql
SELECT 
    transaction_id,
    action,
    old_values->>'amount' AS "Valor anterior",
    new_values->>'amount' AS "Valor nuevo",
    created_at
FROM transactions.audit_logs
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND new_values @> '{"status": "CANCELLED"}'
ORDER BY created_at DESC;

-- JSONB query: buscar transacciones canceladas
```

### 4. Gestión de Presupuestos

#### Ver presupuestos del mes actual
```sql
SELECT 
    id,
    category_id,
    limit_amount,
    alert_percentage,
    month,
    year
FROM transactions.budgets
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND year = EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER
  AND month = EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER
ORDER BY limit_amount DESC;

-- Índice usado: idx_budgets_user_month
```

#### Estado del presupuesto (vs gasto real)
```sql
SELECT 
    id,
    category_id,
    limit_amount,
    spent_amount,
    spent_percentage,
    CASE 
        WHEN status = 'EXCEEDED' THEN '🔴 Excedido'
        WHEN status = 'WARNING' THEN '🟡 Alerta'
        ELSE '🟢 OK'
    END AS "Estado"
FROM transactions.budget_status
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND year = EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER
  AND month = EXTRACT(MONTH FROM CURRENT_DATE)::INTEGER;

-- Usa: transactions.budget_status view
-- Caso de uso: Dashboard de presupuestos
```

#### Presupuestos excedidos
```sql
SELECT 
    id,
    category_id,
    limit_amount,
    spent_amount,
    (spent_amount - limit_amount) AS "Exceso",
    spent_percentage
FROM transactions.budget_status
WHERE user_id = '550e8400-e29b-41d4-a716-446655440000'::UUID
  AND status = 'EXCEEDED'
ORDER BY (spent_amount - limit_amount) DESC;

-- Caso de uso: Alertar usuario
```

---

## 📊 Monitoreo y Performance

### Estadísticas de Tablas

#### Tamaño de tablas (Auth Service)
```sql
-- En: finansecure_auth_db_dev

SELECT 
    table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||table_name)) AS "Tamaño total",
    pg_size_pretty(pg_relation_size(schemaname||'.'||table_name)) AS "Datos",
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||table_name) - 
                   pg_relation_size(schemaname||'.'||table_name)) AS "Índices"
FROM information_schema.tables
WHERE table_schema = 'auth'
ORDER BY pg_total_relation_size(schemaname||'.'||table_name) DESC;

-- Resultado:
--    table_name    | Tamaño total | Datos   | Índices
-- ------------------+--------------+---------+--------
--  refresh_tokens  | 1234 MB      | 500 MB  | 734 MB
--  users           | 234 MB       | 150 MB  | 84 MB
```

#### Tamaño de tablas (Transactions Service)
```sql
-- En: finansecure_transactions_db_dev

SELECT 
    table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||table_name)) AS "Tamaño total"
FROM information_schema.tables
WHERE table_schema = 'transactions'
ORDER BY pg_total_relation_size(schemaname||'.'||table_name) DESC;
```

### Uso de Índices

#### Índices no usados
```sql
SELECT 
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(idx)) AS "Tamaño"
FROM pg_stat_user_indexes
WHERE schemaname = 'transactions'
  AND idx_scan = 0
ORDER BY pg_relation_size(idx) DESC;

-- Si hay resultados: DROP INDEX los que no se usan
-- DROP INDEX transactions.idx_unused;
```

#### Índices más usados
```sql
SELECT 
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'transactions'
ORDER BY idx_scan DESC
LIMIT 10;

-- Muestra índices efectivos
```

### Actividad en Tiempo Real

#### Consultas activas
```sql
SELECT 
    pid,
    usename,
    application_name,
    state,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - state_change)) AS "Segundos en estado",
    query
FROM pg_stat_activity
WHERE datname IN ('finansecure_auth_db_dev', 'finansecure_transactions_db_dev')
  AND pid != pg_backend_pid()
ORDER BY state_change DESC;

-- Útil para debugging
```

#### Conexiones por BD
```sql
SELECT 
    datname,
    COUNT(*) AS "Conexiones"
FROM pg_stat_activity
WHERE datname LIKE 'finansecure_%'
GROUP BY datname;
```

---

## 🐛 Debugging

### Encontrar Inconsistencias

#### Transacciones sin categoría
```sql
SELECT 
    id,
    user_id,
    amount,
    description,
    transaction_date
FROM transactions.transactions
WHERE category_id IS NULL
  AND deleted_at IS NULL;

-- Verificar si es intencional o error
```

#### Usuarios sin transacciones
```sql
SELECT DISTINCT
    u.id,
    u.username,
    u.email,
    u.created_at
FROM auth.users u
LEFT JOIN transactions.transactions t ON u.id = t.user_id
WHERE t.id IS NULL
  AND u.deleted_at IS NULL;

-- Caso de uso: Usuarios nuevos o inactivos
```

#### Datos sospechosos
```sql
-- Transacciones con montos negativos (NO debería pasar)
SELECT COUNT(*)
FROM transactions.transactions
WHERE amount <= 0
  AND deleted_at IS NULL;

-- Si hay resultados: INVESTIGAR
-- (El constraint CHECK debería prevenirlo)
```

---

## 🧹 Mantenimiento

### Limpiezas Regulares

#### Ejecutar limpieza (diaria)
```sql
-- Auth Service
SELECT auth.cleanup_expired_refresh_tokens();

-- Transactions Service
SELECT transactions.cleanup_old_audit_logs();
```

#### Optimizar tablas (semanal)
```sql
-- Recover space from soft deletes
VACUUM ANALYZE auth.users;
VACUUM ANALYZE auth.refresh_tokens;
VACUUM ANALYZE transactions.transactions;
VACUUM ANALYZE transactions.audit_logs;
```

#### Reindex (trimestral)
```sql
-- Si indices están fragmentados
REINDEX DATABASE finansecure_auth_db_dev;
REINDEX DATABASE finansecure_transactions_db_dev;
```

#### Copias de seguridad
```bash
# Backup
pg_dump -U postgres finansecure_auth_db_dev > auth_backup_$(date +%Y%m%d).sql
pg_dump -U postgres finansecure_transactions_db_dev > transactions_backup_$(date +%Y%m%d).sql

# Restore
psql -U postgres finansecure_auth_db_dev < auth_backup_20250120.sql
```

---

## 📈 Script de Monitoreo Completo

```sql
-- dashboard_queries.sql
-- Ejecutar periódicamente para monitoring

-- 1. HEALTH CHECK
SELECT 
    'Auth DB' AS "Base de Datos",
    COUNT(*) AS "Total Usuarios",
    SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS "Activos"
FROM auth.users
WHERE deleted_at IS NULL
UNION ALL
SELECT 
    'Transactions DB',
    COUNT(*) AS "Total Transacciones",
    SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END)
FROM transactions.transactions
WHERE deleted_at IS NULL;

-- 2. ACTIVE SESSIONS
SELECT 
    COUNT(*) AS "Sesiones activas",
    SUM(CASE WHEN expires_at < CURRENT_TIMESTAMP + INTERVAL '24 hours' 
        THEN 1 ELSE 0 END) AS "Próximas a expirar"
FROM auth.refresh_tokens
WHERE revoked_at IS NULL;

-- 3. PENDING TRANSACTIONS
SELECT COUNT(*) AS "Transacciones pendientes"
FROM transactions.transactions
WHERE status = 'PENDING'
  AND deleted_at IS NULL;

-- 4. BUDGET ALERTS
SELECT COUNT(*) AS "Presupuestos excedidos"
FROM transactions.budget_status
WHERE status = 'EXCEEDED'
  AND month = EXTRACT(MONTH FROM CURRENT_DATE);
```

---

**Última actualización:** 2025-01-20  
**Versión:** 1.0

