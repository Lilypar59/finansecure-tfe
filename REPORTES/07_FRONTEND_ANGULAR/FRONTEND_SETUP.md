# 🚀 Instrucciones para Probar FinanSecure Frontend

## Opción 1: Desarrollo Local Rápido (Recomendado)

```bash
cd finansecure-web
npm install
npm run build
npm run start  # O: ng serve para desarrollo
```

Luego accede a: `http://localhost:4200`

---

## Opción 2: Docker (Build ya incluido)

### Paso 1: Build de la imagen
```bash
docker build -f finansecure-web/Dockerfile -t finansecure-frontend:latest .
```

### Paso 2: Ejecutar contenedor
```bash
docker run -p 3000:80 finansecure-frontend:latest
```

Luego accede a: `http://localhost:3000`

---

## Opción 3: Docker Compose (Todos los servicios)

```bash
# Construir imagen
docker-compose build finansecure-frontend

# Ejecutar contenedor
docker-compose up -d finansecure-frontend

# Ver logs
docker-compose logs -f finansecure-frontend
```

Accede a: `http://localhost:3000`

---

## Checklist de Pruebas

- [ ] Página carga sin errores de red
- [ ] Puedo ver el contenido HTML
- [ ] Los estilos CSS cargan correctamente
- [ ] Las rutas de Angular funcionan (intenta navegar)
- [ ] No hay errores en la consola del navegador
