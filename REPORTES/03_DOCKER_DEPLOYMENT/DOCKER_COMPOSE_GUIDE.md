╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║            DOCKER-COMPOSE PRODUCTIVO: MIKROSERVICIOS AISLADOS              ║
║                                                                            ║
║           FinanSecure.Auth + FinanSecure.Transactions                      ║
║           Con bases de datos PostgreSQL aisladas y redes separadas          ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

═════════════════════════════════════════════════════════════════════════════════
📋 ÍNDICE
═════════════════════════════════════════════════════════════════════════════════

1. Explicación arquitectura
2. Servicios incluidos
3. Redes y aislamiento
4. Variables de entorno
5. Volúmenes y persistencia
6. Comandos de uso
7. Monitoreo y logs
8. Troubleshooting

═════════════════════════════════════════════════════════════════════════════════
1️⃣ EXPLICACIÓN ARQUITECTURA
═════════════════════════════════════════════════════════════════════════════════

### TOPOLOGÍA
```
┌─────────────────────────────────────────────────────────────────────────┐
│                          DOCKER-COMPOSE NETWORK                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  AUTH SERVICE DOMAIN                                             │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │                                                                  │  │
│  │  ┌─────────────────┐              ┌──────────────────┐          │  │
│  │  │ finansecure-auth│──────────────│ postgres-auth    │          │  │
│  │  │   (Port 8080)   │              │ (Port 5432)      │          │  │
│  │  │                 │              │                  │          │  │
│  │  │ .NET 8 Runtime  │              │ PostgreSQL 15    │          │  │
│  │  │ Health: /health │              │ User: auth_user  │          │  │
│  │  └────────┬────────┘              └──────────────────┘          │  │
│  │           │                                                      │  │
│  │        [auth-network bridge]                                    │  │
│  │                                                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                             ↓ (backend network)                         │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  TRANSACTIONS SERVICE DOMAIN                                     │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │                                                                  │  │
│  │  ┌──────────────────────┐      ┌──────────────────────┐         │  │
│  │  │finansecure-transactions│      │postgres-transactions │         │  │
│  │  │   (Port 8081)        │      │  (Port 5433)         │         │  │
│  │  │                      │      │                      │         │  │
│  │  │ .NET 8 Runtime       │      │ PostgreSQL 15        │         │  │
│  │  │ Health: /health      │      │ User: transactions_  │         │  │
│  │  │ Conectado a Auth API │      │ Password: ...        │         │  │
│  │  └──────────┬───────────┘      └──────────────────────┘         │  │
│  │             │                                                    │  │
│  │        [transactions-network bridge]                            │  │
│  │                                                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  PGADMIN (Optional - Gestión de ambas BDs)                      │  │
│  ├──────────────────────────────────────────────────────────────────┤  │
│  │  ┌────────────────────────────────────────────────────┐         │  │
│  │  │ pgAdmin (Port 5050)                                │         │  │
│  │  │ Acceso a ambas BDs via auth-network + trans-net   │         │  │
│  │  └────────────────────────────────────────────────────┘         │  │
│  │                                                                  │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
│  [backend network] ← Comunicación inter-servicios                       │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### CARACTERÍSTICAS CLAVE

✅ **Microservicios aislados**
   - Cada servicio tiene su propia BD
   - BDs en volúmenes separados
   - Redes privadas por dominio

✅ **Bases de datos independientes**
   - postgres-auth: Credenciales, usuarios, tokens
   - postgres-transactions: Transacciones, categorías, auditoría

✅ **Comunicación segura**
   - Backend network: inter-service communication
   - JWT tokens para autenticación
   - No acceso directo a BDs entre servicios

✅ **Producción-like**
   - Health checks en ambos servicios
   - Resource limits (CPU, memoria)
   - Logging estructurado
   - Volúmenes persistentes
   - Dependencias ordenadas

✅ **Fácil monitoreo**
   - pgAdmin accesible en puerto 5050
   - Logs separados por servicio
   - Health checks automáticos

═════════════════════════════════════════════════════════════════════════════════
2️⃣ SERVICIOS INCLUIDOS
═════════════════════════════════════════════════════════════════════════════════

### 🗄️  POSTGRES-AUTH (Base de datos Auth Service)
┌─────────────────────────────────────────────────────────────────────────┐
│ Servicio: postgres-auth                                                 │
│ Imagen: postgres:15-alpine                                              │
│ Container: finansecure-postgres-auth                                    │
│                                                                          │
│ PROPÓSITO:                                                              │
│ • Almacenar usuarios, credenciales, refresh tokens                     │
│ • Base de datos específica para autenticación                          │
│ • Aislada de datos de transacciones                                     │
│                                                                          │
│ CREDENCIALES:                                                           │
│ • Usuario: auth_user                                                   │
│ • Contraseña: ${AUTH_DB_PASSWORD} (variable de entorno)               │
│ • Base: ${AUTH_DB_NAME} (default: finansecure_auth_db)                │
│                                                                          │
│ PUERTO EXTERNO: ${AUTH_DB_PORT} (default: 5432)                       │
│ PUERTO INTERNO: 5432                                                    │
│                                                                          │
│ VOLUMEN: auth_db_data → ./data/auth_db/                               │
│ • Persiste datos entre reinicios                                       │
│ • Path: ./data/auth_db/ (crear carpeta)                                │
│                                                                          │
│ RED: auth-network (bridge)                                              │
│ • Aislada de Transactions Service                                      │
│ • Conecta: postgres-auth + finansecure-auth + pgadmin                 │
│                                                                          │
│ HEALTH CHECK:                                                           │
│ • Comando: pg_isready -U auth_user                                    │
│ • Intervalo: 10s                                                       │
│ • Timeout: 5s                                                          │
│ • Reintentos: 5                                                        │
│                                                                          │
│ LOGGING: json-file | max 10MB por archivo | max 3 archivos            │
│                                                                          │
│ VARIABLES CLAVE:                                                        │
│ • POSTGRES_USER: auth_user                                            │
│ • POSTGRES_PASSWORD: ${AUTH_DB_PASSWORD}                              │
│ • POSTGRES_INITDB_ARGS: encoding, locale, etc.                        │
│ • TZ: UTC                                                              │
└─────────────────────────────────────────────────────────────────────────┘

### 🗄️  POSTGRES-TRANSACTIONS (Base de datos Transactions Service)
┌─────────────────────────────────────────────────────────────────────────┐
│ Servicio: postgres-transactions                                         │
│ Imagen: postgres:15-alpine                                              │
│ Container: finansecure-postgres-transactions                            │
│                                                                          │
│ PROPÓSITO:                                                              │
│ • Almacenar transacciones, categorías, auditoría                       │
│ • Base de datos específica para finanzas                               │
│ • Completamente aislada de datos de autenticación                      │
│                                                                          │
│ CREDENCIALES:                                                           │
│ • Usuario: transactions_user                                           │
│ • Contraseña: ${TRANSACTIONS_DB_PASSWORD} (variable)                  │
│ • Base: ${TRANSACTIONS_DB_NAME} (default: finansecure_transactions_db)│
│                                                                          │
│ PUERTO EXTERNO: ${TRANSACTIONS_DB_PORT} (default: 5433)               │
│ PUERTO INTERNO: 5432                                                    │
│                                                                          │
│ VOLUMEN: transactions_db_data → ./data/transactions_db/               │
│ • Persiste datos entre reinicios                                       │
│ • Path: ./data/transactions_db/ (crear carpeta)                        │
│                                                                          │
│ RED: transactions-network (bridge)                                      │
│ • Aislada de Auth Service                                              │
│ • Conecta: postgres-transactions + finansecure-transactions + pgadmin │
│                                                                          │
│ HEALTH CHECK:                                                           │
│ • Comando: pg_isready -U transactions_user                            │
│ • Intervalo: 10s                                                       │
│ • Timeout: 5s                                                          │
│ • Reintentos: 5                                                        │
│                                                                          │
│ LOGGING: json-file | max 10MB por archivo | max 3 archivos            │
│                                                                          │
│ VARIABLES CLAVE:                                                        │
│ • POSTGRES_USER: transactions_user                                     │
│ • POSTGRES_PASSWORD: ${TRANSACTIONS_DB_PASSWORD}                      │
│ • POSTGRES_INITDB_ARGS: encoding, locale, etc.                        │
│ • TZ: UTC                                                              │
└─────────────────────────────────────────────────────────────────────────┘

### 🔐 FINANSECURE-AUTH (Microservicio de Autenticación)
┌─────────────────────────────────────────────────────────────────────────┐
│ Servicio: finansecure-auth                                              │
│ Imagen: Build from: FinanSecure.Auth/Dockerfile                         │
│ Container: finansecure-auth                                             │
│                                                                          │
│ PROPÓSITO:                                                              │
│ • Registro y login de usuarios                                         │
│ • Emisión de JWT tokens                                                │
│ • Validación de credenciales                                           │
│ • Gestión de refresh tokens                                            │
│                                                                          │
│ PUERTO: ${AUTH_SERVICE_PORT} (default: 8080)                          │
│                                                                          │
│ DEPENDENCIAS:                                                           │
│ • postgres-auth (service_healthy)                                      │
│                                                                          │
│ REDES:                                                                  │
│ • auth-network: Conecta con postgres-auth                              │
│ • backend: Comunicación con Transactions Service                       │
│                                                                          │
│ VARIABLES DE ENTORNO PRINCIPALES:                                      │
│ • ASPNETCORE_ENVIRONMENT: ${ENVIRONMENT:-Production}                   │
│ • ASPNETCORE_URLS: http://+:8080                                       │
│ • DB_HOST: postgres-auth (nombre del service)                          │
│ • DB_PORT: 5432                                                        │
│ • DB_DATABASE: ${AUTH_DB_NAME}                                         │
│ • DB_USER: auth_user                                                   │
│ • DB_PASSWORD: ${AUTH_DB_PASSWORD}                                     │
│ • JWT_SECRET_KEY: ${JWT_SECRET_KEY} (CRÍTICO: cambiar en prod)         │
│ • JWT_ISSUER: ${JWT_ISSUER}                                            │
│ • JWT_AUDIENCE: ${JWT_AUDIENCE}                                        │
│ • JWT_EXPIRATION_MINUTES: ${JWT_EXPIRATION_MINUTES}                   │
│ • JWT_REFRESH_EXPIRATION_DAYS: ${JWT_REFRESH_EXPIRATION_DAYS}         │
│ • LOG_LEVEL: ${AUTH_LOG_LEVEL}                                         │
│                                                                          │
│ HEALTH CHECK:                                                           │
│ • Comando: curl -f http://localhost:8080/health                       │
│ • Intervalo: 30s                                                       │
│ • Timeout: 10s                                                         │
│ • Reintentos: 3                                                        │
│ • Start period: 40s                                                    │
│                                                                          │
│ RECURSOS:                                                               │
│ • Límites: 1 CPU, 1 GB RAM                                            │
│ • Reservados: 0.5 CPU, 512 MB RAM                                     │
│                                                                          │
│ VOLÚMENES:                                                              │
│ • auth_logs → ./logs/auth/                                             │
│ • Captura logs de la aplicación                                        │
│                                                                          │
│ LOGGING: json-file | max 10MB | max 3 archivos                        │
└─────────────────────────────────────────────────────────────────────────┘

### 💰 FINANSECURE-TRANSACTIONS (Microservicio de Transacciones)
┌─────────────────────────────────────────────────────────────────────────┐
│ Servicio: finansecure-transactions                                      │
│ Imagen: Build from: FinanSecure.Transactions/Dockerfile                 │
│ Container: finansecure-transactions                                     │
│                                                                          │
│ PROPÓSITO:                                                              │
│ • Registrar transacciones financieras                                  │
│ • Gestionar categorías de gastos                                       │
│ • Calcular presupuestos y resúmenes                                    │
│ • Auditoría de cambios                                                 │
│                                                                          │
│ PUERTO: ${TRANSACTIONS_SERVICE_PORT} (default: 8081)                  │
│                                                                          │
│ DEPENDENCIAS:                                                           │
│ • postgres-transactions (service_healthy)                               │
│ • finansecure-auth (service_healthy)                                    │
│                                                                          │
│ REDES:                                                                  │
│ • transactions-network: Conecta con postgres-transactions               │
│ • backend: Comunicación con Auth Service                                │
│                                                                          │
│ VARIABLES DE ENTORNO PRINCIPALES:                                      │
│ • ASPNETCORE_ENVIRONMENT: ${ENVIRONMENT:-Production}                   │
│ • ASPNETCORE_URLS: http://+:8080                                       │
│ • DB_HOST: postgres-transactions                                        │
│ • DB_PORT: 5432                                                        │
│ • DB_DATABASE: ${TRANSACTIONS_DB_NAME}                                 │
│ • DB_USER: transactions_user                                           │
│ • DB_PASSWORD: ${TRANSACTIONS_DB_PASSWORD}                             │
│ • AUTH_SERVICE_URL: ${AUTH_SERVICE_URL}                               │
│ • JWT_SECRET_KEY: ${JWT_SECRET_KEY} (igual que Auth Service)           │
│ • JWT_ISSUER: ${JWT_ISSUER}                                            │
│ • JWT_AUDIENCE: ${JWT_AUDIENCE}                                        │
│ • LOG_LEVEL: ${TRANSACTIONS_LOG_LEVEL}                                 │
│                                                                          │
│ HEALTH CHECK:                                                           │
│ • Comando: curl -f http://localhost:8080/health                       │
│ • Intervalo: 30s                                                       │
│ • Timeout: 10s                                                         │
│ • Reintentos: 3                                                        │
│ • Start period: 40s                                                    │
│                                                                          │
│ RECURSOS:                                                               │
│ • Límites: 1 CPU, 1 GB RAM                                            │
│ • Reservados: 0.5 CPU, 512 MB RAM                                     │
│                                                                          │
│ VOLÚMENES:                                                              │
│ • transactions_logs → ./logs/transactions/                             │
│ • Captura logs de la aplicación                                        │
│                                                                          │
│ LOGGING: json-file | max 10MB | max 3 archivos                        │
│                                                                          │
│ ⚠️  IMPORTANTE:                                                          │
│ • Depende de Auth Service para validar tokens JWT                      │
│ • Usa misma JWT_SECRET_KEY que Auth Service                            │
│ • Conectado a Backend network para llamadas HTTP a Auth                │
└─────────────────────────────────────────────────────────────────────────┘

### 🔧 PGADMIN (Gestión de Bases de Datos)
┌─────────────────────────────────────────────────────────────────────────┐
│ Servicio: pgadmin                                                       │
│ Imagen: dpage/pgadmin4:7.8-alpine                                       │
│ Container: finansecure-pgadmin                                          │
│                                                                          │
│ PROPÓSITO:                                                              │
│ • Interfaz web para gestionar PostgreSQL                               │
│ • Visualizar tablas, ejecutar queries                                  │
│ • Backup/restore de bases de datos                                     │
│ • Monitoreo y análisis                                                 │
│                                                                          │
│ PUERTO: ${PGADMIN_PORT} (default: 5050)                               │
│ URL: http://localhost:5050/                                            │
│                                                                          │
│ CREDENCIALES:                                                           │
│ • Email: ${PGADMIN_EMAIL}                                              │
│ • Contraseña: ${PGADMIN_PASSWORD}                                      │
│                                                                          │
│ REDES:                                                                  │
│ • auth-network: Acceso a postgres-auth                                 │
│ • transactions-network: Acceso a postgres-transactions                  │
│ • backend: Red compartida                                              │
│                                                                          │
│ DEPENDENCIAS:                                                           │
│ • postgres-auth                                                        │
│ • postgres-transactions                                                 │
│                                                                          │
│ VOLUMEN: pgadmin_data → ./data/pgadmin/                               │
│                                                                          │
│ HEALTH CHECK:                                                           │
│ • Comando: wget --no-verbose --tries=1 --spider http://localhost/...  │
│ • Intervalo: 30s                                                       │
│ • Timeout: 10s                                                         │
│ • Reintentos: 3                                                        │
│                                                                          │
│ LOGGING: json-file | max 5MB | max 2 archivos                         │
│                                                                          │
│ CÓMO AGREGAR SERVIDORES EN PGADMIN:                                   │
│ 1. Acceder a http://localhost:5050/                                    │
│ 2. Login con credenciales                                              │
│ 3. Right-click "Servers" → Register → Server                          │
│ 4. Auth DB:                                                            │
│    • Hostname: postgres-auth                                           │
│    • Port: 5432                                                        │
│    • Username: auth_user                                               │
│    • Password: ${AUTH_DB_PASSWORD}                                     │
│ 5. Transactions DB:                                                    │
│    • Hostname: postgres-transactions                                    │
│    • Port: 5432                                                        │
│    • Username: transactions_user                                       │
│    • Password: ${TRANSACTIONS_DB_PASSWORD}                             │
└─────────────────────────────────────────────────────────────────────────┘

═════════════════════════════════════════════════════════════════════════════════
3️⃣ REDES Y AISLAMIENTO
═════════════════════════════════════════════════════════════════════════════════

### DISEÑO DE REDES

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        AUTH-NETWORK (bridge)                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  finansecure-auth ←──────→ postgres-auth                               │
│       ↓                                                                 │
│   pgadmin (opcional)                                                   │
│                                                                          │
│  • Aislada: No acceso desde Transactions Service                       │
│  • Bridge name: br-auth                                                 │
│  • IP range: 172.21.0.0/16 (por defecto)                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                   TRANSACTIONS-NETWORK (bridge)                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  finansecure-transactions ←──────→ postgres-transactions               │
│       ↓                                                                 │
│   pgadmin (opcional)                                                   │
│                                                                          │
│  • Aislada: No acceso desde Auth Service                               │
│  • Bridge name: br-transactions                                         │
│  • IP range: 172.22.0.0/16 (por defecto)                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                      BACKEND-NETWORK (bridge)                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  finansecure-auth ←──────→ finansecure-transactions                    │
│                                                                          │
│  • Comunicación inter-servicios: JWT validation, data queries          │
│  • Bridge name: br-backend                                              │
│  • IP range: 172.23.0.0/16 (por defecto)                              │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### MATRIZ DE CONECTIVIDAD

| Origen | Destino | Via | Propósito |
|--------|---------|-----|----------|
| finansecure-auth | postgres-auth | auth-network | Leer/escribir usuarios, tokens |
| finansecure-transactions | postgres-transactions | trans-network | Leer/escribir transacciones |
| finansecure-transactions | finansecure-auth | backend-network | Validar JWT tokens (HTTP) |
| pgadmin | postgres-auth | auth-network | Gestión de BD Auth |
| pgadmin | postgres-transactions | trans-network | Gestión de BD Transactions |
| **Host Local** | **Port 8080** | Exposed | Acceso a Auth API |
| **Host Local** | **Port 8081** | Exposed | Acceso a Transactions API |
| **Host Local** | **Port 5050** | Exposed | Acceso a pgAdmin |

### VENTAJAS DEL AISLAMIENTO

✅ Seguridad: Cada microservicio solo accede a su BD
✅ Escalabilidad: Cada servicio puede ser replicado independientemente
✅ Deployment: Cambios en Auth no afectan Transactions
✅ Debugging: Logs/errores aislados por servicio
✅ GDPR: Datos separados por dominio de negocio
✅ Compliance: Auditoría por servicio independiente

═════════════════════════════════════════════════════════════════════════════════
4️⃣ VARIABLES DE ENTORNO
═════════════════════════════════════════════════════════════════════════════════

### ARCHIVOS DE CONFIGURACIÓN

```
.env.example          ← Plantilla (NO modificar, es para documentación)
.env.production       ← Valores para Staging/Production
.env.local            ← Valores locales (desarrollo)
.env.staging          ← Valores para Staging
```

### CONFIGURACIÓN POR ARCHIVO

#### 1. .env.example (Plantilla - NO usar directamente)
```bash
# Copiar y renombrar según entorno:
cp .env.example .env.production
cp .env.example .env.staging
cp .env.example .env.local

