using FinanSecure.Transactions.DTOs;

namespace FinanSecure.Transactions.Interfaces
{
    public interface ITransactionService
    {
        Task<TransactionDto> CreateAsync(Guid userId, CreateTransactionRequest request);
        Task<TransactionDto?> GetByIdAsync(Guid userId, Guid transactionId);
        Task<List<TransactionDto>> GetUserTransactionsAsync(Guid userId, DateTime? startDate, DateTime? endDate);
        Task<TransactionDto> UpdateAsync(Guid userId, Guid transactionId, UpdateTransactionRequest request);
        Task<bool> DeleteAsync(Guid userId, Guid transactionId);
        Task<List<TransactionDto>> GetByCategoryAsync(Guid userId, Guid categoryId);
    }
}
