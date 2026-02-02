# Flujo de Autenticación JWT - FinanSecure

## 1️⃣ Flujo de Login (Obtener Token)

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO/CLIENTE                             │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                             │ 1. POST /api/v1/auth/login
                             │    {username, password}
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  AUTH SERVICE (Puerto 5000)                          │
│                                                                       │
│  POST /api/v1/auth/login                                            │
│  ├─ 1. Hash password con BCrypt                                    │
│  ├─ 2. Comparar con BD                                             │
│  └─ 3. Si es válido:                                               │
│       ├─ Crear Access Token (15 min):                              │
│       │  • sub: userId (GUID)                                      │
│       │  • name: username                                          │
│       │  • email: email@example.com                                │
│       │  • type: "access"                                          │
│       │  • jti: unique-id-for-revocation                          │
│       │  • iss: "FinanSecure.Auth"                                 │
│       │  • aud: "FinanSecure.Transactions"                         │
│       │  • iat: issued-at (timestamp)                              │
│       │  • exp: expiration (now + 900 seconds)                    │
│       │                                                            │
│       ├─ Firmar con clave secreta (HS256)                         │
│       │                                                            │
│       ├─ Crear Refresh Token (7 días):                            │
│       │  • Token aleatorio de 32 bytes en base64                  │
│       │  • Guardar en BD con userId y expiración                  │
│       │                                                            │
│       └─ Retornar respuesta
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                             │ 2. Respuesta 200 OK
                             │    {accessToken, refreshToken, expiresIn}
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO/CLIENTE                             │
│                                                                       │
│  Guardar tokens en:                                                 │
│  • accessToken → localStorage o memory (corta duración)            │
│  • refreshToken → localStorage o cookie (larga duración)           │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 2️⃣ Flujo de Acceso a Recurso Protegido

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO/CLIENTE                             │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                             │ GET /api/v1/transactions
                             │ Header: Authorization: Bearer <accessToken>
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│           TRANSACTIONS SERVICE (Puerto 5001)                        │
│                                                                       │
│  1. JwtValidationMiddleware:                                        │
│     ├─ Extraer token del header "Authorization: Bearer ..."        │
│     ├─ Validar firma con clave secreta (HS256)                    │
│     ├─ Validar claims obligatorios:                                │
│     │  • iss = "FinanSecure.Auth" ✓                                │
│     │  • aud = "FinanSecure.Transactions" ✓                        │
│     │  • exp > now ✓                                               │
│     │  • type = "access" ✓                                         │
│     │  • sub (userId) formato GUID ✓                               │
│     │  • jti presente ✓                                            │
│     │                                                              │
│     └─ Si todo OK: pasar a controller                              │
│        Si falla: return 401 Unauthorized                           │
│                                                                     │
│  2. TransactionsController:                                        │
│     └─ Método está marcado con [Authorize(Bearer)]                 │
│                                                                     │
│  3. SecureControllerBase:                                          │
│     ├─ GetAuthenticatedUserId()                                    │
│     │  └─ Extraer claim 'sub' de User.Claims                       │
│     │     └─ userId = Guid.Parse(claims[ClaimTypes.NameIdentifier])
│     │                                                              │
│     └─ LogAudit() graba:                                           │
│        • userId extraído del JWT                                   │
│        • jti (token ID)                                            │
│        • acción realizada                                          │
│        • IP address                                                │
│        • timestamp                                                 │
│                                                                     │
│  4. TransactionService:                                            │
│     └─ Usar userId para filtrar datos del usuario                  │
│        SELECT * FROM transactions WHERE user_id = @userId          │
│                                                                     │
│  5. Retornar respuesta (200 OK)
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                             │ Datos del usuario (aislados)
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO/CLIENTE                             │
│                                                                       │
│  Recibir datos:                                                     │
│  [                                                                  │
│    {id: "123", userId: "abc", amount: 75.50, ...},                │
│    {id: "124", userId: "abc", amount: 120.00, ...}                │
│  ]                                                                  │
│                                                                     │
│  Nota: userId en respuesta = al que está autenticado (sin riesgo)  │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 3️⃣ Flujo de Refresh Token (Renovación)

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO/CLIENTE                             │
│                                                                       │
│  Access Token va a expirar en < 2 minutos                          │
│  Decidir renovar antes de que expire                               │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                             │ POST /api/v1/auth/refresh-token
                             │ Body: {refreshToken}
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  AUTH SERVICE (Puerto 5000)                          │
│                                                                       │
│  POST /api/v1/auth/refresh-token                                    │
│  ├─ 1. Validar refreshToken existe en BD                            │
│  ├─ 2. Validar no está expirado                                     │
│  ├─ 3. Validar no supera 30 días desde creación original            │
│  ├─ 4. Validar no ha sido revocado (si implementado)                │
│  └─ 5. Si es válido:                                                │
│       ├─ Crear NUEVO Access Token (15 min)                         │
│       ├─ ROTAR: Revocar refresh token anterior                     │
│       ├─ Crear NUEVO Refresh Token (7 días)                        │
│       └─ Guardar nuevo en BD                                        │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                             │ Respuesta 200 OK
                             │ {accessToken, refreshToken}
                             │
                             │ Cliente actualiza tokens
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO/CLIENTE                             │
│                                                                       │
│  • Descartar accessToken anterior                                   │
│  • Descartar refreshToken anterior                                  │
│  • Guardar nuevos tokens                                            │
│  • Continuar con acceso a recursos protegidos                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 4️⃣ Flujo de Logout (Revocación)

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO/CLIENTE                             │
│                                                                       │
│  Usuario hace click en "Logout"                                     │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                             │ POST /api/v1/auth/logout
                             │ Header: Authorization: Bearer <accessToken>
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  AUTH SERVICE (Puerto 5000)                          │
│                                                                       │
│  POST /api/v1/auth/logout                                           │
│  ├─ 1. Validar token (igual que antes)                              │
│  ├─ 2. Extraer jti del token                                        │
│  ├─ 3. OPCIÓN A: Revocar en BD                                      │
│  │    └─ DELETE FROM refresh_tokens WHERE user_id = @userId         │
│  │       (elimina TODOS los tokens de refresh del usuario)         │
│  │                                                                  │
│  ├─ 3. OPCIÓN B: Revocar en Redis (distribuido)                    │
│  │    └─ SET "revoked-token:{jti}" true EX {expirationTime}        │
│  │       (cache distribuido si hay múltiples instancias)           │
│  │                                                                  │
│  └─ 4. Retornar 200 OK
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                             │ 200 OK
                             │ {message: "Logout successful"}
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO/CLIENTE                             │
│                                                                       │
│  • Eliminar tokens de memoria/localStorage                          │
│  • Redirigir a página de login                                      │
│  • Siguiente acceso a recurso protegido será rechazado (401)       │
└──────────────────────────────────────────────────────────────────────┘

