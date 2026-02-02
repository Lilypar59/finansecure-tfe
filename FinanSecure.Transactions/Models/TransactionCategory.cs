namespace FinanSecure.Transactions.Models
{
    public class TransactionCategory
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Name { get; set; } = null!;
        public string? Icon { get; set; }
        public string Type { get; set; } = null!; // "INCOME" o "EXPENSE"
        public string? Color { get; set; }
        public bool IsDefault { get; set; } = false;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        // Relaciones
        public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
    }
}
