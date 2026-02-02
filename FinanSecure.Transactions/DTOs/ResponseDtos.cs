namespace FinanSecure.Transactions.DTOs
{
    public class TransactionDto
    {
        public Guid Id { get; set; }
        public Guid UserId { get; set; }
        public string Type { get; set; } = null!;
        public Guid CategoryId { get; set; }
        public string CategoryName { get; set; } = null!;
        public string Description { get; set; } = null!;
        public decimal Amount { get; set; }
        public DateTime Date { get; set; }
        public string? Notes { get; set; }
        public bool IsRecurring { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class CategoryDto
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = null!;
        public string Type { get; set; } = null!;
        public string? Icon { get; set; }
        public string? Color { get; set; }
        public bool IsDefault { get; set; }
    }

    public class BudgetDto
    {
        public Guid Id { get; set; }
        public Guid CategoryId { get; set; }
        public string CategoryName { get; set; } = null!;
        public decimal Limit { get; set; }
        public decimal Spent { get; set; }
        public decimal Remaining { get; set; }
        public int Month { get; set; }
        public int Year { get; set; }
    }

    public class DashboardSummaryDto
    {
        public string Period { get; set; } = null!;
        public decimal TotalIncome { get; set; }
        public decimal TotalExpenses { get; set; }
        public decimal Balance { get; set; }
        public List<TransactionDto> RecentTransactions { get; set; } = new();
        public List<CategoryBreakdownDto> IncomeByCategory { get; set; } = new();
        public List<CategoryBreakdownDto> ExpenseByCategory { get; set; } = new();
    }

    public class CategoryBreakdownDto
    {
        public string CategoryName { get; set; } = null!;
        public decimal Amount { get; set; }
        public decimal Percentage { get; set; }
    }

    public class MonthlyReportDto
    {
        public int Month { get; set; }
        public int Year { get; set; }
        public decimal TotalIncome { get; set; }
        public decimal TotalExpenses { get; set; }
        public decimal NetIncome { get; set; }
        public List<CategoryBreakdownDto> IncomeBreakdown { get; set; } = new();
        public List<CategoryBreakdownDto> ExpenseBreakdown { get; set; } = new();
    }

    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string Message { get; set; } = null!;
        public T? Data { get; set; }
        public Dictionary<string, string[]>? Errors { get; set; }
    }

    public class ErrorResponse
    {
        public bool Success { get; set; } = false;
        public string Message { get; set; } = null!;
        public Dictionary<string, string[]>? Errors { get; set; }
    }
}
