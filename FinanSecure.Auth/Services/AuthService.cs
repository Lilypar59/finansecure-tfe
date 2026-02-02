using FinanSecure.Auth.DTOs;
using FinanSecure.Auth.Interfaces;
using FinanSecure.Auth.Models;

namespace FinanSecure.Auth.Services
{
    public class AuthService : IAuthService
    {
        private readonly IUserRepository _userRepository;
        private readonly IRefreshTokenRepository _tokenRepository;
        private readonly IJwtService _jwtService;
        private readonly IPasswordService _passwordService;
        private readonly ILogger<AuthService> _logger;

        public AuthService(
            IUserRepository userRepository,
            IRefreshTokenRepository tokenRepository,
            IJwtService jwtService,
            IPasswordService passwordService,
            ILogger<AuthService> logger)
        {
            _userRepository = userRepository;
            _tokenRepository = tokenRepository;
            _jwtService = jwtService;
            _passwordService = passwordService;
            _logger = logger;
        }

        public async Task<AuthResponse> RegisterAsync(RegisterRequest request)
        {
            try
            {
                // Validar que usuario y email no existan
                if (await _userRepository.ExistsAsync(request.Username, request.Email))
                {
                    return new AuthResponse
                    {
                        Success = false,
                        Message = "El usuario o correo ya está registrado."
                    };
                }

                // Crear nuevo usuario
                var user = new User
                {
                    Id = Guid.NewGuid(),
                    Username = request.Username,
                    Email = request.Email,
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    PasswordHash = _passwordService.HashPassword(request.Password),
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };

                var createdUser = await _userRepository.CreateAsync(user);

                _logger.LogInformation("Usuario registrado: {Username} ({Id})", 
                    createdUser.Username, createdUser.Id);

                return new AuthResponse
                {
                    Success = true,
                    Message = "Usuario registrado exitosamente.",
                    User = MapToUserDto(createdUser)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al registrar usuario: {Username}", request.Username);
                return new AuthResponse
                {
                    Success = false,
                    Message = "Error al registrar usuario."
                };
            }
        }

        public async Task<AuthResponse> LoginAsync(LoginRequest request)
        {
            try
            {
                // Buscar usuario por username
                var user = await _userRepository.GetByUsernameAsync(request.Username);
                
                if (user == null || !user.IsActive)
                {
                    _logger.LogWarning("Intento de login fallido para usuario: {Username}", 
                        request.Username);
                    return new AuthResponse
                    {
                        Success = false,
                        Message = "Usuario o contraseña inválidos."
                    };
                }

                // Verificar contraseña
                if (!_passwordService.VerifyPassword(request.Password, user.PasswordHash))
                {
                    _logger.LogWarning("Contraseña inválida para usuario: {Username}", 
                        request.Username);
                    return new AuthResponse
                    {
                        Success = false,
                        Message = "Usuario o contraseña inválidos."
                    };
                }

                // Generar tokens
                var accessToken = _jwtService.GenerateAccessToken(user.Id, user.Username, user.Email);
                var refreshToken = _jwtService.GenerateRefreshToken();

                // Guardar refresh token
                var refreshTokenEntity = new RefreshToken
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    Token = refreshToken,
                    ExpiresAt = DateTime.UtcNow.AddDays(7),
                    CreatedAt = DateTime.UtcNow
                };

                await _tokenRepository.CreateAsync(refreshTokenEntity);

                // Actualizar última sesión
                user.LastLoginAt = DateTime.UtcNow;
                await _userRepository.UpdateAsync(user);

                _logger.LogInformation("Login exitoso para usuario: {Username} ({Id})", 
                    user.Username, user.Id);

                return new AuthResponse
                {
                    Success = true,
                    Message = "Login exitoso.",
                    User = MapToUserDto(user),
                    Tokens = new TokenResponse
                    {
                        AccessToken = accessToken,
                        RefreshToken = refreshToken,
                        ExpiresIn = 900, // 15 minutos en segundos
                        TokenType = "Bearer"
                    }
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al hacer login para usuario: {Username}", 
                    request.Username);
                return new AuthResponse
                {
                    Success = false,
                    Message = "Error al procesar login."
                };
            }
        }

