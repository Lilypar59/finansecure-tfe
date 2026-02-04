# Workflow Final - Código Completo

## Archivo: `.github/workflows/build-and-push.yml`

```yaml
name: Build and Push to AWS ECR

on:
  push:
    branches:
      - main
  workflow_dispatch

concurrency:
  group: ecr-build-${{ github.ref }}
  cancel-in-progress: true

env:
  AWS_REGION: us-east-1

jobs:
  build-and-push:
    name: Build and Push Docker Images to ECR
    runs-on: ubuntu-latest
    timeout-minutes: 45
    permissions:
      contents: read

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set build variables
        id: vars
        run: |
          SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)
          BRANCH_NAME=${{ github.ref_name }}
          TIMESTAMP=$(date -u +'%Y%m%d-%H%M%S')

          echo "short_sha=${SHORT_SHA}" >> $GITHUB_OUTPUT
          echo "branch_name=${BRANCH_NAME}" >> $GITHUB_OUTPUT
          echo "timestamp=${TIMESTAMP}" >> $GITHUB_OUTPUT

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: ecr-login
        uses: aws-actions/amazon-ecr-login@v2

      - name: Set ECR registry
        run: |
          echo "ecr_registry=${{ steps.ecr-login.outputs.registry }}" >> $GITHUB_ENV

      - name: Build and Push Auth Service
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./FinanSecure.Auth/Dockerfile
          push: true
          tags: |
            ${{ env.ecr_registry }}/finansecure-auth:${{ steps.vars.outputs.short_sha }}
            ${{ env.ecr_registry }}/finansecure-auth:${{ steps.vars.outputs.branch_name }}

      - name: Build and Push Frontend Service
        uses: docker/build-push-action@v5
        with:
          context: ./finansecure-web
          file: ./finansecure-web/Dockerfile.prod
          push: true
          tags: |
            ${{ env.ecr_registry }}/finansecure-frontend:${{ steps.vars.outputs.short_sha }}
            ${{ env.ecr_registry }}/finansecure-frontend:${{ steps.vars.outputs.branch_name }}

      - name: Build and Push Website Service
        uses: docker/build-push-action@v5
        with:
          context: ./website
          file: ./website/Dockerfile
          push: true
          tags: |
            ${{ env.ecr_registry }}/finansecure-website:${{ steps.vars.outputs.short_sha }}
            ${{ env.ecr_registry }}/finansecure-website:${{ steps.vars.outputs.branch_name }}

      - name: Summary
        run: |
          echo "✅ Build complete"
          echo "Registry: ${{ env.ecr_registry }}"
          echo "SHA: ${{ steps.vars.outputs.short_sha }}"
          echo "Branch: ${{ steps.vars.outputs.branch_name }}"
```

---

## Explicación Línea por Línea

### Metadata (Líneas 1-7)
```yaml
name: Build and Push to AWS ECR
```
Nombre del workflow visible en GitHub Actions.

```yaml
on:
  push:
    branches:
      - main
  workflow_dispatch
```
Triggers:
- Automático: cuando haces push a `main`
- Manual: puedes ejecutar desde GitHub Actions UI

### Configuración Global (Líneas 8-13)
```yaml
concurrency:
  group: ecr-build-${{ github.ref }}
  cancel-in-progress: true
```
Si haces 2 pushes rápidamente, cancela el primero.

```yaml
env:
  AWS_REGION: us-east-1
```
Región AWS donde está tu ECR.

### Job Principal (Líneas 15-19)
```yaml
jobs:
  build-and-push:
    name: Build and Push Docker Images to ECR
    runs-on: ubuntu-latest
    timeout-minutes: 45
    permissions:
      contents: read
```
Un solo job que:
- Corre en Ubuntu
- Máximo 45 minutos
- Solo necesita leer el código

### Step 1: Checkout (Líneas 22-25)
```yaml
- name: Checkout code
  uses: actions/checkout@v4
  with:
    fetch-depth: 0
```
Descarga el repositorio con todo el historio Git.

### Step 2: Variables (Líneas 27-38)
```yaml
- name: Set build variables
  id: vars
  run: |
    SHORT_SHA=$(echo ${{ github.sha }} | cut -c1-7)
    BRANCH_NAME=${{ github.ref_name }}
    TIMESTAMP=$(date -u +'%Y%m%d-%H%M%S')

    echo "short_sha=${SHORT_SHA}" >> $GITHUB_OUTPUT
    echo "branch_name=${BRANCH_NAME}" >> $GITHUB_OUTPUT
    echo "timestamp=${TIMESTAMP}" >> $GITHUB_OUTPUT
```
Define variables para tagging:
- `short_sha`: Primeros 7 caracteres del commit (ej: `a1b2c3d`)
- `branch_name`: Nombre de la rama (ej: `main`)
- `timestamp`: Fecha/hora (ej: `20260202-143050`)

