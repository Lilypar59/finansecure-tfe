# 🔧 INFORME DE CORRECCIONES: Problemas de CORS y Configuración de API

**Fecha**: 4 de Enero, 2026  
**Problema Principal**: Error CORS al intentar acceder a `http://finansecure-auth:8080/api/v1/auth/login`

---

## 📋 Problemas Encontrados

### 1. **Frontend accediendo directamente a servicios internos** ❌
- **Síntoma**: Error CORS "Solicitud de origen cruzado bloqueada"
- **Causa**: El frontend Angular estaba intenta acceder a `http://finansecure-auth:8080` directamente en lugar de usar `http://localhost` (NGINX)
- **Archivo**: `finansecure-web/src/app/config/api.config.ts`

### 2. **Configuración de CORS incompleta** ❌
- **Síntoma**: CORS falla aunque el servidor lo haya configurado
- **Causa**: El Auth Service solo permitía `http://localhost:3000` y `http://localhost:4200`, pero no `http://localhost` (puerto 80 del NGINX)
- **Archivo**: `FinanSecure.Auth/Program.cs`

### 3. **Dashboard Service con URL hardcodeada** ❌
- **Síntoma**: Dashboard intenta acceder a `http://localhost:5045` (puerto incorrecto)
- **Causa**: URL hardcodeada en lugar de usar configuración centralizada
- **Archivo**: `finansecure-web/src/app/services/dashboard.service.ts`

---

## ✅ Soluciones Implementadas

### 1. Corrección de Configuración de API (api.config.ts)

**Antes:**
```typescript
getAuthUrl: (): string => {
  if (typeof window !== 'undefined' && window.location.hostname === 'localhost') {
    if (window.location.port === '3000') {
      return '/api/v1/auth';
    } else {
      return 'http://localhost:8080/api/v1/auth';  // ❌ URL absoluta direca
    }
  }
  return '/api/v1/auth';
}
```

**Después:**
```typescript
getAuthUrl: (): string => {
  // ✅ SIEMPRE usar ruta relativa
  // El navegador envía la petición a localhost, NGINX la redirige internamente
  return '/api/v1/auth';
}
```

**Ventajas:**
- ✅ Funciona en todos los ambientes (Docker, desarrollo local, producción)
- ✅ NGINX maneja el proxy internamente sin problemas de CORS
- ✅ No hay referencias directas a servicios internos

---

### 2. Corrección de CORS en Auth Service (Program.cs)

**Antes:**
```csharp
policy
    .WithOrigins("http://localhost:3000", "http://localhost:4200", "http://localhost:4201")
    .AllowAnyHeader()
    .AllowAnyMethod()
    .AllowCredentials();
```

**Después:**
```csharp
policy
    .WithOrigins(
        "http://localhost",           // Docker: NGINX en puerto 80
        "http://localhost:80",        // Explícitamente puerto 80
        "http://localhost:3000",      // Docker: Frontend desarrollo
        "http://localhost:4200",      // Desarrollo local Angular
        "http://localhost:4201",      // Desarrollo local Angular alt
        "http://finansecure-frontend" // Nombre DNS interno Docker
    )
    .AllowAnyHeader()
    .AllowAnyMethod()
    .AllowCredentials();
```

**Ventajas:**
- ✅ Permite solicitudes desde NGINX (localhost:80)
- ✅ Mantiene compatibilidad con desarrollo local
- ✅ Permite comunicación por DNS interno en Docker

---

### 3. Corrección de Dashboard Service (dashboard.service.ts)

**Antes:**
```typescript
private apiUrl = 'http://localhost:5045/api/dashboard'; // ❌ URL hardcodeada
```

**Después:**
```typescript
import { API_CONFIG } from '../config/api.config';

private apiUrl = `${API_CONFIG.getTransactionsUrl()}/dashboard`; // ✅ Usa configuración centralizada
```

**Ventajas:**
- ✅ Usa configuración centralizada
- ✅ Accede a través del NGINX
- ✅ Consistente con otros servicios

---

## 🔄 Flujo Correcto Después de las Correcciones

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. NAVEGADOR                                                     │
│    http://localhost:80                                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ GET /api/v1/auth/login
                         │ (Ruta relativa)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. NGINX (API Gateway)                                           │
