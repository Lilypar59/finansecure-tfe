namespace FinanSecure.Transactions.Models
{
    public class Transaction
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; } // Referencia al usuario desde Auth Service
        public string Type { get; set; } = null!; // "INCOME" o "EXPENSE"
        public Guid CategoryId { get; set; }
        public string Description { get; set; } = null!;
        public decimal Amount { get; set; }
        public DateTime Date { get; set; }
        public string? Notes { get; set; }
        public bool IsRecurring { get; set; } = false;
        public string? RecurrencePattern { get; set; } // "DAILY", "WEEKLY", "MONTHLY"
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public bool IsDeleted { get; set; } = false;

        // Relaciones
        public TransactionCategory Category { get; set; } = null!;
    }
}
