using FinanSecure.Auth.Data;
using FinanSecure.Auth.Interfaces;
using FinanSecure.Auth.Repositories;
using FinanSecure.Auth.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// ==============================
// Configuration
// ==============================
var jwtSecret = builder.Configuration["Jwt:SecretKey"]
    ?? throw new InvalidOperationException("Jwt:SecretKey is not configured");
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "FinanSecure.Auth";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "FinanSecure.App";

// ==============================
// Services Registration
// ==============================

// Database
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AuthContext>(options =>
    options.UseNpgsql(connectionString,
        npgsqlOptions => npgsqlOptions.MigrationsAssembly("FinanSecure.Auth")));

// Authentication & Authorization
builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret)),
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = true,
            ValidAudience = jwtAudience,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

// Repositories
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IRefreshTokenRepository, RefreshTokenRepository>();

// Services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IPasswordService, PasswordService>();

// Controllers
builder.Services.AddControllers();

// Swagger/OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "FinanSecure Auth Service API",
        Version = "v1.0.0",
        Description = "API de autenticación y autorización para FinanSecure",
        Contact = new Microsoft.OpenApi.Models.OpenApiContact
        {
            Name = "FinanSecure Team",
            Email = "support@finansecure.com"
        }
    });

    // Configurar seguridad en Swagger
    options.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Description = "Por favor introduzca JWT con el prefijo Bearer (ej: Bearer eyJhbGc...)",
        Name = "Authorization",
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey
    });

    options.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAngular", policy =>
    {
        policy
            // ✅ Permitir acceso desde NGINX/Frontend
            .WithOrigins(
                "http://localhost",           // Docker: NGINX en puerto 80
                "http://localhost:80",        // Explícitamente puerto 80
                "http://localhost:3000",      // Docker: Frontend desarrollo
                "http://localhost:4200",      // Desarrollo local Angular
                "http://localhost:4201",      // Desarrollo local Angular alt
                "http://finansecure-frontend" // Nombre DNS interno Docker
            )
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

// Logging
builder.Services.AddLogging(config =>
{
    config.AddConsole();
    config.AddDebug();
});

// ==============================
// Build App
// ==============================
var app = builder.Build();

// ==============================
// Middleware Pipeline
// ==============================

// Database Migration
// ✅ Ejecutar migraciones en TODOS los ambientes (Development, Staging, Production)
// EF Core crea la BD si no existe, luego aplica migraciones
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<AuthContext>();
    var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
    
    try
    {
        logger.LogInformation("🔄 Iniciando migraciones de base de datos...");
        dbContext.Database.Migrate();
        logger.LogInformation("✅ Migraciones completadas exitosamente");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "❌ Error durante la migración de base de datos");
        // En producción, es mejor fallar rápido
        if (!app.Environment.IsDevelopment())
        {
            throw;
        }
    }
}

// Swagger
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "FinanSecure Auth Service v1");
        options.RoutePrefix = string.Empty; // Disponible en raíz
    });
}

// HTTPS Redirect (disabled for local development)
// app.UseHttpsRedirection();

// CORS
app.UseCors("AllowAngular");

// Authentication & Authorization
app.UseAuthentication();
app.UseAuthorization();

// ==============================
// Health Check Endpoint
// ==============================
// Simple endpoint para Docker health checks
// Retorna 200 OK si la aplicación está corriendo
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
    .WithName("Health")
    .AllowAnonymous();

// Map Controllers
app.MapControllers();

// Custom middleware para manejo de errores (opcional pero recomendado)
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        var logger = app.Services.GetRequiredService<ILogger<Program>>();
        var exceptionHandlerPathFeature = context.Features.Get<Microsoft.AspNetCore.Diagnostics.IExceptionHandlerPathFeature>();
        var exception = exceptionHandlerPathFeature?.Error;

        logger.LogError(exception, "Unhandled exception");

        context.Response.ContentType = "application/json";
        context.Response.StatusCode = StatusCodes.Status500InternalServerError;

        await context.Response.WriteAsJsonAsync(new
        {
            success = false,
            message = "Error interno del servidor.",
            details = app.Environment.IsDevelopment() ? exception?.Message : null
        });
    });
});

// ==============================
// Run
// ==============================
app.Run();
