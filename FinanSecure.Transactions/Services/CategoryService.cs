using FinanSecure.Transactions.DTOs;
using FinanSecure.Transactions.Interfaces;
using FinanSecure.Transactions.Models;

namespace FinanSecure.Transactions.Services
{
    public class CategoryService : ICategoryService
    {
        private readonly ICategoryRepository _categoryRepository;
        private readonly ITransactionRepository _transactionRepository;

        public CategoryService(ICategoryRepository categoryRepository, ITransactionRepository transactionRepository)
        {
            _categoryRepository = categoryRepository;
            _transactionRepository = transactionRepository;
        }

        public async Task<CategoryDto> CreateAsync(Guid userId, CreateCategoryRequest request)
        {
            // Check if category name already exists for this user
            var existing = await _categoryRepository.GetByNameAsync(userId, request.Name);
            if (existing != null)
                throw new InvalidOperationException($"Category '{request.Name}' already exists for this user");

            var category = new TransactionCategory
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Name = request.Name,
                Type = request.Type,
                Icon = request.Icon,
                Color = request.Color,
                IsDefault = false,
                CreatedAt = DateTime.UtcNow
            };

            await _categoryRepository.CreateAsync(category);
            return MapToDto(category);
        }

        public async Task<CategoryDto?> GetByIdAsync(Guid userId, Guid categoryId)
        {
            var category = await _categoryRepository.GetByIdAsync(categoryId);
            if (category == null || category.UserId != userId)
                return null;

            return MapToDto(category);
        }

        public async Task<List<CategoryDto>> GetUserCategoriesAsync(Guid userId, string? type = null)
        {
            var categories = await _categoryRepository.GetByUserAsync(userId, type);
            return categories.Select(MapToDto).ToList();
        }

        public async Task<CategoryDto> UpdateAsync(Guid userId, Guid categoryId, CreateCategoryRequest request)
        {
            var category = await _categoryRepository.GetByIdAsync(categoryId);
            if (category == null || category.UserId != userId)
                throw new InvalidOperationException("Category not found or does not belong to user");

            // Check if new name already exists (and it's not the same category)
            if (request.Name != category.Name)
            {
                var existing = await _categoryRepository.GetByNameAsync(userId, request.Name);
                if (existing != null)
                    throw new InvalidOperationException($"Category '{request.Name}' already exists for this user");
            }

            category.Name = request.Name;
            category.Type = request.Type;
            category.Icon = request.Icon;
            category.Color = request.Color;

            await _categoryRepository.UpdateAsync(category);
            return MapToDto(category);
        }

        public async Task<bool> DeleteAsync(Guid userId, Guid categoryId)
        {
            var category = await _categoryRepository.GetByIdAsync(categoryId);
            if (category == null || category.UserId != userId)
                return false;

            // Check if category has transactions
            var transactions = await _transactionRepository.GetByCategoryAsync(categoryId);
            if (transactions.Any())
                throw new InvalidOperationException("Cannot delete category that has transactions");

            return await _categoryRepository.DeleteAsync(categoryId);
        }

        private CategoryDto MapToDto(TransactionCategory category)
        {
            return new CategoryDto
            {
                Id = category.Id,
                UserId = category.UserId,
                Name = category.Name,
                Type = category.Type,
                Icon = category.Icon,
                Color = category.Color,
                IsDefault = category.IsDefault,
                CreatedAt = category.CreatedAt
            };
        }
    }
}
