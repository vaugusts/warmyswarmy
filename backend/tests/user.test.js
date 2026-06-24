import request from 'supertest';
import app from '../src/index.js';
import UserService from '../src/services/userService.js';

describe('User API Tests', () => {
  const testUser = {
    name: 'John Doe',
    email: 'john@example.com',
    password: 'password123',
    phone: '1234567890',
    role: 'user'
  };

  let createdUserId;

  describe('POST /api/v1/users - Create User', () => {
    it('should create a new user successfully', async () => {
      const response = await request(app)
        .post('/api/v1/users')
        .send(testUser)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.email).toBe(testUser.email);
      expect(response.body.data.password).toBeUndefined(); // Should not expose password
      createdUserId = response.body.data.id;
    });

    it('should fail with validation error on missing email', async () => {
      const response = await request(app)
        .post('/api/v1/users')
        .send({ ...testUser, email: undefined })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.statusCode).toBe(400);
    });

    it('should fail when email already exists', async () => {
      // Create first user
      await UserService.createUser(testUser);

      // Try to create another with same email
      const response = await request(app)
        .post('/api/v1/users')
        .send(testUser)
        .expect(409);

      expect(response.body.success).toBe(false);
    });
  });

  describe('GET /api/v1/users - Get All Users', () => {
    it('should retrieve all users', async () => {
      const response = await request(app)
        .get('/api/v1/users')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data.users)).toBe(true);
    });
  });

  describe('GET /api/v1/users/:id - Get User by ID', () => {
    it('should retrieve a user by ID', async () => {
      if (!createdUserId) {
        const user = await UserService.createUser(testUser);
        createdUserId = user.id;
      }

      const response = await request(app)
        .get(`/api/v1/users/${createdUserId}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe(createdUserId);
    });

    it('should return 404 for non-existent user', async () => {
      const response = await request(app)
        .get('/api/v1/users/invalid-id')
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PUT /api/v1/users/:id - Update User', () => {
    it('should update user successfully', async () => {
      if (!createdUserId) {
        const user = await UserService.createUser(testUser);
        createdUserId = user.id;
      }

      const updateData = { name: 'Jane Doe', phone: '9876543210' };
      const response = await request(app)
        .put(`/api/v1/users/${createdUserId}`)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Jane Doe');
      expect(response.body.data.phone).toBe('9876543210');
    });
  });

  describe('DELETE /api/v1/users/:id - Delete User', () => {
    it('should delete a user successfully', async () => {
      if (!createdUserId) {
        const user = await UserService.createUser(testUser);
        createdUserId = user.id;
      }

      const response = await request(app)
        .delete(`/api/v1/users/${createdUserId}`)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.message).toContain('deleted');
    });
  });

  describe('GET /api/v1/users/search - Search Users', () => {
    it('should search users by query', async () => {
      const response = await request(app)
        .get('/api/v1/users/search')
        .query({ q: 'john' })
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should fail without search query', async () => {
      const response = await request(app)
        .get('/api/v1/users/search')
        .expect(400);

      expect(response.body.success).toBe(false);
    });
  });
});
