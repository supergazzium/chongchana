export default function ({ $axios }) {
  // Add request interceptor to remove Authorization header for public payment QR endpoints
  // This needs to run AFTER @nuxtjs/auth-next sets the token
  $axios.onRequest((config) => {
    const publicEndpoints = [
      '/wallet/payment-qr/validate',
      '/wallet/payment-qr/pay'
    ];

    // Check if this request is to a public endpoint
    const isPublicEndpoint = publicEndpoints.some(endpoint =>
      config.url && (config.url.includes(endpoint) || config.url.endsWith(endpoint))
    );

    if (isPublicEndpoint) {
      // Remove all possible authorization headers
      delete config.headers.common['Authorization'];
      delete config.headers['Authorization'];
      delete config.headers.authorization;

      // Also check for lowercase
      if (config.headers.common) {
        delete config.headers.common.authorization;
      }

      console.log('[axios-public] Removed auth for:', config.url);
    }

    return config;
  });
}
