# Testing JWT - Ejemplos cURL y Postman

Guía completa para testear manualmente los endpoints de autenticación y recursos protegidos.

---

## 🔑 Paso 1: Obtener Access Token

### cURL
```bash
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "juan.perez",
    "password": "SecurePassword123!"
  }'
```

### Postman

**Request:**
```
POST http://localhost:5000/api/v1/auth/login
Content-Type: application/json

{
  "username": "juan.perez",
  "password": "SecurePassword123!"
}
```

**Respuesta (200 OK):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAiLCJuYW1lIjoianVhbi5wZXJleiIsImVtYWlsIjoianVhbi5wZXJlekBleGFtcGxlLmNvbSIsInR5cGUiOiJhY2Nlc3MiLCJqdGkiOiJhOGM3YjJmMS05ZTNkLTRjMmEtOGI1Zi03ZTFkOWMzYTViMmYiLCJpc3MiOiJGaW5hblNlY3VyZS5BdXRoIiwiYXVkIjoiRmluYW5TZWN1cmUuVHJhbnNhY3Rpb25zIiwiaWF0IjoxNzAzOTQ1NDAwLCJleHAiOjE3MDM5NDYzMDB9.dJx1c9fK3e7mN2jL5qR8vW0xY9zB1cD3eF5gH7iJ9kL",
    "refreshToken": "dGVtcHNlY3VyZXJhbmRvbWJhc2U2NGVuY29kZWRzdHJpbmc=",
    "expiresIn": 900
  },
  "message": "Login successful"
}
```

💾 **Guardar el accessToken para los próximos pasos**

---

## 🛡️ Paso 2: Acceder a Recurso Protegido

### cURL (con token)
```bash
# Reemplazar TOKEN con el valor del accessToken anterior
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X GET http://localhost:5001/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### Postman

**Request:**
```
GET http://localhost:5001/api/v1/transactions
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

**Respuesta (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "type": "INCOME",
      "description": "Salary payment",
      "amount": 3000.00,
      "categoryId": "550e8400-e29b-41d4-a716-446655440010",
      "createdAt": "2025-12-20T10:00:00Z",
      "updatedAt": "2025-12-20T10:00:00Z"
    }
  ],
  "message": "Se encontraron 1 transacciones"
}
```

---

## ➕ Paso 3: Crear Transacción (con token)

### cURL
```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X POST http://localhost:5001/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "EXPENSE",
    "categoryId": "550e8400-e29b-41d4-a716-446655440010",
    "description": "Groceries shopping at supermarket",
    "amount": 75.50,
    "date": "2025-12-30T14:30:00Z"
  }'
```

### Postman

**Request:**
```
POST http://localhost:5001/api/v1/transactions
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "type": "EXPENSE",
  "categoryId": "550e8400-e29b-41d4-a716-446655440010",
  "description": "Groceries shopping",
  "amount": 75.50,
  "date": "2025-12-30T14:30:00Z"
}
```

**Respuesta (201 Created):**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440002",
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "type": "EXPENSE",
    "categoryId": "550e8400-e29b-41d4-a716-446655440010",
    "description": "Groceries shopping",
    "amount": 75.50,
    "createdAt": "2025-12-30T14:30:00Z",
    "updatedAt": "2025-12-30T14:30:00Z"
  },
  "message": "Transacción creada para usuario juan.perez"
}
```

---

## 🔄 Paso 4: Renovar Token (Refresh)

### cURL
```bash
REFRESH_TOKEN="dGVtcHNlY3VyZXJhbmRvbWJhc2U2NGVuY29kZWRzdHJpbmc="

curl -X POST http://localhost:5000/api/v1/auth/refresh-token \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }"
```

### Postman

**Request:**
```
POST http://localhost:5000/api/v1/auth/refresh-token
Content-Type: application/json

