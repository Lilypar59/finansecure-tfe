/**
 * Configuración de API dinámica
 * 
 * ARQUITECTURA:
 *  - Navegador accede a: http://localhost:80 (NGINX)
 *  - NGINX enruta /api/* a: http://finansecure-auth:8080 (privado)
 *  - Frontend SIEMPRE debe usar URLs relativas: /api/v1/...
 * 
 * Esto permite que NGINX haga el proxy sin problemas de CORS
 */

export const API_CONFIG = {
  // ✅ CORRECTO: Usar rutas relativas siempre
  // El navegador envía la petición a localhost, NGINX la redirige internamente
  auth: '/api/v1/auth',
  transactions: '/api/v1/transactions',

  // Función que retorna la URL base para autenticación
  getAuthUrl: (): string => {
    // ✅ SIEMPRE usar ruta relativa
    // Funciona en todos los ambientes:
    // - Docker: localhost:80 -> NGINX -> finansecure-auth:8080
    // - Desarrollo local: localhost:4200 -> http://localhost:8080 (desarrollo)
    // - Producción: dominio.com -> reverse proxy a backend
    return '/api/v1/auth';
  },

  // Función que retorna la URL base para transacciones
  getTransactionsUrl: (): string => {
    // ✅ SIEMPRE usar ruta relativa
    return '/api/v1/transactions';
  }
};
