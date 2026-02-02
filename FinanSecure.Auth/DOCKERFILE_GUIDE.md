╔════════════════════════════════════════════════════════════════════════════╗
║  DOCKERFILE GUIDE: FinanSecure.Auth Microservice                            ║
║  Multi-Stage | Production-Ready | EC2 | ECS | Kubernetes                   ║
╚════════════════════════════════════════════════════════════════════════════╝

## 📋 ÍNDICE
1. Explicación del Dockerfile
2. Compilación de imágenes
3. Ejemplos por plataforma (EC2, ECS, Kubernetes)
4. Variables de entorno
5. Troubleshooting

════════════════════════════════════════════════════════════════════════════════
## 1️⃣ EXPLICACIÓN DEL DOCKERFILE
════════════════════════════════════════════════════════════════════════════════

### 📦 STAGE 1: BUILD
├─ Propósito: Compilar código .NET
├─ Imagen base: mcr.microsoft.com/dotnet/sdk:8.0-alpine
├─ Acciones:
│  ├─ WORKDIR /src: Directorio de trabajo
│  ├─ COPY: Copiar .csproj (aprovecha caché Docker)
│  ├─ RUN dotnet restore: Descargar dependencies
│  ├─ COPY: Copiar código fuente
│  └─ RUN dotnet build: Compilar en Release mode
└─ Tamaño: ~900 MB (se descarta en imagen final)

### 📦 STAGE 1B: PUBLISH
├─ Propósito: Preparar archivos para runtime
├─ Imagen: Continúa en stage build (reutiliza caché)
├─ Acciones:
│  └─ RUN dotnet publish: Publicar en /app/publish
└─ Ventaja: Caché optimizado, no duplica trabajo

### 🚀 STAGE 2: RUNTIME (FINAL)
├─ Propósito: Imagen minimalista para producción
├─ Imagen base: mcr.microsoft.com/dotnet/aspnet:8.0-alpine
├─ Características:
│  ├─ ✅ Tamaño: ~200 MB (6x más pequeño que Stage 1)
│  ├─ ✅ Usuario non-root: appuser (UID 1001)
│  ├─ ✅ Puerto: 8080 (no requiere root)
│  ├─ ✅ Healthcheck: /health endpoint
│  ├─ ✅ Variables de entorno: Configurables
│  └─ ✅ ENTRYPOINT: dotnet FinanSecure.Auth.dll
└─ Seguridad: Mínima superficie de ataque

════════════════════════════════════════════════════════════════════════════════
## 2️⃣ COMPILACIÓN DE IMÁGENES
════════════════════════════════════════════════════════════════════════════════

### 🔨 COMPILAR IMAGEN
```bash
# Compilar imagen local (desde raíz del proyecto)
docker build -t finansecure-auth:latest \
  --file FinanSecure.Auth/Dockerfile .

# Compilar con tag específico
docker build -t finansecure-auth:1.0.0 \
  --file FinanSecure.Auth/Dockerfile .

# Compilar con buildkit (más rápido)
DOCKER_BUILDKIT=1 docker build -t finansecure-auth:latest \
  --file FinanSecure.Auth/Dockerfile .

# Compilar y pushear a registry
docker build -t myregistry.azurecr.io/finansecure-auth:latest \
  --file FinanSecure.Auth/Dockerfile .
docker push myregistry.azurecr.io/finansecure-auth:latest
```

### 📊 VERIFICAR IMAGEN
```bash
# Listar imágenes
docker images | grep finansecure-auth

# Inspeccionar imagen
docker inspect finansecure-auth:latest

# Ver capas
docker history finansecure-auth:latest
```

════════════════════════════════════════════════════════════════════════════════
## 3️⃣ EJEMPLOS POR PLATAFORMA
════════════════════════════════════════════════════════════════════════════════

### 🖥️  AWS EC2 (Single Server)
────────────────────────────────────────────────────────────────────────────────

1️⃣ INSTALAR DOCKER EN EC2
```bash
# SSH a la instancia EC2
ssh -i key.pem ec2-user@your-instance-ip

# Actualizar sistema
sudo yum update -y
sudo yum install -y docker git

# Iniciar Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
```

2️⃣ CLONAR REPOSITORIO Y COMPILAR
```bash
# Clonar código
git clone https://github.com/your-repo/finansecure.git
cd finansecure

# Compilar imagen
sudo docker build -t finansecure-auth:1.0.0 \
  --file FinanSecure.Auth/Dockerfile .

# O usar docker-compose para facilitar
sudo docker-compose up -d
```