{
  "refreshToken": "dGVtcHNlY3VyZXJhbmRvbWJhc2U2NGVuY29kZWRzdHJpbmc="
}
```

**Respuesta (200 OK):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTBlODQwMC1lMjliLTQxZDQtYTcxNi00NDY2NTU0NDAwMDAiLCJuYW1lIjoianVhbi5wZXJleiIsImVtYWlsIjoianVhbi5wZXJlekBleGFtcGxlLmNvbSIsInR5cGUiOiJhY2Nlc3MiLCJqdGkiOiJiOGM3YjJmMS05ZTNkLTRjMmEtOGI1Zi03ZTFkOWMzYTViMmYiLCJpc3MiOiJGaW5hblNlY3VyZS5BdXRoIiwiYXVkIjoiRmluYW5TZWN1cmUuVHJhbnNhY3Rpb25zIiwiaWF0IjoxNzAzOTQ2MzAwLCJleHAiOjE3MDM5NDcyMDB9.eJy1d9fK3e7mN2jL5qR8vW0xY9zB1cD3eF5gH7iJ9kM",
    "refreshToken": "bmV3cmVmcmVzaHRva2VuYmFzZTY0ZW5jb2RlZHN0cmluZ2RmZg==",
    "expiresIn": 900
  },
  "message": "Token refreshed"
}
```

💾 **Actualizar tokens locales**

---

## 🚪 Paso 5: Logout (Revocación)

### cURL
```bash
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X POST http://localhost:5000/api/v1/auth/logout \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### Postman

**Request:**
```
POST http://localhost:5000/api/v1/auth/logout
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
```

**Respuesta (200 OK):**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

---

## ❌ Paso 6: Intentar Usar Token Expirado

### cURL
```bash
# Usar el token anterior después de 15 minutos (o intencionalmente expirado)
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

curl -X GET http://localhost:5001/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### Respuesta (401 Unauthorized)

```json
{
  "success": false,
  "message": "Unauthorized - Token expired or invalid"
}
```

---

## 🚨 Paso 7: Intentar Acceder sin Token

### cURL
```bash
curl -X GET http://localhost:5001/api/v1/transactions \
  -H "Content-Type: application/json"
```

### Respuesta (401 Unauthorized)

```json
{
  "success": false,
  "message": "Unauthorized - Missing or invalid Authorization header"
}
```

---

## 🛑 Paso 8: Intentar Usar Token Falso

### cURL
```bash
# Token inventado
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmYWtlIjoiZGF0YSJ9.invalidSignature"

curl -X GET http://localhost:5001/api/v1/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

### Respuesta (401 Unauthorized)

```json
{
  "success": false,
  "message": "Unauthorized - Invalid token signature"
}
```

---

## 🔍 Paso 9: Decodificar Token (JWT.io)

1. Ir a [https://jwt.io](https://jwt.io)
2. Pegar el accessToken completo
3. Ver:
   - **Header:** `{"alg":"HS256","typ":"JWT"}`
   - **Payload:** Claims con userId, username, email, etc
   - **Signature:** Validar clave secreta

**Ejemplo de payload decodificado:**
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

---

## 📋 Collection Postman Completa

### Importar Collection

1. Copiar este JSON
2. Postman → Import → Paste Raw Text
3. Crear environment con variables

### JSON Collection

```json
{
  "info": {
    "name": "FinanSecure JWT Testing",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Auth Service",
      "item": [
        {
          "name": "1. Login",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "url": {
              "raw": "{{auth_url}}/api/v1/auth/login",
              "host": ["{{auth_url}}"],
              "path": ["api", "v1", "auth", "login"]
            },
            "body": {
              "mode": "raw",
              "raw": "{\n  \"username\": \"juan.perez\",\n  \"password\": \"SecurePassword123!\"\n}"
            }
          }
        },
        {
          "name": "2. Refresh Token",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "url": {
              "raw": "{{auth_url}}/api/v1/auth/refresh-token",
              "host": ["{{auth_url}}"],
              "path": ["api", "v1", "auth", "refresh-token"]
            },
            "body": {
              "mode": "raw",
              "raw": "{\n  \"refreshToken\": \"{{refresh_token}}\"\n}"
            }
          }
        },
        {
          "name": "3. Logout",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{access_token}}"
              }
            ],
            "url": {
              "raw": "{{auth_url}}/api/v1/auth/logout",
              "host": ["{{auth_url}}"],
              "path": ["api", "v1", "auth", "logout"]
            }
          }
        }
      ]
    },
    {
      "name": "Transactions Service",
      "item": [
        {
          "name": "1. Get All Transactions",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{access_token}}"
              }
            ],
            "url": {
              "raw": "{{transactions_url}}/api/v1/transactions",
              "host": ["{{transactions_url}}"],
              "path": ["api", "v1", "transactions"]
            }
          }
        },
        {
          "name": "2. Create Transaction",
          "request": {
            "method": "POST",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{access_token}}"
              },
              {
                "key": "Content-Type",
                "value": "application/json"
              }
            ],
            "url": {
              "raw": "{{transactions_url}}/api/v1/transactions",
              "host": ["{{transactions_url}}"],
              "path": ["api", "v1", "transactions"]
            },
            "body": {
              "mode": "raw",
              "raw": "{\n  \"type\": \"EXPENSE\",\n  \"categoryId\": \"550e8400-e29b-41d4-a716-446655440010\",\n  \"description\": \"Groceries\",\n  \"amount\": 75.50,\n  \"date\": \"2025-12-30T14:30:00Z\"\n}"
            }
          }
        },
        {
          "name": "3. Get Transaction by ID",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{access_token}}"
              }
            ],
            "url": {
              "raw": "{{transactions_url}}/api/v1/transactions/{{transaction_id}}",
              "host": ["{{transactions_url}}"],
              "path": ["api", "v1", "transactions", "{{transaction_id}}"]
            }
          }
        }
      ]
    }
  ],
  "variable": [
    {
      "key": "auth_url",
      "value": "http://localhost:5000"
    },
    {
      "key": "transactions_url",
      "value": "http://localhost:5001"
    },
    {
      "key": "access_token",
      "value": ""
    },
    {
      "key": "refresh_token",
      "value": ""
    },
    {
      "key": "transaction_id",
      "value": ""
    }
  ]
}
```

---

## 🔧 Pre-request Script en Postman

Para extraer tokens automáticamente después del login:

```javascript
// En el tab "Tests" de la solicitud "1. Login"
if (pm.response.code === 200) {
    var jsonData = pm.response.json();
    pm.environment.set("access_token", jsonData.data.accessToken);
    pm.environment.set("refresh_token", jsonData.data.refreshToken);
    console.log("✅ Tokens guardados en environment");
}
```

---

## 📊 Flujo Completo de Testing

```
1. [POST] Login
   ├─ Input: {username, password}
   └─ Output: {accessToken, refreshToken} ← Guardar

