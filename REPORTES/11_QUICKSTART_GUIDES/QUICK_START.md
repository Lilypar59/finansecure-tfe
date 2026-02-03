# 🚀 Quick Start: FinanSecure con Docker Compose

## ⚡ Inicio Rápido (5 minutos)

### Paso 1: Verificar requisitos
```bash
# Verificar Docker está instalado
docker --version
# Docker version 20.10.0+

# Verificar Docker Compose está instalado
docker-compose --version
# Docker Compose version 2.0.0+
```

### Paso 2: Clonar/Navegar al proyecto
```bash
cd /ruta/a/FinanSecure-unir
ls -la
# Debería ver: docker-compose.yml, .env.example, finansecure-web/, etc.
```

### Paso 3: Crear archivo .env
```bash
# Copiar ejemplo a .env
cp .env.example .env

# Verificar contenido (valores por defecto están bien para DEV)
cat .env
```

### Paso 4: Levantar servicios
```bash
# Opción A: Construir e iniciar (primera vez)
docker-compose up -d --build

# Opción B: Solo iniciar (si ya está construido)
docker-compose up -d
```

### Paso 5: Esperar que todo esté listo
```bash
# Ver estado
docker-compose ps

# Debería mostrar (STATUS = healthy o running):
# CONTAINER ID   IMAGE                             STATUS
# xxxxxx         finansecure-unir_finansecure-frontend   healthy
# xxxxxx         finansecure-unir_finansecure-auth       healthy
# xxxxxx         postgres:15-alpine                healthy
```

### Paso 6: Acceder a la aplicación
```bash
# Frontend (Angular)
# Abrir navegador en: http://localhost
# O: http://localhost:80

# Login con:
#   Username: demo
#   Password: Demo@1234
#
#   O: admin / Admin@1234
#   O: user / User@1234

# PgAdmin (Gestor de BD)
# Abrir navegador en: http://localhost:5050
#   Email: admin@finansecure.com
#   Password: AdminPassword2024!
```

---

## 🧪 Verificar que todo funciona

### Verificación 1: NGINX está sirviendo
```bash
curl http://localhost/
# Debería retornar HTML de Angular con <app-root></app-root>
```

### Verificación 2: API proxy funciona
```bash
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "demo",
    "password": "Demo@1234"
  }'

# Respuesta esperada:
# {
#   "success": true,
#   "accessToken": "eyJhbGc...",
#   "refreshToken": "eyJhbGc...",
#   "expiresIn": 900,
#   "user": {
#     "id": "...",
#     "username": "demo",
#     "email": "demo@finansecure.com"
#   }
# }
```

### Verificación 3: CORS headers presentes
```bash
curl -i -X OPTIONS http://localhost/api/v1/auth/login

# Debería incluir:
# Access-Control-Allow-Origin: http://localhost
# Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
# Access-Control-Allow-Headers: Content-Type, Authorization
```

### Verificación 4: Base de datos funciona
```bash
# Conectar a PostgreSQL
docker exec -it finansecure-postgres-auth psql \
  -U auth_user \
  -d finansecure_auth_db \
  -c "SELECT * FROM users;"

# Debería mostrar 3 usuarios:
# demo, admin, user
```

---

## 📚 Comandos Útiles

### Logs
```bash
# Ver todos los logs
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f finansecure-auth
docker-compose logs -f finansecure-frontend
docker-compose logs -f postgres-auth

# Ver logs sin seguir (histórico)
docker-compose logs --tail=100
```

### Estado
```bash
# Ver estado de todos los servicios
docker-compose ps

# Ver estadísticas de contenedores (CPU, memoria)
docker stats

# Verificar health
docker-compose ps | grep -E "healthy|unhealthy"
```

### Control
```bash
# Parar servicios (sin eliminar)
docker-compose stop

# Reiniciar servicios
docker-compose restart

# Parar y eliminar contenedores (pero mantiene volúmenes)
docker-compose down

# Parar, eliminar y limpiar volúmenes (resets todo)
docker-compose down -v

# Reiniciar un servicio específico
docker-compose restart finansecure-auth
```