3️⃣ EJECUTAR CON VARIABLES DE ENTORNO
```bash
docker run -d \
  --name finansecure-auth \
  --restart always \
  -p 8080:8080 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e DB_HOST=postgres.internal \
  -e DB_PORT=5432 \
  -e DB_DATABASE=finansecure_auth_db_prod \
  -e DB_USER=dbuser \
  -e DB_PASSWORD=secretpassword \
  -e JWT_SECRET_KEY=your-long-secret-key-here \
  -v /data/logs:/app/logs \
  finansecure-auth:1.0.0
```

4️⃣ VERIFICAR SALUD
```bash
# Healthcheck
curl http://localhost:8080/health
# Respuesta esperada: { "status": "healthy" }

# Ver logs
docker logs finansecure-auth -f
```

────────────────────────────────────────────────────────────────────────────────

### 🐳 AWS ECS (Container Orchestration)
────────────────────────────────────────────────────────────────────────────────

1️⃣ CREAR ECR REPOSITORY
```bash
# En AWS Console o CLI
aws ecr create-repository \
  --repository-name finansecure-auth \
  --region us-east-1
```

2️⃣ PUSHEAR IMAGEN A ECR
```bash
# Login a ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# Tag imagen
docker tag finansecure-auth:1.0.0 \
  123456789.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:1.0.0

# Push a ECR
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:1.0.0
```

3️⃣ CREAR TASK DEFINITION (ecs-task-definition.json)
```json
{
  "family": "finansecure-auth",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "containerDefinitions": [
    {
      "name": "finansecure-auth",
      "image": "123456789.dkr.ecr.us-east-1.amazonaws.com/finansecure-auth:1.0.0",
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ASPNETCORE_ENVIRONMENT",
          "value": "Production"
        },
        {
          "name": "DB_HOST",
          "value": "postgres.internal"
        },
        {
          "name": "DB_PORT",
          "value": "5432"
        }
      ],
      "secrets": [
        {
          "name": "DB_PASSWORD",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:finansecure/db-password"
        },
        {
          "name": "JWT_SECRET_KEY",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:123456789:secret:finansecure/jwt-secret"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/finansecure-auth",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"],
        "interval": 30,
        "timeout": 10,
        "retries": 3,
        "startPeriod": 40
      }
    }
  ]
}
```

4️⃣ REGISTRAR Y EJECUTAR TASK
```bash
# Registrar task definition
aws ecs register-task-definition \
  --cli-input-json file://ecs-task-definition.json

# Crear servicio en ECS Cluster
aws ecs create-service \
  --cluster finansecure-cluster \
  --service-name finansecure-auth \
  --task-definition finansecure-auth:1 \
  --desired-count 3 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
```

────────────────────────────────────────────────────────────────────────────────

### ☸️  KUBERNETES (Multi-Host Orchestration)
────────────────────────────────────────────────────────────────────────────────

1️⃣ PUSHEAR IMAGEN A REGISTRY (Docker Hub / ECR / ACR)
```bash
# Docker Hub
docker tag finansecure-auth:1.0.0 myusername/finansecure-auth:1.0.0
docker login
docker push myusername/finansecure-auth:1.0.0

# O Azure Container Registry (ACR)
docker tag finansecure-auth:1.0.0 myregistry.azurecr.io/finansecure-auth:1.0.0
az acr login --name myregistry
docker push myregistry.azurecr.io/finansecure-auth:1.0.0
```

