using Microsoft.IdentityModel.Tokens;
using System.Text;

namespace FinanSecure.Shared.Configuration;

/// <summary>
/// Configuración centralizada de JWT para toda la arquitectura de microservicios.
/// Usada por: Auth Service (emisión) y Transactions Service (validación)
/// </summary>
public class JwtConfiguration
{
    /// <summary>
    /// Clave secreta para firmar tokens (mínimo 32 caracteres para HS256)
    /// </summary>
    public string SecretKey { get; set; } = string.Empty;

    /// <summary>
    /// Emisor de tokens (solo Auth Service)
    /// </summary>
    public string Issuer { get; set; } = "FinanSecure.Auth";

    /// <summary>
    /// Audiencia esperada (todos los servicios deben validar esto)
    /// </summary>
    public string Audience { get; set; } = "FinanSecure.Transactions";

    /// <summary>
    /// Tiempo de expiración del access token en minutos (15 min recomendado)
    /// </summary>
    public int AccessTokenExpirationMinutes { get; set; } = 15;

    /// <summary>
    /// Tiempo de expiración del refresh token en días (7 días recomendado)
    /// </summary>
    public int RefreshTokenExpirationDays { get; set; } = 7;

    /// <summary>
    /// Máximo de días que un refresh token puede existir sin reauthenticación
    /// </summary>
    public int RefreshTokenMaxDays { get; set; } = 30;

    /// <summary>
    /// Algoritmo de firmado (HS256 actual, migrar a RS256 en futuro)
    /// </summary>
    public string Algorithm { get; set; } = SecurityAlgorithms.HmacSha256Signature;

    /// <summary>
    /// Requerir HTTPS para transmisión de tokens (true en producción)
    /// </summary>
    public bool RequireHttpsMetadata { get; set; } = false;

    /// <summary>
    /// Tolerancia de reloj en segundos para validación de expiración (0 recomendado)
    /// </summary>
    public int ClockSkewSeconds { get; set; } = 0;

    /// <summary>
    /// Validar la firma del token
    /// </summary>
    public bool ValidateIssuerSigningKey { get; set; } = true;

    /// <summary>
    /// Validar el issuer
    /// </summary>
    public bool ValidateIssuer { get; set; } = true;

    /// <summary>
    /// Validar la audiencia
    /// </summary>
    public bool ValidateAudience { get; set; } = true;

    /// <summary>
    /// Validar tiempo de expiración
    /// </summary>
    public bool ValidateLifetime { get; set; } = true;

    /// <summary>
    /// Tipo de token para distinguir access de refresh
    /// </summary>
    public string AccessTokenType { get; set; } = "access";
    public string RefreshTokenType { get; set; } = "refresh";

    /// <summary>
    /// Validar claims personalidos
    /// </summary>
    public bool ValidateCustomClaims { get; set; } = true;

    // ────────────────────────────────────────────────────────────────────────────

    /// <summary>
    /// Obtener la clave de firma como SymmetricSecurityKey
    /// </summary>
    public SymmetricSecurityKey GetSymmetricSecurityKey()
    {
        if (string.IsNullOrEmpty(SecretKey))
            throw new InvalidOperationException("JWT SecretKey is not configured");

        if (SecretKey.Length < 32)
            throw new InvalidOperationException("JWT SecretKey must be at least 32 characters");

        return new SymmetricSecurityKey(Encoding.ASCII.GetBytes(SecretKey));
    }

    /// <summary>
    /// Obtener los parámetros de validación de token
    /// </summary>
    public TokenValidationParameters GetTokenValidationParameters()
    {
        var key = GetSymmetricSecurityKey();

        return new TokenValidationParameters
        {
            ValidateIssuerSigningKey = ValidateIssuerSigningKey,
            IssuerSigningKey = key,
            ValidateIssuer = ValidateIssuer,
            ValidIssuer = Issuer,
            ValidateAudience = ValidateAudience,
            ValidAudience = Audience,
            ValidateLifetime = ValidateLifetime,
            ClockSkew = TimeSpan.FromSeconds(ClockSkewSeconds),
            NameClaimType = System.Security.Claims.ClaimTypes.NameIdentifier  // 'sub' mapea a identity
        };
    }
}

// ════════════════════════════════════════════════════════════════════════════════
// EXTENSIÓN PARA PROGRAM.CS EN AMBOS SERVICIOS
// ════════════════════════════════════════════════════════════════════════════════

/// <summary>
/// Extensiones para configurar JWT en Program.cs
/// </summary>
public static class JwtConfigurationExtensions
{
    /// <summary>
    /// Agregar autenticación JWT al contenedor de servicios
    /// Uso: builder.Services.AddJwtAuthentication(builder.Configuration);
    /// </summary>
    public static IServiceCollection AddJwtAuthentication(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var jwtConfig = new JwtConfiguration();
        configuration.GetSection("Jwt").Bind(jwtConfig);

        // Registrar configuración en DI
        services.AddSingleton(jwtConfig);

        // Agregar autenticación JWT
        services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(options =>
        {
            options.RequireHttpsMetadata = jwtConfig.RequireHttpsMetadata;
            options.SaveToken = true;
            options.TokenValidationParameters = jwtConfig.GetTokenValidationParameters();

            // Event handlers para debugging
            options.Events = new Microsoft.AspNetCore.Authentication.JwtBearer.JwtBearerEvents
            {
                OnTokenValidated = context =>
                {
                    var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<JwtConfiguration>>();
                    var userId = context.Principal?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                    var jti = context.Principal?.FindFirst("jti")?.Value;
                    logger.LogDebug($"JWT validado - UserId: {userId}, JTI: {jti}");
                    return Task.CompletedTask;
                },
                OnAuthenticationFailed = context =>
                {
                    var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<JwtConfiguration>>();
                    logger.LogWarning($"JWT validation failed: {context.Exception?.Message}");
                    return Task.CompletedTask;
                },
                OnForbidden = context =>
                {
                    var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<JwtConfiguration>>();
                    logger.LogWarning($"JWT forbidden: {context.Result?.Failure?.Message}");
                    return Task.CompletedTask;
                }
            };
        });

        return services;
    }

    /// <summary>
    /// Validar que la configuración JWT es válida
    /// </summary>
    public static JwtConfiguration ValidateJwtConfiguration(
        this JwtConfiguration config,
        ILogger logger)
    {
        if (string.IsNullOrEmpty(config.SecretKey))
            throw new InvalidOperationException("JWT:SecretKey is required");

        if (config.SecretKey.Length < 32)
        {
            logger.LogWarning("JWT:SecretKey is less than 32 characters. Recommended: minimum 32 for HS256");
        }

        if (string.IsNullOrEmpty(config.Issuer))
            throw new InvalidOperationException("JWT:Issuer is required");

        if (string.IsNullOrEmpty(config.Audience))
            throw new InvalidOperationException("JWT:Audience is required");

        if (config.AccessTokenExpirationMinutes < 1 || config.AccessTokenExpirationMinutes > 60)
            logger.LogWarning("JWT:AccessTokenExpirationMinutes should be between 1 and 60");

        if (config.RefreshTokenExpirationDays < 1 || config.RefreshTokenExpirationDays > 30)
            logger.LogWarning("JWT:RefreshTokenExpirationDays should be between 1 and 30");

        logger.LogInformation($"JWT Configuration validated - Issuer: {config.Issuer}, Audience: {config.Audience}");

        return config;
    }
}