2. [GET] List Transactions
   ├─ Header: Authorization: Bearer {{access_token}}
   └─ Output: List de transacciones del usuario

3. [POST] Create Transaction
   ├─ Header: Authorization: Bearer {{access_token}}
   ├─ Body: {type, amount, description, ...}
   └─ Output: Nueva transacción con ID

4. [GET] Get Transaction
   ├─ Header: Authorization: Bearer {{access_token}}
   ├─ URL: /api/v1/transactions/{id}
   └─ Output: Transacción específica

5. [POST] Refresh Token
   ├─ Body: {refreshToken}
   └─ Output: {accessToken, refreshToken} nuevos ← Actualizar

6. [POST] Logout
   ├─ Header: Authorization: Bearer {{access_token}}
   └─ Output: Success

7. [GET] List Transactions (con token viejo)
   ├─ Header: Authorization: Bearer {{old_access_token}}
   └─ Output: 401 Unauthorized ✅
```

---

## 🐛 Troubleshooting

### Error: 401 Unauthorized - Missing token

**Problema:** Header Authorization no incluido o formato incorrecto

**Solución:**
```
❌ Authorization: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
✅ Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Error: 401 Unauthorized - Invalid token signature

**Problema:** Secret key diferente en ambos servicios

**Solución:**
- Verificar `appsettings.json` en ambos servicios
- Debe ser IDÉNTICO: `Jwt:SecretKey`
- Reiniciar servicios después de cambiar

### Error: 401 Unauthorized - Token expired

**Problema:** Token expiró (más de 15 minutos)

**Solución:**
- Usar Refresh Token para obtener nuevo Access Token
- Solicitar new login si no hay refresh token válido

### Error: 401 Unauthorized - Invalid token claims

**Problema:** JWT no contiene los claims obligatorios

**Solución:**
- Decodificar en jwt.io y revisar payload
- Verificar que Auth Service está emitiendo correctamente

### Error: 403 Forbidden - Insufficient permissions

**Problema:** Usuario intenta acceder recurso de otro usuario

**Solución:**
- ValidateResourceOwnership() impide cross-user access
- Verificar que el userId extraído del JWT es correcto

---

## 📚 Referencias

- [Postman Documentation](https://learning.postman.com)
- [cURL Manual](https://curl.se/docs/manual.html)
- [JWT.io - Decoder](https://jwt.io)
- [RFC 7519 - JWT](https://tools.ietf.org/html/rfc7519)

