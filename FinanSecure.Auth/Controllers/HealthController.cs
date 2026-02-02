using Microsoft.AspNetCore.Mvc;

namespace FinanSecure.Auth.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class HealthController : ControllerBase
    {
        private readonly ILogger<HealthController> _logger;

        public HealthController(ILogger<HealthController> logger)
        {
            _logger = logger;
        }

        /// <summary>
        /// Health check del servicio
        /// </summary>
        [HttpGet]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public ActionResult<object> Health()
        {
            return Ok(new
            {
                status = "healthy",
                service = "FinanSecure.Auth",
                timestamp = DateTime.UtcNow,
                version = "1.0.0"
            });
        }
    }
}
