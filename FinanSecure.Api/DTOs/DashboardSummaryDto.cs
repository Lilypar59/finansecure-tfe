namespace FinanSecure.Api.DTOs
{
    public class DashboardSummaryDto
    {
        public string Period { get; set; } = string.Empty;
        public decimal TotalIncome { get; set; }
        public decimal TotalExpenses { get; set; }
        public decimal Balance => TotalIncome - TotalExpenses;

        public List<TransactionSummaryDto> RecentTransactions { get; set; } = new();
    }

    public class TransactionSummaryDto
    {
        public DateTime Date { get; set; }
        public string Type { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public decimal Amount { get; set; }
    }
}
