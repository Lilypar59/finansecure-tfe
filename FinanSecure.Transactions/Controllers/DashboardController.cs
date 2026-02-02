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
    public class DashboardController : ControllerBase
    {
        private readonly IDashboardService _dashboardService;
        private readonly ILogger<DashboardController> _logger;

        public DashboardController(IDashboardService dashboardService, ILogger<DashboardController> logger)
        {
            _dashboardService = dashboardService;
            _logger = logger;
        }

        private Guid GetUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            return Guid.Parse(userIdClaim?.Value ?? throw new InvalidOperationException("User ID not found in claims"));
        }

        [HttpGet("summary")]
        [ProducesResponseType(typeof(ApiResponse<DashboardSummaryDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetDashboardSummary()
        {
            try
            {
                var userId = GetUserId();
                var summary = await _dashboardService.GetDashboardSummaryAsync(userId);
                return Ok(new ApiResponse<DashboardSummaryDto>
                {
                    Success = true,
                    Data = summary,
                    Message = "Dashboard summary retrieved successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving dashboard summary");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpGet("monthly-report")]
        [ProducesResponseType(typeof(ApiResponse<MonthlyReportDto>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetMonthlyReport([FromQuery] int month, [FromQuery] int year)
        {
            try
            {
                if (month < 1 || month > 12)
                    return BadRequest(new ApiResponse<object> { Success = false, Message = "Month must be between 1 and 12" });

                var userId = GetUserId();
                var report = await _dashboardService.GetMonthlyReportAsync(userId, month, year);
                return Ok(new ApiResponse<MonthlyReportDto>
                {
                    Success = true,
                    Data = report,
                    Message = "Monthly report retrieved successfully"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving monthly report");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpGet("income-breakdown")]
        [ProducesResponseType(typeof(ApiResponse<List<CategoryBreakdownDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetIncomeBreakdown([FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
        {
            try
            {
                var userId = GetUserId();
                var breakdown = await _dashboardService.GetIncomeBreakdownAsync(userId, startDate, endDate);
                return Ok(new ApiResponse<List<CategoryBreakdownDto>>
                {
                    Success = true,
                    Data = breakdown,
                    Message = $"Retrieved {breakdown.Count} income categories"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving income breakdown");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpGet("expense-breakdown")]
        [ProducesResponseType(typeof(ApiResponse<List<CategoryBreakdownDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetExpenseBreakdown([FromQuery] DateTime startDate, [FromQuery] DateTime endDate)
        {
            try
            {
                var userId = GetUserId();
                var breakdown = await _dashboardService.GetExpenseBreakdownAsync(userId, startDate, endDate);
                return Ok(new ApiResponse<List<CategoryBreakdownDto>>
                {
                    Success = true,
                    Data = breakdown,
                    Message = $"Retrieved {breakdown.Count} expense categories"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving expense breakdown");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }
    }
}