### Database
```bash
# Entrar a PostgreSQL
docker exec -it finansecure-postgres-auth psql \
  -U auth_user \
  -d finansecure_auth_db

# Dentro de psql:
\dt                     # Ver tablas
SELECT * FROM users;    # Ver usuarios
\q                      # Salir

# Ejecutar SQL directo
docker exec finansecure-postgres-auth psql \
  -U auth_user \
  -d finansecure_auth_db \
  -c "SELECT username, email FROM users;"
```

### Debugging
```bash
# Entrar a un contenedor con bash
docker exec -it finansecure-auth bash
docker exec -it finansecure-frontend /bin/sh

# Verificar conectividad entre contenedores
docker exec finansecure-frontend ping finansecure-auth:8080
docker exec finansecure-auth ping postgres-auth:5432

# Ver configuración de NGINX en el contenedor
docker exec finansecure-frontend nginx -T

# Verificar que puerto está escuchando
docker exec finansecure-auth netstat -tlnp | grep 8080
```

---

## 🆘 Troubleshooting Rápido

### Problema: "Connection refused" al login
**Solución:**
```bash
# 1. Verificar que Auth Service esté running
docker-compose ps | grep finansecure-auth

# 2. Ver logs del Auth Service
docker-compose logs finansecure-auth | tail -50

# 3. Esperar health check
sleep 10

# 4. Reiniciar
docker-compose restart finansecure-auth
```

### Problema: "502 Bad Gateway" en /api
**Solución:**
```bash
# 1. Verificar que NGINX tiene ruta /api configurada
docker exec finansecure-frontend nginx -T | grep -A 5 "location /api"

# 2. Verificar que Auth Service está accesible desde NGINX
docker exec finansecure-frontend curl http://finansecure-auth:8080/health

# 3. Recargar NGINX
docker exec finansecure-frontend nginx -s reload
```

### Problema: Base de datos vacía (sin tabla users)
**Solución:**
```bash
# 1. Eliminar volumen
docker-compose down -v

# 2. Recrear
docker-compose up -d --build

# 3. Esperar a que init-db.sql se ejecute (~20 segundos)
sleep 20

# 4. Verificar
docker exec finansecure-postgres-auth psql \
  -U auth_user \
  -d finansecure_auth_db \
  -c "SELECT * FROM users;"
```

### Problema: Puerto ya está en uso
```bash
# Encontrar qué proceso está usando el puerto
lsof -i :80
lsof -i :5050

# Matar el proceso
kill -9 <PID>

# O cambiar el puerto en .env
# FRONTEND_PORT=8000 (en lugar de 80)
```

### Problema: "Permission denied" en scripts
```bash
# Dar permisos de ejecución
chmod +x validate-architecture.sh
bash validate-architecture.sh
```

---

## 📦 Estructura de Directorios

```
FinanSecure-unir/
├── docker-compose.yml              ← ✅ ACTUALIZADO
├── .env.example                     ← Copiar a .env
├── init-db.sql                      ← Script de inicialización
├── validate-architecture.sh         ← ✅ Script de validación
├── DOCKER_COMPOSE_GUIDE.md         ← ✅ Guía completa
├── DOCKER_COMPOSE_CHANGES.md       ← ✅ Resumen de cambios
├── ARQUITECTURA_DEVOPS.md          ← ✅ Explicación arquitectura
│
├── finansecure-web/                 ← Frontend (Angular)
│   ├── Dockerfile.prod
│   ├── nginx.conf                   ← Configuración NGINX
│   ├── src/
│   │   └── app/
│   │       └── config/
│   │           └── api.config.ts    ← Configuración de URLs API
│   └── dist/                        ← Compilado (npm run build)
│
├── FinanSecure.Auth/                ← Backend (Auth Service)
│   ├── Dockerfile
│   ├── Program.cs                   ← Configuración .NET
│   ├── appsettings.json
│   └── appsettings.Development.json
│
└── FinanSecure.Transactions/        ← Backend (Transactions - deshabilitado)
    └── ...
```

