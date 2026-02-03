<!-- ════════════════════════════════════════════════════════════════════════════════
     📋 GUÍA DE CONFIGURACIÓN: LOGIN → WEBSITE
     ════════════════════════════════════════════════════════════════════════════════ -->

# 🔗 Configuración de Navegación: Login ↔ Website

## 📍 ARQUITECTURA IMPLEMENTADA

### Desarrollo Local (Docker)
```
Navegador (localhost)
  │
  ├─→ localhost:80 → Angular SPA (Login, Register, Dashboard)
  │
  └─→ localhost:3000 → Website (Marketing / Información)
```

### AWS (Producción)
```
Navegador (ejemplo.com)
  │
  ├─→ ejemplo.com → Angular SPA (NGINX reverse proxy)
  │
  └─→ website.ejemplo.com (o dominio configurado) → Website estática
```

---

## 🔧 COMPONENTES MODIFICADOS

### 1️⃣ **config/environment.config.ts** (NUEVO)
- Define la configuración de URLs dinámicamente
- Detecta si está en localhost o en AWS
- Exporta `ENVIRONMENT_CONFIG` con `websiteUrl` correcto

```typescript
// En desarrollo: http://localhost:3000
// En AWS: https://website.ejemplo.com (o lo que configures)
export const ENVIRONMENT_CONFIG = getEnvironmentConfig();
```

### 2️⃣ **login.component.ts** (MODIFICADO)
- Importa `ENVIRONMENT_CONFIG`
- Expone `websiteUrl` en la plantilla
- Método `goToWebsite()` abre el website en nueva pestaña

```typescript
export class LoginComponent {
  websiteUrl = ENVIRONMENT_CONFIG.websiteUrl; // ✅ URL dinámica
  
  goToWebsite() {
    window.open(this.websiteUrl, '_blank');
  }
}
```

### 3️⃣ **login.component.html** (MODIFICADO)
- Agrupa botones en sección `.auth-links`
- Botón "Regístrate aquí"
- Botón "Volver al sitio web"

```html
<div class="auth-links">
  <button class="btn btn-link btn-block" (click)="goToRegister()">
    ¿No tienes cuenta? Regístrate aquí
  </button>

  <button class="btn btn-secondary btn-block" (click)="goToWebsite()">
    ← Volver al sitio web
  </button>
</div>
```

### 4️⃣ **login.component.css** (MODIFICADO)
- Estilos para `.auth-links` con gap entre botones
- Separación visual con border-top
- Estilos responsive para móvil

---

## 🚀 FLUJO DE USUARIO

### En Desarrollo Local (Docker)
1. Usuario abre navegador → `localhost` o `localhost:80`
2. Ve Angular SPA con login
3. Puede hacer clic en "Volver al sitio web"
4. Se abre `localhost:3000` en nueva pestaña ✅

### En AWS (Producción)
1. Usuario abre navegador → `ejemplo.com`
2. Ve Angular SPA con login (servido por NGINX en `ejemplo.com`)
3. Puede hacer clic en "Volver al sitio web"
4. Se abre `website.ejemplo.com` en nueva pestaña ✅
5. **NO se rompe** porque usa configuración dinámica ✅

---

## 🔐 SEGURIDAD & CONSIDERACIONES

### ✅ LO QUE ESTÁ BIEN
- **NO hay URLs hardcodeadas** en el HTML/TS
- La URL se obtiene dinámicamente en tiempo de ejecución
- Funciona en cualquier dominio sin cambios de código

### ⚠️ ANTES DE SUBIR A AWS

#### 1. Configurar el NGINX para que NGINX en el dominio raíz sea reverse proxy:
```nginx
# En localhost:80 → FinanSecure.Auth (API)
# En AWS → NGINX actúa como reverse proxy a múltiples servicios
```

#### 2. Decidir la URL del website:
**Opción A:** Subdominio separado (RECOMENDADO)
```
App: ejemplo.com
Website: website.ejemplo.com
```

**Opción B:** Ruta en el mismo dominio
```
App: ejemplo.com/app
Website: ejemplo.com/ (raíz)
```

**Opción C:** Dominio completamente separado
```
App: app.ejemplo.com
Website: ejemplo.com
```

#### 3. Si usas Opción A, actualiza ENVIRONMENT_CONFIG:
```typescript
// En AWS con subdominio:
websiteUrl: `${protocol}//website.${host}`

// En AWS con ruta:
websiteUrl: `${protocol}//${host}/website`

// En AWS con dominio separado: cambiar manualmente
```

---

## 🧪 PRUEBAS

### En Desarrollo (Docker)
```bash
# Levanta Docker Compose
docker compose up

# Abre en navegador
# - localhost → App
# - localhost:3000 → Website
# Prueba el botón "Volver al sitio web" → debe abrir localhost:3000 ✅
```

### En AWS (después de desplegar)
```
Abre en navegador: https://ejemplo.com
Prueba el botón "Volver al sitio web" → debe abrir https://website.ejemplo.com ✅
```

---

## 📦 ARCHIVOS AFECTADOS

```
finansecure-web/
├── src/app/
│   ├── config/
│   │   └── environment.config.ts         ← ✅ NUEVO
│   └── pages/
│       └── login/
│           ├── login.component.ts        ← ✅ MODIFICADO
│           ├── login.component.html      ← ✅ MODIFICADO
│           └── login.component.css       ← ✅ MODIFICADO
```

---

## 🎯 CHECKLIST PRE-PRODUCCIÓN

- [ ] Verificar que `environment.config.ts` detecta correctamente localhost
- [ ] Probar en Docker Compose local
- [ ] Decidir URL del website en AWS (subdominio, ruta, etc.)
- [ ] Actualizar `environment.config.ts` si es necesario para AWS
- [ ] Configurar NGINX en AWS para servir ambos servicios
- [ ] Configurar DNS/dominios en AWS Route53
- [ ] Prueba en AWS después del despliegue
- [ ] Verificar que CORS está correctamente configurado

---

## 💡 TIPS ADICIONALES

### Si quieres agregar más URLs dinámicas en el futuro:
```typescript
// En environment.config.ts
export interface EnvironmentConfig {
  apiUrl: string;
  websiteUrl: string;
  docsUrl?: string;          // ← Agregar más URLs
  supportUrl?: string;       // según necesites
  appName: string;
  environment: 'development' | 'production';
}
```

### Para debuggear la URL en el navegador:
```typescript
// En login.component.ts
ngOnInit() {
  console.log('Website URL:', this.websiteUrl);
  console.log('API URL:', ENVIRONMENT_CONFIG.apiUrl);
  console.log('Environment:', ENVIRONMENT_CONFIG.environment);
}
```

---

**Creado:** 2026-02-02
**Versión:** 1.0.0
