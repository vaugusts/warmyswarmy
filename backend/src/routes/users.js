import express from 'express';
import userController from '../controllers/userController.js';
import { validateRequestBody, validateQueryParams } from '../middleware/validation.js';
import { userValidationSchemas } from '../utils/validators.js';
import Joi from 'joi';

const router = express.Router();

/**
 * User Routes
 * All routes prefixed with /api/users
 */

// Create a new user
router.post(
  '/',
  validateRequestBody(userValidationSchemas.create),
  userController.createUser
);

// Get all users
router.get('/', userController.getAllUsers);

// Search users
router.get(
  '/search',
  validateQueryParams(Joi.object({ q: Joi.string().required() })),
  userController.searchUsers
);

// Get user by ID
router.get('/:id', userController.getUserById);

// Update user
router.put(
  '/:id',
  validateRequestBody(userValidationSchemas.update),
  userController.updateUser
);

// Delete user
router.delete('/:id', userController.deleteUser);

export default router;
