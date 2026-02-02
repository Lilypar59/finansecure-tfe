# Guía Rápida de Inicio - FinanSecure.Auth

## ⚡ Inicio en 5 minutos

### 1. Prerequisitos
```bash
# Verificar .NET 8
dotnet --version
# Debe retornar: 8.x.x

# Verificar PostgreSQL
psql --version
# Debe retornar: psql (PostgreSQL) 12.x o superior
```

### 2. Crear Base de Datos
```bash
# Opción A: Usar script SQL
psql -U postgres -f SETUP_POSTGRESQL.md

# Opción B: Manualmente
psql -U postgres
CREATE DATABASE finansecure_auth_db;
\q
```

### 3. Configurar Cadena de Conexión

Editar `appsettings.Development.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=finansecure_auth_db_dev;Username=postgres;Password=postgres;"
  }
}
```

### 4. Restaurar Paquetes y Compilar
```bash
cd FinanSecure.Auth
dotnet restore
dotnet build
```

### 5. Ejecutar Aplicación
```bash
dotnet run
```

**Salida esperada:**
```
info: Microsoft.EntityFrameworkCore.Infrastructure
      Entity Framework Core 8.0.0 initialized 'AuthContext' using provider 'Npgsql.EntityFrameworkCore.PostgreSQL:8.0.0'
info: Microsoft.EntityFrameworkCore.Database.Command
      Executed DbCommand

Now listening on: http://localhost:5001
Application started. Press Ctrl+C to exit.
```

### 6. Verificar Swagger
Abrir en navegador: http://localhost:5001

Debe mostrar UI de Swagger con todos los endpoints.

## 🧪 Pruebas Rápidas

### Opción 1: Usar Swagger UI
1. Abrir http://localhost:5001
2. Click en "POST /api/v1/auth/register"
3. Click "Try it out"
4. Completar formulario
5. Click "Execute"

### Opción 2: Usar curl

**Registrar usuario:**
```bash
curl -X POST http://localhost:5001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "firstName": "Test",
    "lastName": "User",
    "password": "TestPass123!"
  }'
```

**Login:**
```bash
curl -X POST http://localhost:5001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "TestPass123!"
  }'
```

**Health Check:**
```bash
curl http://localhost:5001/api/v1/health
```

### Opción 3: Usar Postman

1. Importar colección (crear manualmente o desde Swagger)
2. Variables de entorno:
   - `base_url`: http://localhost:5001
   - `token`: (copiar de login response)
   - `refresh_token`: (copiar de login response)

## 📝 Configuración Avanzada

### JWT Secret
Cambiar en `appsettings.json`:
```json
"Jwt": {
  "SecretKey": "your-new-super-secret-key-at-least-32-chars!!!",
  "AccessTokenExpirationMinutes": 15
}
```

### Log Level
```json
"Logging": {
  "LogLevel": {
    "Default": "Debug",
    "Microsoft.EntityFrameworkCore": "Information"
  }
}
```

### CORS Origenes
En `Program.cs`:
```csharp
.WithOrigins(
    "http://localhost:4200",
    "http://localhost:3000",
    "https://myapp.com"
)
```

## 🔍 Verificación de Base de Datos

```bash
# Conectarse
psql -U postgres -d finansecure_auth_db_dev

# Ver tablas
\dt

# Ver usuarios
SELECT * FROM users;

# Ver refresh tokens
SELECT id, user_id, expires_at, revoked_at FROM refresh_tokens;

# Salir
\q
```

## 🛑 Solución de Problemas

### Puerto 5001 ya en uso
```bash
# Encontrar proceso usando puerto
lsof -i :5001

# Matar proceso (macOS/Linux)
kill -9 <PID>

# O cambiar puerto en launchSettings.json
```

### Error de conexión a BD
```bash
# Verificar PostgreSQL corriendo
sudo systemctl status postgresql

# O en macOS
brew services list

# Reiniciar si es necesario
sudo systemctl restart postgresql
```

### Error en migración
```bash
# Ver migraciones
dotnet ef migrations list

# Revertir última
dotnet ef database update -1

# Crear nueva
dotnet ef database update
```

## 📦 Estructura de Archivos Importante

```
FinanSecure.Auth/
├── Controllers/          ← Endpoints HTTP
├── Services/             ← Lógica de negocio
├── Repositories/         ← Acceso a datos
├── Models/               ← Entidades BD
├── Program.cs            ← Configuración principal
├── appsettings.json      ← Config producción
└── appsettings.Development.json  ← Config desarrollo
```

## 🔐 Seguridad Básica

1. **Cambiar JWT Secret**: ⚠️ MUY IMPORTANTE
   ```json
   "SecretKey": "use-command: openssl rand -base64 32"
   ```

2. **Usar contraseñas fuertes**: Mínimo 8 caracteres, mayúsculas, números, símbolos

3. **Usar HTTPS en producción**: Habilitar en `Program.cs`

4. **Configurar CORS correctamente**: Solo orígenes confiables

## 📊 Monitoreo

### Ver logs en tiempo real
```bash
dotnet run --configuration Debug
```

### Logs guardados (si está configurado)
```bash
tail -f logs/application.log
```

## 🚀 Deploy en Producción

1. Cambiar `ASPNETCORE_ENVIRONMENT` a "Production"
2. Usar HTTPS: `app.UseHttpsRedirection();`
3. Deshabilitar Swagger:
   ```csharp
   if (app.Environment.IsDevelopment())
   {
       app.UseSwagger();
   }
   ```
4. Usar variables de entorno para secrets
5. Configurar base de datos remota en appsettings.json

## 📚 Documentación Completa

Ver archivos:
- `README.md` - Documentación completa
- `ARCHITECTURE.md` - Arquitectura y flujos
- `SETUP_POSTGRESQL.md` - Setup de PostgreSQL

## ✅ Checklist Pre-Deploy

- [ ] JWT Secret cambiado
- [ ] Base de datos funcionando
- [ ] Swagger deshabilitado en producción
- [ ] HTTPS configurado
- [ ] CORS restringido
- [ ] Logs configurados
- [ ] Backup de BD configurado
- [ ] Monitoring habilitado

---

**¿Problemas?** Revisar documentación o crear issue en el repositorio.
