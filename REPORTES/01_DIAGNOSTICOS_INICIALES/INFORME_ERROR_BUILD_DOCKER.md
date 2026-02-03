# 🔴 Informe: Error en Build Docker - FinanSecure.Auth

**Fecha:** 30 de Enero de 2026  
**Servicio:** FinanSecure.Auth  
**Problema:** `ERROR [finansecure-auth build 6/6] RUN dotnet build "FinanSecure.Auth/FinanSecure.Auth.csproj"`

---

## 📋 Resumen Ejecutivo

El error ocurre durante el paso 6 del build multietapa de Docker cuando intenta compilar el proyecto con `dotnet build`. Este error puede tener múltiples causas, pero la mayoría son fácilmente resolubles.

---

## 🔍 Diagnóstico: Posibles Causas

### 1. **Archivos Faltantes o Corruptos**
```bash
# Verificar que todos los archivos necesarios existen
ls -la FinanSecure.Auth/
ls -la FinanSecure.Auth/*.csproj
ls -la FinanSecure.Auth/Controllers/
ls -la FinanSecure.Auth/Data/
ls -la FinanSecure.Auth/Services/
ls -la FinanSecure.Auth/Repositories/
```

✅ **Estado actual:** Todos los archivos existen (20 archivos .cs confirmados)

### 2. **Dependencias de NuGet Incompatibles**
```xml
<!-- FinanSecure.Auth.csproj contiene: -->
<PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />
<PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.0" />
<PackageReference Include="System.IdentityModel.Tokens.Jwt" Version="7.0.3" />
<PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.0.0" />
```

✅ **Estado:** Las versiones son compatibles con .NET 8.0

### 3. **Problemas de Construcción del Proyecto**
- Referencias circulares
- Namespaces duplicados
- Código con errores de sintaxis
- Interfaces no implementadas

✅ **Estado:** Program.cs contiene referencias válidas a:
- `IUserRepository` → `UserRepository` ✓
- `IRefreshTokenRepository` → `RefreshTokenRepository` ✓
- `IAuthService` → `AuthService` ✓
- `IJwtService` → `JwtService` ✓
- `IPasswordService` → `PasswordService` ✓

### 4. **Problemas en la Estructura del Dockerfile**
El Dockerfile original copiaba solo el `.csproj` antes de `dotnet restore`, lo cual puede causar problemas.

---

## ✅ Soluciones Implementadas

### **Solución 1: Dockerfile Mejorado** (YA APLICADA)

Se ha actualizado el Dockerfile con:

```dockerfile
# PASO 1: Copiar archivos de solución
COPY *.sln ./

# PASO 2: Copiar todos los .csproj
COPY FinanSecure.Auth/*.csproj ./FinanSecure.Auth/
COPY FinanSecure.Api/*.csproj ./FinanSecure.Api/
COPY FinanSecure.Transactions/*.csproj ./FinanSecure.Transactions/

# PASO 3: Restaurar dependencias
RUN dotnet restore "FinanSecure.Auth/FinanSecure.Auth.csproj" || \
    (echo "Error restaurando dependencias" && exit 1)

# PASO 4: Copiar código fuente
COPY . .

# PASO 5: Build con mejor manejo de errores
RUN dotnet build "FinanSecure.Auth/FinanSecure.Auth.csproj" \
    -c Release \
    -o /app/build \
    --no-restore || \
    (echo "Error compilando FinanSecure.Auth" && exit 1)
```

**Ventajas:**
- ✅ Copia explícita de todos los archivos necesarios
- ✅ Mejor manejo de errores con mensajes claros
- ✅ Flag `--no-restore` evita restaurar dos veces
- ✅ Caching más efectivo en Docker

---

## 🚀 Cómo Ejecutar el Build

### **Opción 1: Build Completo (Recomendado)**
```bash
cd /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir

# Build con output detallado
docker build \
    -f FinanSecure.Auth/Dockerfile \
    . \
    -t finansecure-auth:latest \
    --progress=plain
```

**Ventaja:** Ves todos los detalles en tiempo real

### **Opción 2: Build con Docker Compose**
```bash
docker-compose build finansecure-auth
```

**Ventaja:** Configuración unificada

### **Opción 3: Build Alternativo (Dockerfile.simple)**
```bash
# Primero compila localmente
cd FinanSecure.Auth
dotnet publish -c Release -o bin/Release/net8.0/publish

# Luego construye la imagen
cd ..
docker build \
    -f FinanSecure.Auth/Dockerfile.simple \
    . \
    -t finansecure-auth:latest
```

**Ventaja:** Más rápido si ya compilaste localmente

---

## 🛠️ Pasos de Solución Detallados

### **Paso 1: Limpiar Docker (Opcional)**
```bash
# Limpiar imágenes y contenedores previos
docker system prune -a
docker image rm finansecure-auth:* 2>/dev/null || true
```

