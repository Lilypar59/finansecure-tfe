# 🏗️ Arquitectura de Datos - FinanSecure Microservicios

Documento de arquitectura para aislamiento de datos en microservicios.

---

## 📋 Tabla de Contenidos

1. [Visión General](#visión-general)
2. [Aislamiento de Microservicios](#aislamiento-de-microservicios)
3. [Auth Service Schema](#auth-service-schema)
4. [Transactions Service Schema](#transactions-service-schema)
5. [Mejores Prácticas](#mejores-prácticas)
6. [Script de Instalación](#script-de-instalación)
7. [Monitoreo y Mantenimiento](#monitoreo-y-mantenimiento)

---

## 👁️ Visión General

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA GENERAL                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  PostgreSQL Instance                                            │
│  ├─ Database: finansecure_auth_db_dev                           │
│  │  └─ Schema: auth (Auth Service)                              │
│  │                                                              │
│  └─ Database: finansecure_transactions_db_dev                   │
│     └─ Schema: transactions (Transactions Service)              │
│                                                                  │
│  ⚠️ IMPORTANTE: Bases de datos COMPLETAMENTE AISLADAS          │
│  - Sin foreign keys entre servicios                            │
│  - Único vínculo: userId (GUID) en JWT                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 Aislamiento de Microservicios

### ✅ Qué Hicimos Bien

#### 1. **Bases de Datos Separadas**
```sql
-- Auth Service
CREATE DATABASE finansecure_auth_db_dev;

-- Transactions Service
CREATE DATABASE finansecure_transactions_db_dev;
```
- ✅ Cada servicio tiene su propia BD
- ✅ Cada servicio gestiona su propio schema
- ✅ Sin riesgo de compartir datos accidentalmente

#### 2. **Sin Foreign Keys Cruzadas**
```sql
-- ❌ INCORRECTO (acoplamiento)
ALTER TABLE transactions
ADD CONSTRAINT fk_user_id 
FOREIGN KEY (user_id) REFERENCES auth.users(id);

-- ✅ CORRECTO (desacoplado)
-- Solo referencia por valor (userId)
-- Sin FK - la integridad se valida en la aplicación
```

**Ventajas:**
- Services pueden ser deployados independientemente
- Auth Service puede ser eliminado/reemplazado sin afectar Transactions
- Escalabilidad horizontal más fácil

#### 3. **UserId como Único Vínculo**
```
Auth Service                    Transactions Service
┌──────────┐                    ┌─────────────────┐
│ users    │                    │ transactions    │
│ ─────    │                    │ ───────────────│
│ id (PK)  │──────(UUID)────────│ user_id        │
│ username │   <-- JWT -->      │ amount         │
│ email    │                    │ description    │
└──────────┘                    └─────────────────┘
```

**Flow:**
1. Usuario hace login → Auth Service emite JWT con `sub = userId`
2. JWT se envía a Transactions Service
3. Transactions Service extrae `userId` del JWT (nunca del body/query)
4. Se filtra data por `user_id`

---

## 📊 Auth Service Schema

### Tablas

#### **users**
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,  -- BCrypt
    is_active BOOLEAN DEFAULT TRUE,
    email_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP  -- Soft delete
);
```

**Características:**
- UUID como PK (distributed ID)
- Índices únicos en username y email (login rápido)
- Soft delete (no eliminar datos históricos)
- Timestamps para auditoría

#### **refresh_tokens**
```sql
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- Sin FK (desacoplado)
    token_value VARCHAR(500) UNIQUE NOT NULL,  -- Base64
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,  -- NULL si activo
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent VARCHAR(500)
);
```

**Características:**
- Token revocable (para logout)
- IP y User-Agent para anomalía (opcional)
- One-to-Many con users

### Índices Críticos

| Índice | Propósito | Tipo |
|--------|----------|------|
| `idx_users_username` | Login rápido | UNIQUE |
| `idx_users_email` | Registro rápido | UNIQUE |
| `idx_refresh_tokens_user_id` | Búsqueda tokens activos | Compuesto |
| `idx_refresh_tokens_expires_at` | Limpiar tokens expirados | Rango |

---

## 💰 Transactions Service Schema

### Tablas

#### **categories**
```sql
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- Aislamiento por usuario
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color VARCHAR(7),  -- Ej: #FF5733
    icon VARCHAR(50),  -- Ej: shopping-cart
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);
```

**Características:**
- Cada usuario puede crear sus propias categorías
- Soft delete (mantener histórico)
- Índice compuesto (user_id, name)

#### **transactions**
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,  -- Aislamiento (crítico!)
    category_id UUID,  -- Referencia interna
    type transaction_type NOT NULL,  -- INCOME, EXPENSE, etc
    amount DECIMAL(12, 2) NOT NULL,
    description VARCHAR(500),
    transaction_date TIMESTAMP NOT NULL,
    status transaction_status DEFAULT 'COMPLETED',
    reference_number VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);
```

**Características:**
- **CRÍTICO:** user_id para aislamiento completo
- Rango de búsqueda por fecha eficiente
- ENUM types para seguridad
- Soft delete para auditoría

#### **audit_logs**
```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    transaction_id UUID NOT NULL,
    action audit_action NOT NULL,  -- CREATE, UPDATE, DELETE
    old_values JSONB,  -- Valores previos
    new_values JSONB,  -- Valores nuevos
    changed_fields TEXT[],
    ip_address INET,
    user_agent VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Características:**
- Inmutable (INSERT ONLY)
- JSONB para flexibilidad (future-proof)
- Cumplimiento: auditoría completa de cambios

#### **budgets**
```sql
CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    category_id UUID,
    limit_amount DECIMAL(12, 2) NOT NULL,
    alert_percentage DECIMAL(3, 0) DEFAULT 80,
    month INTEGER NOT NULL,  -- 1-12
    year INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Características:**
- Presupuestos mensuales
- Alertas configurables
- Índice único (user, month, year, category)

### Índices Críticos para Performance

| Índice | Query Típica | Impacto |
|--------|-------------|---------|
| `idx_transactions_user_id` | WHERE user_id = ? | 🔴 CRÍTICO |
| `idx_transactions_user_date` | WHERE user_id = ? AND date BETWEEN | 🔴 CRÍTICO |
| `idx_transactions_type` | WHERE user_id = ? AND type = ? | 🟡 Alto |
| `idx_transactions_status` | WHERE user_id = ? AND status = ? | 🟡 Medio |
| `idx_audit_logs_transaction_id` | Historial de cambios | 🟡 Medio |

---

## 🏆 Mejores Prácticas Implementadas

### 1. **Aislamiento de Datos**

✅ **Por Usuario**
```sql
-- Todas las queries incluyen filtro user_id
SELECT * FROM transactions 
WHERE user_id = $1 AND deleted_at IS NULL;
```

✅ **En el Código C#**
```csharp
// Extraer userId SOLO del JWT (nunca del body)
var userId = User.GetUserIdOrThrow();

// Validar cross-user access
var transaction = await _service.GetAsync(userId, transactionId);
if (transaction.UserId != userId)
    return Forbid();  // 403
```

### 2. **Soft Deletes**

```sql
-- No borrar, solo marcar
UPDATE transactions 
SET deleted_at = CURRENT_TIMESTAMP 
WHERE id = $1;

-- Siempre filtrar deleted_at
SELECT * FROM transactions 
WHERE deleted_at IS NULL;
```

**Ventajas:**
- Auditoría completa
- Recuperación posible
- Cumplimiento normativo

### 3. **Auditoría con JSONB**

```sql
-- Registro flexible de cambios
INSERT INTO audit_logs (user_id, transaction_id, action, old_values, new_values)
VALUES (
    $1, $2, 'UPDATE',
    jsonb_build_object('amount', 100.00, 'status', 'PENDING'),
    jsonb_build_object('amount', 150.00, 'status', 'COMPLETED')
);
```

**Ventajas:**
- Schema-less (flexibilidad para cambios futuros)
- Fácil de consultar con operadores JSONB
- Cumplimiento: prueba exacta de qué cambió

### 4. **Índices Estratégicos**

```sql
-- Composición es importante!
-- ✅ BUENO - Soporta ambas queries
CREATE INDEX idx_transactions_user_date 
ON transactions(user_id, transaction_date DESC);

-- Soporta:
-- WHERE user_id = $1
-- WHERE user_id = $1 AND transaction_date > $2
-- WHERE user_id = $1 AND transaction_date BETWEEN $2 AND $3

-- ❌ MALO - Índice en orden inverso
CREATE INDEX idx_transactions_user_date 
ON transactions(transaction_date DESC, user_id);

-- Solo soporta: WHERE transaction_date > $1
```

### 5. **Funciones Triggers para Auditoría**

```sql
-- Automático: cada UPDATE dispara auditoría
CREATE TRIGGER tr_transactions_audit_update
BEFORE UPDATE ON transactions
FOR EACH ROW
EXECUTE FUNCTION tr_transactions_audit_update();
```

**Ventajas:**
- Auditoría automática (no puede olvidarse)
- Consistencia garantizada
- Rendimiento: triggers son muy rápidos

### 6. **Vistas para Reportes**

```sql
-- Vista: Resumen mensual (materialize para gran volumen)
CREATE VIEW transaction_summary AS
SELECT 
    user_id,
    DATE_TRUNC('month', transaction_date) as month,
    type,
    SUM(amount) as total,
    COUNT(*) as count
FROM transactions
WHERE deleted_at IS NULL
GROUP BY user_id, DATE_TRUNC('month', transaction_date), type;
```

**Ventajas:**
- Queries simples para reportes
- Reutilizable (NO SQL copy-paste)
- Fácil de optimizar

### 7. **Funciones SQL para Lógica Compleja**

```sql
-- Función: Balance del usuario
CREATE FUNCTION get_user_balance_summary(
    p_user_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE,
    p_end_date DATE DEFAULT CURRENT_DATE + INTERVAL '1 day'
) RETURNS TABLE (total_income, total_expenses, net_balance, count)
AS $$
    SELECT 
        SUM(CASE WHEN type = 'INCOME' THEN amount ELSE 0 END),
        SUM(CASE WHEN type = 'EXPENSE' THEN amount ELSE 0 END),
        ...
    FROM transactions
    WHERE user_id = p_user_id AND ...
$$ LANGUAGE SQL;
```

**Uso en C#:**
```csharp
var summary = await _context.Database
    .SqlQueryRaw<BalanceSummary>(
        "SELECT * FROM get_user_balance_summary(@userId)",
        new SqlParameter("@userId", userId)
    ).FirstOrDefaultAsync();
```

---

## 🚀 Script de Instalación

### Paso 1: Crear Bases de Datos

```bash
# Conectar a PostgreSQL
psql -U postgres

# Crear BD para Auth Service
CREATE DATABASE finansecure_auth_db_dev;

# Crear BD para Transactions Service
CREATE DATABASE finansecure_transactions_db_dev;

# Listar BDs
\l

# Salir
\q
```

### Paso 2: Ejecutar Scripts SQL

```bash
# Auth Service
psql -U postgres -d finansecure_auth_db_dev -f auth_service_schema.sql

# Transactions Service
psql -U postgres -d finansecure_transactions_db_dev -f transactions_service_schema.sql
```

### Paso 3: Verificar Instalación

```bash
# Conectar a Auth DB
psql -U postgres -d finansecure_auth_db_dev

# Ver tablas
\dt auth.*

# Ver índices
\di auth.*

# Ver vistas
\dv auth.*

# Ver funciones
\df auth.*
```

### Paso 4: Configurar Connection Strings en appsettings.json

**Auth Service:**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=finansecure_auth_db_dev;Username=postgres;Password=your_password"
  }
}
```

**Transactions Service:**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=finansecure_transactions_db_dev;Username=postgres;Password=your_password"
  }
}
```

---

## 📊 Monitoreo y Mantenimiento

### Consultas de Monitoreo

#### 1. Ver Tabla Sizes
```sql
-- Auth Service
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'auth'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

#### 2. Ver Índices No Usados
```sql
-- Encontrar índices que nunca se usan
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'transactions'
  AND idx_scan = 0
ORDER BY pg_relation_size(relid) DESC;
```

#### 3. Ver Queries Lentas
```sql
-- Habilitar query logging
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- > 1 segundo
SELECT pg_reload_conf();
```

#### 4. Estadísticas de Tablas
```sql
-- Analizar una tabla
ANALYZE transactions;

-- Ver estadísticas
SELECT * FROM pg_stat_user_tables 
WHERE schemaname = 'transactions';
```

### Tareas de Mantenimiento

#### 1. Limpiar Tokens Expirados (Diario)

```sql
-- En Auth DB
SELECT cleanup_expired_refresh_tokens();
-- Retorna: número de tokens eliminados
```

#### 2. Limpiar Logs de Auditoría (Mensual)

```sql
-- En Transactions DB
-- Mantener 7 años de auditoría (cumplimiento)
SELECT cleanup_old_audit_logs(2555);
-- Retorna: número de logs eliminados
```

#### 3. Vacuum and Analyze (Semanal)

```sql
-- Mantenimiento de espacio
VACUUM ANALYZE transactions;
```

#### 4. Backup Diario

```bash
# Auth DB
pg_dump -U postgres finansecure_auth_db_dev > auth_backup_$(date +%Y%m%d).sql

# Transactions DB
pg_dump -U postgres finansecure_transactions_db_dev > transactions_backup_$(date +%Y%m%d).sql
```

---

## 🔍 Validaciones de Seguridad

### Checklist de Aislamiento

- ✅ `user_id` GUID (no secuencial)
- ✅ Índice en `user_id` en todas las tablas financieras
- ✅ Todas las queries filtran por `user_id`
- ✅ Sin FK entre servicios
- ✅ Soft deletes activos
- ✅ Auditoría en transacciones
- ✅ Triggers para integridad
- ✅ Vistas para reportes seguros

### Checklist de Performance

- ✅ Índices en claves de búsqueda frecuentes
- ✅ Índices compuestos en (user_id, fecha)
- ✅ No hay N+1 queries
- ✅ Vistas materializadas para reportes complejos
- ✅ Particiones para tablas > 1GB (futuro)

---

## 📈 Escalabilidad Futura

### Cuándo Hacer Sharding

**Umbral:** Tabla > 10GB o > 1 millón de registros

```sql
-- Ejemplo: Sharding por user_id (hash)
-- Shard 1: user_id % 4 = 0
-- Shard 2: user_id % 4 = 1
-- Shard 3: user_id % 4 = 2
-- Shard 4: user_id % 4 = 3

-- Aplicación enruta basado en hash(user_id)
```

### Cuándo Usar Read Replicas

**Umbral:** > 1,000 QPS en lecturas

```yaml
# Configuración PostgreSQL
Primary: localhost:5432
Read Replica 1: localhost:5433
Read Replica 2: localhost:5434

# Aplicación usa replica para:
# - Reportes
# - Vistas
# - Búsquedas
```

---

## 📚 Referencias SQL

### Operadores JSONB

```sql
-- Extraer valor
SELECT old_values->>'amount' as amount FROM audit_logs;

-- Buscar clave
SELECT * FROM audit_logs 
WHERE new_values ? 'amount';

-- Contiene objeto
SELECT * FROM audit_logs 
WHERE old_values @> '{"status": "PENDING"}';

-- Búsqueda con índice
CREATE INDEX idx_audit_new_values ON audit_logs USING GIN (new_values);
```

### Window Functions (para análisis)

```sql
-- Transacciones ordenadas por fecha
SELECT 
    id,
    amount,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY transaction_date) as row_num,
    LAG(amount) OVER (PARTITION BY user_id ORDER BY transaction_date) as prev_amount,
    amount - LAG(amount) OVER (...) as change
FROM transactions;
```

---

## 🎓 Conclusión

Esta arquitectura garantiza:

✅ **Aislamiento completo** entre microservicios  
✅ **Seguridad** a nivel de BD (user_id filters)  
✅ **Auditoría inmutable** (compliance)  
✅ **Performance** (índices estratégicos)  
✅ **Escalabilidad** (sharding ready)  
✅ **Mantenibilidad** (vistas, funciones, triggers)  

El único acoplamiento es el `user_id` GUID en el JWT, que es la forma correcta de vincular datos en microservicios.