# NUNCA commitear archivos .env (están en .gitignore)
```

#### 2. .env.production (Staging/Producción)
Contiene valores reales de producción.

**IMPORTANTE:** NO commitear a git. Almacenar en:
- AWS Secrets Manager
- Azure Key Vault
- HashiCorp Vault
- Gestión de secretos del orquestador

### VARIABLES CRÍTICAS

| Variable | Por Defecto | Producción | Notas |
|----------|-------------|------------|-------|
| ENVIRONMENT | Production | Production | Development/Staging/Production |
| JWT_SECRET_KEY | your-super-secure... | ⚠️ CAMBIAR | Mínimo 32 chars, random, seguro |
| AUTH_DB_PASSWORD | SecureAuth2024! | ⚠️ CAMBIAR | Contraseña fuerte |
| TRANSACTIONS_DB_PASSWORD | SecureTransactions... | ⚠️ CAMBIAR | Contraseña fuerte |
| PGADMIN_PASSWORD | AdminPassword2024! | ⚠️ CAMBIAR | Contraseña fuerte |
| AUTH_SERVICE_URL | http://finansecure-auth:8080 | Mismo | URL interna del servicio |
| JWT_ISSUER | FinanSecure | FinanSecure | Nombre del emisor JWT |
| JWT_AUDIENCE | FinanSecure.Client | FinanSecure.Client | Audiencia del token |

### GENERADOR DE JWT_SECRET_KEY SEGURO

```bash
# Generar clave aleatoria segura (32+ caracteres)
openssl rand -base64 32

