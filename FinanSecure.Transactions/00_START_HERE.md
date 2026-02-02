# FinanSecure Transactions Service - START HERE 🚀

Bienvenido a **FinanSecure Transactions Service**, el microservicio independiente para gestionar todas las operaciones financieras de FinanSecure.

## ¿Qué es esto?

Este es un **microservicio autónomo** que maneja:
- ✅ Transacciones financieras (ingresos y gastos)
- ✅ Categorías personalizadas por usuario
- ✅ Presupuestos mensuales con límites
- ✅ Dashboard con resúmenes financieros
- ✅ Reportes detallados de ingresos/gastos

## Inicio Rápido (5 minutos)

### 1. **Requisitos Previos**
```bash
- .NET 8.0 SDK
- PostgreSQL 12+ (o ejecutar con Docker)
- FinanSecure.Auth Service (para validación de JWT)
```

### 2. **Configurar Base de Datos**
```bash
# Opción A: PostgreSQL local
psql -U postgres -c "CREATE DATABASE finansecure_transactions_db;"
psql -U postgres -c "CREATE USER finansecure_user WITH PASSWORD 'SecurePass123!';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE finansecure_transactions_db TO finansecure_user;"

# Opción B: Docker
docker run -d \
  --name finansecure-postgres \
  -e POSTGRES_DB=finansecure_transactions_db \
  -e POSTGRES_USER=finansecure_user \
  -e POSTGRES_PASSWORD=SecurePass123! \
  -p 5432:5432 \
  postgres:15
```

### 3. **Ejecutar Migraciones**
```bash
cd FinanSecure.Transactions
dotnet ef database update
```

### 4. **Iniciar el Servicio**
```bash
dotnet run
# Swagger estará en: http://localhost:5001/swagger
```

## 🏗️ Arquitectura

```
FinanSecure.Transactions/
├── Controllers/          → Endpoints HTTP
├── Services/            → Lógica de negocio
├── Repositories/        → Acceso a datos
├── Models/              → Entidades
├── DTOs/                → Objetos de transferencia
├── Data/                → DbContext (EF Core)
├── Interfaces/          → Contratos
├── Migrations/          → Control de versiones DB
└── Program.cs           → Configuración
```

## 📡 Endpoints Principales

### Transacciones
```
POST   /api/v1/transactions              Crear transacción
GET    /api/v1/transactions              Listar transacciones (con filtros por fecha)
GET    /api/v1/transactions/{id}         Obtener transacción
PUT    /api/v1/transactions/{id}         Actualizar transacción
DELETE /api/v1/transactions/{id}         Eliminar transacción (soft delete)
GET    /api/v1/transactions/category/{id} Transacciones por categoría
```

### Categorías
```
POST   /api/v1/categories                Crear categoría
GET    /api/v1/categories                Listar categorías
GET    /api/v1/categories/{id}           Obtener categoría
PUT    /api/v1/categories/{id}           Actualizar categoría
DELETE /api/v1/categories/{id}           Eliminar categoría
```

### Dashboard y Reportes
```
GET    /api/v1/dashboard/summary                          Resumen del mes actual
GET    /api/v1/dashboard/monthly-report?month=1&year=2024 Reporte mensual
GET    /api/v1/dashboard/income-breakdown                 Desglose de ingresos
GET    /api/v1/dashboard/expense-breakdown                Desglose de gastos
```

### Presupuestos
```
POST   /api/v1/budgets                   Crear presupuesto
GET    /api/v1/budgets/{id}              Obtener presupuesto
GET    /api/v1/budgets/month/{month}/{year} Presupuestos del mes
PUT    /api/v1/budgets/{id}              Actualizar presupuesto
DELETE /api/v1/budgets/{id}              Eliminar presupuesto
```

## 🔐 Autenticación

Todos los endpoints requieren **JWT Bearer Token** del Auth Service:

```bash
curl -H "Authorization: Bearer <jwt_token>" \
     http://localhost:5001/api/v1/transactions
```

El token debe ser válido y emitido por **FinanSecure.Auth**.

## 💾 Estructura de Datos

### Transacciones
```csharp
{
  "id": "uuid",
  "userId": "uuid",  // Del token JWT
  "type": "INCOME" | "EXPENSE",
  "categoryId": "uuid",
  "description": "string",
  "amount": 150.50,
  "date": "2024-01-15T10:30:00Z",
  "isRecurring": false,
  "recurrencePattern": "MONTHLY" | null,
  "notes": "string" | null,
  "createdAt": "datetime",
  "updatedAt": "datetime"
}
```

### Categorías
```csharp
{
  "id": "uuid",
  "userId": "uuid",
  "name": "Groceries",
  "type": "EXPENSE",
  "icon": "🛒",
  "color": "#FF5733",
  "isDefault": false,
  "createdAt": "datetime"
}
```

### Presupuestos
```csharp
{
  "id": "uuid",
  "userId": "uuid",
  "categoryId": "uuid",
  "limit": 500.00,
  "month": 1,
  "year": 2024,
  "spent": 350.00,      // Calculado automáticamente
  "remaining": 150.00,  // Limit - Spent
  "createdAt": "datetime"
}
```

## 🚀 Despliegue

### Desarrollo
```bash
dotnet run --configuration Development
```

### Producción
```bash
dotnet publish -c Release
dotnet FinanSecure.Transactions.dll
```

## 📝 Variables de Entorno

```env
ASPNETCORE_ENVIRONMENT=Development
ConnectionStrings__DefaultConnection=Host=localhost;Port=5432;Database=finansecure_transactions_db;Username=finansecure_user;Password=SecurePass123!
Jwt__SecretKey=your-production-secret-key-min-32-chars
Jwt__Issuer=FinanSecure.Auth
Jwt__Audience=FinanSecure.Transactions
```

## 🔗 Integración con Auth Service

Este microservicio depende de **FinanSecure.Auth** para:
- ✅ Validar JWT tokens
- ✅ Extraer UserId desde claims
- ✅ Verificar autenticación

Asegúrate de que Auth Service esté corriendo y que la configuración JWT sea idéntica en ambos servicios.

## ✅ Testing

```bash
# Tests unitarios
dotnet test

# Con cobertura
dotnet test /p:CollectCoverage=true
```

## 📚 Documentación Completa

- [QUICKSTART.md](./QUICKSTART.md) - Guía de uso rápido
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Detalles arquitectónicos
- [SETUP_POSTGRESQL.md](./SETUP_POSTGRESQL.md) - Configuración de BD
- [FinanSecure.Transactions.http](./FinanSecure.Transactions.http) - Ejemplos HTTP

## 🆘 Solución de Problemas

**Error: "No migration found"**
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

**Error: "Connection refused"**
- Verificar que PostgreSQL está corriendo
- Verificar ConnectionString en appsettings.json
- Probar: `psql -h localhost -U finansecure_user -d finansecure_transactions_db`

**Error: "Unauthorized" (401)**
- Verificar que el JWT token es válido
- Verificar que el token fue emitido por Auth Service
- Verificar que Jwt__SecretKey coincide en ambos servicios

## 📞 Soporte

Para problemas o sugerencias, contacta al equipo de FinanSecure.

---

**¡Listo para empezar!** Sigue los pasos en [QUICKSTART.md](./QUICKSTART.md) para tu primer endpoint. 🚀
