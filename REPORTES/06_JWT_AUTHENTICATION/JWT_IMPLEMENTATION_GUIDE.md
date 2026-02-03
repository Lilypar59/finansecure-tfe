# Implementación Práctica - JWT Security en FinanSecure

Guía paso a paso para implementar la estrategia JWT en ambos servicios.

---

## 📋 Tabla de Contenidos

1. [Configuración en Program.cs](#configuración-en-programcs)
2. [Ejemplo en Auth Service (Emisión)](#ejemplo-auth-service)
3. [Ejemplo en Transactions Service (Validación)](#ejemplo-transactions-service)
4. [Extracción Segura de UserId](#extracción-segura-de-userid)
5. [Testing con Swagger](#testing-con-swagger)
6. [Troubleshooting](#troubleshooting)

---

## 🔧 Configuración en Program.cs

### 1. Copiar archivos de utilidad a carpeta compartida

```
FinanSecure.Shared/
├── Configuration/
│   └── JwtConfiguration.cs
├── Security/
│   ├── JwtClaimsExtensions.cs
│   └── SecureControllerBase.cs
└── FinanSecure.Shared.csproj
```

### 2. Auth Service - Program.cs (Emisión de JWT)

```csharp
using FinanSecure.Shared.Configuration;
using FinanSecure.Shared.Security;
using Serilog;

var builder = WebApplicationBuilder.CreateBuilder(args);

// 1. Configurar Serilog para logging
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.Console()
    .WriteTo.File("logs/auth-service-.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

// 2. Registrar DbContext
builder.Services.AddDbContext<AuthContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// 3. Registrar servicios y repositorios
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IPasswordService, PasswordService>();
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();

// 4. ✅ AGREGAR AUTENTICACIÓN JWT
builder.Services.AddJwtAuthentication(builder.Configuration);

// 5. CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});

// 6. Swagger
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "FinanSecure Auth", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            new string[] { }
        }
    });
});

builder.Services.AddControllers();

var app = builder.Build();

// Migraciones automáticas
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AuthContext>();
    db.Database.Migrate();
    
    // Validar configuración JWT
    var jwtConfig = scope.ServiceProvider.GetRequiredService<JwtConfiguration>();
    jwtConfig.ValidateJwtConfiguration(app.Services.GetRequiredService<ILogger<Program>>());
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseRouting();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.Run();
```

### 3. Transactions Service - Program.cs (Validación de JWT)

```csharp
using FinanSecure.Shared.Configuration;
using FinanSecure.Shared.Security;
using Serilog;

var builder = WebApplicationBuilder.CreateBuilder(args);

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .WriteTo.Console()
    .WriteTo.File("logs/transactions-service-.txt", rollingInterval: RollingInterval.Day)
    .CreateLogger();

builder.Host.UseSerilog();

builder.Services.AddDbContext<TransactionsContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// Registrar servicios y repositorios
builder.Services.AddScoped<ITransactionService, TransactionService>();
builder.Services.AddScoped<ITransactionRepository, TransactionRepository>();

// ✅ AGREGAR AUTENTICACIÓN JWT (mismo que Auth Service)
builder.Services.AddJwtAuthentication(builder.Configuration);

// ✅ AGREGAR MIDDLEWARE DE VALIDACIÓN JWT
builder.Services.AddScoped<JwtClaimsValidator>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});

builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo 
    { 
        Title = "FinanSecure Transactions", 
        Version = "v1" 
    });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            new string[] { }
        }
    });
});

builder.Services.AddControllers();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<TransactionsContext>();
    db.Database.Migrate();
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseRouting();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

// ✅ USAR MIDDLEWARE DE VALIDACIÓN JWT
app.UseJwtValidationMiddleware();

app.MapControllers();
app.Run();
```

### 4. appsettings.json (Ambos servicios - IDÉNTICO)

```json
{
  "Jwt": {
    "SecretKey": "your-super-secret-key-minimum-32-characters-for-hs256-security",
    "Issuer": "FinanSecure.Auth",
    "Audience": "FinanSecure.Transactions",
    "AccessTokenExpirationMinutes": 15,
    "RefreshTokenExpirationDays": 7,
    "RefreshTokenMaxDays": 30,
    "RequireHttpsMetadata": false,
    "ClockSkewSeconds": 0,
    "ValidateIssuerSigningKey": true,
    "ValidateIssuer": true,
    "ValidateAudience": true,
    "ValidateLifetime": true,
    "AccessTokenType": "access",
    "RefreshTokenType": "refresh",
    "ValidateCustomClaims": true
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

## 📝 Ejemplo Auth Service

### JwtService.cs (Emisión)

```csharp
using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;
using Microsoft.IdentityModel.Tokens;
using FinanSecure.Shared.Configuration;

namespace FinanSecure.Auth.Services;

public class JwtService : IJwtService
{
    private readonly JwtConfiguration _jwtConfig;
    private readonly ILogger<JwtService> _logger;

    public JwtService(JwtConfiguration jwtConfig, ILogger<JwtService> logger)
    {
        _jwtConfig = jwtConfig;
        _logger = logger;
    }

    public string GenerateAccessToken(Guid userId, string username, string email)
    {
        // 1. Crear claims obligatorios
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),  // 'sub'
            new Claim(ClaimTypes.Name, username),
            new Claim(ClaimTypes.Email, email),
            new Claim("type", _jwtConfig.AccessTokenType),
            new Claim("jti", Guid.NewGuid().ToString()),  // Para revocación
            new Claim("iss", _jwtConfig.Issuer),
            new Claim("aud", _jwtConfig.Audience)
        };

        // 2. Obtener clave de firma
        var key = _jwtConfig.GetSymmetricSecurityKey();
        var signingCredentials = new SigningCredentials(key, _jwtConfig.Algorithm);

        // 3. Crear token
        var expires = DateTime.UtcNow.AddMinutes(_jwtConfig.AccessTokenExpirationMinutes);
        var token = new JwtSecurityToken(
            issuer: _jwtConfig.Issuer,
            audience: _jwtConfig.Audience,
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: expires,
            signingCredentials: signingCredentials);

        var handler = new JwtSecurityTokenHandler();
        var jwt = handler.WriteToken(token);

        _logger.LogInformation($"Access token generado para usuario {userId}. JTI: {claims.First(c => c.Type == "jti").Value}");

        return jwt;
    }

    public string GenerateRefreshToken()
    {
        var randomNumber = new byte[32];
        using (var rng = System.Security.Cryptography.RandomNumberGenerator.Create())
        {
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }
    }
}
```

### AuthController.cs (Login)

```csharp
using Microsoft.AspNetCore.Mvc;
using FinanSecure.Auth.DTOs;
using FinanSecure.Auth.Interfaces;

namespace FinanSecure.Auth.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            var result = await _authService.LoginAsync(request.Username, request.Password);

            return Ok(new ApiResponse<LoginResponse>
            {
                Success = true,
                Data = result,
                Message = "Login successful"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError($"Login failed: {ex.Message}");
            return Unauthorized(new ApiResponse<object>
            {
                Success = false,
                Message = "Invalid credentials"
            });
        }
    }

    [HttpPost("refresh-token")]
    public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        try
        {
            var result = await _authService.RefreshTokenAsync(request.RefreshToken);

            return Ok(new ApiResponse<LoginResponse>
            {
                Success = true,
                Data = result,
                Message = "Token refreshed"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError($"Token refresh failed: {ex.Message}");
            return Unauthorized(new ApiResponse<object>
            {
                Success = false,
                Message = "Invalid refresh token"
            });
        }
    }
}
```

---

## 📡 Ejemplo Transactions Service

### TransactionsController.cs (Validación y Uso de UserId)

```csharp
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using FinanSecure.Shared.Security;
using FinanSecure.Transactions.DTOs;
using FinanSecure.Transactions.Interfaces;

namespace FinanSecure.Transactions.Controllers;

[ApiController]
[Route("api/v1/[controller]")]
[Authorize(AuthenticationSchemes = "Bearer")]
public class TransactionsController : SecureControllerBase
{
    private readonly ITransactionService _transactionService;

    public TransactionsController(
        ITransactionService transactionService,
        ILogger<TransactionsController> logger)
        : base(logger)
    {
        _transactionService = transactionService;
    }

    [HttpPost]
    [ProducesResponseType(StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> CreateTransaction([FromBody] CreateTransactionRequest request)
    {
        try
        {
            // ✅ CORRECTO: UserId SOLO del JWT
            var userId = GetAuthenticatedUserId();
            var userInfo = GetAuthenticatedUserInfo();

            // Auditoría
            LogAudit("CREATE_TRANSACTION", "transactions", new { amount = request.Amount, type = request.Type });

            var transaction = await _transactionService.CreateAsync(userId, request);

            return CreatedAtAction(
                nameof(GetTransaction),
                new { id = transaction.Id },
                new ApiResponse<TransactionDto>
                {
                    Success = true,
                    Data = transaction,
                    Message = $"Transacción creada para usuario {userInfo.Username}"
                });
        }
        catch (Exception ex)
        {
            _logger.LogError($"Error creando transacción: {ex.Message}");
            return StatusCode(500, new ApiResponse<object>
            {
                Success = false,
                Message = "Error interno del servidor"
            });
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetTransaction(Guid id)
    {
        try
        {
            var userId = GetAuthenticatedUserId();

            // Auditoría
            LogAudit("GET_TRANSACTION", "transactions", new { transaction_id = id });

            var transaction = await _transactionService.GetByIdAsync(userId, id);

            if (transaction == null)
                return NotFound(new ApiResponse<object>
                {
                    Success = false,
                    Message = "Transacción no encontrada"
                });

            // ✅ SEGURIDAD: Validar que el usuario es propietario
            var validationResult = ValidateResourceOwnership(transaction.UserId);
            if (validationResult is not OkResult)
                return validationResult;

            return Ok(new ApiResponse<TransactionDto>
            {
                Success = true,
                Data = transaction
            });
        }
        catch (Exception ex)
        {
            _logger.LogError($"Error obteniendo transacción: {ex.Message}");
            return StatusCode(500, new ApiResponse<object>
            {
                Success = false,
                Message = "Error interno del servidor"
            });
        }
    }

    [HttpGet]
    public async Task<IActionResult> ListTransactions()
    {
        try
        {
            var userId = GetAuthenticatedUserId();

            LogAudit("LIST_TRANSACTIONS", "transactions", null);

            var transactions = await _transactionService.GetUserTransactionsAsync(userId, null, null);

            return Ok(new ApiResponse<List<TransactionDto>>
            {
                Success = true,
                Data = transactions,
                Message = $"Se encontraron {transactions.Count} transacciones"
            });
        }
        catch (Exception ex)
        {
            _logger.LogError($"Error listando transacciones: {ex.Message}");
            return StatusCode(500, new ApiResponse<object>
            {
                Success = false,
                Message = "Error interno del servidor"
            });
        }
    }
}
```

---

## 🔑 Extracción Segura de UserId

### ❌ INCORRECTO (PELIGRO DE SEGURIDAD)

```csharp
// ❌ MAL: Permitir que venga en el body
[HttpPost]
public async Task<IActionResult> CreateTransaction(CreateTransactionRequest request)
{
    var userId = request.UserId;  // ← NUNCA: Usuario puede falsificar
    // ...
}

// ❌ MAL: Permitir que venga en query string
[HttpGet]
public async Task<IActionResult> GetTransactions([FromQuery] Guid userId)
{
    // Usuario puede cambiar el ID
    var transactions = await _service.GetAsync(userId);
}

// ❌ MAL: Confiar en header personalizado
var userId = HttpContext.Request.Headers["X-User-Id"];  // Fácil de falsificar
```

### ✅ CORRECTO (SEGURO)

```csharp
// ✅ BIEN: Solo del JWT (no se puede falsificar sin clave privada)
[HttpPost]
[Authorize(AuthenticationSchemes = "Bearer")]
public async Task<IActionResult> CreateTransaction([FromBody] CreateTransactionRequest request)
{
    // El UserId viene SOLO del JWT validado
    var userId = User.GetUserIdOrThrow();  // Del claim 'sub'
    
    // El request NO contiene UserId
    var transaction = await _service.CreateAsync(userId, request);
}

// ✅ BIEN: Usar SecureControllerBase
public class TransactionsController : SecureControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetTransactions()
    {
        // Extraer de JWT de forma segura
        var userId = GetAuthenticatedUserId();
        var transactions = await _service.GetAsync(userId);
    }
}
```

---

## 🧪 Testing con Swagger

### Paso 1: Obtener Token

```bash
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "juan.perez",
    "password": "SecurePassword123!"
  }'
```

**Respuesta:**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "dGVtcHNlY3VyZXJhbmRvbWJhc2U2NGVuY29kZWRzdHJpbmc=",
    "expiresIn": 900
  }
}
```

### Paso 2: Usar Token en Swagger

1. Abre Swagger UI: `http://localhost:5001/swagger`
2. Click en "Authorize" 🔒
3. Pega el token (sin "Bearer "): `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
4. Click en "Authorize"
5. Ahora todos los endpoints estarán autorizados

### Paso 3: Hacer Request a Transactions Service

```bash
curl -X POST http://localhost:5001/api/v1/transactions \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{
    "type": "EXPENSE",
    "categoryId": "550e8400-e29b-41d4-a716-446655440001",
    "description": "Compra de groceries",
    "amount": 75.50,
    "date": "2025-12-30T10:30:00Z"
  }'
```

**Respuesta (UserId extraído del JWT):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "userId": "550e8400-e29b-41d4-a716-446655440000",  // ← Del JWT
    "type": "EXPENSE",
    "categoryId": "550e8400-e29b-41d4-a716-446655440001",
    "amount": 75.50,
    "createdAt": "2025-12-30T10:30:00Z"
  },
  "message": "Transacción creada para usuario juan.perez"
}
```

---

## 🐛 Troubleshooting

### Error: "Unauthorized" (401)

```
Probable causa: Token inválido o expirado

Soluciones:
1. Verificar que el token no ha expirado (15 min)
2. Verificar que Jwt:SecretKey es idéntico en ambos servicios
3. Verificar que Jwt:Issuer es "FinanSecure.Auth"
4. Verificar que Jwt:Audience es "FinanSecure.Transactions"
```

### Error: "Invalid token type"

```
Probable causa: Se está usando un refresh token como access token

Soluciones:
1. Usar el accessToken, no el refreshToken
2. Verificar que el claim "type" es "access"
3. Renovar el token si ha expirado
```

### Error: "User ID not found in claims"

```
Probable causa: JWT no contiene el claim 'sub' (NameIdentifier)

Soluciones:
1. Verificar que Auth Service está emitiendo el claim
2. Verificar que la configuración JWT en ambos servicios es idéntica
3. Decodificar el JWT en jwt.io para ver los claims
```

### Error: "Invalid JWT claims"

```
Probable causa: Faltan claims obligatorios

Claims obligatorios:
- sub (NameIdentifier) - UserId
- name - Username
- email - Email
- type - Token type
- jti - JWT ID
```

---

## 📊 Checklist de Implementación

- ✅ Copiar archivos de utilidad a carpeta compartida
- ✅ Actualizar Program.cs en ambos servicios
- ✅ Configurar appsettings.json idéntico
- ✅ Auth Service emite JWT con claims obligatorios
- ✅ Transactions Service valida JWT
- ✅ Controllers heredan de SecureControllerBase
- ✅ UserId extraído de JWT, no de body/query
- ✅ Auditoría de acciones
- ✅ Testing con Swagger
- ✅ Documentación completada

---

**Próximo paso**: Implementar rate limiting y revocación de tokens