# O Python:
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# O Con openssl (más largo):
openssl rand -hex 32
```

### USO DE VARIABLES EN docker-compose

```yaml
# Sintaxis de interpolación:
DB_PASSWORD: ${AUTH_DB_PASSWORD:-default_value}

# Cómo funciona:
# 1. Lee variable de .env file
# 2. Si no existe, usa valor por defecto (after :-)
# 3. Si no hay por defecto, error en docker-compose up

# Orden de búsqueda:
# 1. Variables de ambiente del sistema
# 2. Variables en archivo .env
# 3. Valor por defecto (en compose)
```

### CARGAR VARIABLES ESPECÍFICAS

```bash
# Usar .env.production
docker-compose --env-file .env.production up -d

# Usar .env.staging
docker-compose --env-file .env.staging up -d

# Usar .env (por defecto)
docker-compose up -d
```

═════════════════════════════════════════════════════════════════════════════════
5️⃣ VOLÚMENES Y PERSISTENCIA
═════════════════════════════════════════════════════════════════════════════════

### ESTRUCTURA DE CARPETAS

```
FinanSecure-unir/
├── docker-compose.yml
├── .env.production
├── .env.example
├── data/                          ← Volúmenes montados
│   ├── auth_db/                   ← BD Auth PostgreSQL
│   │   └── [archivos PostgreSQL]
│   ├── transactions_db/           ← BD Transactions PostgreSQL
│   │   └── [archivos PostgreSQL]
│   └── pgadmin/                   ← Configuración pgAdmin
│       └── [archivos pgAdmin]
├── logs/                          ← Logs de aplicaciones
│   ├── auth/                      ← Logs de Auth Service
│   │   └── [archivos .log]
│   └── transactions/              ← Logs de Transactions Service
│       └── [archivos .log]
└── FinanSecure.Auth/
    └── Dockerfile
