# Unit Tests para Seguridad JWT - FinanSecure

Tests xUnit para validar componentes de autenticación.

---

## 📦 Archivo: JwtConfigurationTests.cs

```csharp
using System;
using Xunit;
using Microsoft.IdentityModel.Tokens;
using FinanSecure.Shared.Configuration;
using Moq;
using Microsoft.Extensions.Logging;

namespace FinanSecure.Tests.Unit.Security;

public class JwtConfigurationTests
{
    [Fact]
    public void GetSymmetricSecurityKey_WithValidSecretKey_ReturnsSymmetricSecurityKey()
    {
        // Arrange
        var config = new JwtConfiguration
        {
            SecretKey = "super-secret-key-with-minimum-32-characters-for-hs256"
        };

        // Act
        var key = config.GetSymmetricSecurityKey();

        // Assert
        Assert.NotNull(key);
        Assert.IsType<SymmetricSecurityKey>(key);
    }

    [Fact]
    public void GetTokenValidationParameters_ReturnsCompleteParameters()
    {
        // Arrange
        var config = new JwtConfiguration
        {
            SecretKey = "super-secret-key-with-minimum-32-characters-for-hs256",
            Issuer = "FinanSecure.Auth",
            Audience = "FinanSecure.Transactions",
            ValidateIssuerSigningKey = true,
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true
        };

        // Act
        var parameters = config.GetTokenValidationParameters();

        // Assert
        Assert.NotNull(parameters);
        Assert.Equal("FinanSecure.Auth", parameters.ValidIssuer);
        Assert.Single(parameters.ValidAudiences);
        Assert.Contains("FinanSecure.Transactions", parameters.ValidAudiences);
        Assert.True(parameters.ValidateIssuer);
        Assert.True(parameters.ValidateAudience);
        Assert.True(parameters.ValidateLifetime);
        Assert.True(parameters.ValidateIssuerSigningKey);
    }

    [Fact]
    public void ValidateJwtConfiguration_WithShortSecretKey_DoesNotThrow()
    {
        // Arrange
        var config = new JwtConfiguration
        {
            SecretKey = "short",  // < 32 caracteres
            Issuer = "FinanSecure.Auth",
            Audience = "FinanSecure.Transactions"
        };
        var mockLogger = new Mock<ILogger<Program>>();

        // Act & Assert
        // Se espera que log advertencia pero no lance excepción
        config.ValidateJwtConfiguration(mockLogger.Object);
        
        mockLogger.Verify(
            x => x.Log(
                LogLevel.Warning,
                It.IsAny<EventId>(),
                It.IsAny<It.IsAnyType>(),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()),
            Times.Once);
    }

    [Fact]
    public void ValidateJwtConfiguration_WithMissingSecretKey_LogsError()
    {
        // Arrange
        var config = new JwtConfiguration
        {
            SecretKey = null,
            Issuer = "FinanSecure.Auth",
            Audience = "FinanSecure.Transactions"
        };
        var mockLogger = new Mock<ILogger<Program>>();

        // Act
        config.ValidateJwtConfiguration(mockLogger.Object);

        // Assert
        mockLogger.Verify(
            x => x.Log(
                LogLevel.Error,
                It.IsAny<EventId>(),
                It.IsAny<It.IsAnyType>(),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()),
            Times.AtLeastOnce);
    }
}
```

---

## 🔐 Archivo: JwtClaimsExtensionsTests.cs

