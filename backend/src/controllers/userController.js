import UserService from '../services/userService.js';
import { sendSuccess, sendError } from '../utils/apiResponse.js';
import { asyncHandler } from '../middleware/errorHandler.js';

/**
 * User Controller
 * Handles HTTP requests for user endpoints
 */

export const userController = {
  /**
   * POST /api/users - Create a new user
   */
  createUser: asyncHandler(async (req, res) => {
    const user = await UserService.createUser(req.body);
    return sendSuccess(res, 201, user, 'User created successfully');
  }),

  /**
   * GET /api/users/:id - Get user by ID
   */
  getUserById: asyncHandler(async (req, res) => {
    const user = await UserService.getUserById(req.params.id);
    return sendSuccess(res, 200, user, 'User retrieved successfully');
  }),

  /**
   * GET /api/users - Get all users
   */
  getAllUsers: asyncHandler(async (req, res) => {
    const users = await UserService.getAllUsers();
    return sendSuccess(res, 200, { users, count: users.length }, 'Users retrieved successfully');
  }),

  /**
   * PUT /api/users/:id - Update user
   */
  updateUser: asyncHandler(async (req, res) => {
    const user = await UserService.updateUser(req.params.id, req.body);
    return sendSuccess(res, 200, user, 'User updated successfully');
  }),

  /**
   * DELETE /api/users/:id - Delete user
   */
  deleteUser: asyncHandler(async (req, res) => {
    const result = await UserService.deleteUser(req.params.id);
    return sendSuccess(res, 200, result, result.message);
  }),

  /**
   * GET /api/users/search - Search users
   */
  searchUsers: asyncHandler(async (req, res) => {
    const { q } = req.query;
    if (!q) {
      return sendError(res, 400, 'Search query required', [{ field: 'q', message: 'Query parameter is required' }]);
    }
    const users = await UserService.searchUsers(q);
    return sendSuccess(res, 200, { users, count: users.length }, 'Search completed');
  })
};

export default userController;
