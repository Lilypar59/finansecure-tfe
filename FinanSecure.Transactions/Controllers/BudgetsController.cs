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
    public class BudgetsController : ControllerBase
    {
        private readonly IBudgetService _budgetService;
        private readonly ILogger<BudgetsController> _logger;

        public BudgetsController(IBudgetService budgetService, ILogger<BudgetsController> logger)
        {
            _budgetService = budgetService;
            _logger = logger;
        }

        private Guid GetUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            return Guid.Parse(userIdClaim?.Value ?? throw new InvalidOperationException("User ID not found in claims"));
        }

        [HttpPost]
        [ProducesResponseType(typeof(ApiResponse<BudgetDto>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> CreateBudget([FromBody] CreateBudgetRequest request)
        {
            try
            {
                var userId = GetUserId();
                var budget = await _budgetService.CreateAsync(userId, request);
                return CreatedAtAction(nameof(GetBudget), new { id = budget.Id },
                    new ApiResponse<BudgetDto>
                    {
                        Success = true,
                        Data = budget,
                        Message = "Budget created successfully"
                    });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ApiResponse<object> { Success = false, Message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating budget");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpGet("{id}")]
        [ProducesResponseType(typeof(ApiResponse<BudgetDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetBudget(Guid id)
        {
            try
            {
                var userId = GetUserId();
                var budget = await _budgetService.GetByIdAsync(userId, id);
                if (budget == null)
                    return NotFound(new ApiResponse<object> { Success = false, Message = "Budget not found" });

                return Ok(new ApiResponse<BudgetDto> { Success = true, Data = budget });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving budget");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpGet("month/{month}/{year}")]
        [ProducesResponseType(typeof(ApiResponse<List<BudgetDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetMonthBudgets(int month, int year)
        {
            try
            {
                if (month < 1 || month > 12)
                    return BadRequest(new ApiResponse<object> { Success = false, Message = "Month must be between 1 and 12" });

                var userId = GetUserId();
                var budgets = await _budgetService.GetMonthBudgetsAsync(userId, month, year);
                return Ok(new ApiResponse<List<BudgetDto>>
                {
                    Success = true,
                    Data = budgets,
                    Message = $"Retrieved {budgets.Count} budgets"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving budgets");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpPut("{id}")]
        [ProducesResponseType(typeof(ApiResponse<BudgetDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> UpdateBudget(Guid id, [FromBody] CreateBudgetRequest request)
        {
            try
            {
                var userId = GetUserId();
                var budget = await _budgetService.UpdateAsync(userId, id, request);
                return Ok(new ApiResponse<BudgetDto>
                {
                    Success = true,
                    Data = budget,
                    Message = "Budget updated successfully"
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ApiResponse<object> { Success = false, Message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating budget");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeleteBudget(Guid id)
        {
            try
            {
                var userId = GetUserId();
                var deleted = await _budgetService.DeleteAsync(userId, id);
                if (!deleted)
                    return NotFound(new ApiResponse<object> { Success = false, Message = "Budget not found" });

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting budget");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }
    }
}