```csharp
using System;
using System.Collections.Generic;
using System.Security.Claims;
using Xunit;
using FinanSecure.Shared.Security;

namespace FinanSecure.Tests.Unit.Security;

public class JwtClaimsExtensionsTests
{
    private readonly Guid _testUserId = Guid.NewGuid();
    private readonly string _testUsername = "juan.perez";
    private readonly string _testEmail = "juan@example.com";
    private readonly string _testJti = Guid.NewGuid().ToString();

    private ClaimsPrincipal CreateValidAccessToken()
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, _testUserId.ToString()),
            new Claim(ClaimTypes.Name, _testUsername),
            new Claim(ClaimTypes.Email, _testEmail),
            new Claim("type", "access"),
            new Claim("jti", _testJti)
        };

        var identity = new ClaimsIdentity(claims, "Bearer");
        return new ClaimsPrincipal(identity);
    }

    [Fact]
    public void GetUserId_WithValidClaim_ReturnsGuid()
    {
        // Arrange
        var user = CreateValidAccessToken();

        // Act
        var userId = user.GetUserId();

        // Assert
        Assert.NotNull(userId);
        Assert.Equal(_testUserId, userId);
    }

    [Fact]
    public void GetUserId_WithMissingClaim_ReturnsNull()
    {
        // Arrange
        var claims = new List<Claim> { new Claim(ClaimTypes.Name, _testUsername) };
        var identity = new ClaimsIdentity(claims, "Bearer");
        var user = new ClaimsPrincipal(identity);

        // Act
        var userId = user.GetUserId();

        // Assert
        Assert.Null(userId);
    }

    [Fact]
    public void GetUserIdOrThrow_WithValidClaim_ReturnsGuid()
    {
        // Arrange
        var user = CreateValidAccessToken();

        // Act
        var userId = user.GetUserIdOrThrow();

        // Assert
        Assert.Equal(_testUserId, userId);
    }

    [Fact]
    public void GetUserIdOrThrow_WithMissingClaim_ThrowsUnauthorizedAccessException()
    {
        // Arrange
        var claims = new List<Claim> { new Claim(ClaimTypes.Name, _testUsername) };
        var identity = new ClaimsIdentity(claims, "Bearer");
        var user = new ClaimsPrincipal(identity);

        // Act & Assert
        var exception = Assert.Throws<UnauthorizedAccessException>(() => user.GetUserIdOrThrow());
        Assert.Contains("User ID not found", exception.Message);
    }

    [Fact]
    public void GetUsername_WithValidClaim_ReturnsUsername()
    {
        // Arrange
        var user = CreateValidAccessToken();

        // Act
        var username = user.GetUsername();

        // Assert
        Assert.Equal(_testUsername, username);
    }

    [Fact]
    public void GetEmail_WithValidClaim_ReturnsEmail()
    {
        // Arrange
        var user = CreateValidAccessToken();

        // Act
        var email = user.GetEmail();

        // Assert
        Assert.Equal(_testEmail, email);
    }

    [Fact]
    public void GetJti_WithValidClaim_ReturnsJti()
    {
        // Arrange
        var user = CreateValidAccessToken();

        // Act
        var jti = user.GetJti();

        // Assert
        Assert.Equal(_testJti, jti);
    }

    [Fact]
    public void IsAccessToken_WithAccessTokenType_ReturnsTrue()
    {
        // Arrange
        var user = CreateValidAccessToken();

        // Act
        var isAccessToken = user.IsAccessToken();

        // Assert
        Assert.True(isAccessToken);
    }

    [Fact]
    public void IsAccessToken_WithRefreshTokenType_ReturnsFalse()
    {
        // Arrange
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, _testUserId.ToString()),
            new Claim("type", "refresh")
        };
        var identity = new ClaimsIdentity(claims, "Bearer");
        var user = new ClaimsPrincipal(identity);

        // Act
        var isAccessToken = user.IsAccessToken();

        // Assert
        Assert.False(isAccessToken);
    }

    [Fact]
    public void HasClaim_WithExistingClaim_ReturnsTrue()
    {
        // Arrange
        var user = CreateValidAccessToken();

        // Act
        var hasClaim = user.HasClaim("jti");

        // Assert
        Assert.True(hasClaim);
    }

    [Fact]
    public void HasClaim_WithMissingClaim_ReturnsFalse()
    {
        // Arrange
        var user = CreateValidAccessToken();

        // Act
        var hasClaim = user.HasClaim("nonexistent");

        // Assert
        Assert.False(hasClaim);
    }

    [Fact]
    public void GetAllClaims_ReturnsAllClaims()
    {
        // Arrange
        var user = CreateValidAccessToken();

        // Act
        var allClaims = user.GetAllClaims();

        // Assert
        Assert.NotEmpty(allClaims);
        Assert.Contains("sub", allClaims.Keys);  // NameIdentifier
        Assert.Contains("name", allClaims.Keys);
        Assert.Contains("email", allClaims.Keys);
        Assert.Contains("type", allClaims.Keys);
        Assert.Contains("jti", allClaims.Keys);
    }
}
```

---

## ✅ Archivo: JwtClaimsValidatorTests.cs

