# FinanSecure Transactions Service - ARCHITECTURE

Documentación técnica detallada del diseño e implementación.

## 📐 Visión General de Arquitectura

FinanSecure Transactions Service implementa **Clean Architecture** con separación de capas:

```
┌─────────────────────────────────────────────────────┐
│         Controllers (API Layer)                     │
│  - TransactionsController                           │
│  - CategoriesController                             │
│  - DashboardController                              │
│  - BudgetsController                                │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│        Services (Business Logic Layer)              │
│  - TransactionService                               │
│  - CategoryService                                  │
│  - BudgetService                                    │
│  - DashboardService                                 │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│    Repositories (Data Access Layer)                 │
│  - TransactionRepository                            │
│  - CategoryRepository                               │
│  - BudgetRepository                                 │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│      DbContext (Entity Framework Core)              │
│  - TransactionsContext                              │
│  - PostgreSQL Provider                              │
└─────────────────────────────────────────────────────┘
```

## 🗄️ Modelo de Datos

### Transacciones
```csharp
Transaction {
  Id: Guid (Primary Key)
  UserId: Guid (FK a Auth Service)
  Type: string ("INCOME" | "EXPENSE")
  CategoryId: Guid (FK → TransactionCategory)
  Description: string (max 500)
  Amount: decimal(12,2)
  Date: DateTime (UTC)
  Notes: string (nullable)
  IsRecurring: bool
  RecurrencePattern: string (nullable - "DAILY", "WEEKLY", "MONTHLY", etc.)
  CreatedAt: DateTime
  UpdatedAt: DateTime
  IsDeleted: bool (soft delete)
}

Indexes:
  - (UserId, Date) → Filtros por rango de fechas
  - (UserId, Type) → Filtros por tipo de transacción
  - (UserId, CategoryId) → Filtros por categoría
  - CategoryId → Joins con categorías
```

### Categorías
```csharp
TransactionCategory {
  Id: Guid (Primary Key)
  UserId: Guid (FK a Auth Service)
  Name: string (max 100, unique per user)
  Type: string ("INCOME" | "EXPENSE")
  Icon: string (emoji o nombre - nullable)
  Color: string (hex color code - nullable)
  IsDefault: bool
  CreatedAt: DateTime
}

Indexes:
  - (UserId, Name) UNIQUE → Garantiza nombres únicos por usuario
```

### Presupuestos
```csharp
Budget {
  Id: Guid (Primary Key)
  UserId: Guid (FK a Auth Service)
  CategoryId: Guid (FK → TransactionCategory)
  Limit: decimal(12,2)
  Month: int (1-12)
  Year: int
  CreatedAt: DateTime
  UpdatedAt: DateTime
}

Indexes:
  - (UserId, Month, Year) → Presupuestos del mes
  - (UserId, CategoryId) → Presupuesto de categoría específica
  - CategoryId → Joins con categorías
```

## 🔄 Flujo de Datos

### Crear Transacción
```
POST /api/v1/transactions
  ↓ (JWT Token) → Extraer UserId del claim
  ↓ (TransactionsController)
  ↓ Validar request
  ↓ (TransactionService.CreateAsync)
  ↓ Validar que categoría existe y pertenece al usuario
  ↓ Crear modelo Transaction
  ↓ (TransactionRepository.CreateAsync)
  ↓ (DbContext.SaveChangesAsync)
  ↓ PostgreSQL
  ↓ Retornar TransactionDto
```

### Obtener Dashboard
```
GET /api/v1/dashboard/summary
  ↓ Extraer UserId del JWT
  ↓ (DashboardService.GetDashboardSummaryAsync)
  ↓ Obtener transacciones del mes actual
  ↓ (TransactionRepository.GetByUserAsync)
  ↓ Agrupar por tipo (INCOME/EXPENSE)
  ↓ Calcular totales
  ↓ Agrupar por categoría
  ↓ Calcular porcentajes
  ↓ Retornar DashboardSummaryDto
```

## 🔐 Seguridad

### Autenticación
- **JWT Bearer Tokens** emitidos por FinanSecure.Auth Service
- Algoritmo: HMAC-SHA256
- TTL: 15 minutos (configurable)

### Autorización
- Todos los endpoints protegidos con `[Authorize]`
- Validación: Token debe ser emitido por Auth Service
- Extraer UserId del claim `sub` (Subject)
- Cada operación verifica que el recurso pertenece al usuario

### Datos Sensibles
- Contraseñas: Manejadas por Auth Service
- Transacciones: Aisladas por UserId
- Sin almacenamiento de datos en plaintext

## 🎯 Patrones y Convenciones

### Nomenclatura Base de Datos
```
snake_case para todas las columnas y tablas
Ejemplo: transaction_categories, created_at, is_deleted
```