```

### CREAR CARPETAS

```bash
# Crear estructura de volúmenes
mkdir -p data/auth_db
mkdir -p data/transactions_db
mkdir -p data/pgadmin
mkdir -p logs/auth
mkdir -p logs/transactions

# Permisos (si necesario)
chmod 755 data/auth_db data/transactions_db data/pgadmin
chmod 755 logs/auth logs/transactions
```

### DEFINICIÓN DE VOLÚMENES EN COMPOSE

```yaml
volumes:
  auth_db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/auth_db    # Path en host
  
  transactions_db_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/transactions_db
  
  pgadmin_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./data/pgadmin
```

### BACKUP Y RESTORE

```bash
# Backup manual de BD Auth
docker exec finansecure-postgres-auth \
  pg_dump -U auth_user finansecure_auth_db > backup_auth.sql

# Backup manual de BD Transactions
docker exec finansecure-postgres-transactions \
  pg_dump -U transactions_user finansecure_transactions_db > backup_trans.sql

# Restore desde backup
cat backup_auth.sql | docker exec -i finansecure-postgres-auth \
  psql -U auth_user finansecure_auth_db
```

### LIMPIEZA DE VOLÚMENES

```bash
# ⚠️  ELIMINA TODOS LOS DATOS
docker-compose down -v

