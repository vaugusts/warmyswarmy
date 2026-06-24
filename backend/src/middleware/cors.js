import cors from 'cors';
import { config } from '../config/env.js';

/**
 * CORS configuration
 * Allows requests from specified origins
 */
const corsOptions = {
  origin: config.cors.origin,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 3600
};

export const corsMiddleware = cors(corsOptions);

export default corsMiddleware;
