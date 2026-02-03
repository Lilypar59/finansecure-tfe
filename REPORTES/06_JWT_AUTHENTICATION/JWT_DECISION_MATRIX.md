# Matriz de Decisiones - Arquitectura JWT FinanSecure

Guía de decisión para responder preguntas clave sobre la implementación JWT.

---

## 🎯 Decisión 1: ¿HS256 o RS256?

### Contexto
- HS256 = Symmetric (clave compartida)
- RS256 = Asymmetric (privada/pública)

### Matriz de Decisión

| Factor | HS256 | RS256 |
|--------|-------|-------|
| **Complejidad** | ✅ Simple | ❌ Compleja (certificados) |
| **Seguridad** | ✅ Buena | ✅✅ Mejor (clave pública distribuible) |
| **Sharing key** | ❌ Ambos servicios necesitan secret | ✅ Solo Auth tiene privada |
| **Performance** | ✅ Más rápido (HMAC) | ❌ Más lento (RSA) |
| **Para MVP** | ✅ RECOMENDADO | ❌ Overkill |
| **Para Producción** | ✅ Aceptable | ✅✅ RECOMENDADO |
| **Migración** | ✅ Documentada | - |

### Recomendación
- **AHORA (MVP):** HS256 con ruta de migración documentada
- **DESPUÉS (Q2 2026):** Migrar a RS256 sin cambios en endpoints

---

## 🎯 Decisión 2: ¿Dónde Almacenar Access Token en Frontend?

### Contexto
- localStorage: Persiste en navegador
- sessionStorage: Se borra al cerrar ventana
- Memory: Se pierde en refresh (peor UX)
- Cookie HttpOnly: Más seguro

### Matriz de Decisión

| Almacenamiento | Ventajas | Desventajas | XSS Risk | CSRF Risk |
|----------------|----------|-------------|---------|-----------|
| **localStorage** | ✅ Persiste, fácil acceso | ❌ Vulnerable a XSS | 🔴 Alto | 🟢 Bajo |
| **sessionStorage** | ✅ Se borra con ventana | ❌ Bad UX (logout al refresh) | 🔴 Alto | 🟢 Bajo |
| **Memory** | ✅ Más seguro | ❌ Se pierde al refresh | 🟡 Medio | 🟢 Bajo |
| **HttpOnly Cookie** | ✅✅ XSS-safe, seguro | ❌ CSRF risk, más complejo | 🟢 Bajo | 🔴 Alto |
| **HttpOnly + CSRF** | ✅✅✅ Best practice | ❌ Más complejo | 🟢 Bajo | 🟢 Bajo |

### Recomendación
- **AHORA (MVP):** localStorage (simple, XSS mitigado con Content-Security-Policy)
- **DESPUÉS:** HttpOnly + Secure cookies + CSRF tokens

**Implementación localStorage:**
```javascript
// Login
const response = await fetch('/api/v1/auth/login', {...});
const {accessToken, refreshToken} = response.data;
localStorage.setItem('accessToken', accessToken);
localStorage.setItem('refreshToken', refreshToken);

// Cualquier request
const token = localStorage.getItem('accessToken');
headers.Authorization = `Bearer ${token}`;

// Logout
localStorage.removeItem('accessToken');
localStorage.removeItem('refreshToken');
```

---

## 🎯 Decisión 3: ¿Access Token: 5 min, 15 min, o 1 hora?

### Contexto
- Más corto = mayor seguridad (menos daño si robado)
- Más largo = mejor UX (menos refreshes)

### Matriz de Decisión

| TTL | Uso | Seguridad | UX | Casos de Uso |
|-----|-----|-----------|----|----|
| **5 min** | 🔴 No recomendado | ✅✅ Excelente | ❌ Muy frecuentes refreshes | Operaciones sensibles (admin) |
| **15 min** | ✅ RECOMENDADO (MVP) | ✅ Buena | ✅ Balance | Usuarios normales |
| **1 hora** | ⚠️ Aceptable | ⚠️ Regular | ✅✅ Excelente | Apps internas, baja seguridad |
| **8 horas** | ❌ No recomendado | ❌ Pobre | ✅✅✅ Excelente pero riesgoso | Legacy |

