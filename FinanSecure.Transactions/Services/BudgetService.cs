using FinanSecure.Transactions.DTOs;
using FinanSecure.Transactions.Interfaces;
using FinanSecure.Transactions.Models;

namespace FinanSecure.Transactions.Services
{
    public class BudgetService : IBudgetService
    {
        private readonly IBudgetRepository _budgetRepository;
        private readonly ICategoryRepository _categoryRepository;

        public BudgetService(IBudgetRepository budgetRepository, ICategoryRepository categoryRepository)
        {
            _budgetRepository = budgetRepository;
            _categoryRepository = categoryRepository;
        }

        public async Task<BudgetDto> CreateAsync(Guid userId, CreateBudgetRequest request)
        {
            // Validate category belongs to user
            var category = await _categoryRepository.GetByIdAsync(request.CategoryId);
            if (category == null || category.UserId != userId)
                throw new InvalidOperationException("Category not found or does not belong to user");

            // Check if budget already exists for this category and month
            var existing = await _budgetRepository.GetByUserCategoryAsync(userId, request.CategoryId, request.Month, request.Year);
            if (existing != null)
                throw new InvalidOperationException("Budget already exists for this category and month");

            var budget = new Budget
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                CategoryId = request.CategoryId,
                Limit = request.Limit,
                Month = request.Month,
                Year = request.Year,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _budgetRepository.CreateAsync(budget);
            return MapToDto(budget, category.Name, 0);
        }

        public async Task<BudgetDto?> GetByIdAsync(Guid userId, Guid budgetId)
        {
            var budget = await _budgetRepository.GetByIdAsync(budgetId);
            if (budget == null || budget.UserId != userId)
                return null;

            var category = await _categoryRepository.GetByIdAsync(budget.CategoryId);
            return MapToDto(budget, category?.Name ?? "Unknown", 0);
        }

        public async Task<List<BudgetDto>> GetMonthBudgetsAsync(Guid userId, int month, int year)
        {
            var budgets = await _budgetRepository.GetByUserMonthAsync(userId, month, year);
            var result = new List<BudgetDto>();

            foreach (var budget in budgets)
            {
                var category = await _categoryRepository.GetByIdAsync(budget.CategoryId);
                result.Add(MapToDto(budget, category?.Name ?? "Unknown", 0));
            }

            return result;
        }

        public async Task<BudgetDto> UpdateAsync(Guid userId, Guid budgetId, CreateBudgetRequest request)
        {
            var budget = await _budgetRepository.GetByIdAsync(budgetId);
            if (budget == null || budget.UserId != userId)
                throw new InvalidOperationException("Budget not found or does not belong to user");

            var category = await _categoryRepository.GetByIdAsync(request.CategoryId);
            if (category == null || category.UserId != userId)
                throw new InvalidOperationException("Category not found or does not belong to user");

            budget.CategoryId = request.CategoryId;
            budget.Limit = request.Limit;
            budget.Month = request.Month;
            budget.Year = request.Year;
            budget.UpdatedAt = DateTime.UtcNow;

            await _budgetRepository.UpdateAsync(budget);
            return MapToDto(budget, category.Name, 0);
        }

        public async Task<bool> DeleteAsync(Guid userId, Guid budgetId)
        {
            var budget = await _budgetRepository.GetByIdAsync(budgetId);
            if (budget == null || budget.UserId != userId)
                return false;

            return await _budgetRepository.DeleteAsync(budgetId);
        }

        private BudgetDto MapToDto(Budget budget, string categoryName, decimal spent)
        {
            return new BudgetDto
            {
                Id = budget.Id,
                UserId = budget.UserId,
                CategoryId = budget.CategoryId,
                CategoryName = categoryName,
                Limit = budget.Limit,
                Month = budget.Month,
                Year = budget.Year,
                Spent = spent,
                Remaining = budget.Limit - spent,
                CreatedAt = budget.CreatedAt,
                UpdatedAt = budget.UpdatedAt
            };
        }
    }
}
