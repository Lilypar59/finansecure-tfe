# Resolución de Incidencia en Comunicación Cliente-Servidor mediante Reverse Proxy

## Resumen

Durante las fases de integración del proyecto FinanSecure se detectó una incidencia crítica que impedía la comunicación correcta entre la interfaz web y los servicios backend cuando se ejecutaba la arquitectura de contenedores mediante Docker Compose con NGINX como punto de entrada. El presente apartado documenta la incidencia, su análisis de causa raíz, las medidas correctivas implementadas y la justificación técnica de la solución adoptada desde una perspectiva de ingeniería DevOps.

---

## 1. Descripción de la Incidencia Detectada

### 1.1 Síntomas Observados

Durante la ejecución de pruebas de integración del cliente Angular (ejecutándose en contenedor con NGINX) contra el servicio de autenticación, se registraron errores HTTP 405 (Method Not Allowed) al intentar realizar solicitudes POST al endpoint `/api/v1/auth/login`. Los logs del servidor reverse proxy indicaban redirecciones inadecuadas (código 301 Moved Permanently) y el bloqueo de métodos HTTP que deberían estar permitidos.

Los síntomas manifestados fueron:
- Error HTTP 405 en respuesta a solicitudes POST
- Redirecciones inesperadas (301) hacia rutas alternativas
- Bloqueo de métodos HTTP válidos en los endpoints de API
- Fallos en la transmisión de datos entre frontend y backend

### 1.2 Contexto Arquitectónico

La arquitectura del proyecto utiliza una estructura basada en microservicios containerizados mediante Docker Compose con la siguiente topología:

- **Capa de Presentación**: Aplicación Angular ejecutándose en contenedor NGINX (puerto 80)
- **Capa de API Gateway**: NGINX como reverse proxy centralizado
- **Capa de Servicios**: Auth Service (puerto 8080) y Transactions Service (puerto 8081), no expuestos directamente
- **Capa de Persistencia**: PostgreSQL en red Docker interna, sin acceso directo desde navegador

Esta arquitectura implementa un patrón de API Gateway que actúa como punto único de entrada, proporcionando una abstracción sobre los servicios internos y gestionando el enrutamiento de tráfico HTTP hacia las instancias backend correspondientes.

### 1.3 Ambiente de Ejecución

La incidencia se manifestó específicamente en el entorno de contenedores Docker, donde se configuraron dos redes Docker distintas: una para la comunicación entre NGINX, Auth Service y Frontend (denominada `backend`), y otra para aislar PostgreSQL (denominada `auth-network`). Esta segmentación de redes es fundamental para implementar principios de menor privilegio en infraestructura.

---

## 2. Análisis de la Causa Raíz

### 2.1 Diferencia entre Resolución de Nombres en Docker y Acceso desde Navegador

La incidencia radicaba en una confusión conceptual entre dos mecanismos de acceso distintos:

**Desde dentro de Docker (contenedor a contenedor):** Los contenedores pueden comunicarse utilizando directamente los nombres DNS de los servicios definidos en el docker-compose.yml (p.ej., `http://finansecure-auth:8080`). Docker mantiene un servidor DNS interno que resuelve estos nombres al direccionamiento IP de los contenedores dentro de la red Docker.

**Desde el navegador del cliente:** El navegador web se ejecuta en la máquina host y no tiene acceso a la red DNS interna de Docker. Por lo tanto, las referencias a direcciones internas como `http://finansecure-auth:8080` resultan en fallos de resolución DNS o violaciones de políticas CORS (Cross-Origin Resource Sharing).

Inicialmente, la configuración del cliente (aplicación Angular) intentaba acceder directamente a los servicios backend utilizando URLs absolutas con direccionamiento interno de Docker (`http://finansecure-auth:8080/api/v1/auth`), lo cual era inaccesible desde el navegador y, en caso de serlo, violaría las restricciones CORS implementadas en los servicios.

### 2.2 Rol del Reverse Proxy en la Gestión de Métodos HTTP

NGINX, actuando como reverse proxy, es responsable de:

1. **Recibir solicitudes HTTP** desde el cliente (navegador)
2. **Validar la solicitud** conforme a su configuración de directivas
3. **Enrutar la solicitud** hacia el servicio backend correspondiente
4. **Propagar la respuesta** nuevamente hacia el cliente

