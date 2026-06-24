import express from 'express';
import bodyParser from 'body-parser';
import { config } from './config/env.js';
import { corsMiddleware } from './middleware/cors.js';
import { requestLogger } from './middleware/requestLogger.js';
import { errorHandler } from './middleware/errorHandler.js';
import { sendSuccess } from './utils/apiResponse.js';
import userRoutes from './routes/users.js';

const app = express();

// ========================
// Middleware Setup
// ========================

// Body parsing
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ limit: '10mb', extended: true }));

// CORS
app.use(corsMiddleware);

// Request logging
app.use(requestLogger);

// ========================
// Routes
// ========================

// Health check endpoint
app.get('/health', (req, res) => {
  return sendSuccess(res, 200, { status: 'OK', timestamp: new Date() }, 'Server is healthy');
});

// API version
app.get(`/api/v${config.apiVersion}`, (req, res) => {
  return sendSuccess(res, 200, { version: config.apiVersion }, 'API is running');
});

// User routes
app.use(`/api/v${config.apiVersion}/users`, userRoutes);

// 404 handler
app.use((req, res) => {
  return res.status(404).json({
    statusCode: 404,
    message: 'Endpoint not found',
    path: req.path,
    success: false
  });
});

// ========================
// Error Handling
// ========================

// Global error handler (must be last)
app.use(errorHandler);

// ========================
// Server Startup
// ========================

const server = app.listen(config.port, () => {
  console.log(`
╔═══════════════════════════════════════╗
║     warmyswarmy API Server Started    ║
╚═══════════════════════════════════════╝
Environment: ${config.nodeEnv}
Port: ${config.port}
API Version: v${config.apiVersion}
Base URL: ${config.apiBaseUrl}
  `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

export default app;
