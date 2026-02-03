// ════════════════════════════════════════════════════════════════════════════════
// 🔧 CONFIGURACIÓN DE ENTORNO
// ════════════════════════════════════════════════════════════════════════════════
//
// Este archivo contiene la configuración de URLs que se adaptan al entorno
// (desarrollo local, testing, producción en AWS, etc.)
//
// IMPORTANTE:
//  - En desarrollo local: URLs apuntan a localhost
//  - En AWS: Las URLs se configuran dinámicamente desde el servidor
//  - El navegador obtiene esta configuración en tiempo de ejecución
//
// ════════════════════════════════════════════════════════════════════════════════

export interface EnvironmentConfig {
  apiUrl: string;
  websiteUrl: string;
  appName: string;
  environment: 'development' | 'production';
}

/**
 * OBTIENE LA CONFIGURACIÓN DEL ENTORNO DE FORMA DINÁMICA
 *
 * En desarrollo: Usa URLs hardcodeadas de localhost
 * En AWS: Obtiene las URLs desde el navegador (window.location)
 *
 * @returns EnvironmentConfig con URLs del entorno actual
 */
export function getEnvironmentConfig(): EnvironmentConfig {
  const isLocalhost = window.location.hostname === 'localhost' ||
                      window.location.hostname === '127.0.0.1';

  if (isLocalhost) {
    // 🏠 DESARROLLO LOCAL: URLs explícitas
    return {
      apiUrl: 'http://localhost',          // NGINX en puerto 80
      websiteUrl: 'http://localhost:3000', // Website en puerto 3000
      appName: 'FinanSecure',
      environment: 'development'
    };
  } else {
    // ☁️  AWS / PRODUCCIÓN: URLs dinámicas
    // El protocolo y host se obtienen del navegador
    const protocol = window.location.protocol; // https:
    const host = window.location.host;         // ejemplo.com o ejemplo.com:puerto

    return {
      apiUrl: `${protocol}//${host}`,                    // NGINX en dominio principal
      websiteUrl: `${protocol}//website.${host}`,        // Subdominio para website (opcional)
      // O si el website está en la misma raíz:
      // websiteUrl: `${protocol}//${host}`,
      appName: 'FinanSecure',
      environment: 'production'
    };
  }
}

// 🔒 Exportar la configuración como singleton
export const ENVIRONMENT_CONFIG = getEnvironmentConfig();
