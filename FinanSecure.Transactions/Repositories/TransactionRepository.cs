using Microsoft.EntityFrameworkCore;
using FinanSecure.Transactions.Data;
using FinanSecure.Transactions.Interfaces;
using FinanSecure.Transactions.Models;

namespace FinanSecure.Transactions.Repositories
{
    public class TransactionRepository : ITransactionRepository
    {
        private readonly TransactionsContext _context;

        public TransactionRepository(TransactionsContext context)
        {
            _context = context;
        }

        public async Task<Transaction?> GetByIdAsync(Guid id)
        {
            return await _context.Transactions
                .FirstOrDefaultAsync(t => t.Id == id && !t.IsDeleted);
        }

        public async Task<List<Transaction>> GetByUserAsync(Guid userId, DateTime? startDate = null, DateTime? endDate = null)
        {
            var query = _context.Transactions
                .Where(t => t.UserId == userId && !t.IsDeleted);

            if (startDate.HasValue)
                query = query.Where(t => t.Date >= startDate.Value);

            if (endDate.HasValue)
                query = query.Where(t => t.Date <= endDate.Value);

            return await query
                .OrderByDescending(t => t.Date)
                .ToListAsync();
        }

        public async Task<List<Transaction>> GetByCategoryAsync(Guid categoryId)
        {
            return await _context.Transactions
                .Where(t => t.CategoryId == categoryId && !t.IsDeleted)
                .OrderByDescending(t => t.Date)
                .ToListAsync();
        }

        public async Task<Transaction> CreateAsync(Transaction transaction)
        {
            _context.Transactions.Add(transaction);
            await _context.SaveChangesAsync();
            return transaction;
        }

        public async Task<Transaction> UpdateAsync(Transaction transaction)
        {
            _context.Transactions.Update(transaction);
            await _context.SaveChangesAsync();
            return transaction;
        }

        public async Task<bool> DeleteAsync(Guid id)
        {
            var transaction = await GetByIdAsync(id);
            if (transaction == null)
                return false;

            transaction.IsDeleted = true;
            transaction.UpdatedAt = DateTime.UtcNow;
            await UpdateAsync(transaction);
            return true;
        }

        public async Task<decimal> GetTotalByTypeAsync(Guid userId, string type, DateTime startDate, DateTime endDate)
        {
            return await _context.Transactions
                .Where(t => t.UserId == userId 
                    && t.Type == type 
                    && t.Date >= startDate 
                    && t.Date <= endDate 
                    && !t.IsDeleted)
                .SumAsync(t => t.Amount);
        }
    }
}