# ⚠️  Elimina volumen específico
docker volume rm finansecure-unir_auth_db_data
```

═════════════════════════════════════════════════════════════════════════════════
6️⃣ COMANDOS DE USO
═════════════════════════════════════════════════════════════════════════════════

### INICIAR STACK

```bash
# Iniciar en background
docker-compose up -d

# Iniciar en foreground (ver logs en tiempo real)
docker-compose up

# Iniciar solo servicios específicos
docker-compose up -d postgres-auth finansecure-auth

# Iniciar con archivo .env específico
docker-compose --env-file .env.production up -d

# Compilar nuevamente (si cambió Dockerfile)
docker-compose up -d --build

# Compilar con BuildKit (más rápido)
DOCKER_BUILDKIT=1 docker-compose up -d --build
```

### PARAR STACK

```bash
# Parar todos los servicios
docker-compose down

# Parar sin eliminar volúmenes (preserva datos)
docker-compose down --remove-orphans

# Parar servicios específicos
docker-compose stop postgres-auth

# Parar y eliminar volúmenes (⚠️ ELIMINA DATOS)
docker-compose down -v
```

### VER ESTADO

```bash
# Listar todos los servicios
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f finansecure-auth

# Ver últimas 100 líneas
docker-compose logs -f --tail=100 finansecure-transactions