### DTOs (Data Transfer Objects)
```csharp
// Requests
CreateTransactionRequest
UpdateTransactionRequest
CreateCategoryRequest
CreateBudgetRequest

// Responses
TransactionDto
CategoryDto
BudgetDto
DashboardSummaryDto
CategoryBreakdownDto
MonthlyReportDto
ApiResponse<T>  // Wrapper genérico
ErrorResponse
```

### Respuestas API
```json
{
  "success": true,
  "data": { /* objeto */ },
  "message": "Operación exitosa"
}
```

## 🔌 Interfaces y Inyección de Dependencias

### Interfaces
```csharp
ITransactionService   → Contrato para operaciones de transacciones
ICategoryService      → Contrato para categorías
IBudgetService        → Contrato para presupuestos
IDashboardService     → Contrato para cálculos de dashboard

ITransactionRepository → Acceso a datos de transacciones
ICategoryRepository    → Acceso a datos de categorías
IBudgetRepository      → Acceso a datos de presupuestos
```

### Registro en Program.cs
```csharp
// Repositories
builder.Services.AddScoped<ITransactionRepository, TransactionRepository>();
builder.Services.AddScoped<ICategoryRepository, CategoryRepository>();
builder.Services.AddScoped<IBudgetRepository, BudgetRepository>();

// Services
builder.Services.AddScoped<ITransactionService, TransactionService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IBudgetService, BudgetService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();

// DbContext
builder.Services.AddDbContext<TransactionsContext>(options =>
    options.UseNpgsql(connectionString));
```

## 📊 Cálculos de Dashboard

### Resumen Mensual
```csharp
var monthStart = new DateTime(year, month, 1);
var monthEnd = monthStart.AddMonths(1).AddDays(-1);

TotalIncome = Σ Amount donde Type="INCOME"
TotalExpenses = Σ Amount donde Type="EXPENSE"
Balance = TotalIncome - TotalExpenses
```

### Desglose por Categoría
```csharp
IncomeByCategory = GroupBy(Type="INCOME", CategoryId)
                   Select(CategoryName, Sum(Amount), Percentage)
                   OrderBy(Amount DESC)

ExpenseByCategory = Similar, pero Type="EXPENSE"

Percentage = (Amount / Total) * 100
```

## ⚡ Optimizaciones de Rendimiento

### Índices Estratégicos
```sql
-- Búsqueda rápida por usuario y fecha
CREATE INDEX ix_transactions_user_id_date 
ON transactions(user_id, date DESC);

-- Filtrado por tipo de transacción
CREATE INDEX ix_transactions_user_id_type 
ON transactions(user_id, type);

-- Búsqueda en presupuestos
CREATE INDEX ix_budgets_user_id_month_year 
ON budgets(user_id, month, year);
```

### Soft Delete
Transacciones marcadas como `is_deleted=true` sin eliminar del DB:
- ✅ Preserva integridad referencial
- ✅ Permite recuperación de datos
- ✅ Auditoría y compliance

Todas las queries filtran automáticamente: `WHERE is_deleted = false`

## 🚀 Escalabilidad

### Horizontal
- Múltiples instancias pueden servir solicitudes
- PostgreSQL maneja concurrencia con locks
- JWT stateless (sin sesiones)

### Vertical
- Índices estratégicos minimizan consultas
- Cálculos de agregaciones en DB (no en memoria)
- Lazy loading deshabilitado en DTOs

## 📈 Métricas Monitoreadas

```
Logs con Serilog:
- Errores y excepciones
- Operaciones de transacciones
- Consultas lentas (QueryEvents)
```

## 🔗 Integración con Auth Service

FinanSecure.Auth proporciona:
- ✅ JWT Token (contiene UserId en claim `sub`)
- ✅ Validación de credenciales
- ✅ Refresh tokens

Transactions Service usa:
- ✅ Valida firma del JWT
- ✅ Extrae UserId del token
- ✅ Asila datos por usuario

## 🧪 Testing

### Unit Tests (planeados)
```csharp
TransactionServiceTests
CategoryServiceTests
BudgetServiceTests
DashboardServiceTests
```

### Integration Tests (planeados)
```
PostgreSQL en contenedor Docker
Tests contra BD real
Validación de migraciones
```

## 📋 Definiciones

**Soft Delete**: Marcar registro como eliminado sin remover de BD  
**DTOs**: Objetos para transferencia de datos entre capas  
**Repository Pattern**: Abstracción de acceso a datos  
**Microservicio**: Servicio independiente con BD propia  
**JWT**: JSON Web Token para autenticación stateless

---

**Próximos temas**: 
- Caching de consultas frecuentes
- Rate limiting por usuario
- Auditoría de cambios
- Notificaciones de presupuesto excedido
