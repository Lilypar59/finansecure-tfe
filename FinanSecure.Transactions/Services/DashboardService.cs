using FinanSecure.Transactions.DTOs;
using FinanSecure.Transactions.Interfaces;

namespace FinanSecure.Transactions.Services
{
    public class DashboardService : IDashboardService
    {
        private readonly ITransactionRepository _transactionRepository;
        private readonly ICategoryRepository _categoryRepository;

        public DashboardService(ITransactionRepository transactionRepository, ICategoryRepository categoryRepository)
        {
            _transactionRepository = transactionRepository;
            _categoryRepository = categoryRepository;
        }

        public async Task<DashboardSummaryDto> GetDashboardSummaryAsync(Guid userId)
        {
            var today = DateTime.UtcNow;
            var monthStart = new DateTime(today.Year, today.Month, 1);
            var monthEnd = monthStart.AddMonths(1).AddDays(-1);

            // Get current month transactions
            var currentMonthTransactions = await _transactionRepository.GetByUserAsync(userId, monthStart, monthEnd);
            
            // Get all transactions for the year
            var yearStart = new DateTime(today.Year, 1, 1);
            var yearTransactions = await _transactionRepository.GetByUserAsync(userId, yearStart, today);

            var totalIncome = currentMonthTransactions
                .Where(t => t.Type == "INCOME")
                .Sum(t => t.Amount);

            var totalExpenses = currentMonthTransactions
                .Where(t => t.Type == "EXPENSE")
                .Sum(t => t.Amount);

            var categories = await _categoryRepository.GetByUserAsync(userId);
            var categoryDict = categories.ToDictionary(c => c.Id);

            // Calculate income breakdown
            var incomeByCategory = currentMonthTransactions
                .Where(t => t.Type == "INCOME")
                .GroupBy(t => t.CategoryId)
                .Select(g => new CategoryBreakdownDto
                {
                    CategoryId = g.Key,
                    CategoryName = categoryDict.TryGetValue(g.Key, out var cat) ? cat.Name : "Unknown",
                    Amount = g.Sum(t => t.Amount),
                    Percentage = totalIncome > 0 ? (g.Sum(t => t.Amount) / totalIncome) * 100 : 0
                })
                .OrderByDescending(x => x.Amount)
                .ToList();

            // Calculate expense breakdown
            var expenseByCategory = currentMonthTransactions
                .Where(t => t.Type == "EXPENSE")
                .GroupBy(t => t.CategoryId)
                .Select(g => new CategoryBreakdownDto
                {
                    CategoryId = g.Key,
                    CategoryName = categoryDict.TryGetValue(g.Key, out var cat) ? cat.Name : "Unknown",
                    Amount = g.Sum(t => t.Amount),
                    Percentage = totalExpenses > 0 ? (g.Sum(t => t.Amount) / totalExpenses) * 100 : 0
                })
                .OrderByDescending(x => x.Amount)
                .ToList();

            // Get recent transactions
            var recentTransactions = currentMonthTransactions
                .OrderByDescending(t => t.Date)
                .Take(10)
                .Select(t =>
                {
                    var catName = categoryDict.TryGetValue(t.CategoryId, out var c) ? c.Name : "Unknown";
                    return new TransactionDto
                    {
                        Id = t.Id,
                        UserId = t.UserId,
                        Type = t.Type,
                        CategoryId = t.CategoryId,
                        CategoryName = catName,
                        Description = t.Description,
                        Amount = t.Amount,
                        Date = t.Date,
                        Notes = t.Notes,
                        IsRecurring = t.IsRecurring,
                        RecurrencePattern = t.RecurrencePattern,
                        CreatedAt = t.CreatedAt,
                        UpdatedAt = t.UpdatedAt
                    };
                })
                .ToList();

            return new DashboardSummaryDto
            {
                Period = $"{monthStart:yyyy-MM-01} to {monthEnd:yyyy-MM-dd}",
                TotalIncome = totalIncome,
                TotalExpenses = totalExpenses,
                Balance = totalIncome - totalExpenses,
                RecentTransactions = recentTransactions,
                IncomeByCategory = incomeByCategory,
                ExpenseByCategory = expenseByCategory
            };
        }

