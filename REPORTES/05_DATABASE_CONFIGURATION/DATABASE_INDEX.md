# 📚 Índice Maestro - FinanSecure Database Architecture

Documento de navegación para toda la arquitectura de bases de datos y microservicios.

---

## 🗺️ Mapa de Documentos

### 1. **ARQUITECTURA** (Conceptual)

#### 📄 DATABASE_ARCHITECTURE.md
- Visión general del sistema
- Aislamiento de microservicios
- Mejores prácticas implementadas
- Decisiones de diseño
- Escalabilidad futura

**Secciones principales:**
- Aislamiento de datos
- Soft deletes
- Auditoría con JSONB
- Índices estratégicos
- Funciones y triggers
- Vistas para reportes

---

### 2. **INSTALACIÓN** (Práctico)

#### 📄 DATABASE_SETUP_GUIDE.md
- Guía paso a paso para configurar PostgreSQL
- Crear bases de datos
- Ejecutar scripts SQL
- Configurar .NET/EF Core
- Seeding de datos
- Troubleshooting

**Secciones principales:**
- Requisitos previos
- PostgreSQL local, Docker, Docker Compose
- Crear bases de datos
- Ejecutar scripts
- Verificación
- Configuración en .NET
- Monitoreo

---

### 3. **ESQUEMAS SQL** (Código)

#### 📄 auth_service_schema.sql (600+ líneas)
**Tablas:**
- `auth.users` - Cuentas de usuario
- `auth.refresh_tokens` - Tokens de sesión

**Índices:** 9 totales
**Vistas:** 2 (active_users, active_sessions)
**Funciones:** 2 (cleanup helpers)
**Triggers:** 1 (auto update last_login)

#### 📄 transactions_service_schema.sql (700+ líneas)
**Tablas:**
- `transactions.categories` - Categorías
- `transactions.transactions` - Transacciones
- `transactions.audit_logs` - Auditoría completa
- `transactions.budgets` - Presupuestos mensuales

**Índices:** 14 totales
**Vistas:** 2 (summary, budget_status)
**Funciones:** 4 (audit helpers, cleanup, balance)
**Triggers:** 5 (auto audit + timestamps)

---

## 🎯 Flujo de Trabajo

### Primera Vez - Setup Completo

```
┌─────────────────────────────────────────────────────┐
│ 1. Leer DATABASE_ARCHITECTURE.md                    │
│    → Entender conceptos y decisiones                │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 2. Seguir DATABASE_SETUP_GUIDE.md                   │
│    → Instalar PostgreSQL                           │
│    → Crear bases de datos                          │
│    → Ejecutar scripts SQL                          │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 3. Verificar schemas con psql/pgAdmin              │
│    → Ver tablas, índices, vistas                    │
│    → Probar conexión desde .NET                     │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ 4. Configurar appsettings.json                      │
│    → Connection strings                            │
│    → EF Core setup                                  │
└─────────────────────────────────────────────────────┘
```

### Desarrollo - Modificar Schema

```
Necesito cambiar algo → Leer DATABASE_ARCHITECTURE.md
                     → Entender el impacto
                     → Modificar SQL en schema files
                     → Ejecutar como migration
                     → Actualizar Entity Models (.NET)
```

### Producción - Deploy

```
Usar DATABASE_SETUP_GUIDE.md → Sección "Configuración en .NET"
                              → EF Core migrations (automáticas)
                              → Respaldo de BD
                              → Verificación post-deploy
```

---

## 📊 Comparativa de Microservicios

| Aspecto | Auth Service | Transactions Service |
|---------|--------------|----------------------|
| **BD** | `finansecure_auth_db_dev` | `finansecure_transactions_db_dev` |
| **Schema** | `auth` | `transactions` |
| **Tablas** | 2 | 4 |
| **Índices** | 9 | 14 |
| **Vistas** | 2 | 2 |
| **Triggers** | 1 | 5 |
| **Enums** | 0 | 3 |
| **Tamaño SQL** | 600+ líneas | 700+ líneas |

---

## 🔐 Principios de Aislamiento

### ✅ LO QUE HICIMOS

1. **Bases de Datos Separadas**
   ```
   Auth BD: finansecure_auth_db_dev
   │ └─ auth.users
   │ └─ auth.refresh_tokens
   
   Transactions BD: finansecure_transactions_db_dev
   │ └─ transactions.categories
   │ └─ transactions.transactions
   │ └─ transactions.audit_logs
   └─ transactions.budgets
   ```

2. **Sin Foreign Keys Cruzadas**
   ```sql
   -- ❌ NUNCA hacer esto:
   ALTER TABLE transactions
   ADD CONSTRAINT fk_user_id
   FOREIGN KEY (user_id) REFERENCES auth.users(id);
   
   -- ✅ CORRECTO: Solo referencia por valor
   -- No hay FK - validación en aplicación
   ```

