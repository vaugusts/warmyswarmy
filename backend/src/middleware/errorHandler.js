import { sendError } from '../utils/apiResponse.js';
import { config } from '../config/env.js';

/**
 * Global error handling middleware
 * Catches all errors and formats them consistently
 */
export const errorHandler = (err, req, res, next) => {
  // Default error
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';
  let errors = err.errors || [];

  // Log error
  console.error({
    timestamp: new Date().toISOString(),
    statusCode,
    message,
    path: req.path,
    method: req.method,
    stack: err.stack
  });

  // Don't expose internal errors in production
  if (config.isProduction && statusCode === 500) {
    message = 'Internal Server Error';
  }

  return sendError(res, statusCode, message, errors);
};

/**
 * Async error wrapper for route handlers
 * Catches errors in async functions and passes to error handler
 */
export const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

export default { errorHandler, asyncHandler };
