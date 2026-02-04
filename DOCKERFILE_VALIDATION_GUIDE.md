# ✅ GUÍA DE VALIDACIÓN - Dockerfile FinanSecure.Auth

## 🎯 Checklist de Verificación

### Antes de hacer commit:

```bash
# 1. Verificar que el Dockerfile existe y es válido
ls -la FinanSecure.Auth/Dockerfile
file FinanSecure.Auth/Dockerfile

# 2. Verificar que .csproj existe
ls -la FinanSecure.Auth/FinanSecure.Auth.csproj

# 3. Verificar que .dockerignore está en raíz
ls -la .dockerignore

# 4. Sintaxis Dockerfile (si tienes hadolint)
hadolint FinanSecure.Auth/Dockerfile
```

---

## 🧪 Test Local: Windows (PowerShell)

### Paso 1: Build sin cache

```powershell
# Ir al directorio raíz del repo
cd c:\LProyectos\Unir\finansecure-tfe

# Build (sin cache para simular CI limpio)
docker build --no-cache -f FinanSecure.Auth/Dockerfile -t finansecure-auth:test .

# Debería ver:
# ✅ Step 1 : FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine
# ✅ Step 2 : WORKDIR /src
# ✅ Step 3 : COPY FinanSecure.Auth/FinanSecure.Auth.csproj...
# ✅ Step 4 : RUN dotnet restore...
# ✅ ... (sin errores)
# ✅ Successfully built <ID>
```

### Paso 2: Verificar imagen

```powershell
# Listar la imagen creada
docker images | findstr finansecure-auth

# Debe mostrar algo como:
# finansecure-auth        test        abc123...    200MB

# Examinar layers
docker history finansecure-auth:test
```

### Paso 3: Correr contenedor

```powershell
# Crear variable de conexión (cambiar valores)
$env:DB_CONNECTION = "Server=postgres-auth;Port=5432;Database=finansecure_auth_db;User Id=auth_user;Password=CHANGE_ME;"

# Correr
docker run --rm `
  -e ASPNETCORE_URLS=http://+:8080 `
  -e ConnectionStrings__DefaultConnection=$env:DB_CONNECTION `
  -e Jwt:SecretKey=test-secret-key-change-me-in-production `
  -p 8080:8080 `
  finansecure-auth:test

# Debería ver:
# info: Microsoft.Hosting.Lifetime[14]
#      Now listening on: http://[::]:8080
```

### Paso 4: Test de conectividad (en otra terminal PowerShell)

```powershell
# Esperar 5 segundos a que arranque
Start-Sleep -Seconds 5

# Test health
curl http://localhost:8080/ -ErrorAction SilentlyContinue

# Test endpoint (si existe)
curl http://localhost:8080/swagger -ErrorAction SilentlyContinue

# Parar el contenedor (Ctrl+C en la ventana anterior)
```

---

## 🧪 Test Local: Linux (WSL o Docker Desktop en Linux)

### Paso 1: Build sin cache

```bash
# Ir al directorio raíz
cd /mnt/c/LProyectos/Unir/finansecure-tfe  # WSL
# o simplemente
cd ~/finansecure-tfe  # Si está en Linux

# Build (sin cache)
docker build --no-cache -f FinanSecure.Auth/Dockerfile -t finansecure-auth:test .

# Debería ver:
# [1/5] FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine
# [2/5] WORKDIR /src
# [3/5] COPY FinanSecure.Auth/FinanSecure.Auth.csproj ...
# [4/5] RUN dotnet restore...
# => exporting to image
# => writing image sha256:...
# => naming to docker.io/library/finansecure-auth:test
```

### Paso 2: Verificar imagen

```bash
docker images | grep finansecure-auth
docker history finansecure-auth:test
```

### Paso 3: Correr contenedor

```bash
# Variables
DB_CONNECTION="Server=postgres-auth;Port=5432;Database=finansecure_auth_db;User Id=auth_user;Password=CHANGE_ME;"

# Correr
docker run --rm \
  -e ASPNETCORE_URLS=http://+:8080 \
  -e ConnectionStrings__DefaultConnection=$DB_CONNECTION \
  -e Jwt:SecretKey=test-secret-key-change-me-in-production \
  -p 8080:8080 \
  finansecure-auth:test

# Debería ver salida de ASP.NET Core
```

### Paso 4: Test (otra terminal)

```bash
# Esperar a que arranque
sleep 5

# Health check
curl http://localhost:8080/ -v

# Logs del contenedor
docker logs <container-id>
```

---

## 🐳 Test con Docker Compose

### Paso 1: Usar compose existente

El archivo `docker-compose.yml` ya está configurado. Agregar a la sección `services`:

```yaml
# Verificar que exista algo como:
services:
  # ... postgres-auth, etc.
  
  finansecure-auth:
    build:
      context: .
      dockerfile: FinanSecure.Auth/Dockerfile
    container_name: finansecure-auth
    ports:
      - "8080:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ConnectionStrings__DefaultConnection=Server=postgres-auth;Port=5432;Database=finansecure_auth_db;User Id=auth_user;Password=${AUTH_DB_PASSWORD}
      - Jwt:SecretKey=${JWT_SECRET_KEY}
    depends_on:
      postgres-auth:
        condition: service_healthy
    networks:
      - auth-network
```

