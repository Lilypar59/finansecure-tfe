# FinanSecure Website - Guía de Uso

## 📋 Descripción

Sitio web informativo y landing page para **FinanSecure**, una plataforma moderna de gestión financiera personal. El sitio presenta la propuesta de valor, características técnicas y permite contacto directo con el equipo.

## 📁 Estructura de Archivos

```
website/
├── index.html              # Página principal (HTML semántico)
├── styles.css              # Estilos (CSS Grid + Flexbox, responsive)
├── script.js               # Interactividad (navegación, validación)
├── WEBSITE_CONTENT.md      # Documentación: contenido y UX
├── WEBSITE_STRUCTURE.md    # Documentación: wireframes y arquitectura
└── README.md               # Este archivo
```

## 🚀 Inicio Rápido

### Opción 1: Abrir en Navegador (Local)
```bash
# Navega a la carpeta website
cd website/

# Abre index.html en tu navegador
open index.html  # macOS
# o
start index.html  # Windows
# o
xdg-open index.html  # Linux
```

### Opción 2: Usar Python SimpleHTTPServer (Recomendado)
```bash
cd website/

# Python 3
python -m http.server 8000

# Python 2
python -m SimpleHTTPServer 8000
```

Luego abre: http://localhost:8000

### Opción 3: Usar Live Server (VS Code)
1. Instala extensión "Live Server" en VS Code
2. Click derecho en `index.html`
3. Select "Open with Live Server"
4. Se abrirá automáticamente en http://localhost:5500

## 📱 Características del Sitio

### Responsividad
- ✅ Desktop (1200px+): Layout completo
- ✅ Tablet (768px): 2 columnas
- ✅ Mobile (375px): 1 columna

### Secciones
1. **Header** - Navegación y branding
2. **Hero** - Propuesta de valor principal
3. **Características** - 6 beneficios clave
4. **Arquitectura** - Detalles técnicos y seguridad
5. **Contacto** - Formulario + información
6. **Login CTA** - Enlace a aplicación web
7. **Footer** - Links y legal

### Interactividad
- ✅ Navegación suave (smooth scroll)
- ✅ Links activos dinámicos (highlight según sección)
- ✅ Animaciones de fade-in en cards
- ✅ Hover effects en botones y links
- ✅ Validación de formulario en frontend

## 🎨 Personalización

### Colores
Edita las variables en `styles.css`:
```css
:root {
    --color-primary: #1a2332;      /* Azul marino principal */
    --color-secondary: #0066cc;    /* Azul profesional */
    --color-accent: #00cc99;       /* Verde menta */
    --color-background: #f5f6f8;   /* Gris claro */
    /* ... más variables ... */
}
```

### Tipografía
La fuente usa system fonts para carga rápida. Para cambiar:
```css
--font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
```

### Contenido
Edita el texto en `index.html`. Secciones principales:
- **H1 Hero:** `<h1>Gestión Financiera Personal</h1>`
- **Features:** Busca `<section id="features">`
- **Architecture:** Busca `<section id="architecture">`
- **Contact:** Busca `<section id="contact">`

## 📧 Configurar Formulario de Contacto

### Opción 1: Usar Formspree.io (Recomendado)
1. Ve a https://formspree.io
2. Crea una cuenta gratis
3. Crea un nuevo proyecto
4. Obtén tu ID de formulario (ej: `abc123def456`)
5. En `index.html`, reemplaza:
```html
<!-- Actual -->
<form class="contact-form" action="https://formspree.io/f/YOUR_FORM_ID" method="POST">

<!-- Ejemplo -->
<form class="contact-form" action="https://formspree.io/f/xyzabc123" method="POST">
```

### Opción 2: Usar mailto: Link (Alternativa simple)
```html
<a href="mailto:info@finansecure.com?subject=Contacto%20FinanSecure">
    Enviar Email
</a>
```

### Opción 3: Backend Custom
Si tienes un servidor .NET disponible:
```javascript
// En script.js, agregar:
document.querySelector('.contact-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const response = await fetch('/api/contact', {
        method: 'POST',
        body: formData
    });
    // Handle response...
});
```

## 🌐 Configurar URLs

### Enlace a Aplicación Web
En varios lugares del sitio se referencias la app web:
```html
<!-- Actual: localhost para desarrollo -->
http://localhost:4200

<!-- Producción (cambiar a): -->
https://tu-dominio.com/app
```

Busca y reemplaza en `index.html`:
- Hero button CTA
- Contact info
- Login section
- Footer

### Emails
Reemplaza los emails de ejemplo:
- `info@finansecure.com` → tu email general
- `support@finansecure.com` → tu email soporte

## 📊 Performance

### Optimizaciones incluidas
- ✅ CSS variables (menores downloads)
- ✅ System fonts (sin cargas externas)
- ✅ No jQuery ni librerías pesadas
- ✅ Minimalista animations (0.3s max)
- ✅ Mobile-first CSS

### Métricas objetivo
- Load time: < 2 segundos
- Lighthouse: > 90
- Contraste WCAG: AA+
- Accessibility: 95+

### Test localmente
```bash
# Chrome DevTools
1. F12 → Lighthouse
2. Run audit
3. Check performance/accessibility
```