3. **UserId como Único Vínculo**
   ```
   JWT (Auth Service)
   ├─ sub = userId (UUID)
   │
   └─→ Transactions Service
       │
       └─ WHERE user_id = $1 (de JWT)
   ```

4. **Auditoría Completa**
   ```sql
   -- Cada cambio registrado
   INSERT INTO audit_logs (
       user_id, transaction_id, action,
       old_values, new_values, changed_fields
   )
   -- Triggers automáticos = auditoría garantizada
   ```

---

## 📈 Índices Críticos

### Auth Service
```sql
-- BÚSQUEDA POR USUARIO
idx_refresh_tokens_user_id           -- Find all sessions
idx_refresh_tokens_user_created      -- Order by created

-- LOGIN
idx_users_username                   -- Username lookup
idx_users_email                      -- Email lookup

-- LIMPIEZA
idx_refresh_tokens_expires_at        -- Find expired tokens
idx_users_is_active                  -- Find active accounts
```

### Transactions Service
```sql
-- BÚSQUEDA POR USUARIO (CRÍTICO)
idx_transactions_user_id             -- WHERE user_id = ?
idx_transactions_user_date           -- WHERE user_id + date range

-- FILTRADO
idx_transactions_category_id         -- By category
idx_transactions_type                -- Income vs Expense
idx_transactions_status              -- Pending vs Completed

-- AUDITORÍA
idx_audit_logs_transaction_id        -- History of transaction
idx_audit_logs_user_created          -- All user changes

-- PRESUPUESTO
idx_budgets_user_month               -- Current month check
```

---

## 🔍 Queries Comunes

### Auth Service

#### Login
```sql
SELECT * FROM auth.users 
WHERE username = $1 AND is_active = true AND deleted_at IS NULL;
-- Usa: idx_users_username
```

#### Validar Token
```sql
SELECT * FROM auth.refresh_tokens 
WHERE token_value = $1 AND revoked_at IS NULL AND expires_at > NOW();
-- Usa: idx_refresh_tokens_token_value
```

#### Listar Sesiones Activas
```sql
SELECT * FROM auth.active_sessions WHERE user_id = $1;
-- Usa: idx_refresh_tokens_user_id
```

---

### Transactions Service

#### Transacciones del Usuario
```sql
SELECT * FROM transactions.transactions 
WHERE user_id = $1 AND deleted_at IS NULL
ORDER BY transaction_date DESC;
-- Usa: idx_transactions_user_date
```

#### Resumen Mensual
```sql
SELECT * FROM transactions.transaction_summary 
WHERE user_id = $1 AND month = DATE_TRUNC('month', NOW());
-- Usa: idx_transactions_user_date (para materializarla)
```

#### Auditoría de Transacción
```sql
SELECT * FROM transactions.audit_logs 
WHERE transaction_id = $1
ORDER BY created_at DESC;
-- Usa: idx_audit_logs_transaction_id
```

#### Balance del Usuario
```sql
SELECT * FROM transactions.get_user_balance_summary(
    p_user_id := $1,
    p_start_date := CURRENT_DATE,
    p_end_date := CURRENT_DATE + INTERVAL '1 day'
);
-- Usa: idx_transactions_user_date internamente
```

---

## 🛠️ Mantenimiento

### Diario
```sql
-- Limpiar tokens expirados (Auth Service)
SELECT auth.cleanup_expired_refresh_tokens();
```

### Mensual
```sql
-- Limpiar logs de auditoría > 7 años (Transactions Service)
SELECT transactions.cleanup_old_audit_logs();

-- Analizar tablas
ANALYZE;
```

### Trimestral
```sql
-- Verificar índices no usados
SELECT * FROM pg_stat_user_indexes 
WHERE idx_scan = 0;

-- Reindex si es necesario
REINDEX DATABASE finansecure_auth_db_dev;
REINDEX DATABASE finansecure_transactions_db_dev;
```

---

## 🎓 Conceptos Clave

### Soft Delete
```sql
-- No eliminar, solo marcar
UPDATE transactions 
SET deleted_at = CURRENT_TIMESTAMP 
WHERE id = $1;

-- Siempre filtrar
SELECT * FROM transactions 
WHERE deleted_at IS NULL;

-- Ventajas:
-- - Auditoría completa
-- - Recuperación posible
-- - Cumplimiento normativo
```

### JSONB para Auditoría
```sql
-- Flexibilidad: cambios futuros no afectan auditoría
INSERT INTO audit_logs (
    old_values, new_values
) VALUES (
    jsonb_build_object('amount', 100, 'status', 'PENDING'),
    jsonb_build_object('amount', 150, 'status', 'COMPLETED')
);

-- Consultas:
WHERE new_values @> '{"status": "COMPLETED"}'
WHERE old_values->>'amount' = '100'
```

