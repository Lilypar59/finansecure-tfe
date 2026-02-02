using FinanSecure.Transactions.Models;

namespace FinanSecure.Transactions.Interfaces
{
    public interface IBudgetRepository
    {
        Task<Budget?> GetByIdAsync(Guid id);
        Task<List<Budget>> GetByUserMonthAsync(Guid userId, int month, int year);
        Task<Budget?> GetByUserCategoryAsync(Guid userId, Guid categoryId, int month, int year);
        Task<Budget> CreateAsync(Budget budget);
        Task<Budget> UpdateAsync(Budget budget);
        Task<bool> DeleteAsync(Guid id);
    }
}
