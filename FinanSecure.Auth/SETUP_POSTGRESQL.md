# Configuración de PostgreSQL para FinanSecure.Auth

## Instalación de PostgreSQL

### En Windows (usando Chocolatey)
```powershell
choco install postgresql
```

### En macOS (usando Homebrew)
```bash
brew install postgresql@15
brew services start postgresql@15
```

### En Linux (Debian/Ubuntu)
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

## Crear Base de Datos

### Usando psql (línea de comandos)

```bash
# Conectarse como usuario postgres
psql -U postgres

# Crear base de datos
CREATE DATABASE finansecure_auth_db;
CREATE DATABASE finansecure_auth_db_dev;

# Crear usuario dedicado (opcional pero recomendado)
CREATE USER finanuser WITH PASSWORD 'securepassword123';

# Otorgar permisos
GRANT ALL PRIVILEGES ON DATABASE finansecure_auth_db TO finanuser;
GRANT ALL PRIVILEGES ON DATABASE finansecure_auth_db_dev TO finanuser;

# Salir
\q
```

### Usando pgAdmin (GUI)

1. Abrir pgAdmin
2. Click derecho en "Databases" → "Create" → "Database"
3. Nombre: `finansecure_auth_db`
4. Owner: (dejar por defecto)
5. Guardar

## Cadena de Conexión

### Producción
```
Host=localhost;Port=5432;Database=finansecure_auth_db;Username=postgres;Password=postgres;
```

### Desarrollo
```
Host=localhost;Port=5432;Database=finansecure_auth_db_dev;Username=postgres;Password=postgres;
```

### Con usuario dedicado
```
Host=localhost;Port=5432;Database=finansecure_auth_db;Username=finanuser;Password=securepassword123;
```

### Remota (en servidor)
```
Host=db.example.com;Port=5432;Database=finansecure_auth;Username=finanuser;Password=securepassword123;
```

## Actualizar appsettings.json

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=finansecure_auth_db;Username=postgres;Password=postgres;"
  }
}
```

## Ejecutar Migraciones

```bash
# Aplicar todas las migraciones (automático en Program.cs)
dotnet run

# O manualmente
dotnet ef database update

# Ver migraciones aplicadas
dotnet ef migrations list

# Revertir última migración
dotnet ef database update -1
```

## Verificar Creación de Tablas

```bash
psql -U postgres -d finansecure_auth_db

# Ver todas las tablas
\dt

# Ver estructura de tabla 'users'
\d users

# Ver índices
\di

# Salir
\q
```

## Tabla users

```sql
-- Estructura esperada
CREATE TABLE public.users (
    id uuid NOT NULL,
    username character varying(100) NOT NULL,
    email character varying(255) NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100) NOT NULL,
    password_hash text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone,
    last_login_at timestamp with time zone,
    CONSTRAINT pk_users PRIMARY KEY (id),
    CONSTRAINT ux_users_username UNIQUE (username),
    CONSTRAINT ux_users_email UNIQUE (email)
);

-- Índices
CREATE INDEX idx_users_username ON public.users (username);
CREATE INDEX idx_users_email ON public.users (email);
```

## Tabla refresh_tokens

```sql
CREATE TABLE public.refresh_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token character varying(500) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_agent character varying(500),
    ip_address character varying(45),
    CONSTRAINT pk_refresh_tokens PRIMARY KEY (id),
    CONSTRAINT fk_refresh_tokens_users FOREIGN KEY (user_id)
        REFERENCES public.users (id) ON DELETE CASCADE
);

-- Índices
CREATE INDEX idx_refresh_tokens_user_id_token ON public.refresh_tokens (user_id, token);
```

## Backup y Restauración

### Backup (dump)
```bash
# Toda la base de datos
pg_dump -U postgres -h localhost finansecure_auth_db > backup.sql

# Solo estructura (sin datos)
pg_dump -U postgres -h localhost --schema-only finansecure_auth_db > schema.sql

# Solo datos (sin estructura)
pg_dump -U postgres -h localhost --data-only finansecure_auth_db > data.sql
```

### Restauración
```bash
# Restaurar desde backup
psql -U postgres -h localhost finansecure_auth_db < backup.sql

# Restaurar en nueva DB
createdb -U postgres finansecure_auth_db_restored
psql -U postgres -h localhost finansecure_auth_db_restored < backup.sql
```

## Conexión desde .NET

```csharp
// En Program.cs
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");

builder.Services.AddDbContext<AuthContext>(options =>
    options.UseNpgsql(connectionString,
        npgsqlOptions => npgsqlOptions.MigrationsAssembly("FinanSecure.Auth")));
```

## Troubleshooting

### Error: "connection refused"
```bash
# Verificar que PostgreSQL esté corriendo
sudo systemctl status postgresql

# Reiniciar si es necesario
sudo systemctl restart postgresql
```

### Error: "authentication failed"
- Verificar usuario y contraseña en cadena de conexión
- Verificar que el usuario existe: `\du` en psql

### Error: "database does not exist"
```bash
# Crear la BD
createdb -U postgres finansecure_auth_db
```

### Error: "role does not exist"
```bash
psql -U postgres

-- Crear usuario
CREATE USER finanuser WITH PASSWORD 'password';

-- Dar permisos
GRANT CREATE ON DATABASE postgres TO finanuser;
```

## Herramientas Útiles

- **pgAdmin**: GUI para PostgreSQL (recomendado)
- **DBeaver**: Cliente universal de BD
- **psql**: Cliente línea de comandos
- **pgBackRest**: Backup avanzado

## Scripts de Inicialización

### init-db.sql
```sql
-- Crear bases de datos
CREATE DATABASE finansecure_auth_db;
CREATE DATABASE finansecure_auth_db_dev;

-- Crear usuario
CREATE USER finanuser WITH PASSWORD 'securepassword123';

-- Otorgar permisos
GRANT ALL PRIVILEGES ON DATABASE finansecure_auth_db TO finanuser;
GRANT ALL PRIVILEGES ON DATABASE finansecure_auth_db_dev TO finanuser;

-- Conectarse a la DB
\c finansecure_auth_db

-- Otorgar permisos sobre schemas
GRANT ALL PRIVILEGES ON SCHEMA public TO finanuser;

-- Permitir creación de tablas
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO finanuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO finanuser;
```

Ejecutar:
```bash
psql -U postgres -f init-db.sql
```
