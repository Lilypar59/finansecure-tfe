using FinanSecure.Transactions.DTOs;

namespace FinanSecure.Transactions.Interfaces
{
    public interface ICategoryService
    {
        Task<CategoryDto> CreateAsync(Guid userId, CreateCategoryRequest request);
        Task<CategoryDto?> GetByIdAsync(Guid userId, Guid categoryId);
        Task<List<CategoryDto>> GetUserCategoriesAsync(Guid userId, string? type = null);
        Task<CategoryDto> UpdateAsync(Guid userId, Guid categoryId, CreateCategoryRequest request);
        Task<bool> DeleteAsync(Guid userId, Guid categoryId);
    }
}
