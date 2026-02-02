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
    public class CategoriesController : ControllerBase
    {
        private readonly ICategoryService _categoryService;
        private readonly ILogger<CategoriesController> _logger;

        public CategoriesController(ICategoryService categoryService, ILogger<CategoriesController> logger)
        {
            _categoryService = categoryService;
            _logger = logger;
        }

        private Guid GetUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier);
            return Guid.Parse(userIdClaim?.Value ?? throw new InvalidOperationException("User ID not found in claims"));
        }

        [HttpPost]
        [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> CreateCategory([FromBody] CreateCategoryRequest request)
        {
            try
            {
                var userId = GetUserId();
                var category = await _categoryService.CreateAsync(userId, request);
                return CreatedAtAction(nameof(GetCategory), new { id = category.Id },
                    new ApiResponse<CategoryDto>
                    {
                        Success = true,
                        Data = category,
                        Message = "Category created successfully"
                    });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ApiResponse<object> { Success = false, Message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating category");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpGet("{id}")]
        [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetCategory(Guid id)
        {
            try
            {
                var userId = GetUserId();
                var category = await _categoryService.GetByIdAsync(userId, id);
                if (category == null)
                    return NotFound(new ApiResponse<object> { Success = false, Message = "Category not found" });

                return Ok(new ApiResponse<CategoryDto> { Success = true, Data = category });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving category");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpGet]
        [ProducesResponseType(typeof(ApiResponse<List<CategoryDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetUserCategories([FromQuery] string? type = null)
        {
            try
            {
                var userId = GetUserId();
                var categories = await _categoryService.GetUserCategoriesAsync(userId, type);
                return Ok(new ApiResponse<List<CategoryDto>>
                {
                    Success = true,
                    Data = categories,
                    Message = $"Retrieved {categories.Count} categories"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving categories");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpPut("{id}")]
        [ProducesResponseType(typeof(ApiResponse<CategoryDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> UpdateCategory(Guid id, [FromBody] CreateCategoryRequest request)
        {
            try
            {
                var userId = GetUserId();
                var category = await _categoryService.UpdateAsync(userId, id, request);
                return Ok(new ApiResponse<CategoryDto>
                {
                    Success = true,
                    Data = category,
                    Message = "Category updated successfully"
                });
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ApiResponse<object> { Success = false, Message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating category");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }

        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> DeleteCategory(Guid id)
        {
            try
            {
                var userId = GetUserId();
                var deleted = await _categoryService.DeleteAsync(userId, id);
                if (!deleted)
                    return NotFound(new ApiResponse<object> { Success = false, Message = "Category not found" });

                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ApiResponse<object> { Success = false, Message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting category");
                return StatusCode(500, new ApiResponse<object> { Success = false, Message = "Internal server error" });
            }
        }
    }
}