IMPORTANTE: Tokens anteriores no son válidos
┌──────────────────────────────────────────────────────┐
│  Si usuario intenta usar vejo token:                 │
│                                                       │
│  Request: GET /api/v1/transactions                  │
│  Header: Authorization: Bearer <OLD_accessToken>    │
│                                                       │
│  Response: 401 Unauthorized                          │
│  Reason: Token en blacklist (revoked)               │
└──────────────────────────────────────────────────────┘
```

---

## 5️⃣ Flujo de Error - Token Inválido

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO/CLIENTE                             │
│                                                                       │
│  Intenta acceder con token falso/modificado:                        │
│                                                                       │
│  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...     │
│                          (modificado por atacante)                   │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│           TRANSACTIONS SERVICE (Puerto 5001)                        │
│                                                                       │
│  JwtValidationMiddleware:                                           │
│  ├─ Extraer token                                                   │
│  ├─ Intentar validar firma con clave secreta                       │
│  ├─ ❌ FALLO: Firma no coincide                                     │
│  │    (La clave de firma es privada, no se puede duplicar)         │
│  │                                                                  │
│  └─ Retornar 401 Unauthorized                                       │
│     {error: "Invalid token signature"}                             │
└────────────────────────────┬──────────────────────────────────────────┘
                             │
                             │ 401 Unauthorized
                             │ {message: "Unauthorized"}
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          USUARIO/CLIENTE                             │
│                                                                       │
│  Acceso denegado. Ir a login y obtener nuevo token.                │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 6️⃣ Estructura del JWT Decodificado

### Header (Algoritmo y tipo)
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

### Payload (Claims)
```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "name": "juan.perez",
  "email": "juan.perez@example.com",
  "type": "access",
  "jti": "a8c7b2f1-9e3d-4c2a-8b5f-7e1d9c3a5b2f",
  "iss": "FinanSecure.Auth",
  "aud": "FinanSecure.Transactions",
  "iat": 1703945400,
  "exp": 1703946300
}
```

### Signature (Firma criptográfica)
```
HMACSHA256(
  base64UrlEncode(header) + "." +
  base64UrlEncode(payload),
  "your-super-secret-key-minimum-32-characters-for-hs256-security"
)
```

### Token completo (3 partes separadas por puntos)
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.
eyJzdWIiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAiLCJuYW1lIjoianVhbi5wZXJleiIsImVtYWlsIjoianVhbi5wZXJlekBleGFtcGxlLmNvbSIsInR5cGUiOiJhY2Nlc3MiLCJqdGkiOiJhOGM3YjJmMS05ZTNkLTRjMmEtOGI1Zi03ZTFkOWMzYTViMmYiLCJpc3MiOiJGaW5hblNlY3VyZS5BdXRoIiwiYXVkIjoiRmluYW5TZWN1cmUuVHJhbnNhY3Rpb25zIiwiaWF0IjoxNzAzOTQ1NDAwLCJleHAiOjE3MDM5NDYzMDB9.
dJx1c9fK3e7mN2jL5qR8vW0xY9zB1cD3eF5gH7iJ9kL
```

