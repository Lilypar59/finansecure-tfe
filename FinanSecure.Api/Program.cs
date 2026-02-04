using FinanSecure.Api.Data;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// ------------------------------
// Services
// ------------------------------

builder.Services.AddControllers();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// EF Core + MySQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<FinanSecureContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));

// CORS (opcional)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAngular", policy =>
    {
        policy
            .WithOrigins("http://localhost:4200")
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var app = builder.Build();

// ------------------------------
// Middleware
// ------------------------------

app.UseSwagger();
app.UseSwaggerUI();

// HTTPS
//app.UseHttpsRedirection();

// CORS
app.UseCors("AllowAngular");

app.UseAuthorization();

// Endpoint raíz simple
app.MapGet("/", () => Results.Json(new { message = "FinanSecure API running" }));

// Controladores
app.MapControllers();

app.Run();
