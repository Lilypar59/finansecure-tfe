# ✅ CHECKLIST DE VERIFICACIÓN: Docker + NGINX + Backend

**Fecha**: 4 de Enero, 2026  
**Objetivo**: Validar que la arquitectura Docker + NGINX + Backend funcione correctamente

---

## 📋 Estado de Verificación

```
□ 1. Navegador solo llama a localhost
□ 2. NGINX enruta correctamente /api
□ 3. Backend recibe POST correctamente
□ 4. Sin errores 301/302 no deseados
□ 5. Docker networking funciona correctamente
```

---

# 1️⃣ NAVEGADOR SOLO LLAMA A LOCALHOST

## Objetivo
Verificar que el frontend (SPA) accede SOLO a `localhost` y no directamente a `finansecure-auth:8080` o `finansecure-transactions:8081`.

## Verificación A: Examinar archivo de configuración del frontend

### Paso 1: Buscar referencias a direcciones de backend en el código Angular
```bash
# Buscar en archivos .ts referencias a direcciones de backend
grep -r "finansecure-auth" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/src/
grep -r "finansecure-transactions" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/src/
grep -r ":8080" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/src/
grep -r ":8081" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/src/
```

**Resultado esperado**:
```
❌ PROBLEMA: Si encuentra algo
✅ CORRECTO: Si NO encuentra nada (vacío)
```

---

### Paso 2: Verificar API URL base en servicio Angular
```bash
# Buscar baseUrl en servicios HTTP
grep -r "baseUrl\|API_URL\|apiUrl" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/src/ \
  | grep -v node_modules \
  | grep -v ".spec.ts"
```

**Resultado esperado**:
```
✅ CORRECTO: 
  apiUrl = '/api/v1/auth'
  apiUrl = '/api/v1/transactions'

❌ PROBLEMA:
  apiUrl = 'http://finansecure-auth:8080'
  apiUrl = 'http://localhost:8080'
  apiUrl = 'http://192.168.x.x:8080'
```

---

### Paso 3: Examinar environment.ts
```bash
cat /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/src/environments/environment.ts
```

**Debería contener algo como**:
```typescript
export const environment = {
  production: false,
  apiBaseUrl: '/api/v1'  // ✅ Ruta relativa (localhost implícito)
};

// ❌ NO DEBERÍA tener:
// apiBaseUrl: 'http://finansecure-auth:8080/api/v1'
// apiBaseUrl: 'http://localhost:8080/api/v1'
```

---

### Paso 4: Revisar interceptores HTTP
```bash
# Buscar interceptadores de HTTP
find /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/src -name "*interceptor*" -type f

# Ver contenido
cat /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/src/app/core/interceptors/*.ts 2>/dev/null
```

**Debería verse**:
```typescript
// ✅ CORRECTO: Rutas relativas
const url = `/api/v1/auth/login`;  // Angular combina con localhost

// ❌ INCORRECTO: URLs absolutas
const url = `http://finansecure-auth:8080/api/v1/auth/login`;
```

---

## Verificación B: Monitorizar tráfico en tiempo de ejecución

### Paso 1: Iniciar Docker Compose
```bash
cd /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir

# Detener contenedores anteriores (si existen)
docker-compose down -v

# Iniciar contenedores
docker-compose up -d

# Esperar 5 segundos a que arranquen
sleep 5

# Verificar que están corriendo
docker-compose ps
```

**Debería mostrar**:
```
NAME                      COMMAND                  STATUS
finansecure-db           "docker-entrypoint..."   Up (healthy)
finansecure-auth         "dotnet FinanSecure..."  Up (healthy)
finansecure-transactions "dotnet FinanSecure..."  Up (healthy)
finansecure-frontend     "nginx -g daemon off"    Up
```

✅ **RESULTADO ESPERADO**: Todos en estado `Up`

---

### Paso 2: Abrir navegador y abrir DevTools

```bash
# Abrir navegador (simulado con curl)
# En realidad, abre en tu navegador:
# 1. Abre http://localhost
# 2. Presiona F12 (DevTools)
# 3. Ve a tab Network
# 4. Realiza login
```

**Lo que deberías ver en Network**:
```
GET   http://localhost/                              ✅
GET   http://localhost/main.xxxxx.js                 ✅
POST  http://localhost/api/v1/auth/login             ✅ (redirigido a NGINX)

❌ NO debería haber:
POST  http://finansecure-auth:8080/api/v1/auth/login
POST  http://172.xx.0.x:8080/api/v1/auth/login
```

---

### Paso 3: Capturar tráfico con tcpdump (línea de comandos)

```bash
# Monitorizar tráfico en la red de Docker
docker run --rm --net=host alpine/tcpdump -i docker0 -n 'dst port 8080 or dst port 8081' -A

