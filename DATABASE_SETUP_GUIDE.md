# 🚀 Database Setup Guide - FinanSecure Microservices

Guía completa para configurar las bases de datos PostgreSQL para ambos microservicios.

---

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Configuración de PostgreSQL](#configuración-de-postgresql)
3. [Crear Bases de Datos](#crear-bases-de-datos)
4. [Ejecutar Scripts SQL](#ejecutar-scripts-sql)
5. [Verificación](#verificación)
6. [Configuración en .NET](#configuración-en-net)
7. [Seeding de Datos](#seeding-de-datos)
8. [Troubleshooting](#troubleshooting)

---

## 📦 Requisitos Previos

### Sistema Operativo
- ✅ Windows, macOS, o Linux
- ✅ Docker (alternativa recomendada)

### PostgreSQL
- ✅ PostgreSQL 12+ (recomendado: 14 o 15)
- ✅ psql CLI tool (incluido en PostgreSQL)

### .NET
- ✅ .NET 8.0 SDK
- ✅ Visual Studio 2022 o VS Code

---

## 🐘 Configuración de PostgreSQL

### Opción 1: PostgreSQL Local (Recomendado para Desarrollo)

#### Windows
```powershell
# Descargar instalador desde https://www.postgresql.org/download/windows/
# Ejecutar instalador con:
# - Port: 5432 (default)
# - Password: postgres (su contraseña segura)
# - Componentes: PostgreSQL Server, pgAdmin 4, Command Line Tools

# Verificar instalación
psql --version
# Output: psql (PostgreSQL) 14.0 (or higher)
```

#### macOS (con Homebrew)
```bash
# Instalar
brew install postgresql@15

# Iniciar servicio
brew services start postgresql@15

# Verificar
psql --version
```

#### Linux (Ubuntu/Debian)
```bash
# Instalar
sudo apt update
sudo apt install postgresql-15 postgresql-contrib-15

# Iniciar servicio
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verificar
psql --version
```

### Opción 2: PostgreSQL en Docker (Recomendado)

```bash
# Crear contenedor PostgreSQL
docker run --name finansecure-postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_USER=postgres \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  -d postgres:15-alpine

# Verificar
docker ps | grep finansecure-postgres

# Conectar
psql -U postgres -h localhost
```

### Opción 3: Docker Compose (Más Fácil)

Crear archivo `docker-compose.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: finansecure-postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --lc-collate=C --lc-ctype=C"
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

Ejecutar:
```bash
# Iniciar
docker-compose up -d

# Verificar
docker-compose ps

# Conectar
psql -U postgres -h localhost
```

---

## 🗄️ Crear Bases de Datos

### Paso 1: Conectar a PostgreSQL

```bash
# Opción 1: Por línea de comandos
psql -U postgres -h localhost

# Opción 2: Con pgAdmin (interfaz gráfica)
# Acceder a http://localhost:5050 (si usas pgAdmin)

# Opción 3: Con VS Code + PostgreSQL extension
```

### Paso 2: Crear Bases de Datos Separadas

```sql
-- Conectado como postgres
-- Crear BD para Auth Service
CREATE DATABASE finansecure_auth_db_dev
  WITH ENCODING 'UTF8' 
  LOCALE 'en_US.UTF-8';

-- Crear BD para Transactions Service
CREATE DATABASE finansecure_transactions_db_dev
  WITH ENCODING 'UTF8' 
  LOCALE 'en_US.UTF-8';

-- Listar bases de datos
\l

-- Salir
\q
```

### Paso 3: Crear Usuarios (Opcional pero Recomendado)

```sql
-- Conectado como postgres

-- Usuario para Auth Service
CREATE USER auth_user WITH ENCRYPTED PASSWORD 'secure_password_1';
GRANT ALL PRIVILEGES ON DATABASE finansecure_auth_db_dev TO auth_user;

-- Usuario para Transactions Service
CREATE USER transactions_user WITH ENCRYPTED PASSWORD 'secure_password_2';
GRANT ALL PRIVILEGES ON DATABASE finansecure_transactions_db_dev TO transactions_user;

-- Listar usuarios
\du
```

---

## 📜 Ejecutar Scripts SQL

### Opción 1: Línea de Comandos (Recomendada)

```bash
# Auth Service
psql -U postgres -h localhost -d finansecure_auth_db_dev -f auth_service_schema.sql

# Transactions Service
psql -U postgres -h localhost -d finansecure_transactions_db_dev -f transactions_service_schema.sql

# Mostrar resultado
echo "Auth Service schema installed ✓"
echo "Transactions Service schema installed ✓"
```

### Opción 2: pgAdmin

1. Abrir pgAdmin (http://localhost:5050)
2. Conectar al servidor PostgreSQL
3. Click derecho en `finansecure_auth_db_dev` → Query Tool
4. Copiar contenido de `auth_service_schema.sql`
5. Ejecutar (F5)
6. Repetir para `transactions_service_schema.sql`

### Opción 3: VS Code + PostgreSQL Extension

1. Instalar extensión "PostgreSQL"
2. Crear conexión a `localhost:5432`
3. Click derecho en `finansecure_auth_db_dev` → Open in Query
4. Abrir archivo `auth_service_schema.sql`
5. Ejecutar (Ctrl+Shift+E)
6. Repetir para Transactions Service

### Opción 4: Script de Bash Automatizado

Crear `setup_databases.sh`:

```bash
#!/bin/bash

set -e  # Exit on error

DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"

echo "🚀 FinanSecure Database Setup"
echo "=============================="

# Auth Service
echo "📦 Installing Auth Service schema..."
psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d finansecure_auth_db_dev -f auth_service_schema.sql
echo "✅ Auth Service schema installed"

# Transactions Service
echo "📦 Installing Transactions Service schema..."
psql -U $DB_USER -h $DB_HOST -p $DB_PORT -d finansecure_transactions_db_dev -f transactions_service_schema.sql
echo "✅ Transactions Service schema installed"

echo ""
echo "🎉 All databases configured successfully!"
```

Ejecutar:
```bash
chmod +x setup_databases.sh
./setup_databases.sh
```

---

## ✅ Verificación

### Paso 1: Verificar Auth Service

```bash
# Conectar
psql -U postgres -h localhost -d finansecure_auth_db_dev

# Comandos de verificación
\dt auth.*              -- Ver tablas
\di auth.*              -- Ver índices
\dv auth.*              -- Ver vistas
\df auth.*              -- Ver funciones

# Listar tablas con detalles
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'auth'
ORDER BY table_name, ordinal_position;

-- Salir
\q
```

**Resultado esperado:**

```
Schema |       Name       | Type  | Owner
--------+------------------+-------+----------
 auth   | users            | table | postgres
 auth   | refresh_tokens   | table | postgres
 auth   | active_users     | view  | postgres
 auth   | active_sessions  | view  | postgres
```

### Paso 2: Verificar Transactions Service

```bash
# Conectar
psql -U postgres -h localhost -d finansecure_transactions_db_dev

# Ver tablas
\dt transactions.*

# Ver enums
SELECT enum_name, enum_range 
FROM information_schema.enums 
WHERE udt_schema = 'transactions';

# Ver estadísticas
SELECT 
    table_name,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||table_name)) AS size
FROM information_schema.tables
WHERE table_schema = 'transactions';
```

**Resultado esperado:**

```
        enum_name         |           enum_range
---------------------------+-------------------------------
 transaction_type          | {INCOME,EXPENSE,TRANSFER,...}
 transaction_status        | {PENDING,COMPLETED,...}
 audit_action              | {CREATE,UPDATE,DELETE,...}
```

### Paso 3: Test de Conexión

```bash
# Desde línea de comandos
psql -U postgres -h localhost -d finansecure_auth_db_dev -c "SELECT COUNT(*) FROM auth.users;"

# Resultado esperado
 count
-------
     0
(1 row)
```

---

## 🔧 Configuración en .NET

### Paso 1: Configurar Connection Strings

**FinanSecure.Auth/appsettings.Development.json:**

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=finansecure_auth_db_dev;Username=postgres;Password=postgres;Pooling=true;MaxPoolSize=20;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning"
    }
  }
}
```

**FinanSecure.Transactions/appsettings.Development.json:**

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=finansecure_transactions_db_dev;Username=postgres;Password=postgres;Pooling=true;MaxPoolSize=20;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning"
    }
  }
}
```

### Paso 2: Instalar EF Core

```bash
# En cada proyecto service

# Auth Service
cd FinanSecure.Auth
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Design

# Transactions Service
cd FinanSecure.Transactions
dotnet add package Microsoft.EntityFrameworkCore
dotnet add package Microsoft.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Design
```

### Paso 3: Crear DbContext (Usando SQL Schemas Existentes)

Opción A: Scaffold desde BD existente (Recomendado)

```bash
# Auth Service
cd FinanSecure.Auth
dotnet ef dbcontext scaffold "Host=localhost;Database=finansecure_auth_db_dev;Username=postgres;Password=postgres" Microsoft.EntityFrameworkCore.PostgreSQL -o Data/Entities --context AuthContext -f

# Transactions Service
cd FinanSecure.Transactions
dotnet ef dbcontext scaffold "Host=localhost;Database=finansecure_transactions_db_dev;Username=postgres;Password=postgres" Microsoft.EntityFrameworkCore.PostgreSQL -o Data/Entities --context TransactionsContext -f
```

Opción B: DbContext Manual (Más control)

```csharp
// FinanSecure.Auth/Data/AuthContext.cs
public class AuthContext : DbContext
{
    public AuthContext(DbContextOptions<AuthContext> options) : base(options) { }
    
    public DbSet<User> Users { get; set; }
    public DbSet<RefreshToken> RefreshTokens { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("auth");
        
        modelBuilder.Entity<User>()
            .HasKey(u => u.Id);
        
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Username)
            .IsUnique();
        
        modelBuilder.Entity<User>()
            .HasIndex(u => u.Email)
            .IsUnique();
        
        // Más configuraciones...
    }
}
```

### Paso 4: Registrar en Program.cs

```csharp
// FinanSecure.Auth/Program.cs
var builder = WebApplicationBuilder.CreateBuilder(args);

// Add DbContext
builder.Services.AddDbContext<AuthContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))
);

