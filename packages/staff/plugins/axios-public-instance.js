import axios from 'axios';

export default ({ $config }, inject) => {
  // Create a completely separate axios instance that bypasses @nuxtjs/auth-next
  const publicAxios = axios.create({
    baseURL: process.env.NUXT_ENV_BASE_URL || 'http://localhost:7001',
    headers: {
      common: {
        'Content-Type': 'application/json',
      },
    },
  });

  // Explicitly remove any Authorization headers before every request
  publicAxios.interceptors.request.use((config) => {
    delete config.headers.Authorization;
    delete config.headers.authorization;
    delete config.headers.common.Authorization;
    delete config.headers.common.authorization;

    console.log('[publicAxios] Request to:', config.url, '- Auth header removed');
    return config;
  });

  // Inject as $publicAxios
  inject('publicAxios', publicAxios);
};