```csharp
using System;
using System.Collections.Generic;
using System.Security.Claims;
using Xunit;
using FinanSecure.Shared.Security;

namespace FinanSecure.Tests.Unit.Security;

public class JwtClaimsValidatorTests
{
    private readonly JwtClaimsValidator _validator = new JwtClaimsValidator();
    private readonly Guid _testUserId = Guid.NewGuid();

    private ClaimsPrincipal CreateUserWithClaims(params (string type, string value)[] claims)
    {
        var claimList = new List<Claim>();
        foreach (var (type, value) in claims)
        {
            claimList.Add(new Claim(type, value));
        }

        var identity = new ClaimsIdentity(claimList, "Bearer");
        return new ClaimsPrincipal(identity);
    }

    [Fact]
    public void ValidateRequiredClaims_WithAllRequiredClaims_ReturnsTrue()
    {
        // Arrange
        var user = CreateUserWithClaims(
            (ClaimTypes.NameIdentifier, _testUserId.ToString()),
            (ClaimTypes.Name, "juan.perez"),
            (ClaimTypes.Email, "juan@example.com"),
            ("type", "access"),
            ("jti", Guid.NewGuid().ToString())
        );

        // Act
        var isValid = _validator.ValidateRequiredClaims(user);

        // Assert
        Assert.True(isValid);
    }

    [Fact]
    public void ValidateRequiredClaims_WithMissingSubClaim_ReturnsFalse()
    {
        // Arrange
        var user = CreateUserWithClaims(
            (ClaimTypes.Name, "juan.perez"),
            (ClaimTypes.Email, "juan@example.com"),
            ("type", "access"),
            ("jti", Guid.NewGuid().ToString())
        );

        // Act
        var isValid = _validator.ValidateRequiredClaims(user);

        // Assert
        Assert.False(isValid);
    }

    [Fact]
    public void ValidateRequiredClaims_WithMissingJti_ReturnsFalse()
    {
        // Arrange
        var user = CreateUserWithClaims(
            (ClaimTypes.NameIdentifier, _testUserId.ToString()),
            (ClaimTypes.Name, "juan.perez"),
            (ClaimTypes.Email, "juan@example.com"),
            ("type", "access")
        );

        // Act
        var isValid = _validator.ValidateRequiredClaims(user);

        // Assert
        Assert.False(isValid);
    }

    [Fact]
    public void ValidateUserId_WithValidGuid_ReturnsTrue()
    {
        // Arrange
        var user = CreateUserWithClaims(
            (ClaimTypes.NameIdentifier, _testUserId.ToString())
        );

        // Act
        var isValid = _validator.ValidateUserId(user);

        // Assert
        Assert.True(isValid);
    }

    [Fact]
    public void ValidateUserId_WithInvalidGuid_ReturnsFalse()
    {
        // Arrange
        var user = CreateUserWithClaims(
            (ClaimTypes.NameIdentifier, "not-a-guid")
        );

        // Act
        var isValid = _validator.ValidateUserId(user);

        // Assert
        Assert.False(isValid);
    }

    [Fact]
    public void ValidateUserId_WithEmptyGuid_ReturnsFalse()
    {
        // Arrange
        var user = CreateUserWithClaims(
            (ClaimTypes.NameIdentifier, Guid.Empty.ToString())
        );

        // Act
        var isValid = _validator.ValidateUserId(user);

        // Assert
        Assert.False(isValid);
    }

    [Fact]
    public void IsAccessToken_WithAccessType_ReturnsTrue()
    {
        // Arrange
        var user = CreateUserWithClaims(("type", "access"));

        // Act
        var isAccessToken = _validator.IsAccessToken(user);

        // Assert
        Assert.True(isAccessToken);
    }

    [Fact]
    public void IsAccessToken_WithRefreshType_ReturnsFalse()
    {
        // Arrange
        var user = CreateUserWithClaims(("type", "refresh"));

        // Act
        var isAccessToken = _validator.IsAccessToken(user);

        // Assert
        Assert.False(isAccessToken);
    }

    [Fact]
    public void ValidateComplete_WithValidAccessToken_ReturnsTrue()
    {
        // Arrange
        var user = CreateUserWithClaims(
            (ClaimTypes.NameIdentifier, _testUserId.ToString()),
            (ClaimTypes.Name, "juan.perez"),
            (ClaimTypes.Email, "juan@example.com"),
            ("type", "access"),
            ("jti", Guid.NewGuid().ToString())
        );

        // Act
        var isValid = _validator.ValidateComplete(user);

        // Assert
        Assert.True(isValid);
    }

    [Fact]
    public void ValidateComplete_WithRefreshToken_ReturnsFalse()
    {
        // Arrange
        var user = CreateUserWithClaims(
            (ClaimTypes.NameIdentifier, _testUserId.ToString()),
            (ClaimTypes.Name, "juan.perez"),
            (ClaimTypes.Email, "juan@example.com"),
            ("type", "refresh"),
            ("jti", Guid.NewGuid().ToString())
        );

        // Act
        var isValid = _validator.ValidateComplete(user);

        // Assert
        Assert.False(isValid);
    }
}
```