---

## 🔑 Variables de Entorno Importantes

```bash
# .env file

# Entorno (Development o Production)
ENVIRONMENT=Development

# Puertos
FRONTEND_PORT=80                     # ← Puerto de NGINX (cambiar a 443 en PROD)
AUTH_SERVICE_PORT=8080              # ← Puerto de Auth (comentar en PROD)
AUTH_DB_PORT=5432                   # ← Puerto de PostgreSQL (comentar en PROD)

# Credenciales Database
AUTH_DB_PASSWORD=SecureAuth2024!    # ← CAMBIAR EN PRODUCCIÓN

# JWT
JWT_SECRET_KEY=your-secret-key-min-32-chars-change-in-prod
JWT_ISSUER=FinanSecure
JWT_AUDIENCE=FinanSecure.Client
JWT_EXPIRATION_MINUTES=15
JWT_REFRESH_EXPIRATION_DAYS=7

# Logging
AUTH_LOG_LEVEL=Information          # Verbose, Information, Warning, Error

# PgAdmin
PGADMIN_EMAIL=admin@finansecure.com
PGADMIN_PASSWORD=AdminPassword2024! # ← CAMBIAR EN PRODUCCIÓN
PGADMIN_PORT=5050
```

---

## 🔐 Usuarios de Test Incluidos

| Username | Password | Email | Rol |
|----------|----------|-------|-----|
| demo | Demo@1234 | demo@finansecure.com | User |
| admin | Admin@1234 | admin@finansecure.com | Admin |
| user | User@1234 | user@finansecure.com | User |

---

## 📊 URLs de Acceso

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **Frontend (Angular)** | http://localhost | demo/Demo@1234 |
| **Auth API** | http://localhost:8080 | - |
| **PgAdmin** | http://localhost:5050 | admin@finansecure.com / AdminPassword2024! |

---

## ✅ Checklist: Verificación Final

```
Antes de reportar un problema, verificar:

[ ] ¿Docker y Docker Compose están instalados?
    docker --version
    docker-compose --version

[ ] ¿El archivo .env existe?
    ls -la .env

[ ] ¿Todos los servicios están running?
    docker-compose ps

[ ] ¿NGINX está healthy?
    curl http://localhost/

[ ] ¿Auth Service está accessible?
    curl http://localhost:8080/health

[ ] ¿Base de datos tiene datos?
    docker exec finansecure-postgres-auth psql -U auth_user -d finansecure_auth_db -c "SELECT * FROM users;"

[ ] ¿Login funciona?
    curl -X POST http://localhost/api/v1/auth/login ...

[ ] ¿Navegador no tiene cache?
    Presionar Ctrl+Shift+Delete (limpiar caché)

Si todo es ✅, la aplicación está lista para usar.
Si algo falla ❌, revisar logs:
    docker-compose logs -f [servicio]
```

---

## 🎓 Próximos Pasos

1. **Verificar que funciona:**
   ```bash
   docker-compose up -d --build
   sleep 30
   curl http://localhost/api/v1/auth/login -X POST -H "Content-Type: application/json" -d '{"username":"demo","password":"Demo@1234"}'
   ```

2. **Abrir navegador:**
   - http://localhost
   - Login con demo/Demo@1234
   - Ver dashboard

3. **Debuggear si es necesario:**
   - `docker-compose logs -f`
   - Ver sección Troubleshooting arriba

4. **Leer documentación:**
   - [DOCKER_COMPOSE_GUIDE.md](DOCKER_COMPOSE_GUIDE.md) - Guía completa
   - [ARQUITECTURA_DEVOPS.md](ARQUITECTURA_DEVOPS.md) - Explicación arquitectura

---

**¡Listo! La aplicación está lista para usar.**

Fecha: 4 de Enero, 2026
Versión: 1.0