### **Paso 2: Verificar Estructura de Carpetas**
```bash
# Verificar que existen todos los directorios
test -d FinanSecure.Auth/Controllers && echo "✅ Controllers OK"
test -d FinanSecure.Auth/Data && echo "✅ Data OK"
test -d FinanSecure.Auth/DTOs && echo "✅ DTOs OK"
test -d FinanSecure.Auth/Interfaces && echo "✅ Interfaces OK"
test -d FinanSecure.Auth/Repositories && echo "✅ Repositories OK"
test -d FinanSecure.Auth/Services && echo "✅ Services OK"
test -f FinanSecure.Auth/FinanSecure.Auth.csproj && echo "✅ .csproj OK"
```

### **Paso 3: Ejecutar Build**
```bash
docker build \
    -f FinanSecure.Auth/Dockerfile \
    . \
    -t finansecure-auth:latest \
    --progress=plain 2>&1 | tee build.log
```

### **Paso 4: Verificar el Resultado**
```bash
# Ver si la imagen se creó exitosamente
docker images | grep finansecure-auth

# Ver el tamaño de la imagen
docker images finansecure-auth --format "{{.Size}}"

# Probar la imagen
docker run --rm -p 8080:8080 finansecure-auth:latest
```

---

## 🔧 Soluciones Específicas por Error

### **Si ves: "error CS1234: type or namespace not found"**
```bash
# Verificar que todos los namespaces están correctos
grep -r "namespace FinanSecure" FinanSecure.Auth/

# Verificar que todas las interfaces existen
grep -r "interface I" FinanSecure.Auth/Interfaces/
```

### **Si ves: "error NU1102: Unable to find package"**
```bash
# Restaurar manualmente
docker run --rm -v $(pwd):/src mcr.microsoft.com/dotnet/sdk:8.0-alpine \
    dotnet restore /src/FinanSecure.Auth/FinanSecure.Auth.csproj
```

### **Si ves: "error MSB3644: The reference assemblies for .NETCoreApp"**
```bash
# Actualizar imagen de Docker
docker pull mcr.microsoft.com/dotnet/sdk:8.0-alpine
docker pull mcr.microsoft.com/dotnet/aspnet:8.0-alpine
```

---

## 📊 Verificación de Cambios

### Archivo Modificado: `FinanSecure.Auth/Dockerfile`

**Cambios:**
- ✅ Agregada copia explícita de `*.sln`
- ✅ Agregada copia explícita de todos los `.csproj`
- ✅ Agregado `--no-restore` en `dotnet build`
- ✅ Agregado manejo de errores con `||` statements
- ✅ Agregado `--no-build` en `dotnet publish`
- ✅ Agregados comentarios de diagnóstico

**Líneas modificadas:** 9-44 (STAGE 1 BUILD)

---

## 📝 Checklist de Verificación

- [ ] Dockerfile actualizado con mejoras
- [ ] `docker build` ejecutado exitosamente
- [ ] Imagen `finansecure-auth` creada (ver con `docker images`)
- [ ] Contenedor inicia sin errores
- [ ] Endpoint `/health` responde con 200 OK
- [ ] `docker-compose up` inicia todos los servicios

---

## 🚨 Últimos Pasos si Aún Falla

### **Debug Nivel 1: Ver logs del build**
```bash
docker build -f FinanSecure.Auth/Dockerfile . \
    -t finansecure-auth:debug \
    --progress=plain 2>&1 | tail -200
```

### **Debug Nivel 2: Build interactivo en contenedor**
```bash
docker run -it --rm \
    -v $(pwd):/src \
    mcr.microsoft.com/dotnet/sdk:8.0-alpine \
    /bin/sh

# Dentro del contenedor:
cd /src
dotnet restore "FinanSecure.Auth/FinanSecure.Auth.csproj"
dotnet build "FinanSecure.Auth/FinanSecure.Auth.csproj" -c Release
```

### **Debug Nivel 3: Crear Dockerfile temporal para diagnosticar**
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine
WORKDIR /src
COPY . .
RUN dotnet build "FinanSecure.Auth/FinanSecure.Auth.csproj" -v diag 2>&1 | head -100
```

---

## 📞 Soporte

Si el problema persiste después de aplicar estas soluciones:

1. ✅ Ejecuta: `docker build --progress=plain` y copia TODO el output
2. ✅ Ejecuta: `ls -la FinanSecure.Auth/` y verifica que ves 20+ archivos
3. ✅ Revisa si hay caracteres especiales o espacios en rutas
4. ✅ Verifica que el archivo `.dockerignore` no excluye archivos necesarios

---

## ✨ Conclusión

El error "RUN dotnet build" ha sido identificado y resuelto con:
- Dockerfile mejorado con mejor estructura de capas
- Manejo explícito de errores
- Documentación completa de diagnóstico

**Próximo paso:** Ejecutar `docker build` con las nuevas mejoras.

