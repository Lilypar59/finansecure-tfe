namespace FinanSecure.Transactions.DTOs
{
    public class CreateTransactionRequest
    {
        public string Type { get; set; } = null!; // "INCOME" or "EXPENSE"
        public Guid CategoryId { get; set; }
        public string Description { get; set; } = null!;
        public decimal Amount { get; set; }
        public DateTime Date { get; set; }
        public string? Notes { get; set; }
        public bool IsRecurring { get; set; } = false;
        public string? RecurrencePattern { get; set; }
    }

    public class UpdateTransactionRequest
    {
        public string? Type { get; set; }
        public Guid? CategoryId { get; set; }
        public string? Description { get; set; }
        public decimal? Amount { get; set; }
        public DateTime? Date { get; set; }
        public string? Notes { get; set; }
    }

    public class CreateCategoryRequest
    {
        public string Name { get; set; } = null!;
        public string Type { get; set; } = null!; // "INCOME" or "EXPENSE"
        public string? Icon { get; set; }
        public string? Color { get; set; }
    }

    public class CreateBudgetRequest
    {
        public Guid CategoryId { get; set; }
        public decimal Limit { get; set; }
        public int Month { get; set; }
        public int Year { get; set; }
    }
}
