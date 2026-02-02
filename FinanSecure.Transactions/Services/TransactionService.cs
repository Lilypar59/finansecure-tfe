using FinanSecure.Transactions.DTOs;
using FinanSecure.Transactions.Interfaces;
using FinanSecure.Transactions.Models;

namespace FinanSecure.Transactions.Services
{
    public class TransactionService : ITransactionService
    {
        private readonly ITransactionRepository _transactionRepository;
        private readonly ICategoryRepository _categoryRepository;

        public TransactionService(ITransactionRepository transactionRepository, ICategoryRepository categoryRepository)
        {
            _transactionRepository = transactionRepository;
            _categoryRepository = categoryRepository;
        }

        public async Task<TransactionDto> CreateAsync(Guid userId, CreateTransactionRequest request)
        {
            // Validate category belongs to user
            var category = await _categoryRepository.GetByIdAsync(request.CategoryId);
            if (category == null || category.UserId != userId)
                throw new InvalidOperationException("Category not found or does not belong to user");

            var transaction = new Transaction
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Type = request.Type,
                CategoryId = request.CategoryId,
                Description = request.Description,
                Amount = request.Amount,
                Date = request.Date,
                Notes = request.Notes,
                IsRecurring = request.IsRecurring,
                RecurrencePattern = request.RecurrencePattern,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _transactionRepository.CreateAsync(transaction);
            return MapToDto(transaction, category.Name);
        }

        public async Task<TransactionDto?> GetByIdAsync(Guid userId, Guid transactionId)
        {
            var transaction = await _transactionRepository.GetByIdAsync(transactionId);
            if (transaction == null || transaction.UserId != userId)
                return null;

            var category = await _categoryRepository.GetByIdAsync(transaction.CategoryId);
            return MapToDto(transaction, category?.Name ?? "Unknown");
        }

        public async Task<List<TransactionDto>> GetUserTransactionsAsync(Guid userId, DateTime? startDate, DateTime? endDate)
        {
            var transactions = await _transactionRepository.GetByUserAsync(userId, startDate, endDate);
            var categories = await _categoryRepository.GetByUserAsync(userId);
            var categoryDict = categories.ToDictionary(c => c.Id, c => c.Name);

            return transactions
                .Select(t => MapToDto(t, categoryDict.TryGetValue(t.CategoryId, out var name) ? name : "Unknown"))
                .ToList();
        }

        public async Task<TransactionDto> UpdateAsync(Guid userId, Guid transactionId, UpdateTransactionRequest request)
        {
            var transaction = await _transactionRepository.GetByIdAsync(transactionId);
            if (transaction == null || transaction.UserId != userId)
                throw new InvalidOperationException("Transaction not found or does not belong to user");

            if (!string.IsNullOrEmpty(request.Type))
                transaction.Type = request.Type;

            if (request.CategoryId.HasValue)
            {
                var category = await _categoryRepository.GetByIdAsync(request.CategoryId.Value);
                if (category == null || category.UserId != userId)
                    throw new InvalidOperationException("Category not found or does not belong to user");
                transaction.CategoryId = request.CategoryId.Value;
            }

            if (!string.IsNullOrEmpty(request.Description))
                transaction.Description = request.Description;

            if (request.Amount.HasValue)
                transaction.Amount = request.Amount.Value;

            if (request.Date.HasValue)
                transaction.Date = request.Date.Value;

            if (request.Notes != null)
                transaction.Notes = request.Notes;

            if (request.IsRecurring.HasValue)
                transaction.IsRecurring = request.IsRecurring.Value;

            if (!string.IsNullOrEmpty(request.RecurrencePattern))
                transaction.RecurrencePattern = request.RecurrencePattern;

            transaction.UpdatedAt = DateTime.UtcNow;
            await _transactionRepository.UpdateAsync(transaction);

            var categoryName = (await _categoryRepository.GetByIdAsync(transaction.CategoryId))?.Name ?? "Unknown";
            return MapToDto(transaction, categoryName);
        }

        public async Task<bool> DeleteAsync(Guid userId, Guid transactionId)
        {
            var transaction = await _transactionRepository.GetByIdAsync(transactionId);
            if (transaction == null || transaction.UserId != userId)
                return false;

            return await _transactionRepository.DeleteAsync(transactionId);
        }

        public async Task<List<TransactionDto>> GetByCategoryAsync(Guid userId, Guid categoryId)
        {
            var category = await _categoryRepository.GetByIdAsync(categoryId);
            if (category == null || category.UserId != userId)
                return new List<TransactionDto>();

            var transactions = await _transactionRepository.GetByCategoryAsync(categoryId);
            return transactions
                .Where(t => t.UserId == userId)
                .Select(t => MapToDto(t, category.Name))
                .ToList();
        }

        private TransactionDto MapToDto(Transaction transaction, string categoryName)
        {
            return new TransactionDto
            {
                Id = transaction.Id,
                UserId = transaction.UserId,
                Type = transaction.Type,
                CategoryId = transaction.CategoryId,
                CategoryName = categoryName,
                Description = transaction.Description,
                Amount = transaction.Amount,
                Date = transaction.Date,
                Notes = transaction.Notes,
                IsRecurring = transaction.IsRecurring,
                RecurrencePattern = transaction.RecurrencePattern,
                CreatedAt = transaction.CreatedAt,
                UpdatedAt = transaction.UpdatedAt
            };
        }
    }
}
