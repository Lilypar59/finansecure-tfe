# 📘 Trabajo Fin de Máster – DevSecOps en pipelines CI/CD

## Incorporación de prácticas DevSecOps en pipelines CI/CD para microservicios contenerizados

---

## Descripción general

Este repositorio contiene el código fuente y los artefactos técnicos desarrollados en el marco del Trabajo Fin de Máster (TFM), cuyo objetivo es analizar e implementar un enfoque DevSecOps aplicado a un pipeline de Integración y Entrega Continua (CI/CD) para una arquitectura basada en microservicios contenerizados.

El proyecto se centra en la definición del diseño arquitectónico, la integración de controles de seguridad automatizados y la aplicación de principios de Infraestructura como Código (IaC), priorizando la trazabilidad, la automatización y la seguridad desde las primeras etapas del ciclo de vida del software.

---

## Alcance del repositorio

El contenido de este repositorio tiene un **carácter académico y demostrativo**. Su finalidad es complementar la memoria del TFM y permitir la revisión de la estructura del proyecto y de los artefactos desarrollados.

- El repositorio **no constituye una solución productiva completa**.
- Algunas configuraciones han sido **simplificadas o abstraídas**.
- El despliegue en entornos cloud productivos queda **fuera del alcance** del trabajo.

---

## Estructura del proyecto

De forma general, el repositorio se organiza en los siguientes bloques:

```text
/
├── microservices/        # Microservicios de la aplicación
│   ├── FinanSecure.Api
│   ├── FinanSecure.Auth
│   ├── FinanSecure.Transactions
│   ├── finansecure-web
│   └── website
│
├── .github/workflows            # Definición del pipeline CI/CD
│   └── deploy.yml
│
├── iac/                  # Infraestructura como Código (IaC)
│   ├── envs/
│   └── modules/
│
├── docs/                 # Documentación y diagramas
│
└── README.md
