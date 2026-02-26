using Microsoft.EntityFrameworkCore;
using FinanSecure.Auth.Models;

namespace FinanSecure.Auth.Data
{
    public class AuthContext : DbContext
    {
        public AuthContext(DbContextOptions<AuthContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<RefreshToken> RefreshTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);
            
            // Configuraciones básicas para PostgreSQL
            modelBuilder.Entity<User>().ToTable("users");
            modelBuilder.Entity<RefreshToken>().ToTable("refresh_tokens");
        }
    }
}
