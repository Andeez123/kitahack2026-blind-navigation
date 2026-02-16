import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    // This helps fix the WebSocket connection failures in some environments
    hmr: {
      protocol: 'ws',
      host: 'localhost',
    },
    // Useful if you're testing on a mobile device on the same WiFi
    host: true, 
  }
});