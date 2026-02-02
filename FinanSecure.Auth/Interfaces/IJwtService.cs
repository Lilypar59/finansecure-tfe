using System.Security.Claims;

namespace FinanSecure.Auth.Interfaces
{
    public interface IJwtService
    {
        string GenerateAccessToken(Guid userId, string username, string email);
        string GenerateRefreshToken();
        ClaimsPrincipal? ValidateToken(string token);
        DateTime GetTokenExpiration();
    }
}