        public async Task<AuthResponse> RefreshTokenAsync(RefreshTokenRequest request)
        {
            try
            {
                // Buscar refresh token
                var refreshToken = await _tokenRepository.GetByTokenAsync(request.RefreshToken);

                if (refreshToken == null || !refreshToken.IsActive)
                {
                    _logger.LogWarning("Refresh token inválido o expirado");
                    return new AuthResponse
                    {
                        Success = false,
                        Message = "Refresh token inválido o expirado."
                    };
                }

                var user = refreshToken.User;

                if (!user.IsActive)
                {
                    return new AuthResponse
                    {
                        Success = false,
                        Message = "Usuario inactivo."
                    };
                }

                // Generar nuevos tokens
                var newAccessToken = _jwtService.GenerateAccessToken(user.Id, user.Username, user.Email);
                var newRefreshToken = _jwtService.GenerateRefreshToken();

                // Revocar token anterior
                await _tokenRepository.RevokeAsync(refreshToken.Token);

                // Crear nuevo refresh token
                var newRefreshTokenEntity = new RefreshToken
                {
                    Id = Guid.NewGuid(),
                    UserId = user.Id,
                    Token = newRefreshToken,
                    ExpiresAt = DateTime.UtcNow.AddDays(7),
                    CreatedAt = DateTime.UtcNow
                };

                await _tokenRepository.CreateAsync(newRefreshTokenEntity);

                _logger.LogInformation("Token refrescado para usuario: {UserId}", user.Id);

                return new AuthResponse
                {
                    Success = true,
                    Message = "Tokens refrescados exitosamente.",
                    Tokens = new TokenResponse
                    {
                        AccessToken = newAccessToken,
                        RefreshToken = newRefreshToken,
                        ExpiresIn = 900,
                        TokenType = "Bearer"
                    }
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al refrescar token");
                return new AuthResponse
                {
                    Success = false,
                    Message = "Error al refrescar token."
                };
            }
        }

        public async Task<bool> RevokeTokenAsync(string refreshToken)
        {
            try
            {
                var result = await _tokenRepository.RevokeAsync(refreshToken);
                if (result)
                {
                    _logger.LogInformation("Token revocado");
                }
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al revocar token");
                return false;
            }
        }

        public async Task<bool> ChangePasswordAsync(Guid userId, ChangePasswordRequest request)
        {
            try
            {
                var user = await _userRepository.GetByIdAsync(userId);

                if (user == null || !_passwordService.VerifyPassword(request.CurrentPassword, user.PasswordHash))
                {
                    _logger.LogWarning("Intento de cambio de contraseña fallido para usuario: {UserId}", userId);
                    return false;
                }

                user.PasswordHash = _passwordService.HashPassword(request.NewPassword);
                await _userRepository.UpdateAsync(user);

                _logger.LogInformation("Contraseña cambiada para usuario: {UserId}", userId);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al cambiar contraseña para usuario: {UserId}", userId);
                return false;
            }
        }

        public async Task<AuthResponse> ValidateAccessTokenAsync(string accessToken)
        {
            try
            {
                var principal = _jwtService.ValidateToken(accessToken);

                if (principal == null)
                {
                    return new AuthResponse
                    {
                        Success = false,
                        Message = "Token inválido."
                    };
                }

                var userIdClaim = principal.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier);
                if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
                {
                    return new AuthResponse
                    {
                        Success = false,
                        Message = "Token sin identidad de usuario."
                    };
                }

                var user = await _userRepository.GetByIdAsync(userId);

                if (user == null || !user.IsActive)
                {
                    return new AuthResponse
                    {
                        Success = false,
                        Message = "Usuario no válido."
                    };
                }

                return new AuthResponse
                {
                    Success = true,
                    Message = "Token válido.",
                    User = MapToUserDto(user)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al validar token");
                return new AuthResponse
                {
                    Success = false,
                    Message = "Error al validar token."
                };
            }
        }

        private UserDto MapToUserDto(User user)
        {
            return new UserDto
            {
                Id = user.Id,
                Username = user.Username,
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName,
                IsActive = user.IsActive,
                CreatedAt = user.CreatedAt,
                LastLoginAt = user.LastLoginAt
            };
        }
    }
}
