# FinanSecure.Auth - Estructura Completa del Microservicio

## 📁 Estructura de Directorios

```
FinanSecure.Auth/
├── Controllers/
│   ├── AuthController.cs          # Endpoints de autenticación
│   └── HealthController.cs        # Health check
├── Data/
│   └── AuthContext.cs             # DbContext de EF Core
├── DTOs/
│   ├── RequestDtos.cs             # Register, Login, RefreshToken requests
│   └── ResponseDtos.cs            # Auth, Token, User, Error responses
├── Interfaces/
│   ├── IAuthService.cs            # Interfaz del servicio de auth
│   ├── IUserRepository.cs         # Interfaz del repositorio de usuarios
│   ├── IRefreshTokenRepository.cs # Interfaz del repositorio de refresh tokens
│   ├── IJwtService.cs             # Interfaz del servicio JWT
│   └── IPasswordService.cs        # Interfaz del servicio de contraseñas
├── Models/
│   ├── User.cs                    # Entidad Usuario
│   └── RefreshToken.cs            # Entidad Refresh Token
├── Repositories/
│   ├── UserRepository.cs          # Implementación del repositorio de usuarios
│   └── RefreshTokenRepository.cs  # Implementación del repositorio de refresh tokens
├── Services/
│   ├── AuthService.cs             # Lógica de autenticación
│   ├── JwtService.cs              # Generación y validación de JWT
│   └── PasswordService.cs         # Hash y verificación de contraseñas
├── Migrations/
│   ├── 20251230100000_InitialCreate.cs
│   └── AuthContextModelSnapshot.cs
├── Properties/
│   └── launchSettings.json        # Configuración de ejecución
├── Program.cs                     # Punto de entrada y configuración
├── FinanSecure.Auth.csproj        # Archivo de proyecto
├── appsettings.json               # Configuración de producción
├── appsettings.Development.json   # Configuración de desarrollo
├── README.md                      # Documentación
├── .gitignore                     # Gitignore
└── ARCHITECTURE.md                # Este archivo
```

## 🏗️ Arquitectura en Capas

```
┌─────────────────────────────────────────────────────┐
│               Controllers (HTTP)                    │
│  ┌──────────────────────────────────────────────┐  │
│  │ AuthController        │ HealthController     │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│               Services (Business Logic)             │
│  ┌──────────────────────────────────────────────┐  │
│  │ AuthService         │ JwtService │ Password… │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│            Repositories (Data Access)               │
│  ┌──────────────────────────────────────────────┐  │
│  │ UserRepository      │ RefreshTokenRepository  │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────┐
│         DbContext (Entity Framework Core)           │
│  ┌──────────────────────────────────────────────┐  │
│  │         AuthContext (PostgreSQL)            │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

## 📦 Modelos de Datos

### User
```csharp
public class User
{
    public Guid Id { get; set; }                    // PK
    public string Username { get; set; }            // Único
    public string Email { get; set; }               // Único
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string PasswordHash { get; set; }        // Hasheado con BCrypt
    public bool IsActive { get; set; }              // Control de acceso
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }
    public ICollection<RefreshToken> RefreshTokens { get; set; }
}
```

**Tabla:** `users`  
**Índices únicos:** Username, Email  
**Relación:** 1:N con RefreshToken (eliminación cascada)

### RefreshToken
```csharp
public class RefreshToken
{
    public Guid Id { get; set; }                    // PK
    public Guid UserId { get; set; }                // FK
    public string Token { get; set; }               // Token opaco
    public DateTime ExpiresAt { get; set; }         // 7 días
    public DateTime? RevokedAt { get; set; }        // Soft revoke
    public DateTime CreatedAt { get; set; }
    public string? UserAgent { get; set; }          // Opcional: tracking
    public string? IpAddress { get; set; }          // Opcional: tracking
    public User User { get; set; }                  // Navegación
    public bool IsActive => RevokedAt == null && ExpiresAt > DateTime.UtcNow;
}
```

**Tabla:** `refresh_tokens`  
**Índices:** (UserId, Token)  
**Relación:** N:1 con User

## 🔐 Flujo de Autenticación

```
┌─────────────────┐
│ Register        │
│ (usuario nuevo) │
└────────┬────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ 1. Validar username/email no existan        │
│ 2. Hash password con BCrypt (12 rounds)     │
│ 3. Guardar usuario en DB                    │
│ 4. Retornar UserDto sin tokens              │
└────────┬─────────────────────────────────────┘
         │
         │
         ▼
┌─────────────────┐
│ Login           │
│ (obtener tokens)│
└────────┬────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ 1. Buscar usuario por username               │
│ 2. Verificar contraseña vs hash              │
│ 3. Generar Access Token (JWT, 15 min)       │
│ 4. Generar Refresh Token (opaco, 7 días)    │
│ 5. Guardar Refresh Token en DB              │
│ 6. Actualizar LastLoginAt                   │
│ 7. Retornar ambos tokens                    │
└────────┬─────────────────────────────────────┘
         │
         │
         ▼
