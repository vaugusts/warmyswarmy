import { sendError } from '../utils/apiResponse.js';
import { validateData } from '../utils/validators.js';

/**
 * Request body validation middleware factory
 * Validates incoming request data against a schema
 */
export const validateRequestBody = (schema) => {
  return (req, res, next) => {
    const { valid, data, errors } = validateData(req.body, schema);

    if (!valid) {
      return sendError(
        res,
        400,
        'Validation Error',
        errors
      );
    }

    // Replace body with validated data
    req.body = data;
    next();
  };
};

/**
 * Query parameter validation middleware factory
 */
export const validateQueryParams = (schema) => {
  return (req, res, next) => {
    const { valid, data, errors } = validateData(req.query, schema);

    if (!valid) {
      return sendError(
        res,
        400,
        'Query Validation Error',
        errors
      );
    }

    req.query = data;
    next();
  };
};

export default {
  validateRequestBody,
  validateQueryParams
};
