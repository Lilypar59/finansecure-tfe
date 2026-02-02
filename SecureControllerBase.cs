using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace FinanSecure.Shared.Security;

/// <summary>
/// Base controller con métodos de seguridad para extraer UserId
/// Todos los controllers protegidos deben heredar de aquí
/// </summary>
[ApiController]
[Microsoft.AspNetCore.Authorization.Authorize(AuthenticationSchemes = "Bearer")]
public abstract class SecureControllerBase : ControllerBase
{
    protected readonly ILogger<SecureControllerBase> _logger;

    protected SecureControllerBase(ILogger<SecureControllerBase> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Extraer UserId del JWT (única fuente de verdad)
    /// NUNCA permitas que viene del body o query string
    /// </summary>
    protected Guid GetAuthenticatedUserId()
    {
        try
        {
            var userId = User.GetUserIdOrThrow();
            _logger.LogDebug($"Authenticated user: {userId}");
            return userId;
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning($"Failed to get user ID: {ex.Message}");
            throw;
        }
    }

    /// <summary>
    /// Extraer UserId de forma segura (devuelve null si no existe)
    /// </summary>
    protected Guid? GetAuthenticatedUserIdSafe()
    {
        return User?.GetUserId();
    }

    /// <summary>
    /// Obtener información completa del usuario desde JWT
    /// </summary>
    protected UserInfo GetAuthenticatedUserInfo()
    {
        return new UserInfo
        {
            UserId = User.GetUserIdOrThrow(),
            Username = User.GetUsername() ?? "Unknown",
            Email = User.GetEmail() ?? "Unknown",
            Jti = User.GetJti() ?? "Unknown"
        };
    }

    /// <summary>
    /// Validar que el usuario es propietario del recurso
    /// Usa para evitar que usuarios accedan a recursos de otros
    /// </summary>
    protected IActionResult ValidateResourceOwnership(Guid resourceOwnerId)
    {
        var userId = GetAuthenticatedUserId();

        if (userId != resourceOwnerId)
        {
            _logger.LogWarning($"Access denied: User {userId} tried to access resource of user {resourceOwnerId}");
            return Forbid("You do not have permission to access this resource");
        }

        return Ok();
    }

    /// <summary>
    /// Validar claims obligatorios
    /// </summary>
    protected bool ValidateRequiredClaims()
    {
        var validator = new JwtClaimsValidator(_logger);
        
        if (!validator.ValidateRequiredClaims(User))
        {
            _logger.LogWarning("JWT validation failed: missing required claims");
            return false;
        }

        return true;
    }

    /// <summary>
    /// Log de auditoría para acciones
    /// </summary>
    protected void LogAudit(string action, string resource, object? data = null)
    {
        var userId = User.GetUserId();
        var jti = User.GetJti();
        var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString();

        _logger.LogInformation(
            "AUDIT: Action={Action} User={UserId} Resource={Resource} IP={IpAddress} JTI={Jti}",
            action, userId, resource, ipAddress, jti);
    }
}

/// <summary>
/// DTO con información segura del usuario desde JWT
/// </summary>
public class UserInfo
{
    public Guid UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Jti { get; set; } = string.Empty;
}

/// <summary>
/// Middleware para validar JWT claims en cada request
/// </summary>
public class JwtValidationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<JwtValidationMiddleware> _logger;

    public JwtValidationMiddleware(RequestDelegate next, ILogger<JwtValidationMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Si el usuario está autenticado
        if (context.User?.Identity?.IsAuthenticated == true)
        {
            var validator = new JwtClaimsValidator(_logger);

            // Validar claims obligatorios
            if (!validator.ValidateRequiredClaims(context.User))
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                await context.Response.WriteAsJsonAsync(
                    new { error = "Invalid JWT claims" });
                return;
            }

            // Validar que es un access token (no refresh)
            if (!validator.IsAccessToken(context.User))
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                await context.Response.WriteAsJsonAsync(
                    new { error = "Invalid token type" });
                return;
            }

            // Validar UserId
            if (!validator.ValidateUserId(context.User))
            {
                context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                await context.Response.WriteAsJsonAsync(
                    new { error = "Invalid user identity" });
                return;
            }

            var userId = context.User.GetUserId();
            _logger.LogDebug($"JWT validated for user: {userId}");
        }

        await _next(context);
    }
}

/// <summary>
/// Extension para registrar JWT validation en Program.cs
/// Uso: app.UseJwtValidationMiddleware();
/// </summary>
public static class JwtValidationMiddlewareExtensions
{
    public static IApplicationBuilder UseJwtValidationMiddleware(
        this IApplicationBuilder app)
    {
        return app.UseMiddleware<JwtValidationMiddleware>();
    }
}
