# FinanSecure Transactions Service - QUICKSTART

Guía rápida para poner en marcha el Transactions Service en 5 minutos.

## 1. Base de Datos

```bash
# Crear BD en PostgreSQL
psql -U postgres
CREATE DATABASE finansecure_transactions_db;
CREATE USER finansecure_user WITH PASSWORD 'SecurePass123!';
GRANT ALL PRIVILEGES ON DATABASE finansecure_transactions_db TO finansecure_user;
\q
```

## 2. Migraciones

```bash
cd FinanSecure.Transactions
dotnet ef database update
```

## 3. Ejecutar

```bash
dotnet run
# Swagger: http://localhost:5001/swagger
```

## 4. Primer Endpoint

### A. Obtener JWT Token (desde Auth Service)
```bash
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "usuario",
    "password": "contraseña"
  }'
# Respuesta contiene "accessToken"
```

### B. Crear Categoría
```bash
curl -X POST http://localhost:5001/api/v1/categories \
  -H "Authorization: Bearer <tu_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Groceries",
    "type": "EXPENSE",
    "icon": "🛒",
    "color": "#FF5733"
  }'
```

### C. Crear Transacción
```bash
curl -X POST http://localhost:5001/api/v1/transactions \
  -H "Authorization: Bearer <tu_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "EXPENSE",
    "categoryId": "category-uuid-aqui",
    "description": "Compra de groceries",
    "amount": 75.50,
    "date": "2024-01-15T10:30:00Z"
  }'
```

### D. Dashboard
```bash
curl -X GET http://localhost:5001/api/v1/dashboard/summary \
  -H "Authorization: Bearer <tu_token>"
```

## 5. Usar Swagger UI

Abre: **http://localhost:5001/swagger**

- Click en "Authorize" 🔒
- Pega tu JWT token sin el prefijo "Bearer "
- ¡Los endpoints estarán desbloqueados!

## 6. Estructura Base de Datos

| Tabla | Propósito |
|-------|-----------|
| transaction_categories | Categorías del usuario |
| transactions | Transacciones (INCOME/EXPENSE) |
| budgets | Presupuestos mensuales |

## 7. Configuración de Desarrollo

Edita `appsettings.Development.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=finansecure_transactions_db;Username=finansecure_user;Password=SecurePass123!"
  },
  "Jwt": {
    "SecretKey": "tu-clave-secreta-minimo-32-caracteres",
    "Issuer": "FinanSecure.Auth",
    "Audience": "FinanSecure.Transactions"
  }
}
```

## 8. Comandos Útiles

```bash
# Ver logs
dotnet run --verbosity Debug

# Crear nueva migración
dotnet ef migrations add NombreMigracion

# Ver estado BD
dotnet ef migrations list

# Revertir última migración
dotnet ef migrations remove

# Limpiar BD
dotnet ef database drop
```

## 9. Verificar Conectividad

```bash
# Health Check (no requiere auth)
curl http://localhost:5001/health

# Si Auth Service está en otro puerto, edita en Program.cs
# Cambiar puerto por defecto: launchSettings.json
```

## 10. Próximos Pasos

✅ Leer [ARCHITECTURE.md](./ARCHITECTURE.md) para entender el diseño  
✅ Explorar endpoints en [FinanSecure.Transactions.http](./FinanSecure.Transactions.http)  
✅ Configurar CI/CD en tu repositorio  
✅ Integrar con frontend Angular

---

**¿Problemas?** Ver sección "Solución de Problemas" en [00_START_HERE.md](./00_START_HERE.md)
