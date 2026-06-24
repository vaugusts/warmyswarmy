import { v4 as uuidv4 } from 'uuid';

/**
 * User Model
 * Represents a user in the system
 * Can be replaced with database ORM models (Sequelize, TypeORM, etc.)
 */
export class User {
  constructor(name, email, password, phone = null, role = 'user') {
    this.id = uuidv4();
    this.name = name;
    this.email = email;
    this.password = password; // In production, should be hashed
    this.phone = phone;
    this.role = role;
    this.isActive = true;
    this.createdAt = new Date();
    this.updatedAt = new Date();
  }

  /**
   * Convert to JSON (exclude sensitive data)
   */
  toJSON() {
    const { password, ...user } = this;
    return user;
  }

  /**
   * Update user properties
   */
  update(data) {
    Object.keys(data).forEach(key => {
      if (key !== 'id' && key !== 'createdAt' && key !== 'password') {
        this[key] = data[key];
      }
    });
    this.updatedAt = new Date();
  }
}

/**
 * In-memory user storage (for demo purposes)
 * Replace with actual database in production
 */
export class UserStore {
  constructor() {
    this.users = new Map();
  }

  create(user) {
    this.users.set(user.id, user);
    return user;
  }

  findById(id) {
    return this.users.get(id);
  }

  findByEmail(email) {
    for (const user of this.users.values()) {
      if (user.email === email) return user;
    }
    return null;
  }

  findAll() {
    return Array.from(this.users.values());
  }

  update(id, data) {
    const user = this.users.get(id);
    if (user) {
      user.update(data);
    }
    return user;
  }

  delete(id) {
    return this.users.delete(id);
  }
}

export default { User, UserStore };
