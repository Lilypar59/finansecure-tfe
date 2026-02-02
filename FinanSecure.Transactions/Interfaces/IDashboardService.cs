using FinanSecure.Transactions.DTOs;

namespace FinanSecure.Transactions.Interfaces
{
    public interface IDashboardService
    {
        Task<DashboardSummaryDto> GetDashboardSummaryAsync(Guid userId);
        Task<MonthlyReportDto> GetMonthlyReportAsync(Guid userId, int month, int year);
        Task<List<CategoryBreakdownDto>> GetIncomeBreakdownAsync(Guid userId, DateTime startDate, DateTime endDate);
        Task<List<CategoryBreakdownDto>> GetExpenseBreakdownAsync(Guid userId, DateTime startDate, DateTime endDate);
    }
}
