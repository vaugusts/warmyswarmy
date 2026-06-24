import { User, UserStore } from '../models/User.js';
import { ApiError } from '../utils/apiResponse.js';

// In-memory store for demo (replace with database)
const userStore = new UserStore();

/**
 * User Service
 * Business logic for user operations
 */
export class UserService {
  /**
   * Create a new user
   */
  static async createUser(userData) {
    // Check if user already exists
    const existingUser = userStore.findByEmail(userData.email);
    if (existingUser) {
      throw new ApiError(409, 'User with this email already exists');
    }

    const user = new User(
      userData.name,
      userData.email,
      userData.password,
      userData.phone,
      userData.role
    );

    userStore.create(user);
    return user.toJSON();
  }

  /**
   * Get user by ID
   */
  static async getUserById(id) {
    const user = userStore.findById(id);
    if (!user) {
      throw new ApiError(404, 'User not found');
    }
    return user.toJSON();
  }

  /**
   * Get all users
   */
  static async getAllUsers() {
    const users = userStore.findAll();
    return users.map(user => user.toJSON());
  }

  /**
   * Update user
   */
  static async updateUser(id, updateData) {
    const user = userStore.findById(id);
    if (!user) {
      throw new ApiError(404, 'User not found');
    }

    // Check if email is being changed and if new email exists
    if (updateData.email && updateData.email !== user.email) {
      const existingUser = userStore.findByEmail(updateData.email);
      if (existingUser) {
        throw new ApiError(409, 'Email already in use');
      }
    }

    userStore.update(id, updateData);
    return userStore.findById(id).toJSON();
  }

  /**
   * Delete user
   */
  static async deleteUser(id) {
    const user = userStore.findById(id);
    if (!user) {
      throw new ApiError(404, 'User not found');
    }

    userStore.delete(id);
    return { message: 'User deleted successfully' };
  }

  /**
   * Search users by name or email
   */
  static async searchUsers(query) {
    const allUsers = userStore.findAll();
    const lowerQuery = query.toLowerCase();

    return allUsers
      .filter(user => 
        user.name.toLowerCase().includes(lowerQuery) ||
        user.email.toLowerCase().includes(lowerQuery)
      )
      .map(user => user.toJSON());
  }
}

export default UserService;
