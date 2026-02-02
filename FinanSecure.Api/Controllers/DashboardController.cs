using FinanSecure.Api.Data;
using FinanSecure.Api.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FinanSecure.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DashboardController : ControllerBase
    {
        private readonly FinanSecureContext _context;

        public DashboardController(FinanSecureContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<DashboardSummaryDto>> Get()
        {
            var now = DateTime.UtcNow;
            var monthStart = new DateTime(now.Year, now.Month, 1);

            var income = await _context.Transactions
                .Where(t => t.Type == "INCOME" && t.Date >= monthStart)
                .SumAsync(t => (decimal?)t.Amount) ?? 0m;

            var expenses = await _context.Transactions
                .Where(t => t.Type == "EXPENSE" && t.Date >= monthStart)
                .SumAsync(t => (decimal?)t.Amount) ?? 0m;

            var recent = await _context.Transactions
                .OrderByDescending(t => t.Date)
                .Take(5)
                .Select(t => new TransactionSummaryDto
                {
                    Date = t.Date,
                    Type = t.Type,
                    Category = t.Category,
                    Amount = t.Amount
                })
                .ToListAsync();

            var summary = new DashboardSummaryDto
            {
                Period = $"{monthStart:yyyy-MM-dd} - {now:yyyy-MM-dd}",
                TotalIncome = income,
                TotalExpenses = expenses,
                RecentTransactions = recent
            };

            return Ok(summary);
        }
    }
}
