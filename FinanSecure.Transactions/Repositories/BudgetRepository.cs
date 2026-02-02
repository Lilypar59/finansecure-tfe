using Microsoft.EntityFrameworkCore;
using FinanSecure.Transactions.Data;
using FinanSecure.Transactions.Interfaces;
using FinanSecure.Transactions.Models;

namespace FinanSecure.Transactions.Repositories
{
    public class BudgetRepository : IBudgetRepository
    {
        private readonly TransactionsContext _context;

        public BudgetRepository(TransactionsContext context)
        {
            _context = context;
        }

        public async Task<Budget?> GetByIdAsync(Guid id)
        {
            return await _context.Budgets
                .FirstOrDefaultAsync(b => b.Id == id);
        }

        public async Task<List<Budget>> GetByUserMonthAsync(Guid userId, int month, int year)
        {
            return await _context.Budgets
                .Where(b => b.UserId == userId && b.Month == month && b.Year == year)
                .OrderByDescending(b => b.CreatedAt)
                .ToListAsync();
        }

        public async Task<Budget?> GetByUserCategoryAsync(Guid userId, Guid categoryId, int month, int year)
        {
            return await _context.Budgets
                .FirstOrDefaultAsync(b => b.UserId == userId 
                    && b.CategoryId == categoryId 
                    && b.Month == month 
                    && b.Year == year);
        }

        public async Task<Budget> CreateAsync(Budget budget)
        {
            _context.Budgets.Add(budget);
            await _context.SaveChangesAsync();
            return budget;
        }

        public async Task<Budget> UpdateAsync(Budget budget)
        {
            _context.Budgets.Update(budget);
            await _context.SaveChangesAsync();
            return budget;
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var budget = await GetByIdAsync(id);
            if (budget == null)
                return false;

            _context.Budgets.Remove(budget);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