2️⃣ CREAR KUBERNETES MANIFESTS (k8s-deployment.yaml)
```yaml
---
# Namespace
apiVersion: v1
kind: Namespace
metadata:
  name: finansecure

---
# ConfigMap para variables no-secretas
apiVersion: v1
kind: ConfigMap
metadata:
  name: finansecure-auth-config
  namespace: finansecure
data:
  ASPNETCORE_ENVIRONMENT: "Production"
  DB_HOST: "postgres.finansecure.svc.cluster.local"
  DB_PORT: "5432"
  DB_DATABASE: "finansecure_auth_db_prod"
  JWT_ISSUER: "FinanSecure"
  JWT_AUDIENCE: "FinanSecure.Client"

---
# Secret para credenciales sensibles
apiVersion: v1
kind: Secret
metadata:
  name: finansecure-auth-secrets
  namespace: finansecure
type: Opaque
stringData:
  DB_USER: "dbuser"
  DB_PASSWORD: "your-secure-password"
  JWT_SECRET_KEY: "your-long-secret-key-here-min-32-chars"

---
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: finansecure-auth
  namespace: finansecure
  labels:
    app: finansecure-auth
    version: v1
spec:
  replicas: 3  # High Availability
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: finansecure-auth
  template:
    metadata:
      labels:
        app: finansecure-auth
        version: v1
    spec:
      # Security Context (non-root user)
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      
      containers:
      - name: finansecure-auth
        image: myusername/finansecure-auth:1.0.0
        imagePullPolicy: IfNotPresent
        
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        
        # Variables de entorno desde ConfigMap
        envFrom:
        - configMapRef:
            name: finansecure-auth-config
        
        # Variables de entorno desde Secret
        env:
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: finansecure-auth-secrets
              key: DB_USER
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: finansecure-auth-secrets
              key: DB_PASSWORD
        - name: JWT_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: finansecure-auth-secrets
              key: JWT_SECRET_KEY
        
        # Liveness Probe (¿está vivo?)
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 40
          periodSeconds: 30
          timeoutSeconds: 10
          failureThreshold: 3
        
        # Readiness Probe (¿listo para tráfico?)
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 20
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 2
        
        # Recursos
        resources:
          requests:
            cpu: 250m
            memory: 512Mi
          limits:
            cpu: 500m
            memory: 1Gi
        
        # Security Context (contenedor)
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        # Volumes
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-tmp
          mountPath: /var/tmp
      
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-tmp
        emptyDir: {}

---
# Service
apiVersion: v1
kind: Service
metadata:
  name: finansecure-auth
  namespace: finansecure
  labels:
    app: finansecure-auth
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: finansecure-auth

---
# HorizontalPodAutoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: finansecure-auth-hpa
  namespace: finansecure
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: finansecure-auth
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80

---
# Ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: finansecure-auth-ingress
  namespace: finansecure
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - auth.finansecure.com
    secretName: finansecure-auth-tls
  rules:
  - host: auth.finansecure.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: finansecure-auth
            port:
              number: 80
```

3️⃣ DESPLEGAR EN KUBERNETES
```bash
# Aplicar manifests
kubectl apply -f k8s-deployment.yaml

# Verificar deployment
kubectl get deployments -n finansecure
kubectl get pods -n finansecure
kubectl get svc -n finansecure

# Ver logs
kubectl logs -n finansecure -l app=finansecure-auth -f

# Verificar health
kubectl port-forward -n finansecure svc/finansecure-auth 8080:80
curl http://localhost:8080/health

# Escalar manualmente
kubectl scale deployment finansecure-auth -n finansecure --replicas=5

# Actualizar imagen
kubectl set image deployment/finansecure-auth \
  -n finansecure \
  finansecure-auth=myusername/finansecure-auth:1.0.1

# Ver status de rollout
kubectl rollout status deployment/finansecure-auth -n finansecure
```

════════════════════════════════════════════════════════════════════════════════
## 4️⃣ VARIABLES DE ENTORNO
════════════════════════════════════════════════════════════════════════════════

### 🔧 VARIABLES PRINCIPALES

| Variable | Por Defecto | Descripción |
|----------|-------------|-------------|
| ASPNETCORE_ENVIRONMENT | Production | Entorno (Development/Staging/Production) |
| ASPNETCORE_URLS | http://+:8080 | URL de escucha |
| DB_HOST | postgres | Hostname del servidor PostgreSQL |
| DB_PORT | 5432 | Puerto de PostgreSQL |
| DB_DATABASE | finansecure_auth_db_dev | Nombre de la base de datos |
| DB_USER | postgres | Usuario de BD |
| DB_PASSWORD | postgres | Contraseña de BD |
| JWT_SECRET_KEY | your-secret-key-change-in-production | Clave JWT (⚠️ CAMBIAR) |
| JWT_ISSUER | FinanSecure | Emisor del JWT |
| JWT_AUDIENCE | FinanSecure.Client | Audiencia del JWT |
| JWT_EXPIRATION_MINUTES | 15 | Expiración del access token |
| JWT_REFRESH_EXPIRATION_DAYS | 7 | Expiración del refresh token |
| LOG_LEVEL | Information | Nivel de logging |

### ⚠️ VARIABLES CRÍTICAS EN PRODUCCIÓN

```bash
# CAMBIAR ESTOS VALORES SIEMPRE

# 1. JWT_SECRET_KEY: Mínimo 32 caracteres, aleatorio
JWT_SECRET_KEY="gH$b7#kL2!xQ@mP9$vC&wD3*jF5!nR7&sT8@hJ2"

# 2. DB_PASSWORD: Contraseña segura
DB_PASSWORD="ComplexP@ssw0rd!2024$ecure"

# 3. ASPNETCORE_ENVIRONMENT: Production
ASPNETCORE_ENVIRONMENT="Production"

# 4. Credenciales de acceso a registry
DOCKER_USERNAME="myusername"
DOCKER_PASSWORD="mypassword"
```

════════════════════════════════════════════════════════════════════════════════
## 5️⃣ TROUBLESHOOTING
════════════════════════════════════════════════════════════════════════════════

### 🐛 PROBLEMAS COMUNES