Un error común en configuraciones de reverse proxy es la ausencia o mala configuración de directivas que especifiquen explícitamente qué métodos HTTP deben ser permitidos y reenviados. Si la configuración de NGINX no incluye explícitamente directivas de proxy para una ruta específica, el servidor puede responder con un error 405, rechazando métodos que debería permitir.

En este caso, la configuración inicial de NGINX carecía de directivas de proxy suficientemente específicas para las rutas `/api/*`, lo cual resultaba en que los métodos POST, PUT y DELETE se procesaban según las reglas por defecto del servidor web (que tienden a rechazarlos para recursos estáticos), en lugar de ser reenviados al backend.

### 2.3 Impacto de Configuración Incorrecta de NGINX en APIs REST

NGINX procesa las solicitudes de acuerdo a su configuración ordenada, evaluando bloques `location` de mayor a menor especificidad. Si un bloque `location` que maneja rutas genéricas (como `location /`) se coloca antes de bloques más específicos (como `location /api/v1/auth/`), las solicitudes API serán procesadas por la regla genérica en lugar de la específica.

Adicionalmente, las directivas de proxy (`proxy_pass`, `proxy_http_version`, `proxy_set_header`, etc.) son esenciales para transformar y reenviar correctamente las solicitudes HTTP. Sin estas directivas, NGINX trata las solicitudes como si fueran para contenido estático y aplica reglas restrictivas respecto a métodos HTTP permitidos.

Las API RESTful dependen fundamentalmente de métodos HTTP como POST, PUT, DELETE y PATCH. Una configuración que bloquee estos métodos hace completamente inviable cualquier operación de creación, actualización o eliminación de recursos, lo cual impide el funcionamiento correcto de cualquier aplicación cliente.

---

## 3. Medidas Correctivas Aplicadas

### 3.1 Reorganización de la Configuración de NGINX

Se implementaron cambios en la configuración del servidor NGINX para asegurar el correcto enrutamiento de solicitudes API:

**Principio de Especificidad:** Los bloques `location` que manejan rutas API específicas (`/api/v1/auth/`, `/api/v1/transactions/`) fueron posicionados **antes** del bloque genérico `location /`, asegurando que las solicitudes API sean evaluadas por las reglas más específicas en primer lugar.

**Directivas de Proxy Completas:** Cada bloque `location` para rutas API ahora incluye un conjunto completo de directivas de proxy:
- `proxy_pass`: especifica el destino interno del servicio
- `proxy_http_version 1.1`: asegura compatibilidad con HTTP/1.1 y WebSocket
- `proxy_set_header`: transmite información crítica como Host, X-Real-IP, X-Forwarded-For, X-Forwarded-Proto
- `proxy_cache_bypass`: desactiva caché para solicitudes que requieren datos frescos

Estas directivas garantizan que las solicitudes sean reenviadas íntegramente al backend sin transformaciones incorrectas que causarían errores de protocolo.

### 3.2 Corrección de la Configuración de Docker Compose

Se ajustó el archivo `docker-compose.yml` para asegurar:

**Orden de Servicios:** Las directivas de proxy en NGINX se configuraron de modo que referencian los servicios backend (`finansecure-auth`, `finansecure-transactions`) por su nombre DNS interno, que Docker resuelve automáticamente dentro de la red Docker.

**Configuración de Redes:** Se mantuvieron dos redes separadas según el principio de menor privilegio:
- Red `backend`: conecta NGINX, Auth Service y Transactions Service
- Red `auth-network`: conecta Auth Service y PostgreSQL, aislando la base de datos

**Soporte para Métodos HTTP:** Al enrutar correctamente las solicitudes mediante `proxy_pass`, todos los métodos HTTP estándar (GET, POST, PUT, DELETE, PATCH, OPTIONS) se transmiten sin restricciones hacia los servicios backend.

### 3.3 Garantía de Soporte para Métodos POST sin Redirecciones Indebidas

La solución implementada elimina las redirecciones inadecuadas mediante:

1. **Especificidad de Rutas:** Las rutas API son ahora manejadas por bloques `location` específicos que no aplican transformaciones URL que provoquen redirecciones.

