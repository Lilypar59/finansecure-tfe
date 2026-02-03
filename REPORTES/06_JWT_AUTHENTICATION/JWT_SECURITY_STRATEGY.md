# JWT Security Strategy - FinanSecure Microservices

## 🏗️ Arquitectura de Seguridad JWT

```
┌──────────────────────────────────────────────────────────────────┐
│                      Cliente (Frontend Angular)                  │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                    1. POST /login
                             │
┌────────────────────────────▼─────────────────────────────────────┐
│                    FinanSecure.Auth Service                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Valida credenciales (usuario + contraseña)              │  │
│  │ Genera JWT firmado con HMAC-SHA256                      │  │
│  │ Genera Refresh Token                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                    │
│              2. Retorna {accessToken, refreshToken}             │
└────────────────────────────┬─────────────────────────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    3. Guard JWT en header        4. Guarda en localStorage
              │                             │
              │                             │
┌─────────────▼──────────────────────────────────────────────────┐
│              FinanSecure.Transactions Service                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 1. Recibe: Authorization: Bearer <jwt>                │  │
│  │ 2. Valida firma (HMAC-SHA256)                          │  │
│  │ 3. Verifica issuer y audience                          │  │
│  │ 4. Valida expiración                                   │  │
│  │ 5. Extrae UserId del claim 'sub'                       │  │
│  │ 6. Procesa request con aislamiento de datos             │  │
│  └────────────────────────────────────────────────────────┘  │
│                             │                                  │
│              Response (datos solo del usuario)                │
└─────────────────────────────┬──────────────────────────────────┘
                             │
                    5. Retorna datos
                             │
                    ┌────────▼────────┐
                    │ Expira token?   │
                    └────────┬────────┘
                             │
                    ┌────────▼────────────────┐
                    │ SI → POST /refresh-token│
                    │      (con refreshToken) │
                    └──────────────────────────┘
```

---

## 📋 Claims Obligatorios del JWT

### Access Token (JWT estándar)

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",    // USER ID (obligatorio)
  "name": "juan.perez",                              // USERNAME (obligatorio)
  "email": "juan@finansecure.com",                   // EMAIL (obligatorio)
  "iss": "FinanSecure.Auth",                         // ISSUER (obligatorio)
  "aud": "FinanSecure.Transactions",                 // AUDIENCE (obligatorio)
  "iat": 1735689600,                                 // ISSUED AT (obligatorio)
  "exp": 1735690500,                                 // EXPIRATION (obligatorio - 15 min)
  "type": "access",                                  // TOKEN TYPE (validación extra)
  "jti": "unique-token-id-12345"                     // JWT ID (para revocación)
}
```

### Refresh Token (sin firma JWT, solo base64)

```
RandomBytes(32) → Base64 encoded
Almacenado en BD con:
  - UserId
  - Token hash (no plaintext)
  - ExpiresAt (7 días)
  - RevokedAt (nullable, para revocación)
  - CreatedAt
  - LastUsedAt (para auditoría)
  - UserAgent (para detección de robo)
  - IpAddress (para detección de robo)
```

---

## ⏱️ Tiempos de Vida (TTL)

| Token | TTL | Razón |
|-------|-----|-------|
| **Access Token** | 15 minutos | Corto para limitar exposición en caso de robo |
| **Refresh Token** | 7 días | Largo para experiencia de usuario sin reauthenticación |
| **Refresh Token Máximo** | 30 días | Máximo sin autenticación, obliga a login |

### Estrategia de Renovación

```
Usuario logueado
    ↓
Usa access token durante 15 minutos
    ↓
Token expira
    ↓
Frontend detecta 401 Unauthorized
    ↓
POST /refresh-token con refreshToken
    ↓
Auth Service:
  - Valida refresh token
  - Verifica no esté revocado
  - Verifica no haya pasado 7 días
  - Revoca token anterior
  - Emite nuevo access token
  ↓
Frontend actualiza token en localStorage
    ↓
Reintenta request original
```

---

## 🔐 Ejemplo de Payload Completo

### Request al crear token

```bash
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "juan.perez",
  "password": "SecurePassword123!"
}
```

### Response del servidor

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAiLCJuYW1lIjoianVhbi5wZXJleiIsImVtYWlsIjoianVhbkBmaW5hbnNlY3VyZS5jb20iLCJpc3MiOiJGaW5hbnNlY3VyZS5BdXRoIiwiYXVkIjoiRmluYW5zZWN1cmUuVHJhbnNhY3Rpb25zIiwiaWF0IjoxNzM1Njg5NjAwLCJleHAiOjE3MzU2OTA1MDAsInR5cGUiOiJhY2Nlc3MiLCJqdGkiOiJ1bmlxdWUtdG9rZW4taWQtMTIzNDUifQ.signature-here",
    "refreshToken": "dGVtcHNlY3VyZXJhbmRvbWJhc2U2NGVuY29kZWRzdHJpbmc=",
    "expiresIn": 900,
    "tokenType": "Bearer",
    "user": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "username": "juan.perez",
      "email": "juan@finansecure.com"
    }
  }
}
```