│    - Recibe petición en puerto 80                                │
│    - Ve origen: http://localhost (PERMITIDO)                     │
│    - Enruta a: http://finansecure-auth:8080/api/v1/auth/login  │
│    - (Comunicación INTERNA - sin CORS)                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ (Red Docker: auth-network)
                         │ Sin problema de CORS (mismo servidor)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. AUTH SERVICE                                                  │
│    - Recibe petición del NGINX                                   │
│    - Verifica CORS origin: http://localhost (PERMITIDO)          │
│    - Procesa login                                               │
│    - Responde con JSON + JWT token                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ (Red Docker: auth-network)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. NGINX                                                         │
│    - Recibe respuesta del Auth Service                           │
│    - Responde al navegador con origen correcto                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Response (200 OK + Token)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. NAVEGADOR                                                     │
│    - Recibe respuesta                                            │
│    - Almacena token en localStorage                              │
│    - Inicia sesión (✅ SIN errores CORS)                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🧪 Validación de las Correcciones

### Paso 1: Verificar Estado de Contenedores
```bash
docker-compose ps
# Debería mostrar:
# finansecure-auth        ✅ healthy
# finansecure-postgres    ✅ healthy  
# finansecure-frontend    ✅ healthy
```

### Paso 2: Probar Endpoints
```bash
# Frontend
curl -I http://localhost
# Debería retornar: 200 OK

# Health check del Auth Service
curl -I http://localhost:8080/health
# Debería retornar: 200 OK (no 500)
```

### Paso 3: Probar Login en Navegador
```
1. Abrir: http://localhost
2. Ir a página de login
3. Ingresar: 
   - Username: demo
   - Password: demo
4. Verificar que:
   - ✅ NO hay error CORS en consola
   - ✅ Se almacena token en localStorage
   - ✅ Se redirige a dashboard
```

### Paso 4: Verificar Peticiones en DevTools
```javascript
// En la consola del navegador
localStorage.getItem('token')
// Debería retornar un JWT token válido
```

---

## 📊 Comparativa: Antes vs Después

| Aspecto | Antes | Después |
|---------|-------|---------|
| **URL del Frontend** | `http://finansecure-auth:8080` | `/api/v1/auth` (relativa) |
| **CORS permitidos** | localhost:3000, :4200, :4201 | localhost (todos los puertos) |
| **Enrutamiento** | Directo a backend | A través de NGINX |
| **Problema CORS** | ❌ Sí (origen diferente) | ✅ No (NGINX resuelve) |
| **Escalabilidad** | ❌ No (URLs hardcodeadas) | ✅ Sí (configurable) |
| **Seguridad** | ⚠️ Backend expuesto | ✅ Backend privado |

---

## 🚀 Próximos Pasos

1. **Esperar a que Docker Compose termine de reconstruir** (2-3 minutos)
   ```bash
   docker-compose logs -f
   ```

2. **Verificar que los contenedores estén HEALTHY**
   ```bash
   docker ps
   ```

3. **Probar login en navegador**
   - Abrir: http://localhost
   - Username: demo
   - Password: demo

4. **Si sigue habiendo error CORS:**
   - Revisar logs: `docker-compose logs finansecure-auth`
   - Verificar que NGINX está enrutando correctamente
   - Verificar que el navegador envía peticiones a `localhost` (no a `finansecure-auth:8080`)

---

## 📝 Archivos Modificados

1. ✅ `finansecure-web/src/app/config/api.config.ts` - Rutas relativas
2. ✅ `FinanSecure.Auth/Program.cs` - CORS configurado para localhost:80
3. ✅ `finansecure-web/src/app/services/dashboard.service.ts` - URL centralizada
4. ✅ `FinanSecure.Auth/Dockerfile` - curl instalado para healthcheck

---

## 💡 Lecciones Aprendidas

1. **Nunca hardcodear URLs de APIs** - Usar configuración centralizada
2. **CORS y Proxy** - Cuando usas un API Gateway (NGINX), el CORS se configura en el gateway y en el servicio
3. **Rutas relativas** - Permiten que el mismo código funcione en múltiples ambientes
4. **Docker networking** - Los contenedores se comunican por DNS interno sin problemas de CORS

---

## ✅ Estado Actual

- [x] Problemas identificados
- [x] Soluciones implementadas
- [x] Contenedores en reconstrucción
- [ ] Verificación en navegador (próximo paso)
- [ ] Pruebas de login completas
- [ ] Validación final de arquitectura
