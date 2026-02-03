# 📊 Estado de la Configuración del Proyecto

## ✅ Lo que hemos hecho:

### 1. **Microservicios .NET**
- ✅ Dockerfile para `FinanSecure.Auth` (corregido)
- ✅ Dockerfile para `FinanSecure.Transactions` (creado)
- ✅ docker-compose.yml con ambos servicios + PostgreSQL
- ✅ Archivo `.env` con variables de entorno
- ✅ Directorios para volúmenes persistentes

### 2. **Frontend Angular**
- ✅ Dockerfile para `finansecure-web` (creado)
- ✅ nginx.conf para servir la aplicación
- ✅ Agregado al docker-compose.yml
- ✅ Información de setup en FRONTEND_SETUP.md

---

## 🚀 Próximos Pasos para Probar TODO

### **MÉTODO RECOMENDADO: Desarrollo Local + Docker**

#### Paso 1: Instalar dependencias del Frontend
```bash
cd /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web
npm install
```

#### Paso 2: Build del Frontend
```bash
npm run build
```

Esto genera: `dist/finansecure-web/`

#### Paso 3: Iniciar Microservicios con Docker
```bash
cd /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir
docker-compose up -d postgres-auth postgres-transactions finansecure-auth finansecure-transactions
```

#### Paso 4: Servir el Frontend Localmente
```bash
# Opción A: Desarrollo Angular (con live reload)
npm start

# Opción B: Producción con http-server
npx http-server dist/finansecure-web/browser -p 3000
```

#### Paso 5: Acceder a la Aplicación
- Frontend: `http://localhost:4200` (dev) o `http://localhost:3000` (prod)
- Auth API: `http://localhost:8080`
- Transactions API: `http://localhost:8081`
- PgAdmin: `http://localhost:5050`

---

## 🐳 MÉTODO ALTERNATIVO: Todo con Docker Compose

```bash
cd /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir

# Ejecutar TODO
docker-compose up -d

# Esperar ~2-3 minutos para que compile

# Ver estado
docker-compose ps

# Ver logs
docker-compose logs -f
```

Luego accede a:
- Frontend: `http://localhost:3000`
- Auth: `http://localhost:8080`
- Transactions: `http://localhost:8081`

---

## ⚠️ Notas Importantes

1. **npm install** puede tardar 2-5 minutos la primera vez
2. **ng build** puede tardar 3-10 minutos
3. **.NET build** en Docker tarda mucho la primera vez (10-15 min)
4. Usa `--build` solo si necesitas recompilar todo
5. Los volúmenes persistentes están en `./data/` y `./logs/`

---

## 🔧 Troubleshooting

### Error: Node.js no instalado
```bash
# Instalar Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Error: npm install muy lento
```bash
# Usar npm ci en lugar de npm install (más rápido)
npm ci
```

### Error: Docker out of space
```bash
# Limpiar imágenes/volúmenes no usados
docker system prune -a
```

---

## 📋 Resumen de Puertos

| Servicio | Puerto | URL |
|----------|--------|-----|
| Frontend (Dev) | 4200 | http://localhost:4200 |
| Frontend (Prod) | 3000 | http://localhost:3000 |
| Auth Service | 8080 | http://localhost:8080 |
| Transactions | 8081 | http://localhost:8081 |
| PgAdmin | 5050 | http://localhost:5050 |
| Auth DB | 5432 | localhost:5432 |
| Trans DB | 5433 | localhost:5433 |

---

## ✨ Próximo Paso Recomendado

Ejecuta esto ahora:
```bash
cd /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web
npm install
```

Luego actualiza el docker-compose.yml para que use el build ya compilado en lugar de hacer el build dentro de Docker.