### Triggers para Automación
```sql
-- Cada INSERT dispara trigger
CREATE TRIGGER tr_transactions_audit_insert
AFTER INSERT ON transactions
FOR EACH ROW
EXECUTE FUNCTION tr_transactions_audit_insert();

-- Auditoría automática = garantizada
-- No puede olvidarse en el código
```

---

## 🚀 Escalabilidad

### Cuándo Optimizar

| Métrica | Umbral | Acción |
|---------|--------|--------|
| Tablas | > 10GB | Particionar por user_id |
| QPS | > 1,000 | Agregar read replicas |
| Latencia | > 100ms | Revisar índices |
| Índices | > 20 | Revisar estrategia |

### Sharding Preparado
```
El schema actual está preparado para sharding:

users → hash(user_id) % 4
├─ Shard 0: user_id % 4 = 0
├─ Shard 1: user_id % 4 = 1
├─ Shard 2: user_id % 4 = 2
└─ Shard 3: user_id % 4 = 3

Aplicación enruta basado en user_id
```

---

## 📞 Preguntas Frecuentes

### ¿Por qué bases de datos separadas?
```
Aislamiento completo entre microservicios.
Si Auth Service cae, Transactions sigue funcionando.
Escalabilidad independiente.
```

### ¿Sin FK entre servicios es seguro?
```
SÍ. La integridad se valida en la aplicación.
El UUID user_id en JWT es inmutable.
Cada service solo ve sus propios datos.
```

### ¿Cómo recuperar datos eliminados?
```
Soft delete + audit_logs permite recuperar:
- Ver deleted_at timestamp
- Ver old_values en audit_logs
- Restaurar con DELETE ... WHERE id = ?; UPDATE ... SET deleted_at = NULL;
```

### ¿Qué pasa si alguien consulta sin user_id?
```
Todas las queries incluyen WHERE user_id = $1
User_id viene SOLO del JWT (extraído del sub claim)
Nunca del body/query string
→ Imposible acceder a datos de otro usuario
```

---

## 📊 Diagrama de Flujo

```
┌─────────────┐
│  User Login │
└──────┬──────┘
       │
       ↓
┌─────────────────────────────────────┐
│ Auth Service                         │
│ ├─ Query: auth.users (idx_username) │
│ ├─ Validate: password_hash          │
│ ├─ Create: refresh_token            │
│ └─ Return: JWT {sub: userId}        │
└──────┬──────────────────────────────┘
       │
       │ JWT Token {sub: userId}
       ↓
┌─────────────────────────────────────────────┐
│ Request to Transactions Service             │
│ ├─ Header: Authorization: Bearer JWT       │
│ └─ Extract: userId = JWT.sub               │
└──────┬──────────────────────────────────────┘
       │
       ↓
┌──────────────────────────────────────────────┐
│ Transactions Service                          │
│ ├─ Query: transactions (idx_user_date)       │
│ │  WHERE user_id = $1 (from JWT)            │
│ ├─ Audit: audit_logs insert (trigger)       │
│ ├─ Check: budget_status (view)              │
│ └─ Return: User's transactions only          │
└──────┬───────────────────────────────────────┘
       │
       ↓
┌─────────────┐
│ User Response│
└─────────────┘
```

---

## ✅ Checklist de Auditoría

### Seguridad
- ✅ No hay datos sin `deleted_at IS NULL`
- ✅ Todas las queries filtran por `user_id`
- ✅ UserId viene del JWT (no del body)
- ✅ Soft deletes activos
- ✅ Auditoría en transacciones

### Performance
- ✅ Índices en claves de búsqueda
- ✅ Índices compuestos (user_id, fecha)
- ✅ Partial indexes para activos
- ✅ Vistas para reportes complejos

### Compliance
- ✅ Auditoría inmutable (audit_logs)
- ✅ JSONB before/after snapshots
- ✅ 7-year retention policy
- ✅ IP/User-Agent tracking

---

## 🎯 Próximos Pasos

1. **Leer DATABASE_ARCHITECTURE.md** - Entender el diseño
2. **Seguir DATABASE_SETUP_GUIDE.md** - Instalar y configurar
3. **Revisar SQL files** - Ver la implementación
4. **Verificar en psql/pgAdmin** - Confirmar todo funciona
5. **Configurar .NET** - Connection strings y EF Core
6. **Escribir Entity Models** - Scaffolding desde BD
7. **Crear Repositories** - Data access layer
8. **Unit Tests** - Validar lógica

---

## 📞 Soporte

**Errores comunes:**
- Ver DATABASE_SETUP_GUIDE.md → Troubleshooting

**Preguntas sobre diseño:**
- Ver DATABASE_ARCHITECTURE.md → Mejores Prácticas

**Queries SQL:**
- Ver QUERIES_COMUNES.md (próximo documento)

---

**Última actualización:** 2025-01-20  
**Versión:** 1.0  
**Estado:** ✅ Completo