# Ver logs sin timestamps
docker-compose logs -f --no-log-prefix
```

### EJECUTAR COMANDOS

```bash
# Ejecutar comando en contenedor
docker-compose exec finansecure-auth curl http://localhost:8080/health

# Ejecutar bash
docker-compose exec postgres-auth bash

# Conectarse a psql (BD Auth)
docker-compose exec postgres-auth \
  psql -U auth_user -d finansecure_auth_db

# Conectarse a psql (BD Transactions)
docker-compose exec postgres-transactions \
  psql -U transactions_user -d finansecure_transactions_db
```

### ESCALA DE SERVICIOS

```bash
# ⚠️  No soportado para servicios con puertos fijos
# Razón: Conflicto de puertos si se replica

# Solución: Usar orquestador (Kubernetes, Docker Swarm)
# o balanceador de carga (Nginx, HAProxy)
```

### ACTUALIZAR SERVICIOS

```bash
# Actualizar imagen y reiniciar
docker-compose up -d --no-deps --build finansecure-auth

# Reiniciar servicio sin actualizar imagen
docker-compose restart finansecure-auth

# Eliminar y recrear contenedor
docker-compose up -d --no-deps --force-recreate finansecure-auth
```

═════════════════════════════════════════════════════════════════════════════════
7️⃣ MONITOREO Y LOGS
═════════════════════════════════════════════════════════════════════════════════

### VERIFICAR SALUD

```bash
# Health status de todos
docker-compose ps

