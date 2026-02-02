using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using FinanSecure.Transactions.DTOs;
using FinanSecure.Transactions.Interfaces;
using System.Security.Claims;

namespace FinanSecure.Transactions.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    [Authorize(AuthenticationSchemes = "Bearer")]
    public class TransactionsController : ControllerBase
    {
        private readonly ITransactionService _transactionService;
        private readonly ILogger<TransactionsController> _logger;

        public TransactionsController(ITransactionService transactionService, ILogger<TransactionsController> logger)
        {
            _transactionService = transactionService;
            _logger = logger;
        }

        private Guid GetUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            return Guid.Parse(userIdClaim?.Value ?? throw new InvalidOperationException("User ID not found in claims"));
        }

        [HttpPost]
        [ProducesResponseType(typeof(ApiResponse<TransactionDto>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> CreateTransaction([FromBody] CreateTransactionRequest request)
        {
            try
            {
                var userId = GetUserId();
                var transaction = await _transactionService.CreateAsync(userId, request);
                return CreatedAtAction(nameof(GetTransaction), new { id = transaction.Id }, 
                    new ApiResponse<TransactionDto>
                    {
                        Success = true,
                        Data = transaction,
                        Message = "Transaction created successfully"
                    });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ApiResponse<object> { Success = false, Message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating transaction");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpGet("{id}")]
        [ProducesResponseType(typeof(ApiResponse<TransactionDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetTransaction(Guid id)
        {
            try
            {
                var userId = GetUserId();
                var transaction = await _transactionService.GetByIdAsync(userId, id);
                if (transaction == null)
                    return NotFound(new ApiResponse<object> { Success = false, Message = "Transaction not found" });

                return Ok(new ApiResponse<TransactionDto> { Success = true, Data = transaction });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving transaction");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<List<TransactionDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetUserTransactions([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate)
        {
            try
            {
                var userId = GetUserId();
                var transactions = await _transactionService.GetUserTransactionsAsync(userId, startDate, endDate);
                return Ok(new ApiResponse<List<TransactionDto>>
                {
                    Success = true,
                    Data = transactions,
                    Message = $"Retrieved {transactions.Count} transactions"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving transactions");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpPut("{id}")]
        [ProducesResponseType(typeof(ApiResponse<TransactionDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> UpdateTransaction(Guid id, [FromBody] UpdateTransactionRequest request)
        {
            try
            {
                var userId = GetUserId();
                var transaction = await _transactionService.UpdateAsync(userId, id, request);
                return Ok(new ApiResponse<TransactionDto>
                {
                    Success = true,
                    Data = transaction,
                    Message = "Transaction updated successfully"
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ApiResponse<object> { Success = false, Message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating transaction");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeleteTransaction(Guid id)
        {
            try
            {
                var userId = GetUserId();
                var deleted = await _transactionService.DeleteAsync(userId, id);
                if (!deleted)
                    return NotFound(new ApiResponse<object> { Success = false, Message = "Transaction not found" });

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting transaction");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpGet("category/{categoryId}")]
        [ProducesResponseType(typeof(ApiResponse<List<TransactionDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetByCategory(Guid categoryId)
        {
            try
            {
                var userId = GetUserId();
                var transactions = await _transactionService.GetByCategoryAsync(userId, categoryId);
                return Ok(new ApiResponse<List<TransactionDto>>
                {
                    Success = true,
                    Data = transactions,
                    Message = $"Retrieved {transactions.Count} transactions for category"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving transactions by category");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }
    }
}
