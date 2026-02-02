# FinanSecure Transactions Service - PostgreSQL Setup

Guía para configurar PostgreSQL para el Transactions Service.

## 📋 Requisitos

- PostgreSQL 12 o superior
- pgAdmin (opcional, para UI)
- psql (cliente PostgreSQL)

## 🐳 Opción 1: Docker (Recomendado)

### Crear contenedor PostgreSQL

```bash
docker run -d \
  --name finansecure-db \
  -e POSTGRES_DB=finansecure_transactions_db \
  -e POSTGRES_USER=finansecure_user \
  -e POSTGRES_PASSWORD=SecurePass123! \
  -e POSTGRES_INITDB_ARGS="-c max_connections=200" \
  -v finansecure-data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgres:15-alpine
```

### Verificar conexión

```bash
docker exec -it finansecure-db psql -U finansecure_user -d finansecure_transactions_db
```

## 🔧 Opción 2: PostgreSQL Local (Linux/Mac)

### Instalar PostgreSQL

```bash
# macOS
brew install postgresql@15

# Ubuntu/Debian
sudo apt-get install postgresql postgresql-contrib

# Iniciar servicio
sudo systemctl start postgresql
```

### Crear usuario y BD

```bash
# Conectarse como superuser
sudo -u postgres psql

# Dentro de psql:
CREATE DATABASE finansecure_transactions_db;
CREATE USER finansecure_user WITH PASSWORD 'SecurePass123!';
GRANT ALL PRIVILEGES ON DATABASE finansecure_transactions_db TO finansecure_user;
\q
```

## 🔧 Opción 3: PostgreSQL Windows

1. Descargar desde [postgresql.org](https://www.postgresql.org/download/windows/)
2. Ejecutar instalador
3. Establecer password para usuario `postgres`
4. Verificar puerto: 5432

```cmd
# Crear BD (Command Prompt como admin)
psql -U postgres -c "CREATE DATABASE finansecure_transactions_db;"
psql -U postgres -c "CREATE USER finansecure_user WITH PASSWORD 'SecurePass123!';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE finansecure_transactions_db TO finansecure_user;"
```

## ✅ Verificar Instalación

```bash
# Conectarse a la BD
psql -h localhost -U finansecure_user -d finansecure_transactions_db

# Dentro de psql, listar tablas
\dt

# Ver esquema
\d

# Salir
\q
```

## 📊 Explorar BD con pgAdmin

### Instalar pgAdmin (Docker)

```bash
docker run -d \
  --name pgadmin \
  -e PGADMIN_DEFAULT_EMAIL=admin@finansecure.com \
  -e PGADMIN_DEFAULT_PASSWORD=admin123 \
  -p 5050:80 \
  dpage/pgadmin4
```

### Acceder a pgAdmin
- URL: http://localhost:5050
- Email: admin@finansecure.com
- Password: admin123

### Conectar a BD
1. Right-click "Servers" → "Register" → "Server"
2. Name: `FinanSecure Transactions`
3. Host: `localhost` (o nombre del contenedor)
4. Port: `5432`
5. Username: `finansecure_user`
6. Password: `SecurePass123!`

## 🔄 Migraciones con Entity Framework

### Ver migraciones pendientes

```bash
cd FinanSecure.Transactions
dotnet ef migrations list
```

### Aplicar migraciones

```bash
dotnet ef database update
```

### Crear migración nueva

```bash
dotnet ef migrations add NombreMigracion -o Migrations
dotnet ef database update
```

### Revertir última migración

```bash
dotnet ef migrations remove
dotnet ef database update
```

## 📈 Copia de Seguridad

### Backup completo

```bash
# Docker
docker exec finansecure-db pg_dump -U finansecure_user finansecure_transactions_db > backup.sql

# Local
pg_dump -h localhost -U finansecure_user finansecure_transactions_db > backup.sql
```

### Restaurar desde backup

```bash
# Docker
docker exec -i finansecure-db psql -U finansecure_user finansecure_transactions_db < backup.sql

# Local
psql -h localhost -U finansecure_user finansecure_transactions_db < backup.sql
```

## 🔒 Configuración de Seguridad

### Archivo pg_hba.conf (conexiones)

```conf
# Permitir conexiones locales
local   finansecure_transactions_db   finansecure_user   md5

# Permitir conexiones remotas (cambiar según necesidad)
host    finansecure_transactions_db   finansecure_user   127.0.0.1/32   md5
```

### Cambiar contraseña

```bash
psql -U postgres
ALTER USER finansecure_user WITH PASSWORD 'NuevaContraseña123!';
\q
```

## 📊 Monitoreo

### Ver conexiones activas

```sql
SELECT datname, usename, application_name, state
FROM pg_stat_activity
WHERE datname = 'finansecure_transactions_db';
```

### Ver tamaño de BD

```sql
SELECT pg_size_pretty(pg_database_size('finansecure_transactions_db'));
```

### Ver estadísticas de tablas

```sql
SELECT schemaname, tablename, seq_scan, seq_tup_read, idx_scan
FROM pg_stat_user_tables
ORDER BY seq_scan DESC;
```

## 🚨 Troubleshooting

### Error: "Connection refused"

```bash
# Verificar si PostgreSQL está corriendo
docker ps  # Para Docker
sudo systemctl status postgresql  # Para Linux

# Iniciar si no está corriendo
docker start finansecure-db
sudo systemctl start postgresql
```

### Error: "role does not exist"

```bash
# Recrear usuario
sudo -u postgres psql
DROP USER IF EXISTS finansecure_user;
CREATE USER finansecure_user WITH PASSWORD 'SecurePass123!';
GRANT ALL PRIVILEGES ON DATABASE finansecure_transactions_db TO finansecure_user;
\q
```

### Error: "database does not exist"

```bash
# Listar BDs
psql -U postgres -l

# Crear BD
psql -U postgres -c "CREATE DATABASE finansecure_transactions_db;"
```

## 🔗 Connection String (appsettings.json)

```json
"ConnectionStrings": {
  "DefaultConnection": "Host=localhost;Port=5432;Database=finansecure_transactions_db;Username=finansecure_user;Password=SecurePass123!"
}
```

### Variables opcionales
```
Pooling=true;              // Activar pool de conexiones
MaxPoolSize=20;            // Máximo de conexiones
CommandTimeout=30;         // Timeout de comandos
```

## 📚 Recursos Útiles

- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
- [EF Core PostgreSQL](https://www.npgsql.org/efcore/)

---

**¡Listo!** PostgreSQL está configurado y listo para usarse con Transactions Service.