### JWT Decodificado

**Header:**
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Payload:**
```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "name": "juan.perez",
  "email": "juan@finansecure.com",
  "iss": "FinanSecure.Auth",
  "aud": "FinanSecure.Transactions",
  "iat": 1735689600,
  "exp": 1735690500,
  "type": "access",
  "jti": "unique-token-id-12345"
}
```

**Signature:**
```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  "your-256-bit-secret-key-minimum-32-characters"
)
```

---

## 🔧 Configuración JWT Bearer en Program.cs (.NET 8)

### FinanSecure.Auth - Emisión de JWT

```csharp
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

var builder = WebApplicationBuilder.CreateBuilder(args);

// 1. Configurar opciones JWT
var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = Encoding.ASCII.GetBytes(
    jwtSettings["SecretKey"] ?? 
    throw new InvalidOperationException("JWT Secret Key not configured"));

// 2. Registrar servicios de autenticación
builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(x =>
{
    x.RequireHttpsMetadata = false; // Solo en desarrollo
    x.SaveToken = true;
    x.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(secretKey),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"] ?? "FinanSecure.Auth",
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"] ?? "FinanSecure.Transactions",
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero, // Sin tolerancia de expiración
        NameClaimType = ClaimTypes.NameIdentifier // 'sub' mapea a identity
    };
});

// 3. Inyectar configuración JWT
builder.Services.Configure<JwtSettings>(builder.Configuration.GetSection("Jwt"));

var app = builder.Build();

// 4. Usar autenticación antes de autorización
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.Run();
```

### FinanSecure.Transactions - Validación de JWT

```csharp
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplicationBuilder.CreateBuilder(args);

var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = Encoding.ASCII.GetBytes(
    jwtSettings["SecretKey"] ?? 
    throw new InvalidOperationException("JWT Secret Key not configured"));

// LA MISMA CONFIGURACIÓN que en Auth Service
builder.Services.AddAuthentication(x =>
{
    x.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    x.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(x =>
{
    x.RequireHttpsMetadata = false;
    x.SaveToken = true;
    x.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(secretKey),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"] ?? "FinanSecure.Auth",
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"] ?? "FinanSecure.Transactions",
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };
});

// Eventos para debugging
builder.Services.AddAuthentication().AddJwtBearer(options =>
{
    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = context =>
        {
            var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
            var userId = context.Principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            logger.LogInformation($"Token validado para usuario: {userId}");
            return Task.CompletedTask;
        },
        OnAuthenticationFailed = context =>
        {
            var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<Program>>();
            logger.LogError($"Autenticación fallida: {context.Exception.Message}");
            return Task.CompletedTask;
        }
    };
});

var app = builder.Build();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.Run();
```

### appsettings.json (Ambos servicios)

```json
{
  "Jwt": {
    "SecretKey": "your-super-secret-key-minimum-32-characters-long-for-security",
    "Issuer": "FinanSecure.Auth",
    "Audience": "FinanSecure.Transactions",
    "ExpirationMinutes": 15,
    "RefreshTokenExpirationDays": 7,
    "RefreshTokenMaxDays": 30
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore.Authentication": "Debug"
    }
  }
}
```

---

## 🛡️ Buenas Prácticas de Seguridad

### 1. Generación de Tokens (Auth Service)