## 🔒 Seguridad

### Checklist
- [ ] HTTPS en producción (requerido)
- [ ] CORS configurado si usa API backend
- [ ] Validación de formularios (frontend + backend)
- [ ] Rate limiting en API backend
- [ ] Content Security Policy header

### Headers recomendados (server)
```
Strict-Transport-Security: max-age=31536000
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
```

## 📈 SEO

### Meta Tags (ya incluidos)
```html
<title>FinanSecure - Gestión Financiera Moderna y Segura</title>
<meta name="description" content="...">
<meta property="og:title" content="...">
<meta property="og:description" content="...">
```

### Para mejorar
1. Crear `sitemap.xml`
2. Crear `robots.txt`
3. Agregar Google Analytics
4. Optimizar imágenes
5. Structured data (schema.org)

### Palabras clave target
- Gestión financiera personal
- Aplicación de presupuestos
- Seguimiento de gastos
- Seguridad fintech
- Microservicios financieros

## 🧪 Testing

### Manual Testing Checklist
```
NAVEGACIÓN
[ ] Header links funcionan
[ ] Smooth scroll activo
[ ] Active state se actualiza
[ ] Header fijo en scroll

HERO
[ ] Botones visibles
[ ] Texto legible (contraste)
[ ] Responsive correcta

FEATURES
[ ] Cards se muestran (6)
[ ] Hover effects funcionan
[ ] Mobile: apiladas verticales

ARQUITECTURA
[ ] Diagrama visible
[ ] Security items 6/6
[ ] Tech list completa

CONTACTO
[ ] Formulario valida
[ ] Emails funcionales
[ ] Info de contacto correcta

FOOTER
[ ] Links funcionales
[ ] Año actualizado
[ ] Responsive correcto

RESPONSIVIDAD
[ ] Desktop: 1920px ✓
[ ] Tablet: 768px ✓
[ ] Mobile: 375px ✓
[ ] Touch targets > 48px ✓

ACCESIBILIDAD
[ ] Teclado navigation
[ ] Screen reader
[ ] Contraste 4.5:1
[ ] Focus visible
[ ] Alt text presente
```

## 📚 Documentación

### Archivos de referencia
- **WEBSITE_CONTENT.md** - Copys, UX recomendaciones, SEO keywords
- **WEBSITE_STRUCTURE.md** - Wireframes ASCII, arquitectura, patrones diseño

### Para expandir el sitio
1. **Blog:** Crear carpeta `/blog` con posts
2. **Pricing:** Nueva sección `/pricing`
3. **API Docs:** Link a Swagger en `/api`
4. **Blog Post Template:**
```html
<section id="blog-post-1" class="blog-post">
    <h2>Título del Post</h2>
    <p class="date">Publicado: 2025-01-15</p>
    <article>
        <!-- Contenido aquí -->
    </article>
</section>
```

## 🚢 Deployment

### GitHub Pages (Gratis)
```bash
1. Crea repo: finansecure-website
2. Push carpeta /website al root
3. Settings → Pages → Deploy from main/docs
4. Acceso: https://tu-usuario.github.io/finansecure-website
```

### Netlify (Gratis + features)
```bash
1. npm install -g netlify-cli
2. netlify deploy --prod --dir website
3. Seguir prompts
4. Custom domain: tu-dominio.com
```

### Vercel (Gratis + rápido)
```bash
1. Conecta repo a Vercel
2. Deploy automático
3. Preview URL generada
4. HTTPS incluido
```

### Servidor propio
```bash
# Copiar archivos a servidor
scp -r website/* usuario@servidor.com:/var/www/finansecure/

# Configurar nginx
server {
    listen 443 ssl http2;
    server_name finansecure.com;
    root /var/www/finansecure;
    
    ssl_certificate /etc/letsencrypt/live/finansecure.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/finansecure.com/privkey.pem;
    
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
```

## 🐛 Troubleshooting

### Formulario no envía
- [ ] Verifica URL de Formspree es correcta
- [ ] Asegúrate que method="POST"
- [ ] Abre DevTools → Network → ver response

### Estilos no carga
- [ ] Verifica ruta de CSS: `<link rel="stylesheet" href="styles.css">`
- [ ] Asegúrate que styles.css está en mismo directorio que index.html
- [ ] Chrome: Ctrl+Shift+R (hard refresh)

### Links internos no funcionan
- [ ] Verifica IDs en secciones: `<section id="features">`
- [ ] Los href deben coincidir: `href="#features"`
- [ ] Usa Inspector para verificar ID

### Mobile scroll lento
- [ ] Revisa performance en Chrome DevTools
- [ ] Reduce animaciones
- [ ] Optimiza imágenes

## 📞 Soporte

Para preguntas:
1. Revisa `WEBSITE_CONTENT.md` (UX + copys)
2. Revisa `WEBSITE_STRUCTURE.md` (arquitectura)
3. Abre DevTools (F12) para debugging
4. Valida HTML: https://validator.w3.org/

---

**Versión:** 1.0  
**Última actualización:** 2025-01-15  
**Autor:** Equipo FinanSecure  
**Licencia:** Privado - Todos los derechos reservados