2. **Preservación de Métodos HTTP:** Las directivas de proxy preservan el método HTTP original de la solicitud sin intentar modificarlo o rechazarlo basándose en reglas de contenido estático.

3. **Configuración CORS Complementaria:** En paralelo, se actualizó la configuración de CORS en el Auth Service para incluir explícitamente el origen `http://localhost` (NGINX en puerto 80) como origen permitido, eliminando conflictos de política de origen compartida.

4. **Rutas Relativas en Cliente:** La aplicación Angular fue configurada para utilizar rutas relativas (p.ej., `/api/v1/auth/login`) en lugar de URLs absolutas, permitiendo que el navegador envíe las solicitudes al mismo host desde el cual carga la página (NGINX), y NGINX las enrute internamente hacia los servicios backend.

---

## 4. Justificación Técnica de la Solución

### 4.1 NGINX como Punto Único de Entrada

La decisión de que NGINX actúe como punto único de entrada (API Gateway) se justifica desde múltiples perspectivas:

**Abstracción de Topología:** Desvincula el cliente de la implementación interna de la arquitectura. Cambios en puertos, direccionamiento o cantidad de instancias de servicios no requieren modificación de la lógica cliente.

**Gestión Centralizada de Tráfico:** Todas las solicitudes HTTP pasan por una capa única que puede implementar políticas de autenticación, autorización, rate limiting, logging y monitoreo de manera uniforme.

**Simplificación de CORS y Seguridad:** Elimina la necesidad de configurar CORS en cada servicio individual para múltiples orígenes. El proxy puede normalizar las solicitudes y respuestas conforme a políticas de seguridad centralizadas.

**Facilita Escalabilidad Horizontal:** Si en futuras fases se requiere ejecutar múltiples instancias de un servicio backend, el reverse proxy puede distribuir la carga entre ellas mediante algoritmos como round-robin o least connections, transparentemente para el cliente.

### 4.2 Beneficios en Términos de Seguridad, Mantenibilidad y Escalabilidad

**Seguridad:**
- Oculta la topología interna de la infraestructura, reduciendo la superficie de ataque expuesta
- Permite implementar Web Application Firewall (WAF), detección de inyecciones y validación de payloads en un punto centralizado
- Facilita rate limiting y protección contra ataques DDoS
- Aísla las bases de datos y servicios internos de acceso directo desde Internet

**Mantenibilidad:**
- Las reglas de enrutamiento y transformación de solicitudes se gestionan en un único lugar
- Las actualizaciones a servicios backend no requieren cambios en la configuración cliente
- Los logs centralizados en NGINX proporcionan visibilidad sobre el tráfico API
- Permite A/B testing, canary deployments y migraciones de servicios sin impacto en clientes

**Escalabilidad:**
- Posibilita agregar nuevos servicios backend o instancias sin reconfigurar el cliente
- Permite implementar load balancing, failover automático y health-based routing
- Reduce la complejidad de gestionar conexiones directo entre cliente y múltiples servicios
- Facilita la ejecución en diferentes entornos (desarrollo, staging, producción) con configuraciones de proxy distintas pero código cliente idéntico

### 4.3 Eliminación de Dependencias Incorrectas del Frontend hacia Servicios Internos

La solución elimina completamente las referencias hardcodeadas del cliente hacia servicios internos mediante:

1. **Uso de Rutas Relativas:** Todas las solicitudes API ahora utilizan rutas relativas (`/api/v1/...`), lo que permite que se ejecuten contra cualquier servidor que implemente el mismo contrato de API.

2. **Centralización de Configuración:** La URL base de la API se gestiona a través de un archivo de configuración centralizado que puede variar por ambiente sin recompilación del código.

3. **Independencia del Modelo de Despliegue:** El cliente no requiere conocimiento sobre puertos internos, direccionamientos DNS internos de Docker u otros detalles de infraestructura.

---

## 5. Relación con Principios DevOps y DevSecOps

### 5.1 Automatización y Coherencia de Entornos

La solución implementada alinea con los principios fundamentales de DevOps:

**Infraestructura como Código:** La configuración de NGINX y Docker Compose se expresa en archivos declarativos versionables, permitiendo reproducir idénticamente el mismo entorno en máquinas de desarrollo, integración continua, staging y producción.