        public async Task<MonthlyReportDto> GetMonthlyReportAsync(Guid userId, int month, int year)
        {
            var monthStart = new DateTime(year, month, 1);
            var monthEnd = monthStart.AddMonths(1).AddDays(-1);

            var transactions = await _transactionRepository.GetByUserAsync(userId, monthStart, monthEnd);
            var categories = await _categoryRepository.GetByUserAsync(userId);
            var categoryDict = categories.ToDictionary(c => c.Id);

            var totalIncome = transactions
                .Where(t => t.Type == "INCOME")
                .Sum(t => t.Amount);

            var totalExpenses = transactions
                .Where(t => t.Type == "EXPENSE")
                .Sum(t => t.Amount);

            var incomeBreakdown = transactions
                .Where(t => t.Type == "INCOME")
                .GroupBy(t => t.CategoryId)
                .Select(g => new CategoryBreakdownDto
                {
                    CategoryId = g.Key,
                    CategoryName = categoryDict.TryGetValue(g.Key, out var cat) ? cat.Name : "Unknown",
                    Amount = g.Sum(t => t.Amount),
                    Percentage = totalIncome > 0 ? (g.Sum(t => t.Amount) / totalIncome) * 100 : 0
                })
                .OrderByDescending(x => x.Amount)
                .ToList();

            var expenseBreakdown = transactions
                .Where(t => t.Type == "EXPENSE")
                .GroupBy(t => t.CategoryId)
                .Select(g => new CategoryBreakdownDto
                {
                    CategoryId = g.Key,
                    CategoryName = categoryDict.TryGetValue(g.Key, out var cat) ? cat.Name : "Unknown",
                    Amount = g.Sum(t => t.Amount),
                    Percentage = totalExpenses > 0 ? (g.Sum(t => t.Amount) / totalExpenses) * 100 : 0
                })
                .OrderByDescending(x => x.Amount)
                .ToList();

            return new MonthlyReportDto
            {
                Month = month,
                Year = year,
                TotalIncome = totalIncome,
                TotalExpenses = totalExpenses,
                NetIncome = totalIncome - totalExpenses,
                IncomeBreakdown = incomeBreakdown,
                ExpenseBreakdown = expenseBreakdown
            };
        }

        public async Task<List<CategoryBreakdownDto>> GetIncomeBreakdownAsync(Guid userId, DateTime startDate, DateTime endDate)
        {
            var transactions = await _transactionRepository.GetByUserAsync(userId, startDate, endDate);
            var categories = await _categoryRepository.GetByUserAsync(userId);
            var categoryDict = categories.ToDictionary(c => c.Id);

            var totalIncome = transactions
                .Where(t => t.Type == "INCOME")
                .Sum(t => t.Amount);

            return transactions
                .Where(t => t.Type == "INCOME")
                .GroupBy(t => t.CategoryId)
                .Select(g => new CategoryBreakdownDto
                {
                    CategoryId = g.Key,
                    CategoryName = categoryDict.TryGetValue(g.Key, out var cat) ? cat.Name : "Unknown",
                    Amount = g.Sum(t => t.Amount),
                    Percentage = totalIncome > 0 ? (g.Sum(t => t.Amount) / totalIncome) * 100 : 0
                })
                .OrderByDescending(x => x.Amount)
                .ToList();
        }

        public async Task<List<CategoryBreakdownDto>> GetExpenseBreakdownAsync(Guid userId, DateTime startDate, DateTime endDate)
        {
            var transactions = await _transactionRepository.GetByUserAsync(userId, startDate, endDate);
            var categories = await _categoryRepository.GetByUserAsync(userId);
            var categoryDict = categories.ToDictionary(c => c.Id);

            var totalExpenses = transactions
                .Where(t => t.Type == "EXPENSE")
                .Sum(t => t.Amount);

            return transactions
                .Where(t => t.Type == "EXPENSE")
                .GroupBy(t => t.CategoryId)
                .Select(g => new CategoryBreakdownDto
                {
                    CategoryId = g.Key,
                    CategoryName = categoryDict.TryGetValue(g.Key, out var cat) ? cat.Name : "Unknown",
                    Amount = g.Sum(t => t.Amount),
                    Percentage = totalExpenses > 0 ? (g.Sum(t => t.Amount) / totalExpenses) * 100 : 0
                })
                .OrderByDescending(x => x.Amount)
                .ToList();
        }
    }
}