var app = builder.Build();
app.Run();
```

---

## 🌱 Seeding de Datos

### Crear Seed Function

```sql
-- auth_service_seed.sql
INSERT INTO auth.users (username, email, password_hash, is_active, email_verified)
VALUES 
    ('admin', 'admin@finansecure.com', '$2b$12$...', true, true),
    ('testuser', 'test@finansecure.com', '$2b$12$...', true, true);

-- transactions_service_seed.sql
INSERT INTO transactions.categories (user_id, name, description, color, icon, is_active)
VALUES 
    ((SELECT id FROM auth.users WHERE username = 'testuser'), 'Groceries', 'Food and groceries', '#FF6B6B', 'shopping-cart', true),
    ((SELECT id FROM auth.users WHERE username = 'testuser'), 'Utilities', 'Electric, water, gas', '#4ECDC4', 'zap', true),
    ((SELECT id FROM auth.users WHERE username = 'testuser'), 'Salary', 'Monthly salary', '#45B7D1', 'dollar-sign', true);
```

Ejecutar:
```bash
psql -U postgres -h localhost -d finansecure_auth_db_dev -f auth_service_seed.sql
psql -U postgres -h localhost -d finansecure_transactions_db_dev -f transactions_service_seed.sql
```

---

## 🔍 Troubleshooting

### Error: "Could not connect to server"

```bash
# Verificar que PostgreSQL está corriendo
psql --version

