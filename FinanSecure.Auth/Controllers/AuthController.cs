using FinanSecure.Auth.DTOs;
using FinanSecure.Auth.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace FinanSecure.Auth.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;
        private readonly ILogger<AuthController> _logger;

        public AuthController(IAuthService authService, ILogger<AuthController> logger)
        {
            _authService = authService;
            _logger = logger;
        }

        /// <summary>
        /// Registrar un nuevo usuario
        /// </summary>
        [HttpPost("register")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new ErrorResponse
                {
                    Message = "Datos de registro inválidos.",
                    Errors = ModelState
                        .Where(ms => ms.Value?.Errors.Count > 0)
                        .ToDictionary(ms => ms.Key, ms => ms.Value!.Errors.Select(e => e.ErrorMessage).ToArray())
                });
            }

            var response = await _authService.RegisterAsync(request);

            return response.Success 
                ? Ok(response) 
                : BadRequest(response);
        }

        /// <summary>
        /// Login de usuario
        /// </summary>
        [HttpPost("login")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
        {
            if (!ModelState.IsValid)
            {
                return BadRequest(new ErrorResponse
                {
                    Message = "Datos de login inválidos."
                });
            }

            var response = await _authService.LoginAsync(request);

            return response.Success
                ? Ok(response)
                : Unauthorized(response);
        }

        /// <summary>
        /// Refrescar access token usando refresh token
        /// </summary>
        [HttpPost("refresh-token")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<AuthResponse>> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            var response = await _authService.RefreshTokenAsync(request);

            return response.Success
                ? Ok(response)
                : Unauthorized(response);
        }

        /// <summary>
        /// Logout - revocar refresh token
        /// </summary>
        [HttpPost("logout")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        public async Task<ActionResult<object>> Logout([FromBody] RefreshTokenRequest request)
        {
            var success = await _authService.RevokeTokenAsync(request.RefreshToken);

            return success
                ? Ok(new { success = true, message = "Logout exitoso." })
                : BadRequest(new { success = false, message = "Error al hacer logout." });
        }

        /// <summary>
        /// Validar access token
        /// </summary>
        [HttpPost("validate")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        public async Task<ActionResult<AuthResponse>> Validate([FromQuery] string token)
        {
            if (string.IsNullOrEmpty(token))
            {
                return BadRequest(new ErrorResponse
                {
                    Message = "Token no proporcionado."
                });
            }

            var response = await _authService.ValidateAccessTokenAsync(token);

            return response.Success
                ? Ok(response)
                : Unauthorized(response);
        }
    }
}
