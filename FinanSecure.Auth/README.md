# FinanSecure.Auth - Microservicio de Autenticación

Microservicio independiente responsable de identidad, autenticación y autorización para la plataforma FinanSecure.

## Características

✅ Registro de usuarios con validación  
✅ Login seguro con contraseñas hasheadas (BCrypt)  
✅ Emisión de JWT Access Tokens  
✅ Refresh Tokens con revocación  
✅ Validación de tokens  
✅ Cambio de contraseñas  
✅ Health check endpoint  
✅ Swagger/OpenAPI documentation  
✅ Preparado para rate limiting  
✅ Logging estructurado  
✅ CORS configurado para múltiples orígenes  

## Arquitectura

```
Controllers (API endpoints)
    ↓
Services (Business logic)
    ↓
Repositories (Data access)
    ↓
DbContext (EF Core)
    ↓
PostgreSQL
```

## Requisitos

- .NET 8.0 SDK
- PostgreSQL 12+
- Visual Studio 2022 / VS Code

## Configuración

### 1. Variables de Entorno / appsettings.json

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=finansecure_auth_db;Username=postgres;Password=postgres;"
  },
  "Jwt": {
    "SecretKey": "your-super-secret-key-change-this-in-production",
    "Issuer": "FinanSecure.Auth",
    "Audience": "FinanSecure.App",
    "AccessTokenExpirationMinutes": 15,
    "RefreshTokenExpirationDays": 7
  }
}
```

### 2. Crear Base de Datos PostgreSQL

```bash
# Crear base de datos
createdb finansecure_auth_db -U postgres

# O desde psql
psql -U postgres
CREATE DATABASE finansecure_auth_db;
```

### 3. Ejecutar Migraciones

```bash
# Aplicar migraciones automáticamente (en Program.cs)
dotnet run

# O manualmente
dotnet ef database update
```

## Endpoints

### Autenticación

#### Registro
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "username": "juan.perez",
  "email": "juan@example.com",
  "firstName": "Juan",
  "lastName": "Pérez",
  "password": "SecurePass123!"
}

Response 200:
{
  "success": true,
  "message": "Usuario registrado exitosamente.",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "juan.perez",
    "email": "juan@example.com",
    "firstName": "Juan",
    "lastName": "Pérez",
    "isActive": true,
    "createdAt": "2025-12-30T10:30:00Z",
    "lastLoginAt": null
  }
}
```

#### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "juan.perez",
  "password": "SecurePass123!"
}

Response 200:
{
  "success": true,
  "message": "Login exitoso.",
  "user": { ... },
  "tokens": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "xK9mL2pQ5vB8nC3jH7fG6dE0wA4sT1rU...",
    "expiresIn": 900,
    "tokenType": "Bearer"
  }
}
```

#### Refrescar Token
```http
POST /api/v1/auth/refresh-token
Content-Type: application/json

{
  "refreshToken": "xK9mL2pQ5vB8nC3jH7fG6dE0wA4sT1rU..."
}

Response 200:
{
  "success": true,
  "message": "Tokens refrescados exitosamente.",
  "tokens": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "newRefreshTokenValue...",
    "expiresIn": 900,
    "tokenType": "Bearer"
  }
}
```

#### Logout
```http
POST /api/v1/auth/logout
Content-Type: application/json

{
  "refreshToken": "xK9mL2pQ5vB8nC3jH7fG6dE0wA4sT1rU..."
}

Response 200:
{
  "success": true,
  "message": "Logout exitoso."
}
```

#### Validar Token
```http
POST /api/v1/auth/validate?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

Response 200:
{
  "success": true,
  "message": "Token válido.",
  "user": { ... }
}
```

### Health Check

```http
GET /api/v1/health

Response 200:
{
  "status": "healthy",
  "service": "FinanSecure.Auth",
  "timestamp": "2025-12-30T10:30:00Z",
  "version": "1.0.0"
}
```

## Uso de JWT en Requests

Para acceder a endpoints protegidos, incluir el Access Token en el header:

```http
GET /api/v1/protected-endpoint
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Estructura de JWT

El Access Token contiene los siguientes claims:

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "name": "juan.perez",
  "email": "juan@example.com",
  "iat": 1735560600,
  "exp": 1735561500,
  "iss": "FinanSecure.Auth",
  "aud": "FinanSecure.App"
}
```

## Seguridad

- ✅ Contraseñas hasheadas con BCrypt (rounds=12)
- ✅ JWT firmado con HMAC SHA-256
- ✅ Refresh tokens con expiración
- ✅ Revocación de tokens
- ✅ CORS habilitado solo para orígenes confiables
- ✅ Validación de entrada en controllers

## Desarrollo

### Crear Migración Nueva

```bash
dotnet ef migrations add NombreMigracion
dotnet ef database update
```

### Ejecutar en Desarrollo

```bash
dotnet run
```

Swagger disponible en: http://localhost:5001

### Tests

Próximamente: Tests unitarios y de integración.

## Preparación para Rate Limiting

El servicio está preparado para integración con bibliotecas de rate limiting como:

- AspNetCoreRateLimit
- RateLimitMiddleware personalizado

Ejemplo de configuración futura:

```csharp
builder.Services.AddRateLimiting(options =>
{
    options.AddFixedWindowLimiter("auth_limiter", policy =>
    {
        policy.Window = TimeSpan.FromMinutes(1);
        policy.PermitLimit = 5; // 5 intentos por minuto
        policy.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
    });
});

app.UseRateLimiter();
```

## Futuras Mejoras

- [ ] 2FA (Two-Factor Authentication)
- [ ] OAuth2/OIDC support
- [ ] Social login (Google, GitHub)
- [ ] Auditoría de accesos
- [ ] Rate limiting
- [ ] Tests automatizados
- [ ] API versioning mejorado
- [ ] Cache de tokens revocados

## Troubleshooting

### Error: "Connection to database failed"
- Verificar que PostgreSQL esté ejecutándose
- Validar cadena de conexión en appsettings.json
- Verificar credenciales de base de datos

### Error: "Invalid token"
- Verificar que el secreto JWT sea el mismo entre generación y validación
- Verificar expiración del token
- Verificar que el issuer y audience coincidan

## Licencia

Propietario - FinanSecure Team
