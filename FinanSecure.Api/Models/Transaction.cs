namespace FinanSecure.Api.Models
{
    public class Transaction
    {
        public int Id { get; set; }
        public string Type { get; set; } = null!; // "INCOME" o "EXPENSE"
        public string Category { get; set; } = null!;
        public string? Description { get; set; }
        public decimal Amount { get; set; }
        public DateTime Date { get; set; }
    }
}