# Health status detallado
docker inspect finansecure-auth | grep -A 5 '"Health"'

# Verificar endpoints
curl http://localhost:8080/health
curl http://localhost:8081/health

# Status de BDs
docker-compose exec postgres-auth pg_isready -U auth_user
docker-compose exec postgres-transactions pg_isready -U transactions_user
```

### ACCEDER A INTERFACES

```
Auth API:
  http://localhost:8080/swagger     (Swagger UI)
  http://localhost:8080/health      (Health Check)

Transactions API:
  http://localhost:8081/swagger     (Swagger UI)
  http://localhost:8081/health      (Health Check)

pgAdmin:
  http://localhost:5050/
  Email: admin@finansecure.com
  Password: AdminPassword2024!

Bases de Datos:
  Auth:           postgres-auth:5432
  Transactions:   postgres-transactions:5432
```

### LOGS Y DEBUGGING

```bash
# Logs de error completo
docker-compose logs finansecure-auth 2>&1 | grep -i error

# Logs en tiempo real (últimas líneas)
docker-compose logs -f --tail=50 finansecure-transactions

# Logs con timestamp
docker-compose logs --timestamps -f

# Guardar logs en archivo
docker-compose logs > all_logs.txt

# Ver logs de BD
docker-compose logs postgres-auth | head -50
```

═════════════════════════════════════════════════════════════════════════════════
8️⃣ TROUBLESHOOTING
═════════════════════════════════════════════════════════════════════════════════

### ❌ Error: "postgres-auth: name resolution failed"

**Causa:** El contenedor no puede resolver el nombre del servicio

**Soluciones:**
```bash
# 1. Verificar que los servicios están en la misma red
docker network inspect br-auth | grep "Containers"

# 2. Reiniciar docker-compose
docker-compose down
docker-compose up -d

# 3. Verificar nombre del service (debe coincidir con compose)
# En .yml: service name = postgres-auth
# En ENV: DB_HOST=postgres-auth
```

### ❌ Error: "Health check failed"

**Causa:** El servicio no responde a health check

**Soluciones:**
```bash
# 1. Ver logs detallados
docker-compose logs finansecure-auth

