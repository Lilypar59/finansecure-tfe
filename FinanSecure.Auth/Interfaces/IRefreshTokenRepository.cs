using FinanSecure.Auth.Models;

namespace FinanSecure.Auth.Interfaces
{
    public interface IRefreshTokenRepository
    {
        Task<RefreshToken?> GetByTokenAsync(string token);
        Task<RefreshToken> CreateAsync(RefreshToken refreshToken);
        Task<bool> RevokeAsync(string token);
        Task<bool> RevokeAllAsync(Guid userId);
        Task<List<RefreshToken>> GetActiveByUserAsync(Guid userId);
        Task CleanupExpiredAsync();
    }
}