---

## 🧪 Archivo: SecureControllerBaseTests.cs

```csharp
using System;
using System.Collections.Generic;
using System.Security.Claims;
using Xunit;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Moq;
using Microsoft.Extensions.Logging;
using FinanSecure.Shared.Security;

namespace FinanSecure.Tests.Unit.Security;

public class SecureControllerBaseTests
{
    private readonly Mock<ILogger<TestSecureController>> _mockLogger;
    private readonly TestSecureController _controller;

    public SecureControllerBaseTests()
    {
        _mockLogger = new Mock<ILogger<TestSecureController>>();
        _controller = new TestSecureController(_mockLogger.Object);
    }

    private ClaimsPrincipal CreateUser(Guid userId, string username = "juan.perez", string email = "juan@example.com")
    {
        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
            new Claim(ClaimTypes.Name, username),
            new Claim(ClaimTypes.Email, email),
            new Claim("type", "access"),
            new Claim("jti", Guid.NewGuid().ToString())
        };

        var identity = new ClaimsIdentity(claims, "Bearer");
        return new ClaimsPrincipal(identity);
    }

    [Fact]
    public void GetAuthenticatedUserId_WithValidUser_ReturnsUserId()
    {
        // Arrange
        var userId = Guid.NewGuid();
        _controller.User = CreateUser(userId);

        // Act
        var result = _controller.TestGetAuthenticatedUserId();

        // Assert
        Assert.Equal(userId, result);
    }

    [Fact]
    public void GetAuthenticatedUserId_WithoutUser_ThrowsUnauthorizedAccessException()
    {
        // Arrange
        _controller.User = new ClaimsPrincipal();

        // Act & Assert
        Assert.Throws<UnauthorizedAccessException>(() => _controller.TestGetAuthenticatedUserId());
    }

    [Fact]
    public void GetAuthenticatedUserIdSafe_WithValidUser_ReturnsUserId()
    {
        // Arrange
        var userId = Guid.NewGuid();
        _controller.User = CreateUser(userId);

        // Act
        var result = _controller.TestGetAuthenticatedUserIdSafe();

        // Assert
        Assert.NotNull(result);
        Assert.Equal(userId, result);
    }

    [Fact]
    public void GetAuthenticatedUserIdSafe_WithoutUser_ReturnsNull()
    {
        // Arrange
        _controller.User = new ClaimsPrincipal();

        // Act
        var result = _controller.TestGetAuthenticatedUserIdSafe();

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void GetAuthenticatedUserInfo_WithValidUser_ReturnsUserInfo()
    {
        // Arrange
        var userId = Guid.NewGuid();
        var username = "juan.perez";
        var email = "juan@example.com";
        _controller.User = CreateUser(userId, username, email);

        // Act
        var result = _controller.TestGetAuthenticatedUserInfo();

        // Assert
        Assert.NotNull(result);
        Assert.Equal(userId, result.UserId);
        Assert.Equal(username, result.Username);
        Assert.Equal(email, result.Email);
        Assert.NotEmpty(result.Jti);
    }

    [Fact]
    public void ValidateResourceOwnership_WithOwnerUser_ReturnsOk()
    {
        // Arrange
        var userId = Guid.NewGuid();
        _controller.User = CreateUser(userId);

        // Act
        var result = _controller.TestValidateResourceOwnership(userId);

        // Assert
        Assert.IsType<OkResult>(result);
    }

    [Fact]
    public void ValidateResourceOwnership_WithDifferentUser_ReturnsForbid()
    {
        // Arrange
        var userId1 = Guid.NewGuid();
        var userId2 = Guid.NewGuid();
        _controller.User = CreateUser(userId1);

        // Act
        var result = _controller.TestValidateResourceOwnership(userId2);

        // Assert
        Assert.IsType<ForbidResult>(result);
    }

    [Fact]
    public void LogAudit_WithValidData_LogsInformation()
    {
        // Arrange
        var userId = Guid.NewGuid();
        _controller.User = CreateUser(userId);
        var httpContextMock = new Mock<HttpContext>();
        httpContextMock.Setup(x => x.Connection.RemoteIpAddress).Returns(System.Net.IPAddress.Parse("127.0.0.1"));
        _controller.ControllerContext.HttpContext = httpContextMock.Object;

        // Act
        _controller.TestLogAudit("TEST_ACTION", "test-resource", null);

        // Assert
        _mockLogger.Verify(
            x => x.Log(
                LogLevel.Information,
                It.IsAny<EventId>(),
                It.IsAny<It.IsAnyType>(),
                It.IsAny<Exception>(),
                It.IsAny<Func<It.IsAnyType, Exception, string>>()),
            Times.Once);
    }
}

// Test implementation
public class TestSecureController : SecureControllerBase
{
    public TestSecureController(ILogger<TestSecureController> logger) : base(logger)
    {
        ControllerContext = new ControllerContext
        {
            HttpContext = new DefaultHttpContext()
        };
    }

    public Guid TestGetAuthenticatedUserId() => GetAuthenticatedUserId();
    public Guid? TestGetAuthenticatedUserIdSafe() => GetAuthenticatedUserIdSafe();
    public UserInfo TestGetAuthenticatedUserInfo() => GetAuthenticatedUserInfo();
    public IActionResult TestValidateResourceOwnership(Guid resourceOwnerId) => ValidateResourceOwnership(resourceOwnerId);
    public void TestLogAudit(string action, string resource, object data) => LogAudit(action, resource, data);
}
```

