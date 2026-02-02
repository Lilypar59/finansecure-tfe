using Microsoft.EntityFrameworkCore;
using FinanSecure.Transactions.Data;
using FinanSecure.Transactions.Interfaces;
using FinanSecure.Transactions.Models;

namespace FinanSecure.Transactions.Repositories
{
    public class CategoryRepository : ICategoryRepository
    {
        private readonly TransactionsContext _context;

        public CategoryRepository(TransactionsContext context)
        {
            _context = context;
        }

        public async Task<TransactionCategory?> GetByIdAsync(Guid id)
        {
            return await _context.Categories
                .FirstOrDefaultAsync(c => c.Id == id);
        }

        public async Task<List<TransactionCategory>> GetByUserAsync(Guid userId, string? type = null)
        {
            var query = _context.Categories
                .Where(c => c.UserId == userId);

            if (!string.IsNullOrEmpty(type))
                query = query.Where(c => c.Type == type);

            return await query
                .OrderBy(c => c.IsDefault ? 0 : 1)
                .ThenBy(c => c.Name)
                .ToListAsync();
        }

        public async Task<TransactionCategory?> GetByNameAsync(Guid userId, string name)
        {
            return await _context.Categories
                .FirstOrDefaultAsync(c => c.UserId == userId && c.Name == name);
        }

        public async Task<TransactionCategory> CreateAsync(TransactionCategory category)
        {
            _context.Categories.Add(category);
            await _context.SaveChangesAsync();
            return category;
        }

        public async Task<TransactionCategory> UpdateAsync(TransactionCategory category)
        {
            _context.Categories.Update(category);
            await _context.SaveChangesAsync();
            return category;
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var category = await GetByIdAsync(id);
            if (category == null)
                return false;

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();
            return true;
        }
    }
}