**Consistencia Ambiental:** Un mismo código base se ejecuta sin modificación en todos los ambientes. Las diferencias de configuración (puertos internos, DNS, etc.) se gestionan mediante variables de entorno y archivos de configuración, no mediante cambios en el código de la aplicación.

**Automatización del Despliegue:** Docker Compose automatiza completamente la orquestación de contenedores, eliminando pasos manuales propensos a errores. La definición declarativa en `docker-compose.yml` especifica exactamente qué contenedores ejecutar, qué puertos exponer, qué redes configurar y qué volúmenes montar.

### 5.2 Separación de Responsabilidades

La arquitectura resultante implementa claramente la separación de responsabilidades:

- **NGINX**: responsable únicamente del enrutamiento, transformación de solicitudes y gestión de tráfico HTTP
- **Auth Service**: responsable únicamente de la lógica de autenticación, generación de tokens y validación de credenciales
- **Transactions Service**: responsable únicamente de la lógica de transacciones
- **PostgreSQL**: responsable únicamente de la persistencia y consulta de datos
- **Cliente Angular**: responsable únicamente de la interfaz de usuario y lógica de presentación

Esta separación clara facilita el desarrollo independiente de cada componente, permite que diferentes equipos trabajen en paralelo sin dependencias, y hace el sistema más resiliente ante fallos parciales.

### 5.3 Reducción de Superficie de Ataque y Mejora del Control del Tráfico

Desde una perspectiva de DevSecOps:

**Menor Superficie de Ataque:**
- Solo NGINX está expuesto al navegador del cliente (puerto 80). Los servicios backend no son accesibles directamente desde Internet.
- Las bases de datos están completamente aisladas en una red Docker interna, inaccesibles desde fuera de la infraestructura.
- Cada componente expone únicamente los puertos necesarios para su función, bloqueando todos los demás.

**Control Granular del Tráfico:**
- NGINX puede implementar listas blancas/negras de IP, validación de headers, filtrado de payloads y otras reglas de seguridad.
- Las redes Docker permiten implementar políticas de aislamiento: services que no necesitan comunicarse entre sí pueden ejecutarse en redes distintas.
- Los logs centralizados en NGINX proporcionan trazabilidad completa de todas las solicitudes HTTP, facilitando auditoría y detección de anomalías.

**Gestión de Credenciales:**
- Las credenciales de base de datos y tokens JWT no se transmiten entre componentes innecesariamente.
- NGINX valida la autenticidad de solicitudes antes de reenviarlo a servicios internos que podrían ser más vulnerables.
- Las redirecciones y manipulaciones indebidas de tráfico (como las que causaban errores 405) se eliminan, reduciendo vectores de ataque basados en confusión de estado.

---

## Conclusiones

La incidencia detectada en la comunicación cliente-servidor mediante HTTP 405 fue causada fundamentalmente por una configuración incorrecta del reverse proxy NGINX que no especificaba adecuadamente las directivas de proxy para las rutas API, combinada con referencias indebidas del cliente hacia servicios internos que son inaccesibles y violarían restricciones CORS.

Las medidas correctivas implementadas centralizan el enrutamiento HTTP a través de NGINX, implementando explícitamente las directivas de proxy necesarias en el orden correcto, y configurando el cliente para utilizar rutas relativas que se enrutan automáticamente a través del API Gateway.

Esta solución se alinea perfectamente con los principios de arquitectura moderna DevOps y DevSecOps, proporcionando automatización, coherencia ambiental, separación de responsabilidades clara, reducción de superficie de ataque y control granular del tráfico. La arquitectura resultante es más mantenible, escalable, segura y resiliente que la configuración anterior.

La resolución de esta incidencia constituye un hito importante en la madurez operacional del proyecto FinanSecure, demostrando la importancia de patrones arquitectónicos establecidos como API Gateway y la necesidad de alineamiento entre la topología de infraestructura y la configuración del código cliente.

---

**Documento Técnico de Ingeniería DevOps**  
**Proyecto**: FinanSecure - Plataforma de Gestión Financiera Segura  
**Fecha**: Enero de 2026  
**Clasificación**: Memoria Académica - Anexo Técnico