---

## 7️⃣ Validación de Seguridad en Cada Paso

### ✅ En Auth Service (Emisión)
```
[ ] Password validado contra hash en BD
[ ] Crear claims obligatorios (sub, name, email, type, jti)
[ ] Firmar con clave secreta
[ ] Expiraciones correctas (15 min access, 7 días refresh)
[ ] Registrar auditoría (user, timestamp, IP)
[ ] Guardar refresh token en BD
```

### ✅ En Transactions Service (Validación)
```
[ ] Token presente en header Authorization
[ ] Firma válida (no modificada)
[ ] Issuer = "FinanSecure.Auth"
[ ] Audience = "FinanSecure.Transactions"
[ ] Expiration > now (no expirado)
[ ] Type = "access" (no es refresh token)
[ ] UserId (sub) presente y formato GUID
[ ] No está en blacklist (revocado)
[ ] Extraer userId SOLO del JWT (no del body)
[ ] Registrar auditoría de acceso
```

### ✅ En Controlador
```
[ ] Validar recurso pertenece al usuario autenticado
[ ] No permitir cross-user access
[ ] Registrar auditoría de operación
[ ] Usar userId del JWT para filtros de BD
```

---

## 🔐 Seguridad: ¿Por qué esto protege?

| Amenaza | Protección |
|---------|-----------|
| **Usuario A intenta acceder datos de B** | `ValidateResourceOwnership()` verifica userId |
| **Atacante falsifica token** | Firma HMAC-SHA256 requiere clave privada |
| **Atacante modifica claims** | Cambiar claim invalida firma automáticamente |
| **Token expirado se sigue usando** | Validación de `exp` claim en middleware |
| **Usar refresh token como access token** | Validación de `type` claim ("access" vs "refresh") |
| **Usuario A reutiliza token de B** | JWT es única combinación de claims + firma |
| **Logout no funciona** | Revocación por JTI en blacklist |
| **Password débil** | BCrypt con 12 rounds resiste ataques |

---

## 📱 Flujo completo en Timeline

```
T=0:00   [Usuario abre app]
         └─ No hay token

T=0:05   [Usuario hace login]
         └─ POST /auth/login → Auth Service
         └─ Validar password
         └─ Crear JWT (15 min)
         └─ Crear Refresh Token (7 días)
         └─ Guardar refresh token en BD

T=0:10   [Usuario accede transacciones]
         └─ GET /transactions + Bearer <token>
         └─ Transactions Service valida JWT
         └─ Extraer userId del JWT
         └─ Retornar datos del usuario

T=14:55  [Access Token va a expirar]
         └─ Cliente decide renovar (proactivo)

T=14:57  [Renovación automática]
         └─ POST /auth/refresh-token → Auth Service
         └─ Validar refresh token
         └─ Crear NUEVO access token (15 min)
         └─ Revocar refresh token anterior
         └─ Crear NUEVO refresh token (7 días)

T=15:02  [Usuario continúa usando app]
         └─ Nuevo token tiene 14:58 de vida

T=7 días [Máximo sin reauthentication]
         └─ Refresh token expira
         └─ Usuario debe hacer login nuevamente

T=7d+1m  [Usuario intenta usar refresh token expirado]
         └─ POST /auth/refresh-token → Falla
         └─ Usuario redirigido a login

T=7d+2m  [Usuario hace logout explícito]
         └─ POST /auth/logout
         └─ Revocar todos los tokens en BD/Redis
         └─ Cliente elimina tokens

T=7d+3m  [Usuario intenta usar vejo token]
         └─ GET /transactions + Bearer <old-token>
         └─ Middleware detecta en blacklist
         └─ 401 Unauthorized
```

---

## 📚 Referencias

- [RFC 7519 - JSON Web Token (JWT)](https://tools.ietf.org/html/rfc7519)
- [RFC 7518 - JSON Web Algorithms (JWA)](https://tools.ietf.org/html/rfc7518)
- [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [Microsoft ASP.NET Core JWT Authentication](https://docs.microsoft.com/en-us/aspnet/core/security/authentication/jwt-authn)
- [IdentityModel.Tokens.Jwt NuGet Package](https://www.nuget.org/packages/System.IdentityModel.Tokens.Jwt)