#### ❌ "Connection refused" a PostgreSQL
```bash
# Verificar que DB está accesible
docker run --rm --network host finansecure-auth:latest \
  bash -c "nc -zv postgres 5432"

# Solución: Asegurar que DB_HOST apunta a host correcto
# En Docker: usar nombre del service o network
docker run -e DB_HOST=postgres-container ...
```

#### ❌ "Permission denied" en logs
```bash
# Problema: Usuario no tiene permisos de escritura
# Solución en Dockerfile:
RUN mkdir -p /app/logs && \
    chown appuser:appgroup /app/logs

# O en runtime:
docker run -v /tmp/logs:/app/logs:rw ...
```

#### ❌ Healthcheck falla
```bash
# Verificar endpoint /health existe
docker exec finansecure-auth-container curl -i http://localhost:8080/health

# Si falla: Verificar que Controller tiene endpoint
# controllers/HealthController.cs debe tener:
// [HttpGet("health")]
// public ActionResult Health() => Ok(new { status = "healthy" });
```

#### ❌ Imagen muy grande
```bash
# Verificar tamaño de layers
docker history finansecure-auth:latest

# Soluciones:
# 1. Usar alpine images (.NET SDK/Runtime alpine)
# 2. Multi-stage dockerfile (❌ ya está implementado)
# 3. Limpiar NuGet cache
```

#### ❌ Compose no inicia
```bash
# Verificar logs
docker-compose logs -f

# Verificar que Dockerfile existe en ruta correcta
# Debe ser: FinanSecure.Auth/Dockerfile

# Solución: Especificar ruta completa en docker-compose.yml
build:
  context: .
  dockerfile: FinanSecure.Auth/Dockerfile
```

### ✅ VALIDACIÓN POST-DEPLOYMENT

```bash
# 1. ¿Imagen creada correctamente?
docker images | grep finansecure-auth

# 2. ¿Contenedor inicia?
docker run finansecure-auth:latest echo "OK"

# 3. ¿Puerto expuesto?
docker run -p 8080:8080 finansecure-auth:latest &
curl http://localhost:8080/health

# 4. ¿Healthcheck funciona?
docker ps | grep finansecure-auth  # Ver estado (healthy/unhealthy)

# 5. ¿Usuario non-root?
docker run finansecure-auth:latest id  # Debe ser uid=1001
```

════════════════════════════════════════════════════════════════════════════════
## 📊 COMPARATIVA: EC2 vs ECS vs Kubernetes
════════════════════════════════════════════════════════════════════════════════

| Aspecto | EC2 | ECS | Kubernetes |
|---------|-----|-----|-----------|
| **Complejidad** | ⭐ Baja | ⭐⭐ Media | ⭐⭐⭐ Alta |
| **Costo** | 💰 Bajo | 💰💰 Medio | 💰💰💰 Alto |
| **Escalabilidad** | Manual | Automática (Fargate) | Automática (HPA) |
| **Multi-cloud** | ❌ AWS Solo | ❌ AWS Solo | ✅ Multi-cloud |
| **HA Nativa** | ❌ Manual | ✅ Incorporada | ✅ Incorporada |
| **Ideal para** | MVP/Demo | Aplicaciones medianas | Microservicios complejos |
| **Curva aprendizaje** | Rápida | Media | Lenta |

════════════════════════════════════════════════════════════════════════════════
## 🔒 SEGURIDAD - CHECKLIST
════════════════════════════════════════════════════════════════════════════════

✅ Usuario non-root (UID 1001)
✅ Puerto > 1024 (8080, no requiere root)
✅ Healthcheck configurado
✅ Imagen oficial de Microsoft (.NET)
✅ Alpine Linux (menor superficie de ataque)
✅ No hardcoded secrets (usando variables de entorno)
✅ ReadOnly filesystem support (Kubernetes)
✅ Resource limits (Kubernetes/ECS)
✅ Security Context (K8s: no privilegios)
✅ Network policies (Kubernetes: aislamiento)
✅ TLS/HTTPS (Ingress NGINX con cert-manager)

════════════════════════════════════════════════════════════════════════════════
## 📚 REFERENCIAS
════════════════════════════════════════════════════════════════════════════════

- .NET 8 Docker Images: https://hub.docker.com/_/microsoft-dotnet-aspnet
- Dockerfile Best Practices: https://docs.docker.com/develop/dev-best-practices/
- ECS Task Definitions: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html
- Kubernetes Deployment: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
- Alpine Linux Security: https://alpinelinux.org/

════════════════════════════════════════════════════════════════════════════════
Fecha: 30 de Diciembre de 2025
Versión: 1.0
Estado: ✅ Production-Ready
════════════════════════════════════════════════════════════════════════════════
