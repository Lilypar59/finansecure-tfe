using System.Security.Claims;
using System.IdentityModel.Tokens.Jwt;

namespace FinanSecure.Shared.Security;

/// <summary>
/// Utilidades para extraer y validar claims del JWT
/// Garantiza aislamiento de datos por usuario
/// </summary>
public static class JwtClaimsExtensions
{
    /// <summary>
    /// Extraer UserId del principal (única fuente de verdad para aislamiento de datos)
    /// </summary>
    public static Guid? GetUserId(this ClaimsPrincipal user)
    {
        var claim = user?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        if (string.IsNullOrEmpty(claim))
            return null;

        return Guid.TryParse(claim, out var userId) ? userId : null;
    }

    /// <summary>
    /// Extraer UserId con validación (lanza excepción si no existe)
    /// </summary>
    public static Guid GetUserIdOrThrow(this ClaimsPrincipal user)
    {
        var userId = user.GetUserId();
        
        if (userId == null || userId == Guid.Empty)
            throw new UnauthorizedAccessException("User ID not found in JWT claims");

        return userId.Value;
    }

    /// <summary>
    /// Extraer nombre de usuario
    /// </summary>
    public static string? GetUsername(this ClaimsPrincipal user)
    {
        return user?.FindFirst(ClaimTypes.Name)?.Value;
    }

    /// <summary>
    /// Extraer email
    /// </summary>
    public static string? GetEmail(this ClaimsPrincipal user)
    {
        return user?.FindFirst(ClaimTypes.Email)?.Value;
    }

    /// <summary>
    /// Extraer JWT ID (para revocación y auditoría)
    /// </summary>
    public static string? GetJti(this ClaimsPrincipal user)
    {
        return user?.FindFirst("jti")?.Value;
    }

    /// <summary>
    /// Extraer tipo de token (access o refresh)
    /// </summary>
    public static string? GetTokenType(this ClaimsPrincipal user)
    {
        return user?.FindFirst("type")?.Value;
    }

    /// <summary>
    /// Validar que el token es de tipo "access"
    /// </summary>
    public static bool IsAccessToken(this ClaimsPrincipal user)
    {
        return user?.GetTokenType() == "access";
    }

    /// <summary>
    /// Validar que el usuario tiene un claim específico
    /// </summary>
    public static bool HasClaim(this ClaimsPrincipal user, string claimType)
    {
        return user?.FindFirst(claimType) != null;
    }

    /// <summary>
    /// Obtener todos los claims del usuario (para auditoría)
    /// </summary>
    public static Dictionary<string, string> GetAllClaims(this ClaimsPrincipal user)
    {
        return user?.Claims
            .ToDictionary(c => c.Type, c => c.Value) 
            ?? new Dictionary<string, string>();
    }
}

/// <summary>
/// Validación segura de JWT claims
/// </summary>
public class JwtClaimsValidator
{
    private readonly ILogger<JwtClaimsValidator> _logger;

    public JwtClaimsValidator(ILogger<JwtClaimsValidator> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Validar que el JWT contiene todos los claims obligatorios
    /// </summary>
    public bool ValidateRequiredClaims(ClaimsPrincipal user)
    {
        var requiredClaims = new[]
        {
            ClaimTypes.NameIdentifier,  // sub
            ClaimTypes.Name,             // name
            ClaimTypes.Email,            // email
            "type",                      // access|refresh
            "jti"                        // JWT ID
        };

        foreach (var claim in requiredClaims)
        {
            if (user?.FindFirst(claim) == null)
            {
                _logger.LogWarning($"Missing required claim: {claim}");
                return false;
            }
        }

        return true;
    }

    /// <summary>
    /// Validar que el UserId es válido
    /// </summary>
    public bool ValidateUserId(ClaimsPrincipal user)
    {
        var userId = user.GetUserId();
        
        if (userId == null || userId == Guid.Empty)
        {
            _logger.LogWarning("Invalid or empty UserId in JWT");
            return false;
        }

        return true;
    }

    /// <summary>
    /// Validar que es un token de acceso (no refresh)
    /// </summary>
    public bool IsAccessToken(ClaimsPrincipal user)
    {
        var tokenType = user?.FindFirst("type")?.Value;
        
        if (tokenType != "access")
        {
            _logger.LogWarning($"Expected 'access' token type, got: {tokenType}");
            return false;
        }

        return true;
    }

    /// <summary>
    /// Validación completa
    /// </summary>
    public bool ValidateComplete(ClaimsPrincipal user)
    {
        return ValidateRequiredClaims(user) &&
               ValidateUserId(user) &&
               IsAccessToken(user);
    }
}

/// <summary>
/// Análisis de JWT (sin verificación de firma)
/// Solo para debugging y auditoría
/// </summary>
public static class JwtAnalyzer
{
    /// <summary>
    /// Decodificar JWT sin verificar firma (SOLO PARA DEBUGGING)
    /// </summary>
    public static JwtSecurityToken? DecodeJwtWithoutVerification(string token)
    {
        try
        {
            var handler = new JwtSecurityTokenHandler();
            var jwtToken = handler.ReadJwtToken(token);
            return jwtToken;
        }
        catch (Exception ex)
        {
            return null;
        }
    }

    /// <summary>
    /// Obtener información del JWT para logging
    /// </summary>
    public static Dictionary<string, object> GetJwtInfo(string token)
    {
        var jwtToken = DecodeJwtWithoutVerification(token);

        if (jwtToken == null)
            return new Dictionary<string, object> { { "error", "Invalid JWT" } };

        return new Dictionary<string, object>
        {
            { "header", jwtToken.Header },
            { "payload", jwtToken.Payload },
            { "expiration", jwtToken.ValidTo },
            { "issued_at", jwtToken.IssuedAt },
            { "claims_count", jwtToken.Claims.Count() }
        };
    }
}