# En otra terminal, hacer petición desde frontend
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"Demo@1234"}'
```

**Resultado esperado**:
```
❌ NO debería haber tráfico directo a :8080 desde IP del cliente
✅ Todo debe ir a :80 (NGINX)
```

---

### Paso 4: Verificar logs de NGINX
```bash
# Ver logs de acceso NGINX
docker logs finansecure-frontend | grep "POST /api"
```

**Debería mostrar**:
```
172.20.0.1 - - [04/Jan/2026:10:30:45 +0000] "POST /api/v1/auth/login HTTP/1.1" 200 ...
```

✅ **RESULTADO**: Petición llegó a NGINX (:80)

---

### Paso 5: Verificar logs del backend

```bash
# Ver logs de Auth Service
docker logs finansecure-auth | grep -i "login\|request" | tail -20
```

**Debería mostrar**:
```
2026-01-04 10:30:45 - Authentication request received for user: demo
2026-01-04 10:30:45 - Authentication successful
```

✅ **RESULTADO**: Backend procesó la petición

---

## ✅ Checklist 1: Navegador solo llama a localhost

```
□ Paso 1: grep NO encuentra referencias a :8080 en código
□ Paso 2: apiUrl = '/api/v1' (rutas relativas)
□ Paso 3: environment.ts sin URLs absolutas
□ Paso 4: Interceptores usan rutas relativas
□ Paso 5: Network DevTools muestra POST /api/v1/... (no :8080)
□ Paso 6: NGINX logs muestran petición en :80
□ Paso 7: Backend logs confirman recepción

