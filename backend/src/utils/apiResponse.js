/**
 * Standard API Response Wrapper
 * Ensures consistent response format across all endpoints
 */

export class ApiResponse {
  constructor(statusCode, data, message = 'Success') {
    this.statusCode = statusCode;
    this.data = data;
    this.message = message;
    this.success = statusCode < 400;
  }

  /**
   * Return response object
   */
  toJSON() {
    return {
      statusCode: this.statusCode,
      data: this.data,
      message: this.message,
      success: this.success
    };
  }
}

/**
 * Error Response Wrapper
 */
export class ApiError extends Error {
  constructor(statusCode, message = 'An error occurred', errors = []) {
    super(message);
    this.statusCode = statusCode;
    this.errors = errors;
    this.data = null;
    this.success = false;
  }

  toJSON() {
    return {
      statusCode: this.statusCode,
      data: this.data,
      message: this.message,
      errors: this.errors,
      success: this.success
    };
  }
}

/**
 * Success response helper
 */
export const sendSuccess = (res, statusCode = 200, data = null, message = 'Success') => {
  const response = new ApiResponse(statusCode, data, message);
  return res.status(statusCode).json(response);
};

/**
 * Error response helper
 */
export const sendError = (res, statusCode = 500, message = 'Internal Server Error', errors = []) => {
  const error = new ApiError(statusCode, message, errors);
  return res.status(statusCode).json(error);
};