```csharp
public class JwtService : IJwtService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<JwtService> _logger;

    public string GenerateAccessToken(Guid userId, string username, string email)
    {
        // 1. Clave secreta mínimo 256 bits (32 caracteres)
        var secretKey = Encoding.ASCII.GetBytes(
            _configuration["Jwt:SecretKey"] ?? 
            throw new InvalidOperationException("JWT Secret Key not configured"));

        // 2. Usar HS256 (HMAC-SHA256) - Soporta migración a RS256
        var signingCredentials = new SigningCredentials(
            new SymmetricSecurityKey(secretKey),
            SecurityAlgorithms.HmacSha256Signature);

        // 3. Claims obligatorios y autenticación
        var claims = new List<Claim>
        {
            // OBLIGATORIOS
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),  // 'sub'
            new Claim(ClaimTypes.Name, username),
            new Claim(ClaimTypes.Email, email),
            new Claim("type", "access"),
            new Claim("jti", Guid.NewGuid().ToString()),  // Para revocación
            
            // OPCIONALES pero recomendados
            new Claim("iss", _configuration["Jwt:Issuer"]),
            new Claim("aud", _configuration["Jwt:Audience"])
        };

        // 4. Expiración corta (15 minutos)
        var expirationMinutes = int.Parse(_configuration["Jwt:ExpirationMinutes"] ?? "15");
        var expires = DateTime.UtcNow.AddMinutes(expirationMinutes);

        // 5. Crear token con overhead mínimo
        var securityToken = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: expires,
            signingCredentials: signingCredentials);

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.WriteToken(securityToken);

        _logger.LogInformation($"Token generado para usuario: {userId}");
        
        return token;
    }
}
```

### 2. Validación de Tokens (Transactions Service)

```csharp
public class TransactionService : ITransactionService
{
    private readonly ITransactionRepository _repository;
    private readonly ILogger<TransactionService> _logger;

    public async Task<TransactionDto> CreateAsync(Guid userId, CreateTransactionRequest request)
    {
        // 1. UserId viene SOLO del JWT (NUNCA del body de request)
        // 2. Validar que el claim 'sub' existe y es válido
        if (userId == Guid.Empty)
            throw new UnauthorizedAccessException("Invalid user identity");

        // 3. Validar que el request sea del usuario autenticado
        // (no dejar que cree transacciones para otros usuarios)
        
        var transaction = new Transaction
        {
            Id = Guid.NewGuid(),
            UserId = userId,  // ← Siempre del JWT
            Type = request.Type,
            CategoryId = request.CategoryId,
            Description = request.Description,
            Amount = request.Amount,
            Date = request.Date,
            CreatedAt = DateTime.UtcNow
        };

        await _repository.CreateAsync(transaction);
        _logger.LogInformation($"Transacción creada por usuario: {userId}");
        
        return MapToDto(transaction);
    }
}
```

### 3. Extracción Segura de UserId

```csharp
[ApiController]
[Route("api/v1/[controller]")]
[Authorize(AuthenticationSchemes = "Bearer")]
public class TransactionsController : ControllerBase
{
    // ✅ CORRECTO: Extraer del claim 'sub' (nameidentifier)
    private Guid GetAuthenticatedUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
        
        if (userIdClaim == null)
        {
            _logger.LogWarning("Usuario sin claim 'sub' (NameIdentifier)");
            throw new UnauthorizedAccessException("User identity not found in token");
        }

        if (!Guid.TryParse(userIdClaim.Value, out var userId))
        {
            _logger.LogWarning($"UserId inválido en token: {userIdClaim.Value}");
            throw new UnauthorizedAccessException("Invalid user identity format");
        }

        return userId;
    }

    [HttpPost]
    public async Task<IActionResult> CreateTransaction([FromBody] CreateTransactionRequest request)
    {
        var userId = GetAuthenticatedUserId();  // ← Única fuente de verdad
        var transaction = await _transactionService.CreateAsync(userId, request);
        return CreatedAtAction(nameof(GetTransaction), new { id = transaction.Id }, transaction);
    }

    // ❌ INCORRECTO: Nunca extraer de QueryString o Body
    // private Guid GetUserId(string userIdFromBody) → PELIGRO
}
```

### 4. Validación de Expiración

```csharp
// En Program.cs
x.TokenValidationParameters = new TokenValidationParameters
{
    // ... otros settings ...
    
    ValidateLifetime = true,  // ← SIEMPRE true
    ClockSkew = TimeSpan.Zero  // ← Sin tolerancia (validar hora exacta)
};
```

### 5. Gestión de Secreto

```csharp
// ❌ NUNCA en código
const string Secret = "my-secret-key";

// ✅ SIEMPRE desde configuration
var secret = builder.Configuration["Jwt:SecretKey"];

// ✅ CON SECRET MANAGER en desarrollo
// dotnet user-secrets set "Jwt:SecretKey" "your-secret-key"

// ✅ CON VAULT en producción
// Azure Key Vault, AWS Secrets Manager, HashiCorp Vault
var secret = await secretVaultClient.GetSecretAsync("jwt-secret-key");
```

### 6. Renovación de Refresh Token (Rotación)

