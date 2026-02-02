using FinanSecure.Transactions.Models;

namespace FinanSecure.Transactions.Interfaces
{
    public interface ITransactionRepository
    {
        Task<Transaction?> GetByIdAsync(Guid id);
        Task<List<Transaction>> GetByUserAsync(Guid userId, DateTime? startDate = null, DateTime? endDate = null);
        Task<List<Transaction>> GetByCategoryAsync(Guid categoryId);
        Task<Transaction> CreateAsync(Transaction transaction);
        Task<Transaction> UpdateAsync(Transaction transaction);
        Task<bool> DeleteAsync(Guid id);
        Task<decimal> GetTotalByTypeAsync(Guid userId, string type, DateTime startDate, DateTime endDate);
    }
}