### Step 3: AWS Config (Líneas 40-45)
```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ env.AWS_REGION }}
```
Configura credenciales de AWS para acceder a ECR.

**Requiere 2 secretos:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

### Step 4: ECR Login (Líneas 47-49)
```yaml
- name: Login to Amazon ECR
  id: ecr-login
  uses: aws-actions/amazon-ecr-login@v2
```
Autentica con ECR usando las credenciales de AWS.

### Step 5: Set Registry (Líneas 51-53)
```yaml
- name: Set ECR registry
  run: |
    echo "ecr_registry=${{ steps.ecr-login.outputs.registry }}" >> $GITHUB_ENV
```
Guarda la URI del ECR registry en una variable global.

Ejemplo: `123456789012.dkr.ecr.us-east-1.amazonaws.com`

### Steps 6-8: Build & Push (Líneas 55-91)
```yaml
- name: Build and Push Auth Service
  uses: docker/build-push-action@v5
  with:
    context: .
    file: ./FinanSecure.Auth/Dockerfile
    push: true
    tags: |
      ${{ env.ecr_registry }}/finansecure-auth:${{ steps.vars.outputs.short_sha }}
      ${{ env.ecr_registry }}/finansecure-auth:${{ steps.vars.outputs.branch_name }}
```

Construye y pushea cada imagen con 2 tags:
- `a1b2c3d` (SHA corto)
- `main` (rama)

**Para cada servicio:**

**Auth:**
```
$ECR_REGISTRY/finansecure-auth:a1b2c3d
$ECR_REGISTRY/finansecure-auth:main
```

**Frontend:**
```
$ECR_REGISTRY/finansecure-frontend:a1b2c3d
$ECR_REGISTRY/finansecure-frontend:main
```

**Website:**
```
$ECR_REGISTRY/finansecure-website:a1b2c3d
$ECR_REGISTRY/finansecure-website:main
```

### Step 9: Summary (Líneas 93-98)
```yaml
- name: Summary
  run: |
    echo "✅ Build complete"
    echo "Registry: ${{ env.ecr_registry }}"
    echo "SHA: ${{ steps.vars.outputs.short_sha }}"
    echo "Branch: ${{ steps.vars.outputs.branch_name }}"
```
Imprime un resumen al final.

---

## Variables Dinámicas

| Variable | Ejemplo | Dónde se usa |
|----------|---------|--------------|
| `${{ github.sha }}` | `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6` | Identificador del commit |
| `${{ steps.vars.outputs.short_sha }}` | `a1b2c3d` | Tags de imágenes |
| `${{ steps.vars.outputs.branch_name }}` | `main` | Tags de imágenes |
| `${{ env.AWS_REGION }}` | `us-east-1` | Configuración de AWS |
| `${{ env.ecr_registry }}` | `123456789012.dkr.ecr.us-east-1...` | URIs de imágenes |
| `${{ secrets.AWS_ACCESS_KEY_ID }}` | (secreto) | Auth de AWS |
| `${{ secrets.AWS_SECRET_ACCESS_KEY }}` | (secreto) | Auth de AWS |

---

## Flujo de Ejecución

```
1. Push a main
   ↓
2. Trigger automático del workflow
   ↓
3. Spin up: Ubuntu runner
   ↓
4. Checkout del código
   ↓
5. Calcula SHA corto, rama, timestamp
   ↓
6. Autentica con AWS
   ↓
7. Login a ECR
   ↓
8. Build image #1 (Auth) + push
   ↓
9. Build image #2 (Frontend) + push
   ↓
10. Build image #3 (Website) + push
   ↓
11. Print summary
   ↓
12. Workflow completo ✅
```

---

## Líneas Clave

| Línea | Propósito |
|-------|-----------|
| 3-7 | Cuándo ejecutar |
| 8-13 | Configuración global |
| 40-45 | Autenticación AWS |
| 47-49 | Login a ECR |
| 55-66 | Build Auth |
| 68-79 | Build Frontend |
| 81-91 | Build Website |

---

## Requisitos Funcionales

✅ **Necesarios:**
- 2 GitHub Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- AWS_ACCOUNT_ID (inferido en el secret)
- 3 Dockerfiles existentes
- Push a rama `main`

✅ **Generados automáticamente:**
- Short SHA del commit
- Nombre de la rama
- Timestamp

---

## Tiempo de Ejecución Esperado

```
Setup:        ~2 min
Checkout:     ~1 min
AWS config:   ~1 min
ECR login:    ~1 min
Build Auth:   ~8 min
Build Front:  ~8 min
Build Web:    ~3 min
Summary:      <1 min
─────────────────────
Total:        ~20-25 min
```

---

**Este workflow es limpio, eficiente y listo para Fase 4.** ✅
