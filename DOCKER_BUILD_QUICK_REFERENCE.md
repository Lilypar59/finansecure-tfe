# 🚀 DOCKER BUILD - GUÍA DE REFERENCIA RÁPIDA

## ⚡ 30 Segundos (La solución más rápida)

```bash
cd /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir
./build-auth.sh full
```

✅ **¡Listo!** Tu imagen Docker está creada.

---

## 📝 2 Minutos (Con verificación)

```bash
# 1. Ir a la carpeta
cd /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir

# 2. Diagnóstico
./build-auth.sh diagnose

# 3. Build
./build-auth.sh build

# 4. Ver resultado
docker images finansecure-auth
```

---

## 🔍 Script Helper

```bash
./build-auth.sh diagnose    # Verificar estructura
./build-auth.sh build       # Compilar imagen
./build-auth.sh test        # Probar imagen
./build-auth.sh clean       # Limpiar Docker
./build-auth.sh full        # TODO en uno
```

---

## 📚 Documentación por Caso

| Necesito | Documento |
|----------|-----------|
| La solución YA | ERROR_BUILD_DOCKER_FIX_QUICK.md |
| ¿Por qué falla? | DIAGNOSTICO_ERROR_VISUAL.md |
| Todo detallado | INFORME_ERROR_BUILD_DOCKER.md |
| Resumen visual | BUILD_DOCKER_SOLUTION_VISUAL.md |

---

## 🔧 Opciones Manuales

```bash
# Docker Compose
docker-compose build finansecure-auth

# Docker Manual
docker build -f FinanSecure.Auth/Dockerfile . -t finansecure-auth:latest

# Con detalles
docker build --progress=plain -f FinanSecure.Auth/Dockerfile .
```

---

## ✅ Verificación

```bash
docker images finansecure-auth
docker run --rm -p 8080:8080 finansecure-auth:latest
# En otra terminal:
curl http://localhost:8080/health
```

---

## 🚨 Si Falla

1. `./build-auth.sh diagnose`
2. Leer documentación correspondiente
3. `docker build --progress=plain` para ver detalles