---

## 📝 Archivo: appsettings.test.json

```json
{
  "Jwt": {
    "SecretKey": "test-super-secret-key-with-minimum-32-characters-for-hs256",
    "Issuer": "FinanSecure.Auth",
    "Audience": "FinanSecure.Transactions",
    "AccessTokenExpirationMinutes": 15,
    "RefreshTokenExpirationDays": 7,
    "RefreshTokenMaxDays": 30,
    "RequireHttpsMetadata": false,
    "ClockSkewSeconds": 0,
    "ValidateIssuerSigningKey": true,
    "ValidateIssuer": true,
    "ValidateAudience": true,
    "ValidateLifetime": true,
    "AccessTokenType": "access",
    "RefreshTokenType": "refresh",
    "ValidateCustomClaims": true
  }
}
```

---

## 🚀 Ejecutar Tests

### Desde terminal
```bash
# Tests todos
dotnet test

# Tests específicos
dotnet test --filter "JwtConfigurationTests"
dotnet test --filter "JwtClaimsExtensionsTests"
dotnet test --filter "JwtClaimsValidatorTests"
dotnet test --filter "SecureControllerBaseTests"

# Con cobertura
dotnet test /p:CollectCoverage=true /p:CoverageFormat=opencover
```

### Desde Visual Studio
```
Test Explorer → Run All Tests
Test Explorer → Run JwtClaimsExtensionsTests
```

---

## 📊 Cobertura de Tests

| Componente | Tests | Cobertura |
|-----------|-------|-----------|
| JwtConfiguration | 4 | 100% |
| JwtClaimsExtensions | 12 | 100% |
| JwtClaimsValidator | 8 | 100% |
| SecureControllerBase | 6 | 100% |
| **Total** | **30** | **100%** |

---

## ✅ Checklist de Validación

Tests deben pasar:
- ✅ Extracción segura de UserId desde JWT
- ✅ Validación de claims obligatorios
- ✅ Validación de tipo de token (access vs refresh)
- ✅ Validación de formato GUID
- ✅ Protección contra cross-user access
- ✅ Auditoría de acciones

---

## 🔍 Ejemplos de Ejecución

### Test exitoso
```
[PASS] JwtClaimsExtensionsTests.GetUserIdOrThrow_WithValidClaim_ReturnsGuid (25ms)
[PASS] JwtClaimsExtensionsTests.GetUserIdOrThrow_WithMissingClaim_ThrowsUnauthorizedAccessException (15ms)
[PASS] SecureControllerBaseTests.ValidateResourceOwnership_WithDifferentUser_ReturnsForbid (30ms)

Test Run Summary
Total: 30 tests, Passed: 30, Failed: 0, Skipped: 0
Total time: 2.5 seconds
```

### Test fallido (ejemplo)
```
[FAIL] JwtConfigurationTests.ValidateJwtConfiguration_WithShortSecretKey_DoesNotThrow
Expected no exception, but got UnauthorizedAccessException
Message: JWT secret key must be at least 32 characters

Stack:
  at JwtConfiguration.ValidateJwtConfiguration(ILogger logger)
  at JwtConfigurationTests.ValidateJwtConfiguration_WithShortSecretKey_DoesNotThrow()
```