### Recomendación
- **FinanSecure MVP:** 15 minutos (balance seguridad/UX)
- **Transacciones sensibles:** 5 minutos
- **Mobile app:** 30 minutos (refresh background)

---

## 🎯 Decisión 4: ¿Refresh Token: 7 días, 30 días, o 90 días?

### Contexto
- Más largo = sesión más larga
- Más corto = force re-login
- Máximo de 30 días según OWASP

### Matriz de Decisión

| TTL | Máximo | Renovación | UX | Seguridad |
|-----|--------|-----------|----|----|
| **1 día** | ❌ Muy corto | Diario | ⚠️ Molesto | ✅✅ Excelente |
| **7 días** | ✅ RECOMENDADO | Semanal | ✅ Buena | ✅ Buena |
| **14 días** | ⚠️ Aceptable | Bi-semanal | ✅ Buena | ⚠️ Regular |
| **30 días** | ✅ Máximo OWASP | Mensual | ✅ Buena | ⚠️ Riesgo |
| **90 días** | ❌ Excepto admin | Trimestral | ✅ Excelente | ❌ Pobre |

### Recomendación
- **FinanSecure MVP:** 7 días (balance estándar)
- **Admin users:** 1 día
- **Remember-me:** 30 días + verificación de IP

---

## 🎯 Decisión 5: ¿Usar appsettings.json o Key Vault?

### Contexto
- appsettings.json: fácil de trabajar
- Key Vault: seguro para producción

### Matriz de Decisión

| Ubicación | Desarrollo | Staging | Producción | Riesgo Seguridad |
|-----------|-----------|---------|-----------|-----------------|
| **appsettings.json** | ✅ Simple | ⚠️ Cuidado | ❌ Nunca | 🔴 Secret en código |
| **appsettings.Development.json** | ✅ Ideal | ❌ No | ❌ No | 🟡 Local only |
| **Environment Variables** | ⚠️ Posible | ✅ Buena | ✅ Buena | 🟢 Bajo |
| **Azure Key Vault** | ❌ Overkill | ⚠️ Posible | ✅✅ RECOMENDADO | 🟢 Excelente |
| **Secrets.json** | ✅ Ideal | ❌ No | ❌ No | 🟢 Desarrollo only |

### Recomendación

**Desarrollo local:**
```json
// appsettings.Development.json
{
  "Jwt": {
    "SecretKey": "dev-secret-key-minimum-32-characters-for-testing"
  }
}
```

**Staging/Producción:**
```bash
# Environment variable
export Jwt__SecretKey="prod-super-secret-key-minimum-32-characters"

# O en appsettings.json (sin secret)
{
  "Jwt": {
    "SecretKey": "${Jwt__SecretKey}"  // Reemplazado por variable
  }
}
```

**Producción con Azure Key Vault:**
```csharp
// Program.cs
var keyVaultUrl = new Uri(builder.Configuration["KeyVault:Url"]);
var credential = new DefaultAzureCredential();
builder.Configuration.AddAzureKeyVault(keyVaultUrl, credential);
```

---

## 🎯 Decisión 6: ¿CORS: AllowAll o Restringido?

### Contexto
- AllowAll: fácil para desarrollo, inseguro
- Restringido: más seguro, requiere configuración

### Matriz de Decisión

| Política CORS | Desarrollo | Staging | Producción | Seguridad |
|---------------|-----------|---------|-----------|-----------|
| **AllowAll** | ✅ Simple | ❌ No | ❌ Nunca | 🔴 Crítica |
| **Whitelist dominios** | ⚠️ Requiere config | ✅ Ideal | ✅ RECOMENDADO | 🟢 Excelente |
| **Localhost only** | ✅ Ideal | ❌ No | ❌ No | 🟢 Perfecto |
| **Dynamic whitelist** | ❌ Complejo | ⚠️ Posible | ✅ Flexible | 🟢 Buena |

