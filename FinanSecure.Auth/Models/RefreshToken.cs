namespace FinanSecure.Auth.Models
{
    public class RefreshToken
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Token { get; set; } = null!;
        public DateTime ExpiresAt { get; set; }
        public DateTime? RevokedAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public string? UserAgent { get; set; }
        public string? IpAddress { get; set; }

        // Relación
        public User User { get; set; } = null!;

        public bool IsActive => RevokedAt == null && ExpiresAt > DateTime.UtcNow;
    }
}