### Paso 2: Build y test con compose

```bash
# Build (usa caché si es posible)
docker-compose build finansecure-auth

# Correr todo
docker-compose up -d

# Verificar que está corriendo
docker-compose ps

# Ver logs
docker-compose logs finansecure-auth

# Test
curl http://localhost:8080/

# Parar
docker-compose down
```

---

## 🔍 Validación de Errores Comunes

### Error 1: "COPY failed: file not found"

```
COPY failed: file not found in build context: FinanSecure.Auth/FinanSecure.Auth.csproj
```

**Causa:** El archivo no existe o ruta incorrecta

**Solución:**
```bash
# Verificar que existe
ls FinanSecure.Auth/FinanSecure.Auth.csproj  # Linux
dir FinanSecure.Auth\FinanSecure.Auth.csproj  # Windows

# Verificar rutas (case-sensitive en Linux)
# FinanSecure.Auth ≠ finansecure.auth
```

---

### Error 2: "dotnet restore failed"

```
error: Unable to load the service index for source https://api.nuget.org/v3/index.json
```

**Causa:** Sin conexión a internet o timeout

**Solución:**
```bash
# Verificar que Docker tiene internet
docker run --rm alpine ping google.com

# Aumentar timeout si está lento
docker build --build-arg BUILDKIT_INLINE_CACHE=1 ...
```

---

### Error 3: "dotnet build failed with MSBuild"

```
error : Microsoft.CSharp.RuntimeBinder
error : System.Reflection
```

**Causa:** Dependencia faltante en .csproj

**Solución:**
```bash
# Verificar .csproj (debe tener todas las PackageReference)
cat FinanSecure.Auth/FinanSecure.Auth.csproj

# Comparar con versión local que funciona
# Asegurar que versiones de paquetes sean compatibles
```

---

### Error 4: "ConnectionStrings__DefaultConnection not configured"

Este es un error esperado en runtime si no pasas las variables de entorno.

**Solución:**
```bash
docker run \
  -e ConnectionStrings__DefaultConnection="Server=localhost;..." \
  finansecure-auth:test
```

---

## 📊 Métricas Esperadas

### Tiempo de Build

| Escenario | Tiempo Esperado | Notas |
|-----------|-----------------|-------|
| Primera build (sin cache) | 5-10 min | Descarga SDK, dependencias |
| Segunda build (sin cambios) | 30 seg | Reutiliza layers |
| Build con código modificado | 1-2 min | Reutiliza restore layer |
| Build con .csproj modificado | 3-5 min | Invalida restore layer |

### Tamaño de Imagen

| Métrica | Valor | Descripción |
|---------|-------|-------------|
| Imagen final | 200 MB | aspnet:8.0-alpine base |
| SDK (descartado) | 900 MB | No entra en imagen final |
| Ahorrado | 700 MB | Multi-stage build |

### Layers

```bash
docker history finansecure-auth:test
```

Debe mostrar:
- `FROM aspnet:8.0-alpine` (~150 MB)
- `COPY --from=publish` (~50 MB)
- Otros layers (curl, usuario, labels)

Total: ~200 MB ✅

---

## 🚀 Validación en CI (GitHub Actions)

### Paso 1: Hacer commit local

```bash
git add FinanSecure.Auth/Dockerfile
git add DOCKERFILE_FIXES_EXPLANATION.md
git commit -m "fix: Dockerfile Auth independiente - sin .sln"
```

### Paso 2: Push a rama de prueba

```bash
git checkout -b test/dockerfile-fix
git push origin test/dockerfile-fix

# Crear PR en GitHub
# El pipeline en build-and-push.yml se ejecutará automáticamente
```

### Paso 3: Monitorear en GitHub

```
GitHub Actions → build-and-push.yml → Build and Push Auth Service

Debe ver:
✅ Checkout code
✅ Set build variables
✅ Configure AWS credentials
✅ Login to Amazon ECR
✅ Build and Push Auth Service
✅ Summary
```

### Paso 4: Validar ECR

```bash
# Una vez que push a main, verificar ECR
aws ecr describe-repositories --repository-names finansecure-auth

# Listar tags
aws ecr list-images --repository-name finansecure-auth
```

---

## 📋 Test Checklist Final

- [ ] Dockerfile compila localmente (Windows)
- [ ] Dockerfile compila localmente (Linux/WSL)
- [ ] Contenedor arranca sin errores
- [ ] Endpoint raíz responde (GET /)
- [ ] Variables de entorno se aplican correctamente
- [ ] No hay archivos innecesarios en la imagen
- [ ] Usuario es appuser (no root)
- [ ] HEALTHCHECK funciona
- [ ] GitHub Actions ejecuta exitosamente
- [ ] Imagen se pushea a ECR
- [ ] Imagen tiene tags correctos (sha + branch)

---

## 🔗 Referencias

- [Multi-stage builds docs](https://docs.docker.com/build/building/multi-stage/)
- [.NET Docker images](https://mcr.microsoft.com/en-us/product/dotnet/aspnet)
- [Docker best practices](https://docs.docker.com/develop/dev-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