### Recomendación

**Desarrollo:**
```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("Development", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});
```

**Producción:**
```csharp
var allowedOrigins = builder.Configuration["Cors:AllowedOrigins"]?.Split(";");

builder.Services.AddCors(options =>
{
    options.AddPolicy("Production", policy =>
    {
        policy
            .WithOrigins(allowedOrigins)
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials();
    });
});
```

**appsettings.Production.json:**
```json
{
  "Cors": {
    "AllowedOrigins": "https://app.finansecure.com;https://admin.finansecure.com"
  }
}
```

---

## 🎯 Decisión 7: ¿Rate Limiting: MemoryCache o Redis?

### Contexto
- MemoryCache: simple, single instance
- Redis: distribuido, múltiples instancias

### Matriz de Decisión

| Tecnología | Single Server | Multiple Servers | Complejidad | Costo |
|-----------|---------------|-----------------|-----------|-------|
| **MemoryCache** | ✅ IDEAL | ❌ No sincroniza | 🟢 Simple | 💰 Gratis |
| **DistributedMemoryCache** | ✅ Buena | ⚠️ Single DB | 🟡 Medio | 💰 Gratis |
| **Redis** | ⚠️ Overkill | ✅ IDEAL | 🔴 Complejo | 💵 Costo |
| **Azure Cache** | ⚠️ Overkill | ✅ IDEAL | 🔴 Complejo | 💵💵 Caro |

### Recomendación

**MVP (single server):**
```csharp
builder.Services.AddMemoryCache();
// Implementar RateLimitingMiddleware con MemoryCache
```

**Producción (múltiples servidores):**
```csharp
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = builder.Configuration.GetConnectionString("Redis");
});
```

---

## 🎯 Decisión 8: ¿Token Revocation: BD o Redis?

### Contexto
- BD: persistente, menos rápido
- Redis: rápido, requiere servicio externo

### Matriz de Decisión

| Almacenamiento | Velocidad | Persistencia | Query | Costo |
|--|--|--|--|--|
| **BD (SQL)** | ⚠️ Lento | ✅ Sí | ✅ SQL queries | 💰 BD |
| **Redis** | ✅ Rápido | ❌ No (volatile) | ❌ Key-value | 💵 Redis |
| **BD + Redis** | ✅ Hybrid | ✅ Sí | ✅ Sí | 💵💵 Ambos |
| **Token en JWT (no revocable)** | ✅✅ Rápido | - | - | 💰 Gratis |

### Recomendación

**MVP (sin revocación):**
- No implementar revocación
- Access tokens cortos (15 min) mitigan riesgo
- Logout solo invalida refresh token

**Fase 2 (con revocación):**
```csharp
// Redis (recomendado)
var jti = token.Claims.First(c => c.Type == "jti").Value;
await _cache.SetAsync($"revoked:{jti}", true, expirationTime);

// Validar en middleware
var isRevoked = await _cache.GetAsync($"revoked:{jti}");
if (isRevoked) return 401;
```

---

## 🎯 Decisión 9: ¿Swagger: Habilitado o Deshabilitado en Producción?

### Contexto
- Facilita desarrollo/testing
- Expone endpoints a atacantes

### Matriz de Decisión

| Entorno | Swagger | GraphQL | Documentation | Pros/Cons |
|---------|---------|---------|--------------|-----------|
| **Desarrollo** | ✅ HABILITADO | ⚠️ Opcional | ✅ Automática | ✅ Máxima visibilidad |
| **Staging** | ✅ HABILITADO | ⚠️ Opcional | ✅ Automática | ✅ Para QA |
| **Producción** | ❌ DESHABILITADO | ⚠️ Opcional | ✅ Externa | ✅ Seguridad |

### Recomendación

```csharp
// Program.cs
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
else if (app.Environment.IsStaging())
{
    // En staging, requiere auth
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.RoutePrefix = "api/docs";
        // c.SwaggerEndpoint("/swagger/v1/swagger.json", "API V1");
    });
}
// Producción: ninguno
```