# Si usas Docker:
docker ps | grep postgres

# Si Docker no está corriendo:
docker-compose up -d
```

### Error: "database does not exist"

```sql
-- Verificar que las BDs existen
\l

-- Si no existen, crearlas
CREATE DATABASE finansecure_auth_db_dev;
CREATE DATABASE finansecure_transactions_db_dev;
```

### Error: "permission denied for schema auth"

```sql
-- Dar permisos al usuario
GRANT USAGE ON SCHEMA auth TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO postgres;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA auth TO postgres;

-- Mismo para transactions
GRANT USAGE ON SCHEMA transactions TO postgres;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA transactions TO postgres;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA transactions TO postgres;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA transactions TO postgres;
```

### Error: "extension uuid-ossp does not exist"

```sql
-- Crear extensión
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Verificar
SELECT * FROM pg_extension WHERE extname = 'uuid-ossp';
```

### Error: Connection String en .NET

```csharp
// ❌ INCORRECTO
"Host=localhost:5432;Database=..."

// ✅ CORRECTO
"Host=localhost;Port=5432;Database=..."
```

---

## 📊 Monitoreo

### Ver Procesos Activos

```sql
SELECT 
    pid,
    usename,
    application_name,
    state,
    query
FROM pg_stat_activity
WHERE datname IN ('finansecure_auth_db_dev', 'finansecure_transactions_db_dev');
```

### Tamaño de Bases de Datos

```sql
SELECT 
    datname,
    pg_size_pretty(pg_database_size(datname)) AS size
FROM pg_database
WHERE datname LIKE 'finansecure_%';
```

### Consultas Lentas

```sql
-- Habilitar query logging
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- Log queries > 1 segundo
SELECT pg_reload_conf();

-- Ver logs
tail -f /var/log/postgresql/postgresql.log
```

---

## 📝 Checklist Final

- ✅ PostgreSQL instalado y corriendo
- ✅ Bases de datos creadas
- ✅ Scripts SQL ejecutados
- ✅ Tablas, vistas, funciones verificadas
- ✅ Connection strings configurados
- ✅ EF Core instalado
- ✅ DbContext creado
- ✅ Datos de seed insertados
- ✅ Conexión desde .NET probada

---

## 🎓 Siguientes Pasos

1. **Crear Entity Models** (C#)
2. **Implementar Repositories**
3. **Escribir Unit Tests**
4. **Configurar CI/CD**
5. **Deploy a Producción**

¡Listo para desarrollar! 🚀

