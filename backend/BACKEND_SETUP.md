# Backend Setup Guide

## Overview
The warmyswarmy backend is a Node.js + Express.js API server with a modular, production-ready structure.

## Prerequisites
- Node.js 16+ 
- npm or yarn
- PostgreSQL 12+ (optional, for production database)

## Installation

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Environment Configuration
Copy the example environment file and update with your values:
```bash
cp .env.example .env
```

Edit `.env` with your configuration:
```
PORT=3001
NODE_ENV=development
DB_HOST=localhost
DB_PORT=5432
DB_NAME=warmyswarmy_dev
DB_USER=postgres
DB_PASSWORD=your_password
CORS_ORIGIN=http://localhost:3000
LOG_LEVEL=info
```

## Running the Server

### Development Mode (with auto-reload)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

### Testing
```bash
# Run tests
npm test

# Watch mode
npm run test:watch

# With coverage
npm test -- --coverage
```

### Linting
```bash
# Check for linting errors
npm run lint

# Fix linting errors
npm run lint:fix
```

## Project Structure

```
backend/
├── src/
│   ├── config/           # Configuration files
│   │   ├── env.js       # Environment variables
│   │   └── database.js  # Database configuration
│   ├── controllers/      # Request handlers
│   │   └── userController.js
│   ├── middleware/       # Express middleware
│   │   ├── cors.js
│   │   ├── errorHandler.js
│   │   ├── requestLogger.js
│   │   └── validation.js
│   ├── models/          # Data models
│   │   └── User.js
│   ├── routes/          # API route definitions
│   │   └── users.js
│   ├── services/        # Business logic
│   │   └── userService.js
│   ├── utils/           # Utility functions
│   │   ├── apiResponse.js
│   │   └── validators.js
│   └── index.js         # Application entry point
├── tests/               # Test files
│   └── user.test.js
├── .env.example         # Example environment variables
├── package.json         # Dependencies and scripts
└── BACKEND_SETUP.md     # This file
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PORT | 3001 | Server port |
| NODE_ENV | development | Environment (development, production, test) |
| DB_HOST | localhost | Database host |
| DB_PORT | 5432 | Database port |
| DB_NAME | warmyswarmy_dev | Database name |
| DB_USER | postgres | Database user |
| DB_PASSWORD | password | Database password |
| CORS_ORIGIN | http://localhost:3000 | CORS allowed origin |
| LOG_LEVEL | info | Logging level |

## API Documentation

### Base URL
`http://localhost:3001/api/v1`

### Endpoints

#### User Management

**Create User**
```
POST /users
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "phone": "1234567890",
  "role": "user"
}
```

**Get All Users**
```
GET /users
```

**Get User by ID**
```
GET /users/:id
```

**Update User**
```
PUT /users/:id
Content-Type: application/json

{
  "name": "Jane Doe",
  "phone": "9876543210"
}
```

**Delete User**
```
DELETE /users/:id
```

**Search Users**
```
GET /users/search?q=john
```

### Response Format

All responses follow a standard format:

**Success Response (200-299)**
```json
{
  "statusCode": 200,
  "data": { ... },
  "message": "Success message",
  "success": true
}
```

**Error Response (400-599)**
```json
{
  "statusCode": 400,
  "data": null,
  "message": "Error message",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ],
  "success": false
}
```

## Architecture

### Middleware Pipeline
1. Body Parser - Parse JSON/URL-encoded bodies
2. CORS - Handle cross-origin requests
3. Request Logger - Log all incoming requests
4. Routes - Route to appropriate handler
5. Error Handler - Catch and format errors

### Data Flow
```
Request → Validation → Controller → Service → Response
```

### Key Patterns

**Error Handling**
- Centralized error handler middleware
- Async error wrapper for catching promise rejections
- Consistent error response format

**Validation**
- Joi schemas for data validation
- Validation middleware for routes
- Field-level error messages

**Response Formatting**
- API response wrapper class
- Helper functions for success/error responses
- Consistent status codes

## Database Integration

Currently using in-memory storage (UserStore). To integrate with a real database:

1. Install ORM/Database driver (Sequelize, TypeORM, etc.)
2. Update `src/config/database.js`
3. Replace `UserStore` with database models
4. Update services to use database queries

Example with Sequelize:
```javascript
import { Sequelize } from 'sequelize';

const sequelize = new Sequelize(databaseConfig.connection);
```

## Development Tips

### Adding a New Endpoint

1. **Create a model** (if needed) in `src/models/`
2. **Create a service** in `src/services/` with business logic
3. **Create a controller** in `src/controllers/`
4. **Create routes** in `src/routes/`
5. **Add validation schemas** to `src/utils/validators.js`
6. **Update route file** to use middleware and controllers
7. **Write tests** in `backend/tests/`
8. **Register routes** in `src/index.js`

### Adding Middleware

Create a new file in `src/middleware/` and export as a function:
```javascript
export const myMiddleware = (req, res, next) => {
  // Middleware logic
  next();
};
```

## Performance Considerations

- Request logging only in development mode
- CORS preflight caching (3600s max age)
- Connection pooling for database
- Error stack traces hidden in production
- Body size limits (10MB)

## Security Considerations

- CORS configured for specific origins
- Input validation on all endpoints
- Passwords should be hashed (bcrypt recommended)
- SQL injection prevention with parameterized queries
- HTTPS in production
- Rate limiting recommended for production
- Authentication/Authorization middleware needed for production

## Troubleshooting

### Port Already in Use
```bash
# Kill process on port 3001 (macOS/Linux)
lsof -ti:3001 | xargs kill -9
```

### Database Connection Error
- Check `.env` configuration
- Verify database is running
- Check database credentials

### Module Not Found
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

## Next Steps

1. **Step 3: Infrastructure** - Set up Terraform/Bicep for cloud deployment
2. **Step 4: Frontend** - Build React/Vue frontend
3. **Step 5: Tests** - Add integration and e2e tests

## Resources

- [Express.js Documentation](https://expressjs.com/)
- [Node.js Best Practices](https://nodejs.org/en/docs/guides/)
- [Joi Validation](https://joi.dev/)
- [dotenv Documentation](https://github.com/motdotla/dotenv)

## Support

For issues or questions, refer to the main project README.md
