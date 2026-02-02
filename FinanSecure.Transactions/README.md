# README - FinanSecure Transactions Service

Microservicio independiente para gestión de transacciones financieras en FinanSecure.

## 📌 Descripción

FinanSecure Transactions Service es responsable de:
- ✅ Crear, leer, actualizar y eliminar transacciones
- ✅ Gestionar categorías personalizadas por usuario
- ✅ Definir y monitorear presupuestos mensuales
- ✅ Generar dashboards y reportes financieros
- ✅ Calcular análisis de ingresos y gastos

## 🎯 Características Principales

| Característica | Descripción |
|---|---|
| **API RESTful** | Endpoints estándar para todas las operaciones |
| **JWT Auth** | Integración con FinanSecure.Auth Service |
| **Base de Datos** | PostgreSQL con migraciones EF Core |
| **Soft Delete** | Preserva datos, marca como eliminados |
| **Dashboard** | Resumen menual de financias |
| **Reportes** | Análisis detallado por categoría |
| **Presupuestos** | Límites mensuales por categoría |
| **Logging** | Serilog para auditoría y debugging |

## 🚀 Inicio Rápido

```bash
# 1. Clonar/Navegar al directorio
cd FinanSecure.Transactions

# 2. Configurar BD
# Ver: SETUP_POSTGRESQL.md

# 3. Restaurar paquetes
dotnet restore

# 4. Aplicar migraciones
dotnet ef database update

# 5. Ejecutar
dotnet run

# 6. Swagger UI
# Abre: http://localhost:5001/swagger
```

## 📦 Estructura del Proyecto

```
FinanSecure.Transactions/
├── Controllers/            # API Endpoints
│   ├── TransactionsController.cs
│   ├── CategoriesController.cs
│   ├── DashboardController.cs
│   └── BudgetsController.cs
├── Services/              # Business Logic
│   ├── TransactionService.cs
│   ├── CategoryService.cs
│   ├── BudgetService.cs
│   └── DashboardService.cs
├── Repositories/          # Data Access
│   ├── TransactionRepository.cs
│   ├── CategoryRepository.cs
│   └── BudgetRepository.cs
├── Models/                # Domain Entities
│   ├── Transaction.cs
│   ├── TransactionCategory.cs
│   └── Budget.cs
├── DTOs/                  # Request/Response Objects
│   ├── RequestDtos.cs
│   └── ResponseDtos.cs
├── Data/                  # EF Core
│   └── TransactionsContext.cs
├── Interfaces/            # Contracts
├── Migrations/            # DB Schema Versions
├── Properties/            # Project Settings
├── Program.cs             # Configuration
├── appsettings.json       # Default Settings
├── FinanSecure.Transactions.csproj
└── Documentation/
    ├── 00_START_HERE.md
    ├── QUICKSTART.md
    ├── ARCHITECTURE.md
    ├── SETUP_POSTGRESQL.md
    ├── FinanSecure.Transactions.http
    └── README.md
```

## 🔌 Endpoints

### Transacciones
```
POST   /api/v1/transactions
GET    /api/v1/transactions
GET    /api/v1/transactions/{id}
PUT    /api/v1/transactions/{id}
DELETE /api/v1/transactions/{id}
GET    /api/v1/transactions/category/{categoryId}
```

### Categorías
```
POST   /api/v1/categories
GET    /api/v1/categories
GET    /api/v1/categories/{id}
PUT    /api/v1/categories/{id}
DELETE /api/v1/categories/{id}
```

### Dashboard
```
GET    /api/v1/dashboard/summary
GET    /api/v1/dashboard/monthly-report
GET    /api/v1/dashboard/income-breakdown
GET    /api/v1/dashboard/expense-breakdown
```

### Presupuestos
```
POST   /api/v1/budgets
GET    /api/v1/budgets/{id}
GET    /api/v1/budgets/month/{month}/{year}
PUT    /api/v1/budgets/{id}
DELETE /api/v1/budgets/{id}
```

## 🔐 Seguridad

