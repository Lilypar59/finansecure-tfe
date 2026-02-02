using FinanSecure.Transactions.Models;

namespace FinanSecure.Transactions.Interfaces
{
    public interface ICategoryRepository
    {
        Task<TransactionCategory?> GetByIdAsync(Guid id);
        Task<List<TransactionCategory>> GetByUserAsync(Guid userId, string? type = null);
        Task<TransactionCategory?> GetByNameAsync(Guid userId, string name);
        Task<TransactionCategory> CreateAsync(TransactionCategory category);
        Task<TransactionCategory> UpdateAsync(TransactionCategory category);
        Task<bool> DeleteAsync(Guid id);
    }
}
