using FinanSecure.Api.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace FinanSecure.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TestController : ControllerBase
{
    private readonly FinanSecureContext _context;

    public TestController(FinanSecureContext context)
    {
        _context = context;
    }

    // GET api/test/db
    [HttpGet("db")]
    public async Task<IActionResult> TestDbConnection()
    {
        try
        {
            var count = await _context.Transactions.CountAsync();

            var first = await _context.Transactions
                .OrderBy(t => t.Id)
                .Select(t => new {
                    t.Id,
                    t.Type,
                    t.Category,
                    t.Amount
                })
                .FirstOrDefaultAsync();

            return Ok(new
            {
                success = true,
                message = "Database connection OK",
                totalTransactions = count,
                sample = first
            });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                success = false,
                error = ex.Message,
                stack = ex.StackTrace
            });
        }
    }
}