```csharp
public async Task<AuthResponse> RefreshTokenAsync(string refreshToken)
{
    // 1. Buscar refresh token en BD
    var storedToken = await _refreshTokenRepository.GetAsync(refreshToken);
    
    if (storedToken == null)
        throw new UnauthorizedAccessException("Invalid refresh token");
    
    // 2. Validar que NO esté revocado
    if (storedToken.RevokedAt.HasValue)
        throw new UnauthorizedAccessException("Refresh token has been revoked");
    
    // 3. Validar que NO haya expirado
    if (DateTime.UtcNow > storedToken.ExpiresAt)
        throw new UnauthorizedAccessException("Refresh token expired");
    
    // 4. Validar que no supere máximo de 30 días
    if ((DateTime.UtcNow - storedToken.CreatedAt).TotalDays > 30)
        throw new UnauthorizedAccessException("Refresh token lifetime exceeded");
    
    // 5. Revocar token anterior (rotación)
    storedToken.RevokedAt = DateTime.UtcNow;
    await _refreshTokenRepository.UpdateAsync(storedToken);
    
    // 6. Generar nuevo access token
    var user = await _userRepository.GetByIdAsync(storedToken.UserId);
    var newAccessToken = _jwtService.GenerateAccessToken(user.Id, user.Username, user.Email);
    
    // 7. Generar nuevo refresh token
    var newRefreshToken = GenerateRefreshToken();
    var refreshTokenEntity = new RefreshToken
    {
        Id = Guid.NewGuid(),
        UserId = storedToken.UserId,
        Token = newRefreshToken,
        ExpiresAt = DateTime.UtcNow.AddDays(7),
        CreatedAt = DateTime.UtcNow
    };
    await _refreshTokenRepository.CreateAsync(refreshTokenEntity);
    
    return new AuthResponse
    {
        AccessToken = newAccessToken,
        RefreshToken = newRefreshToken,
        ExpiresIn = 900
    };
}
```

---

## 🔄 Migración a Clave Pública (RS256)

### Paso 1: Generar Certificado (Una sola vez)

```bash
# Generar RSA private key (2048 bits mínimo)
openssl genrsa -out jwt-private-key.pem 2048

# Extraer public key
openssl rsa -in jwt-private-key.pem -pubout -out jwt-public-key.pem

# Guardar en Azure Key Vault o similar
```

### Paso 2: Cambiar en Program.cs (Auth Service)

```csharp
// Antes: HS256
var signingCredentials = new SigningCredentials(
    new SymmetricSecurityKey(secretKey),
    SecurityAlgorithms.HmacSha256Signature);

// Después: RS256
var rsa = RSA.Create();
rsa.ImportFromPem(privateKeyPem);  // Cargar desde Key Vault
var signingCredentials = new SigningCredentials(
    new RsaSecurityKey(rsa),
    SecurityAlgorithms.RsaSha256Signature);
```

### Paso 3: Cambiar en Program.cs (Transactions Service)

```csharp
// Antes: HS256
var secretKey = Encoding.ASCII.GetBytes(jwtSettings["SecretKey"]);
var key = new SymmetricSecurityKey(secretKey);

// Después: RS256 (validar solo con public key)
var rsa = RSA.Create();
rsa.ImportFromPem(publicKeyPem);  // Cargar public key
var key = new RsaSecurityKey(rsa);

x.TokenValidationParameters = new TokenValidationParameters
{
    IssuerSigningKey = key,
    // ... resto igual ...
};
```

**Ventaja**: Auth Service firma con private key, todos los servicios validan con public key (sin compartir secreto)

---

## ⏱️ Rate Limiting y Revocación

### 1. Rate Limiting por Usuario

```csharp
public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IDistributedCache _cache;  // Redis
    private readonly ILogger<RateLimitingMiddleware> _logger;

    public async Task InvokeAsync(HttpContext context)
    {
        var userId = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        if (userId == null)
        {
            await _next(context);
            return;
        }

        var key = $"rate-limit:{userId}:{DateTime.UtcNow:yyyyMMddHHmm}";
        var requestCount = int.Parse(await _cache.GetStringAsync(key) ?? "0");

        // Máximo 100 requests por minuto
        if (requestCount >= 100)
        {
            context.Response.StatusCode = StatusCodes.Status429TooManyRequests;
            await context.Response.WriteAsJsonAsync(new { error = "Too many requests" });
            return;
        }

        await _cache.SetStringAsync(key, (requestCount + 1).ToString(), 
            TimeSpan.FromMinutes(1));

        await _next(context);
    }
}

// En Program.cs
app.UseMiddleware<RateLimitingMiddleware>();
```

### 2. Revocación de Tokens (Token Blacklist)

