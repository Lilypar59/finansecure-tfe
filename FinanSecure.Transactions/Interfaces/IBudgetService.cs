using FinanSecure.Transactions.DTOs;

namespace FinanSecure.Transactions.Interfaces
{
    public interface IBudgetService
    {
        Task<BudgetDto> CreateAsync(Guid userId, CreateBudgetRequest request);
        Task<BudgetDto?> GetByIdAsync(Guid userId, Guid budgetId);
        Task<List<BudgetDto>> GetMonthBudgetsAsync(Guid userId, int month, int year);
        Task<BudgetDto> UpdateAsync(Guid userId, Guid budgetId, CreateBudgetRequest request);
        Task<bool> DeleteAsync(Guid userId, Guid budgetId);
    }
}