- **Autenticación**: JWT Bearer Tokens (de FinanSecure.Auth)
- **Autorización**: Todos los endpoints requieren token válido
- **Aislamiento**: Cada usuario solo ve sus datos
- **Contraseñas**: Manejadas por Auth Service (nunca tocadas aquí)

## 💾 Requisitos

| Componente | Versión | Propósito |
|---|---|---|
| .NET | 8.0+ | Runtime |
| PostgreSQL | 12+ | Base de datos |
| FinanSecure.Auth | v1 | Autenticación |

## 🛠️ Dependencias NuGet

```xml
<PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />
<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.0" />
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.0.0" />
<PackageReference Include="Swashbuckle.AspNetCore" Version="6.4.6" />
<PackageReference Include="Serilog.AspNetCore" Version="8.0.0" />
```

## 📚 Documentación Detallada

- **[00_START_HERE.md](./00_START_HERE.md)** - Guía de inicio
- **[QUICKSTART.md](./QUICKSTART.md)** - Primeros pasos rápidos
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Detalles técnicos
- **[SETUP_POSTGRESQL.md](./SETUP_POSTGRESQL.md)** - Configuración de BD
- **[FinanSecure.Transactions.http](./FinanSecure.Transactions.http)** - Ejemplos HTTP

## 🧪 Testing

```bash
# Tests unitarios
dotnet test

# Con cobertura
dotnet test /p:CollectCoverage=true /p:CoverageFormat=opencover
```

## 🚢 Despliegue

### Desarrollo
```bash
dotnet run --configuration Development
```

### Producción
```bash
dotnet publish -c Release
dotnet FinanSecure.Transactions.dll
```

## 🔗 Integración con otros servicios

### FinanSecure.Auth (Requerido)
- Proporciona JWT tokens
- Valida credenciales
- Gestiona usuarios

**Configuración necesaria**:
```json
{
  "Jwt": {
    "SecretKey": "la-misma-clave-secreta",
    "Issuer": "FinanSecure.Auth",
    "Audience": "FinanSecure.Transactions"
  }
}
```

### FinanSecure Frontend Angular
- Consume endpoints de Transactions Service
- Envia JWT en headers
- Muestra dashboard y reportes

## 📊 Modelos de Datos

### Transaction
- `Id` (Guid)
- `UserId` (Guid - del JWT)
- `Type` (INCOME | EXPENSE)
- `CategoryId` (Guid)
- `Description` (string)
- `Amount` (decimal)
- `Date` (DateTime)
- `IsRecurring` (bool)
- `Notes` (string?)

### TransactionCategory
- `Id` (Guid)
- `UserId` (Guid)
- `Name` (string, unique per user)
- `Type` (INCOME | EXPENSE)
- `Icon` (string?)
- `Color` (hex string?)

### Budget
- `Id` (Guid)
- `UserId` (Guid)
- `CategoryId` (Guid)
- `Limit` (decimal)
- `Month` (1-12)
- `Year` (int)

## ⚙️ Variables de Entorno

```env
ASPNETCORE_ENVIRONMENT=Development|Production
ConnectionStrings__DefaultConnection=Host=localhost;Port=5432;Database=finansecure_transactions_db;...
Jwt__SecretKey=your-secret-key-min-32-chars
Jwt__Issuer=FinanSecure.Auth
Jwt__Audience=FinanSecure.Transactions
```

## 🐛 Troubleshooting

### "Connection refused"
→ Verificar que PostgreSQL está corriendo: `docker ps`

### "Unauthorized" (401)
→ JWT token inválido o expirado. Reautenticar en Auth Service.

### "No migration found"
→ Ejecutar: `dotnet ef database update`

Ver [00_START_HERE.md](./00_START_HERE.md) para más soluciones.

## 📝 Licencia

Propiedad de FinanSecure. Uso interno.

## 👥 Equipo

- **Arquitectura**: Clean Architecture (3 capas)
- **Patrón**: Repository + Service + Controller
- **ORM**: Entity Framework Core 8.0
- **Autenticación**: JWT Bearer

## 📞 Soporte

Para problemas técnicos, contactar al equipo de desarrollo FinanSecure.

---

**Versión**: 1.0  
**Estado**: ✅ Production Ready  
**Última actualización**: 2024-12-30