```csharp
public class TokenRevocationService : ITokenRevocationService
{
    private readonly IDistributedCache _cache;

    // Agregar token a blacklist al logout
    public async Task RevokeTokenAsync(string jti, DateTime expiresAt)
    {
        var key = $"revoked-token:{jti}";
        var timeToLive = expiresAt - DateTime.UtcNow;
        
        if (timeToLive > TimeSpan.Zero)
        {
            await _cache.SetStringAsync(key, "revoked", timeToLive);
        }
    }

    // Verificar si token está revocado
    public async Task<bool> IsTokenRevokedAsync(string jti)
    {
        var key = $"revoked-token:{jti}";
        var value = await _cache.GetStringAsync(key);
        return value != null;
    }
}

// En middleware de validación
public class CheckTokenRevocationMiddleware
{
    public async Task InvokeAsync(HttpContext context, ITokenRevocationService revocationService)
    {
        var jti = context.User?.FindFirst("jti")?.Value;
        
        if (jti != null && await revocationService.IsTokenRevokedAsync(jti))
        {
            context.Response.StatusCode = StatusCodes.Status401Unauthorized;
            await context.Response.WriteAsJsonAsync(new { error = "Token has been revoked" });
            return;
        }

        await _next(context);
    }
}
```

### 3. Auditoría de Tokens

```csharp
public class TokenAuditService
{
    private readonly ILogger<TokenAuditService> _logger;
    private readonly ITokenAuditRepository _auditRepository;

    public async Task LogTokenIssuedAsync(Guid userId, string jti, string ipAddress, string userAgent)
    {
        var audit = new TokenAudit
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Jti = jti,
            Action = "TOKEN_ISSUED",
            IpAddress = ipAddress,
            UserAgent = userAgent,
            Timestamp = DateTime.UtcNow
        };

        await _auditRepository.CreateAsync(audit);
        _logger.LogInformation($"Token emitido para usuario {userId} desde IP {ipAddress}");
    }

    public async Task LogTokenRevokedAsync(Guid userId, string jti)
    {
        var audit = new TokenAudit
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Jti = jti,
            Action = "TOKEN_REVOKED",
            Timestamp = DateTime.UtcNow
        };

        await _auditRepository.CreateAsync(audit);
        _logger.LogInformation($"Token revocado para usuario {userId}");
    }
}
```

---

## 📊 Tabla Comparativa: HS256 vs RS256

| Aspecto | HS256 | RS256 |
|--------|-------|-------|
| **Algoritmo** | HMAC (simétrico) | RSA (asimétrico) |
| **Secreto** | Compartido (riesgoso) | Private key (emisor) |
| **Validación** | Acceso a secreto | Public key (distribuible) |
| **Microservicios** | Riesgoso | Recomendado |
| **Escalabilidad** | Media | Alta |
| **Rendimiento** | Rápido | Más lento |
| **Migración** | A RS256 | Final |

---

## ✅ Checklist de Seguridad JWT

- ✅ Claims obligatorios: `sub`, `iss`, `aud`, `iat`, `exp`, `jti`
- ✅ Access token: 15 minutos
- ✅ Refresh token: 7 días (máximo 30)
- ✅ UserId SOLO del JWT (nunca del body)
- ✅ Validación de firma HMAC-SHA256
- ✅ Validación de issuer y audience
- ✅ Validación de expiración sin tolerancia
- ✅ Refresh token con rotación (revoca anterior)
- ✅ Refresh token revocable en logout
- ✅ Auditoría de emisión y revocación
- ✅ Rate limiting por usuario
- ✅ Secreto mínimo 32 caracteres
- ✅ Secreto en configuration, no en código
- ✅ HTTPS en producción (RequireHttpsMetadata = true)
- ✅ Detección de revocación de token
- ✅ Preparado para migración a RS256

---

## 🚀 Roadmap de Seguridad

**Fase 1 (Actual)**: HS256 con secreto compartido
- Rápido de implementar
- Funcional para arquitectura actual

**Fase 2 (Q2 2026)**: Migrar a RS256
- Public key certificate
- Múltiples servicios sin compartir secreto

**Fase 3 (Q3 2026)**: Token introspection
- OAuth 2.0 token introspection endpoint
- Verificación centralizada en Auth Service

**Fase 4 (Q4 2026)**: Device flow y TOTP
- Two-factor authentication
- Autenticación por dispositivo

---

## 📚 Referencias

- [JWT.io - Oficial](https://jwt.io)
- [RFC 7519 - JWT](https://tools.ietf.org/html/rfc7519)
- [OWASP JWT Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [Microsoft IdentityModel Documentation](https://github.com/AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet)