┌─────────────────────────────────┐
│ Request con Access Token        │
│ Authorization: Bearer <JWT>     │
└────────┬────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ 1. Validar JWT (firma, exp, iss, aud)       │
│ 2. Extraer UserId del claim "sub"           │
│ 3. Procesar request autenticado             │
└────────┬─────────────────────────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Token Expirado           │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ POST /refresh-token                          │
│ Body: { "refreshToken": "..." }              │
└────────┬─────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ 1. Buscar Refresh Token en DB                │
│ 2. Validar: no revocado, no expirado        │
│ 3. Revocar token anterior                    │
│ 4. Generar nuevo Access Token                │
│ 5. Generar nuevo Refresh Token               │
│ 6. Guardar nuevo token en DB                 │
│ 7. Retornar nuevos tokens                    │
└────────┬─────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ POST /logout                                 │
│ Body: { "refreshToken": "..." }              │
└────────┬─────────────────────────────────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│ 1. Buscar Refresh Token en DB                │
│ 2. Marcar como revocado (RevokedAt = ahora)  │
│ 3. Retornar success                          │
└──────────────────────────────────────────────┘
```

## 🔑 JWT Claims

**Access Token** (válido 15 minutos):
```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",    // UserId
  "name": "juan.perez",                              // Username
  "email": "juan@example.com",
  "iat": 1735560600,                                 // Issued at
  "exp": 1735561500,                                 // Expires at
  "iss": "FinanSecure.Auth",
  "aud": "FinanSecure.App"
}
```

## 📋 Endpoints API

### v1 (Actual)
```
POST   /api/v1/auth/register      → Registrar usuario
POST   /api/v1/auth/login         → Login y obtener tokens
POST   /api/v1/auth/refresh-token → Renovar access token
POST   /api/v1/auth/logout        → Revocar refresh token
POST   /api/v1/auth/validate      → Validar access token
GET    /api/v1/health             → Health check
```

## 🛠️ Dependencias Clave

| Paquete | Versión | Propósito |
|---------|---------|----------|
| Microsoft.EntityFrameworkCore | 8.0.0 | ORM |
| Npgsql.EntityFrameworkCore.PostgreSQL | 8.0.0 | Proveedor PostgreSQL |
| System.IdentityModel.Tokens.Jwt | 7.0.0 | JWT |
| Microsoft.AspNetCore.Authentication.JwtBearer | 8.0.0 | Middleware JWT |
| BCrypt.Net-Next | 4.0.3 | Hash de contraseñas |
| Swashbuckle.AspNetCore | 6.4.6 | Swagger/OpenAPI |

## 🔄 Inyección de Dependencias

En `Program.cs`:
```csharp
// Repositories
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();

// Services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IPasswordService, PasswordService>();
```

## 🧪 Ejemplos de Requests

### Registro
```bash
curl -X POST http://localhost:5001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "juan.perez",
    "email": "juan@example.com",
    "firstName": "Juan",
    "lastName": "Pérez",
    "password": "SecurePass123!"
  }'
```

### Login
```bash
curl -X POST http://localhost:5001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "juan.perez",
    "password": "SecurePass123!"
  }'
```

### Request Protegido
```bash
curl -X GET http://localhost:5001/api/v1/protected \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## 🔒 Seguridad

✅ **Hashing de Contraseñas**
- BCrypt con 12 rounds (costo)
- Tarda ~100ms por password

✅ **JWT Firmado**
- HMAC SHA-256
- Validación de issuer y audience
- Expiración automática

✅ **Refresh Token**
- Token opaco (no JWT)
- Expiración: 7 días
- Revocación suave (soft delete)

✅ **CORS**
- Permitir solo orígenes confiables
- Métodos y headers controlados

✅ **Validación**
- Entrada validada en controllers
- Índices únicos en DB (username, email)

## 📈 Escalabilidad Futura

1. **Caching**
   - Cachear usuarios frecuentes
   - Cachear keys públicas de JWT

2. **Rate Limiting**
   - 5 intentos de login/min
   - 10 registros/min por IP

3. **Audit**
   - Registrar todos los logins
   - Registrar cambios de contraseña

4. **2FA**
   - TOTP (Time-based OTP)
   - Email verification

5. **OAuth2**
   - Implementar OAuth2 server
   - Soportar social login

## 🚀 Próximos Pasos

1. ✅ Crear base de datos PostgreSQL
2. ✅ Ejecutar migraciones: `dotnet ef database update`
3. ✅ Ejecutar en desarrollo: `dotnet run`
4. ✅ Acceder a Swagger: http://localhost:5001
5. ✅ Probar endpoints

## 📚 Referencias

- [JWT - RFC 7519](https://tools.ietf.org/html/rfc7519)
- [BCrypt - Spring Security](https://docs.spring.io/spring-security/reference/features/authentication/password-storage.html)
- [EF Core - PostgreSQL](https://www.npgsql.org/efcore/)
- [ASP.NET Core Auth](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/)