# 2. Aumentar start_period en compose
# start_period: 40s → 60s (dar más tiempo)

# 3. Verificar que el endpoint existe
docker-compose exec finansecure-auth \
  curl -v http://localhost:8080/health

# 4. Verificar conectividad a BD
docker-compose exec finansecure-auth \
  curl -v http://postgres-auth:5432/
```

### ❌ Error: "Port already in use"

**Causa:** Puerto 8080, 5432, etc. ya está en uso

**Soluciones:**
```bash
# 1. Cambiar puerto en .env
AUTH_SERVICE_PORT=8082  # cambiar de 8080 a 8082

# 2. Ver qué está usando el puerto
lsof -i :8080  # macOS/Linux
netstat -ano | findstr :8080  # Windows

# 3. Matar proceso que usa el puerto
kill -9 <PID>
```

### ❌ Error: "Volume mount failed"

**Causa:** Carpeta no existe o permisos incorrectos

**Soluciones:**
```bash
# 1. Crear carpetas
mkdir -p data/auth_db data/transactions_db logs/auth logs/transactions

# 2. Permisos
chmod 755 data/ logs/

# 3. Owner (si necesario)
chown -R 999:999 data/  # UID de PostgreSQL
```

### ❌ Conexión rechazada a BD

**Causa:** BD no está lista o credenciales incorrectas

**Soluciones:**
```bash
# 1. Verificar credenciales en .env
grep -E "AUTH_DB|TRANSACTIONS_DB" .env

# 2. Esperar a que BD esté lista
docker-compose logs postgres-auth | tail -20

# 3. Conectarse manualmente
docker-compose exec postgres-auth \
  psql -U auth_user -d finansecure_auth_db -c "SELECT 1;"
```

### ❌ Aplicación no conecta a Auth Service

**Causa:** Variables de entorno incorrectas o redes desconectadas

**Soluciones:**
```bash
# 1. Verificar ENV en Transactions
docker-compose exec finansecure-transactions \
  env | grep AUTH_SERVICE_URL

# 2. Probar conectividad
docker-compose exec finansecure-transactions \
  ##curl http://finansecure-auth:8080/health
  curl http://localhost:8080/health

# 3. Verificar que ambos están en "backend" network
docker network inspect br-backend | grep "Containers"
```

═════════════════════════════════════════════════════════════════════════════════
✅ CHECKLIST DE VALIDACIÓN
═════════════════════════════════════════════════════════════════════════════════

Después de `docker-compose up -d`:

- [ ] Todos los servicios están "Up"
  ```bash
  docker-compose ps
  ```

- [ ] Health checks están "healthy"
  ```bash
  docker-compose ps | grep healthy
  ```

- [ ] Auth API responde
  ```bash
  curl http://localhost:8080/health
  ```

- [ ] Transactions API responde
  ```bash
  curl http://localhost:8081/health
  ```

- [ ] Bases de datos están listas
  ```bash
  docker-compose logs postgres-auth | grep "ready to accept"
  docker-compose logs postgres-transactions | grep "ready to accept"
  ```

- [ ] Redes están conectadas
  ```bash
  docker network ls | grep br-
  ```

- [ ] Volúmenes tienen datos
  ```bash
  ls -la data/auth_db/
  ls -la data/transactions_db/
  ```

- [ ] pgAdmin accesible (opcional)
  ```bash
  curl -I http://localhost:5050/
  ```

═════════════════════════════════════════════════════════════════════════════════
📚 REFERENCIAS
═════════════════════════════════════════════════════════════════════════════════

Docker Compose Docs:
https://docs.docker.com/compose/

PostgreSQL Docker:
https://hub.docker.com/_/postgres

pgAdmin4:
https://hub.docker.com/r/dpage/pgadmin4

Microservices with Docker:
https://docs.docker.com/engine/examples/running_redis_service/

Network Modes:
https://docs.docker.com/network/

════════════════════════════════════════════════════════════════════════════════
Fecha: 30 de Diciembre de 2025
Ingeniero: DevOps Senior
Versión: 2.0 (Production-Ready)
Estado: ✅ READY FOR DEPLOYMENT
════════════════════════════════════════════════════════════════════════════════