ESTADO FINAL: ✅ NAVEGADOR SOLO USA LOCALHOST
```

---

---

# 2️⃣ NGINX ENRUTA CORRECTAMENTE /api

## Objetivo
Verificar que NGINX intercepta peticiones `/api/*` y las proxea correctamente.

## Verificación A: Estructura de nginx.conf

### Paso 1: Verificar archivo nginx.conf existe y es válido
```bash
# Verificar sintaxis
docker run --rm -v /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web:/app \
  nginx:alpine nginx -t -c /app/nginx.conf
```

**Resultado esperado**:
```
nginx: the configuration file /app/nginx.conf syntax is ok
nginx: configuration file /app/nginx.conf test is successful
✅ CORRECTO
```

---

### Paso 2: Verificar que nginx.conf contiene las rutas
```bash
# Buscar locations en nginx.conf
grep -n "location /api" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/nginx.conf
```

**Resultado esperado**:
```
44:    location /api/v1/auth/ {
56:    location /api/v1/transactions/ {
```

✅ **CORRECTO**: Ambas rutas presentes

---

### Paso 3: Verificar proxy_pass en nginx.conf
```bash
# Buscar proxy_pass
grep -n "proxy_pass" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/nginx.conf
```

**Resultado esperado**:
```
45:    proxy_pass http://finansecure-auth:8080/api/v1/auth/;
57:    proxy_pass http://finansecure-transactions:8081/api/v1/transactions/;
```

✅ **CORRECTO**: Proxies configurados a servicios internos

---

## Verificación B: Enrutamiento en tiempo de ejecución

### Paso 1: Obtener IP interna del contenedor NGINX
```bash
# Obtener IP del contenedor frontend (NGINX)
docker inspect finansecure-frontend | grep -A 5 "IPAddress"
```

**Resultado esperado**:
```
"IPAddress": "172.20.0.5"
```

Anota esta IP como `<NGINX_IP>`.

---

### Paso 2: Obtener IP interna del backend Auth
```bash
# Obtener IP del backend Auth
docker inspect finansecure-auth | grep -A 5 "IPAddress"
```

**Resultado esperado**:
```
"IPAddress": "172.20.0.3"
```

Anota esta IP como `<AUTH_IP>`.

---

### Paso 3: Verificar conexión NGINX → Auth (desde dentro de Docker)
```bash
# Entrar en contenedor NGINX
docker exec finansecure-frontend /bin/sh

# Dentro del contenedor, probar conexión DNS
nslookup finansecure-auth
ping -c 2 finansecure-auth

# Probar conexión al puerto 8080
nc -zv finansecure-auth 8080

# Salir del contenedor
exit
```

**Resultado esperado**:
```
Server: 127.0.0.11:53
Address 1: 172.20.0.3 finansecure-auth.auth-network
✅ DNS resuelve correctamente

Connection to finansecure-auth 8080 port [tcp/*] succeeded!
✅ Puerto 8080 accesible
```

---

### Paso 4: Prueba de enrutamiento: petición OPTIONS (preflight)

```bash
# OPTIONS es usado por CORS, NGINX debe responder
curl -v -X OPTIONS http://localhost/api/v1/auth/login \
  -H "Origin: http://localhost" \
  -H "Access-Control-Request-Method: POST"
```

**Resultado esperado**:
```
< HTTP/1.1 204 No Content
< Access-Control-Allow-Origin: http://localhost
< Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
```

✅ **CORRECTO**: NGINX respondió (no fue al backend)

---

### Paso 5: Prueba de enrutamiento: petición GET
```bash
# GET a una ruta de API
curl -v http://localhost/api/v1/auth/validate-token
```

**Resultado esperado**:
```
< HTTP/1.1 401 Unauthorized
(o respuesta del backend)

❌ NO debería ser:
< HTTP/1.1 404 Not Found (nginx error)
< HTTP/1.1 502 Bad Gateway (problema con proxy)
```

✅ **CORRECTO**: Llegó al backend

---

### Paso 6: Verificar headers en respuesta
```bash
# Obtener headers de respuesta completa
curl -i -X GET http://localhost/api/v1/auth/validate-token | head -20
```

**Debería incluir**:
```
HTTP/1.1 401 Unauthorized
Access-Control-Allow-Origin: http://localhost  ← NGINX agregó
Content-Type: application/json                  ← Del backend
```

✅ **CORRECTO**: Headers CORS agregados por NGINX

---

### Paso 7: Verificar routing hacia diferentes backends

```bash
# Auth Service (8080)
curl -v http://localhost/api/v1/auth/validate-token 2>&1 | grep "< HTTP"

# Transactions Service (8081)
curl -v http://localhost/api/v1/transactions/list 2>&1 | grep "< HTTP"
```

**Resultado esperado**:
```
Auth: < HTTP/1.1 401 Unauthorized (o similar)
Transactions: < HTTP/1.1 401 Unauthorized (o similar)

✅ Ambos enrutados correctamente
```

---

### Paso 8: Ver logs de NGINX en tiempo real
```bash
# Terminal 1: Ver logs
docker logs -f finansecure-frontend

# Terminal 2: Hacer petición
curl http://localhost/api/v1/auth/validate-token

# Terminal 1 debería mostrar:
# 172.20.0.1 - - [04/Jan/2026:10:35:12 +0000] "GET /api/v1/auth/validate-token HTTP/1.1" 401
```

✅ **CORRECTO**: Petición logged y enrutada

---

## ✅ Checklist 2: NGINX enruta correctamente /api

```
□ Paso 1: nginx.conf sintaxis válida
□ Paso 2: Locations /api/v1/auth/ y /api/v1/transactions/ presentes
□ Paso 3: proxy_pass apunta a :8080 y :8081
□ Paso 4: NGINX puede resolver DNS (nslookup finansecure-auth)
□ Paso 5: NGINX puede conectar a puerto 8080 (nc -zv)
□ Paso 6: OPTIONS retorna 204 (CORS preflight)
□ Paso 7: GET retorna respuesta del backend (no 404)
□ Paso 8: Headers CORS presentes en respuesta
□ Paso 9: Ambos servicios enrutados (auth y transactions)
□ Paso 10: Logs muestran peticiones enrutadas

ESTADO FINAL: ✅ NGINX ENRUTA CORRECTAMENTE
```

---

---

# 3️⃣ BACKEND RECIBE POST CORRECTAMENTE

## Objetivo
Verificar que el backend Auth Service recibe peticiones POST y procesa autenticación.

## Verificación A: Backend está funcional

### Paso 1: Verificar que el contenedor está corriendo
```bash
# Ver estado del contenedor
docker ps | grep finansecure-auth

# Debería mostrar: UP
docker inspect finansecure-auth --format='{{.State.Status}}'
```

**Resultado esperado**:
```
Up
✅ CORRECTO
```

---

### Paso 2: Verificar que el puerto 8080 está escuchando
```bash
# Desde el host
docker exec finansecure-auth netstat -tlnp 2>/dev/null | grep 8080

# O con ss (más moderno)
docker exec finansecure-auth ss -tlnp | grep 8080
```

**Resultado esperado**:
```
tcp 0 0 0.0.0.0:8080 0.0.0.0:* LISTEN
✅ CORRECTO
```

---

### Paso 3: Verificar health check del backend
```bash
# Hacer petición a /health
curl -v http://localhost/api/v1/auth/health 2>&1 | grep "< HTTP"
```

**Resultado esperado**:
```
< HTTP/1.1 200 OK
✅ Backend está vivo
```

O si health check no existe:
```bash
# Intentar login sin credenciales
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Resultado esperado**:
```
< HTTP/1.1 400 Bad Request
(No debería ser 404 o 502)
✅ Backend procesó petición
```

---

## Verificación B: POST al backend

### Paso 1: Obtener credenciales válidas
```bash
# Las credenciales están en Program.cs o migrations
# Generalmente: username=demo, password=Demo@1234

# O buscar en código
grep -r "demo\|Demo" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/FinanSecure.Auth/ \
  | grep -i "password\|seed" | head -5
```

---

### Paso 2: Enviar POST de login
```bash
# POST con credenciales
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "demo",
    "password": "Demo@1234"
  }' \
  -v
```

**Resultado esperado**:
```
< HTTP/1.1 200 OK
< Content-Type: application/json

{
  "success": true,
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "message": "Login successful"
}

✅ CORRECTO: POST procesado
```

**Si error**:
```
< HTTP/1.1 401 Unauthorized
{
  "success": false,
  "message": "Invalid credentials"
}

🟡 Verificar credenciales, pero POST llegó al backend

< HTTP/1.1 502 Bad Gateway
✅ POST llegó a NGINX, pero backend no responde

< HTTP/1.1 404 Not Found
❌ NGINX no encontró ruta (problema en nginx.conf)
```

---

### Paso 3: Verificar que es POST (no GET redirigido)
```bash
# Hacer GET a la misma ruta
curl -X GET http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -v
```

**Resultado esperado**:
```
< HTTP/1.1 405 Method Not Allowed
(O 400/401, depende del backend)

✅ Backend rechaza GET (correcto)
```

---

### Paso 4: Verificar body de POST se recibe
```bash
# Hacer POST con data inválida para ver si backend procesa
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"","password":""}' \
  -v
```

**Resultado esperado**:
```
< HTTP/1.1 400 Bad Request
{
  "success": false,
  "message": "Username and password are required"
}

✅ Backend validó body (data llegó)
```

---

### Paso 5: Verificar headers en petición POST

```bash
# Ver headers que NGINX envia
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer token123" \
  -d '{"username":"demo","password":"Demo@1234"}' \
  -v 2>&1 | grep "^>" | head -20
```

**Debería mostrar**:
```
> POST /api/v1/auth/login HTTP/1.1
> Host: localhost
> Content-Type: application/json
> Authorization: Bearer token123
✅ Headers transmitidos
```

---

## Verificación C: Logs del backend

### Paso 1: Ver logs en tiempo real
```bash
# Terminal 1: Ver logs
docker logs -f finansecure-auth --tail 50

# Terminal 2: Hacer petición
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"Demo@1234"}'

# Terminal 1 debería mostrar algo como:
# info: FinanSecure.Auth.Controllers.AuthController[0]
#       Login attempt for user: demo
# info: FinanSecure.Auth.Services.AuthService[0]
#       User authenticated successfully
```

✅ **CORRECTO**: Logs muestran procesamiento

---

### Paso 2: Verificar IP de cliente en logs
```bash
# Ver logs con grep
docker logs finansecure-auth | grep -i "login\|request" | tail -5
```

**Debería mostrar algo como**:
```
2026-01-04 10:40:00 - Request from 172.20.0.5 (NGINX)
2026-01-04 10:40:00 - Authentication request received
2026-01-04 10:40:00 - User: demo authenticated
✅ Petición procesada
```

---

### Paso 3: Verificar database logging (si aplica)
```bash
# Ver si BD recibió queries
docker logs finansecure-db | grep -i "select\|update\|insert" | tail -5

# O conectar a BD y ver logs
docker exec finansecure-db psql -U postgres -d finansecure \
  -c "SELECT * FROM logs ORDER BY created_at DESC LIMIT 5;" 2>/dev/null
```

✅ **CORRECTO**: BD procesó autenticación

---

## ✅ Checklist 3: Backend recibe POST correctamente

```
□ Paso 1: Contenedor finansecure-auth está UP
□ Paso 2: Puerto 8080 escuchando
□ Paso 3: Health check responde 200
□ Paso 4: POST /api/v1/auth/login retorna 200 (con token válido)
□ Paso 5: GET rechazado (405 o similar)
□ Paso 6: POST sin credenciales retorna 400
□ Paso 7: Headers Authorization se transmiten
□ Paso 8: Logs muestran "Login attempt"
□ Paso 9: Logs muestran "User authenticated"
□ Paso 10: Base de datos procesó query

ESTADO FINAL: ✅ BACKEND RECIBE POST CORRECTAMENTE
```

---

---

# 4️⃣ SIN ERRORES 301/302 NO DESEADOS

## Objetivo
Verificar que no hay redirecciones inesperadas que rompan flujo de peticiones.

## Verificación A: Verificar redirecciones en nginx.conf

### Paso 1: Buscar returns en nginx.conf
```bash
# Buscar todas las líneas con 301/302/307
grep -n "301\|302\|307" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/nginx.conf
```

**Resultado esperado**:
```
❌ No debería encontrar líneas con 301/302/307

✅ Si encuentra algo, debe ser:
   - Redirección HTTP → HTTPS (solo en producción)
   - Redirección de trailing slash (ej: /api/ → /api)
```

---

### Paso 2: Buscar return statements problemáticos
```bash
# Buscar statements return que podrían ser problema
grep -n "return 30[0-9]" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/nginx.conf
```

**Resultado esperado**:
```
(sin resultados)
✅ CORRECTO: Sin redirecciones HTTP
```

---

## Verificación B: Redirecciones en tiempo de ejecución

### Paso 1: Seguir redirecciones con curl

```bash
# -L sigue redirecciones, -v muestra cada una
curl -v http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"Demo@1234"}'
```

**Resultado esperado**:
```
< HTTP/1.1 200 OK
(O 401, 400, pero NO 301/302)

❌ PROBLEMA:
< HTTP/1.1 301 Moved Permanently
< Location: http://localhost/api/v1/auth/login/
```

---

### Paso 2: Petición sin seguir redirecciones
```bash
# Sin -L, muestra redireccionamientos
curl -v -I http://localhost/api/v1/auth/login \
  2>&1 | grep "< HTTP\|< Location"
```

**Resultado esperado**:
```
< HTTP/1.1 200 OK
(NO Location header)

❌ PROBLEMA:
< HTTP/1.1 301 Moved Permanently
< Location: http://...
```

---

### Paso 3: Verificar trailing slash
```bash
# Con trailing slash
curl -v http://localhost/api/v1/auth/login/ \
  2>&1 | grep "< HTTP"

# Sin trailing slash
curl -v http://localhost/api/v1/auth/login \
  2>&1 | grep "< HTTP"
```

**Resultado esperado**:
```
Ambos deberían retornar igual (200, 401, 400, etc.)
Sin redirecciones entre ellos

❌ PROBLEMA:
/login →301→ /login/
```

---

### Paso 4: Verificar SPA routing (no redirige /api)
```bash
# Ruta SPA que NO es /api
curl -v http://localhost/dashboard 2>&1 | grep "< HTTP" | head -1

# Debería retornar 200 con HTML (angular)
# NO 301/302
```

**Resultado esperado**:
```
< HTTP/1.1 200 OK
(HTML con SPA)

❌ PROBLEMA:
< HTTP/1.1 301 Moved Permanently
```

---

### Paso 5: Ver cadena de redirecciones
```bash
# Verbose con todos los pasos
curl -v -L http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"Demo@1234"}' \
  2>&1 | grep "> \|< HTTP\|< Location"
```

**Resultado esperado**:
```
> POST /api/v1/auth/login HTTP/1.1
< HTTP/1.1 200 OK
(FIN, solo una petición)

❌ PROBLEMA:
> POST /api/v1/auth/login HTTP/1.1
< HTTP/1.1 301 Moved Permanently
< Location: http://localhost/api/v1/auth/login/
> POST /api/v1/auth/login/ HTTP/1.1
< HTTP/1.1 200 OK
(Dos peticiones, ineficiente)
```

---

### Paso 6: Verificar en DevTools del navegador
```
1. Abre http://localhost en navegador
2. Abre DevTools (F12)
3. Ve a Network tab
4. Realiza login
5. Busca cualquier petición roja (error) o amarilla (redirección)
```

**Debería verse**:
```
✅ POST /api/v1/auth/login → 200 (verde)
✅ GET /main.abc.js → 200 (verde)

❌ NO debería haber:
❌ POST /api/v1/auth/login → 301 (amarillo)
❌ POST /api/v1/auth/login → 302 (amarillo)
```

---

### Paso 7: Verificar logs de NGINX
```bash
# Buscar códigos de estado en logs
docker logs finansecure-frontend | grep "301\|302\|307"
```

**Resultado esperado**:
```
(sin resultados)
✅ CORRECTO: Sin redirecciones
```

---

## ✅ Checklist 4: Sin errores 301/302 no deseados

```
□ Paso 1: nginx.conf NO contiene return 30x
□ Paso 2: curl sin -L retorna 200/401 (no 30x)
□ Paso 3: Con y sin trailing slash retorna igual
□ Paso 4: SPA routes (/dashboard) no redirigen
□ Paso 5: Cadena de peticiones solo 1 step (no redirige)
□ Paso 6: DevTools muestra todas peticiones 200 (verde)
□ Paso 7: Logs NGINX sin 30x

ESTADO FINAL: ✅ SIN REDIRECCIONES NO DESEADAS
```

---

---

# 5️⃣ DOCKER NETWORKING FUNCIONA CORRECTAMENTE

## Objetivo
Verificar que la red de Docker está correctamente configurada y los servicios se comunican.

## Verificación A: Red de Docker

### Paso 1: Verificar que red existe
```bash
# Listar redes
docker network ls
```

**Resultado esperado**:
```
NETWORK ID     NAME                DRIVER    SCOPE
abc12def3g     finansecure-unir_auth-network    bridge    local
xyz98def7g     finansecure-unir_default         bridge    local
```

✅ **CORRECTO**: Red `auth-network` existe

---

### Paso 2: Inspeccionar red auth-network
```bash
# Ver detalles de la red
docker network inspect finansecure-unir_auth-network
```

**Resultado esperado**:
```json
[
    {
        "Name": "finansecure-unir_auth-network",
        "Driver": "bridge",
        "Containers": {
            "abc123...": {
                "Name": "finansecure-auth",
                "IPv4Address": "172.20.0.3/16"
            },
            "def456...": {
                "Name": "finansecure-transactions",
                "IPv4Address": "172.20.0.4/16"
            },
            "xyz789...": {
                "Name": "finansecure-frontend",
                "IPv4Address": "172.20.0.5/16"
            }
        }
    }
]
```

✅ **CORRECTO**: Todos los servicios en la red

---

### Paso 3: Verificar subnet
```bash
# Ver IPAM (IP Address Management)
docker network inspect finansecure-unir_auth-network | grep -A 10 "IPAM"
```

**Resultado esperado**:
```
"IPAM": {
    "Driver": "default",
    "Config": [
        {
            "Subnet": "172.20.0.0/16"
        }
    ]
}
✅ Subnet correcta
```

---

## Verificación B: Conectividad entre contenedores

### Paso 1: Probar DNS interno (frontend → auth)
```bash
# Entrar en contenedor frontend
docker exec -it finansecure-frontend /bin/sh

# Dentro del contenedor:
# Resolver DNS del backend auth
nslookup finansecure-auth

# Debería mostrar:
# Server: 127.0.0.11:53
# Address 1: 172.20.0.3 finansecure-auth
# ✅ CORRECTO

# Salir
exit
```

---

### Paso 2: Probar conectividad NGINX → Auth
```bash
# Desde frontend, conectar a auth:8080
docker exec finansecure-frontend \
  nc -zv finansecure-auth 8080
```

**Resultado esperado**:
```
Connection to finansecure-auth 8080 port [tcp/*] succeeded!
✅ CORRECTO: Conectividad funciona
```

---

### Paso 3: Probar conectividad NGINX → Transactions
```bash
# Desde frontend, conectar a transactions:8081
docker exec finansecure-frontend \
  nc -zv finansecure-transactions 8081
```

**Resultado esperado**:
```
Connection to finansecure-transactions 8081 port [tcp/*] succeeded!
✅ CORRECTO
```

---

### Paso 4: Petición HTTP desde NGINX a Auth
```bash
# Desde frontend, hacer petición HTTP a auth
docker exec finansecure-frontend \
  wget -q -O- http://finansecure-auth:8080/api/v1/auth/health
```

**Resultado esperado**:
```
{"status":"ok"}
(o similar)
✅ HTTP funciona internamente
```

---

### Paso 5: Verificar base de datos
```bash
# Ver red de base de datos
docker network ls | grep postgres

# Inspeccionar red
docker network inspect finansecure-unir_default | grep -A 20 "Containers"
```

**Debería mostrar**:
```
"finansecure-db": {
    "IPv4Address": "172.21.0.2/16"
},
"finansecure-auth": {
    "IPv4Address": "172.21.0.3/16"
},
"finansecure-transactions": {
    "IPv4Address": "172.21.0.4/16"
}
✅ BD conectada a backend services
```

---

### Paso 6: Probar conectividad BD ← Auth
```bash
# Conectar a BD desde Auth
docker exec finansecure-auth \
  nc -zv finansecure-db 5432
```

**Resultado esperado**:
```
Connection to finansecure-db 5432 port [tcp/postgresql] succeeded!
✅ BD accesible
```

---

## Verificación C: Isolamiento de redes

### Paso 1: Verificar que frontend NO puede acceder a BD directamente
```bash
# Frontend NO está en red de BD
docker exec finansecure-frontend \
  nc -zv finansecure-db 5432 2>&1
```

**Resultado esperado**:
```
failed.
✅ CORRECTO: Isolado (frontend no puede acceder BD)
```

---

### Paso 2: Verificar que frontend PUEDE acceder a Auth
```bash
# Frontend SÍ está en auth-network
docker exec finansecure-frontend \
  nc -zv finansecure-auth 8080
```

**Resultado esperado**:
```
succeeded!
✅ CORRECTO: Frontend accede a Auth
```

---

### Paso 3: Diagrama de redes
```
Verificar que la topología es:

         ┌─────────────────────────────────────┐
         │     Frontend (NGINX) :80            │
         │         IP: 172.20.0.5              │
         └─────────────────────────────────────┘
         
    ┌────────────────────┬───────────────────┐
    │                    │                   │
    │                    │                   │
┌───────────────────┐ ┌─────────────────────┐
│   Auth :8080      │ │ Transactions :8081  │
│ 172.20.0.3        │ │ 172.20.0.4          │
└───────────────────┘ └─────────────────────┘
    │                    │
    └────────────────────┤
                         │
                  ┌──────────────┐
                  │   BD :5432   │
                  │ 172.21.0.2   │
                  └──────────────┘

auth-network: {frontend, auth, transactions}
default network: {auth, transactions, bd}
```

---

## Verificación D: Health checks

### Paso 1: Verificar health check de BD
```bash
# Ver si BD marca como healthy
docker inspect finansecure-db --format='{{.State.Health.Status}}'
```

**Resultado esperado**:
```
healthy
✅ CORRECTO
```

---

### Paso 2: Verificar health check de Auth
```bash
docker inspect finansecure-auth --format='{{.State.Health.Status}}'
```

**Resultado esperado**:
```
healthy
✅ CORRECTO
```

---

### Paso 3: Ver historial de health checks
```bash
# Ver últimos health checks
docker inspect finansecure-auth | grep -A 20 "HealthLog"
```

**Debería mostrar**:
```
"HealthLog": [
    {
        "Start": "2026-01-04T10:00:00.000Z",
        "End": "2026-01-04T10:00:05.000Z",
        "ExitCode": 0,
        "Output": "OK"
    }
]
✅ Health checks funcionando
```

---

## Verificación E: Logs de red

### Paso 1: Ver logs de docker-compose
```bash
# Logs de servicios
docker-compose logs --tail 20
```

**Debería mostrar**:
```
finansecure-auth | ... listening on port 8080
finansecure-transactions | ... listening on port 8081
finansecure-frontend | ... listening on port 80
✅ Todos escuchando
```

---

### Paso 2: Ver logs de conexión
```bash
# Logs de auth mostrando peticiones
docker logs finansecure-auth | grep -i "connection\|listening\|connected"
```

**Debería mostrar**:
```
Connected to database
Database connection successful
Listening on port 8080
✅ Conexiones establecidas
```

---

## ✅ Checklist 5: Docker networking funciona correctamente

```
□ Paso 1: Red auth-network existe
□ Paso 2: Frontend, Auth, Transactions en auth-network
□ Paso 3: Subnet correcto (172.20.0.0/16)
□ Paso 4: DNS resuelve finansecure-auth ✓
□ Paso 5: Conectividad NGINX → Auth:8080 ✓
□ Paso 6: Conectividad NGINX → Transactions:8081 ✓
□ Paso 7: Petición HTTP interna funciona ✓
□ Paso 8: Frontend NO accede directo a BD ✓
□ Paso 9: Backend ACCEDE a BD ✓
□ Paso 10: Health checks: all healthy ✓
□ Paso 11: Logs muestran conexiones establecidas

ESTADO FINAL: ✅ DOCKER NETWORKING FUNCIONA CORRECTAMENTE
```

---

---

# 📊 SCRIPT DE VALIDACIÓN COMPLETA AUTOMÁTICA

Si no quieres hacerlo manualmente, usa este script:

```bash
#!/bin/bash
# File: validate-arquitectura.sh

echo "═══════════════════════════════════════════════════"
echo "✅ VALIDACIÓN COMPLETA DE ARQUITECTURA"
echo "═══════════════════════════════════════════════════"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0

# Helper function
check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        ((PASS++))
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        ((FAIL++))
    fi
}

# ═══════════════════════════════════════════════════════
# 1. NAVEGADOR SOLO LLAMA A LOCALHOST
# ═══════════════════════════════════════════════════════
echo ""
echo "1️⃣ NAVEGADOR SOLO LLAMA A LOCALHOST"
echo "───────────────────────────────────"

grep -r "finansecure-auth:8080\|:8080\|:8081" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/src/ 2>/dev/null > /dev/null
[ $? -ne 0 ]
check_result $? "No referencias a :8080 en código frontend"

# ═══════════════════════════════════════════════════════
# 2. NGINX ENRUTA CORRECTAMENTE
# ═══════════════════════════════════════════════════════
echo ""
echo "2️⃣ NGINX ENRUTA CORRECTAMENTE /api"
echo "────────────────────────────────────"

grep -q "location /api/v1/auth/" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/nginx.conf
check_result $? "Location /api/v1/auth/ existe"

grep -q "proxy_pass http://finansecure-auth:8080" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/nginx.conf
check_result $? "proxy_pass a auth:8080 existe"

# ═══════════════════════════════════════════════════════
# 3. BACKEND RECIBE POST
# ═══════════════════════════════════════════════════════
echo ""
echo "3️⃣ BACKEND RECIBE POST CORRECTAMENTE"
echo "─────────────────────────────────────"

# Esperar a que servicios estén listos
sleep 3

docker ps | grep -q finansecure-auth
check_result $? "Contenedor finansecure-auth running"

curl -s http://localhost/api/v1/auth/health > /dev/null 2>&1
check_result $? "Health check responde"

# ═══════════════════════════════════════════════════════
# 4. SIN REDIRECCIONES 301/302
# ═══════════════════════════════════════════════════════
echo ""
echo "4️⃣ SIN ERRORES 301/302 NO DESEADOS"
echo "────────────────────────────────────"

grep -q "return 30[0-9]" /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir/finansecure-web/nginx.conf
[ $? -ne 0 ]
check_result $? "nginx.conf sin return 30x"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/api/v1/auth/validate-token)
[[ "$HTTP_STATUS" != "301" && "$HTTP_STATUS" != "302" ]]
check_result $? "GET /api no redirige (HTTP $HTTP_STATUS)"

# ═══════════════════════════════════════════════════════
# 5. DOCKER NETWORKING
# ═══════════════════════════════════════════════════════
echo ""
echo "5️⃣ DOCKER NETWORKING FUNCIONA"
echo "──────────────────────────────"

docker network ls | grep -q "auth-network"
check_result $? "Red auth-network existe"

docker exec finansecure-frontend nc -zv finansecure-auth 8080 > /dev/null 2>&1
check_result $? "NGINX conecta a Auth:8080"

docker exec finansecure-frontend nc -zv finansecure-transactions 8081 > /dev/null 2>&1
check_result $? "NGINX conecta a Transactions:8081"

docker inspect finansecure-auth --format='{{.State.Health.Status}}' | grep -q "healthy"
check_result $? "Health check: Auth healthy"

docker inspect finansecure-db --format='{{.State.Health.Status}}' | grep -q "healthy"
check_result $? "Health check: BD healthy"

# ═══════════════════════════════════════════════════════
# RESUMEN
# ═══════════════════════════════════════════════════════
echo ""
echo "═══════════════════════════════════════════════════"
echo "📊 RESUMEN"
echo "═══════════════════════════════════════════════════"
echo -e "${GREEN}✅ PASS: $PASS${NC}"
echo -e "${RED}❌ FAIL: $FAIL${NC}"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 TODAS LAS PRUEBAS PASARON${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  ALGUNAS PRUEBAS FALLARON${NC}"
    exit 1
fi
```

---

## Usar el script

```bash
# Hacer script ejecutable
chmod +x validate-arquitectura.sh

# Ejecutar
./validate-arquitectura.sh
```

---

# 🎯 EJECUCIÓN RÁPIDA: TODOS LOS COMANDOS

```bash
# 1. Iniciar servicios
cd /mnt/f/2025/unir/psu\ IA2/app-web/FinanSecure-unir
docker-compose down -v
docker-compose up -d
sleep 5

# 2. Verificar frontend (localhost)
echo "=== Verificar localhost ==="
curl -I http://localhost/
curl -I http://localhost/api/v1/auth/validate-token

# 3. Verificar networking
echo "=== Verificar Docker Networking ==="
docker network ls
docker exec finansecure-frontend nc -zv finansecure-auth 8080
docker exec finansecure-frontend nc -zv finansecure-transactions 8081

# 4. Probar login
echo "=== Probar POST Login ==="
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"Demo@1234"}' \
  -v

# 5. Verificar logs
echo "=== Verificar Logs ==="
docker logs finansecure-frontend | tail -5
docker logs finansecure-auth | tail -5

# 6. Validación automática
./validate-arquitectura.sh
```

---

# ✅ CHECKLIST FINAL

```
NAVEGADOR SOLO LLAMA A LOCALHOST:      □ ✅
NGINX ENRUTA CORRECTAMENTE /api:       □ ✅
BACKEND RECIBE POST CORRECTAMENTE:     □ ✅
SIN ERRORES 301/302 NO DESEADOS:       □ ✅
DOCKER NETWORKING FUNCIONA:            □ ✅

═══════════════════════════════════════════
ESTADO GENERAL:                         ✅ OK
═══════════════════════════════════════════
```
