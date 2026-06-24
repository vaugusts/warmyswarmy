import Joi from 'joi';

/**
 * User validation schemas
 */
export const userValidationSchemas = {
  create: Joi.object({
    name: Joi.string().required().min(2).max(100),
    email: Joi.string().email().required(),
    password: Joi.string().required().min(8),
    phone: Joi.string().optional(),
    role: Joi.string().valid('user', 'admin').default('user')
  }),

  update: Joi.object({
    name: Joi.string().optional().min(2).max(100),
    email: Joi.string().email().optional(),
    phone: Joi.string().optional(),
    role: Joi.string().valid('user', 'admin').optional()
  }),

  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  })
};

/**
 * Validate request data against schema
 */
export const validateData = (data, schema) => {
  const { error, value } = schema.validate(data, {
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    const errors = error.details.map(err => ({
      field: err.path.join('.'),
      message: err.message
    }));
    return { valid: false, errors };
  }

  return { valid: true, data: value };
};

export default {
  userValidationSchemas,
  validateData
};
