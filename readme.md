# FinanSecure – Aplicación Web para Gestión de Finanzas Personales

## introducción

FinanSecure es una aplicación web desarrollada con fines académicos, diseñada para demostrar cómo puede construirse un sistema completo utilizando asistentes de programación basados en Inteligencia Artificial. El proyecto integra un frontend en Angular, un backend en .NET 8, y una base de datos en MySQL, permitiendo gestionar de forma sencilla ingresos, gastos y un dashboard con información financiera consolidada.

Este repositorio contiene todo lo necesario para ejecutar el proyecto en un entorno local, incluyendo instrucciones de instalación, configuración y ejecución de cada uno de los módulos.

### Características principales

- Visualización de ingresos, gastos y balance general.
- Dashboard con transacciones recientes.
- Backend REST en .NET 8 con Swagger habilitado.
- Base de datos MySQL con tabla transactions.
- Frontend Angular con componentes standalone.
- Todo el código generado mediante interacción asistida por IA.

### Tecnologías utilizadas

- .NET 8 / C#
- Entity Framework Core 8
- Angular 17+ (standalone components)
- Node.js / Angular CLI
- MySQL 8 o MariaDB
- Swagger/OpenAPI
- phpMyAdmin (opcional)

## 🚀 Guía de instalación y ejecución

A continuación se describen los pasos básicos para ejecutar el proyecto FinanSecure tras descargarlo desde GitHub.

### 1. Requisitos previos

Asegúrate de tener instalados los siguientes componentes:

- .NET SDK 8  https://dotnet.microsoft.com/download
- Node.js (v18 o superior)  https://nodejs.org/
- Angular CLI:
   npm install -g @angular/cli
- MySQL Server o MariaDB
- (Opcional) phpMyAdmin o MySQL Workbench para administrar la base de datos.

### 2. Clonar el repositorio
git clone https://github.com/lilypar59/FinanSecure.git
cd FinanSecure


Asegúrate de identificar dos carpetas principales:

FinanSecure.Api/        → Backend .NET 8
finansecure-web/        → Frontend Angular

### 3. Configurar la base de datos MySQL

Accede a tu cliente MySQL (phpMyAdmin, Workbench o consola) y ejecuta:

CREATE DATABASE IF NOT EXISTS finansecure_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE finansecure_db;

CREATE TABLE IF NOT EXISTS transactions (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    Type VARCHAR(20) NOT NULL,
    Category VARCHAR(100) NOT NULL,
    Description VARCHAR(255),
    Amount DECIMAL(10,2) NOT NULL,
    Date DATETIME NOT NULL
);

INSERT INTO transactions (Type, Category, Description, Amount, Date) VALUES
('INCOME', 'Salario', 'Pago mensual', 2500.00, NOW() - INTERVAL 5 DAY),
('EXPENSE', 'Alimentación', 'Supermercado', 150.50, NOW() - INTERVAL 4 DAY),
('EXPENSE', 'Transporte', 'Gasolina', 60.00, NOW() - INTERVAL 3 DAY),
('INCOME', 'Freelance', 'Proyecto web', 600.00, NOW() - INTERVAL 2 DAY),
('EXPENSE', 'Ocio', 'Cine', 30.00, NOW() - INTERVAL 1 DAY);

Crear usuario para conexión desde .NET
CREATE USER IF NOT EXISTS 'finanuser'@'localhost'
IDENTIFIED BY 'FinanSecure2025!';

GRANT ALL PRIVILEGES ON finansecure_db.* TO 'finanuser'@'localhost';
FLUSH PRIVILEGES;

### 4. Configurar el backend (.NET 8)

Edita el archivo:

FinanSecure.Api/appsettings.json


Y coloca tu conexión MySQL:

{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Port=3306;Database=finansecure_db;User=finanuser;Password=FinanSecure2025!;SslMode=none"
  }
}

#### Ejecutar la API
cd FinanSecure.Api
dotnet restore
dotnet run


La API estará disponible en:

http://localhost:5045


Documentación Swagger:

http://localhost:5045/swagger

### 5. Ejecutar el frontend Angular
cd finansecure-web
npm install
ng serve


Accede en el navegador:

http://localhost:4200


Deberías ver el dashboard cargando los datos reales provenientes del backend.

### 6. Verificación final

Swagger muestra los endpoints funcionando.

El dashboard de Angular muestra ingresos, gastos y balance.

La consola no reporta errores en Angular ni en la API.

Los datos coinciden con los registros de la tabla transactions.

## 📁 Estructura del proyecto

FinanSecure/
│
├── FinanSecure.Api/          
│   ├── Controllers/
│   ├── Data/
│   ├── Models/
│   ├── Program.cs
│   └── appsettings.json
│
└── finansecure-web/
    ├── src/
    ├── app.routes.ts
    ├── app.config.ts
    └── pages/dashboard/

## 🙌 Sobre este proyecto

FinanSecure fue desarrollado como parte de la asignatura Desarrollo de aplicaciones con asistentes de programación basados en IA. Todo el código del proyecto —backend, frontend y scripts SQL— fue generado mediante interacción con una Inteligencia Artificial, mientras que el rol del estudiante consistió en dirigir, revisar, corregir y consolidar el trabajo producido.

El objetivo principal es evidenciar el potencial (y también las limitaciones) de la IA como herramienta de apoyo en el desarrollo moderno.

## 📜 Licencia

Este proyecto tiene fines educativos y puede ser reutilizado libremente con propósitos formativos.