---

## 🎯 Decisión 10: ¿2FA: Obligatorio u Opcional?

### Contexto
- Obligatorio: máxima seguridad, peor UX
- Opcional: balance

### Matriz de Decisión

| Política | Seguridad | UX | Costo | Regulación |
|---------|-----------|----|----|--|
| **Sin 2FA** | ❌ Pobre | ✅✅ Excelente | 💰 Gratis | ❌ No cumple |
| **2FA Opcional** | ✅ Buena | ✅ Buena | 💰 Bajo | ✅ Cumple |
| **2FA Obligatorio** | ✅✅ Excelente | ⚠️ Molesto | 💰 Bajo | ✅✅ Cumple |
| **2FA + Biometría** | ✅✅✅ Máxima | ❌ Complejidad | 💵 Alto | ✅✅ Excepcional |

### Recomendación

**MVP (sin 2FA):**
- Solo password BCrypt
- Documentar para fase 2

**Fase 3 (2FA):**
```csharp
// TOTP (Time-based One-Time Password)
// Google Authenticator, Microsoft Authenticator, Authy
await _authService.GenerateTotpSecretAsync(userId);
await _authService.VerifyTotpAsync(userId, code);
```

---

## 📊 Decisiones Recomendadas - Resumen

| Decisión | Recomendación | Fase |
|----------|---------------|------|
| 1. Algoritmo | HS256 → RS256 | MVP → Q2 2026 |
| 2. Token Storage | localStorage → HttpOnly | MVP → Q3 2026 |
| 3. Access TTL | 15 minutos | MVP permanente |
| 4. Refresh TTL | 7 días (máx 30) | MVP permanente |
| 5. Secrets | appsettings.json → Key Vault | MVP → Producción |
| 6. CORS | Whitelist | MVP → Producción |
| 7. Rate Limiting | MemoryCache → Redis | MVP → Escala |
| 8. Revocation | No (early) → Redis | - → Fase 2 |
| 9. Swagger | Habilitado → Deshabilitado | MVP → Producción |
| 10. 2FA | No → TOTP Opcional | MVP → Fase 3 |

---

## 🚀 Roadmap Sugerido

```
MVP (Ahora):
├─ HS256 + 15 min access + 7 día refresh
├─ localStorage para tokens
├─ appsettings.json + secrets.json
├─ CORS whitelist básico
├─ Sin rate limiting (early)
├─ Sin revocación (short TTL mitigates)
├─ Swagger habilitado
└─ Sin 2FA

Fase 2 (Q1 2026):
├─ Rate limiting (MemoryCache)
├─ Token revocation (BD + Redis)
├─ Token audit service
├─ Anomaly detection
└─ RS256 migration strategy complete

Fase 3 (Q2 2026):
├─ Migración a RS256 (cero downtime)
├─ HttpOnly cookies + CSRF tokens
├─ TOTP 2FA (opcional)
└─ Session management mejorado

Fase 4 (Q3 2026):
├─ OAuth 2.0 Device Flow
├─ 2FA obligatorio para admin
├─ Multi-device session control
└─ Advanced analytics
```

---

## 📋 Checklist Final

Antes de ir a producción:

- ✅ Secret key de 32+ caracteres en Key Vault
- ✅ CORS restringido a dominios permitidos
- ✅ Swagger deshabilitado
- ✅ HTTPS requerido (RequireHttpsMetadata: true)
- ✅ Logs sin tokens completos (solo jti)
- ✅ Password hashing con BCrypt (12+ rounds)
- ✅ Access token TTL: 15-30 minutos
- ✅ Refresh token TTL: 7-30 días
- ✅ Rate limiting configurado (5 login intentos/15min)
- ✅ Auditoría habilitada (logs de todas las acciones)
- ✅ Cross-user access protection validado
- ✅ Tests pasando 100%
- ✅ Documentación completada
- ✅ Disaster recovery plan (secret key rotation)

