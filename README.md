# warmyswarmy

A full-stack web application project structure.

## 📋 Project Overview

warmyswarmy is a modern full-stack application with a Node.js/Express backend, frontend, infrastructure as code, and comprehensive testing setup.

## 📁 Repository Structure

```
warmyswarmy/
├── backend/              # Node.js + Express API server
│   ├── src/             # Source code
│   ├── tests/           # Backend tests
│   ├── config/          # Configuration files
│   └── BACKEND_SETUP.md # Backend documentation
├── frontend/            # React/Vue frontend (Step 4)
├── tests/               # E2E and integration tests (Step 5)
├── infrastructure/      # Terraform/Bicep IaC (Step 3)
├── .gitignore          # Git ignore rules
├── .editorconfig        # Editor configuration
└── README.md           # This file
```

## 🚀 Quick Start

### Prerequisites
- Node.js 16+
- npm or yarn
- Git

### Backend Setup

```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

The API will be available at `http://localhost:3001/api/v1`

For detailed backend setup, see [BACKEND_SETUP.md](./backend/BACKEND_SETUP.md)

## 📦 Technology Stack

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **Validation**: Joi
- **Middleware**: CORS, Body Parser
- **Testing**: Jest, Supertest
- **Database**: (Ready for integration - PostgreSQL recommended)

### Frontend (Planned)
- React or Vue.js
- Modern JavaScript (ES6+)
- State management
- Component library

### Infrastructure (Planned)
- Terraform or Bicep
- Cloud deployment (AWS/Azure)
- CI/CD pipeline

### Testing (Planned)
- Unit tests
- Integration tests
- E2E tests
- Performance tests

## 🔌 API Endpoints

### Health Check
```
GET /health
```

### User Management
```
POST   /api/v1/users              # Create user
GET    /api/v1/users              # Get all users
GET    /api/v1/users/:id          # Get user by ID
PUT    /api/v1/users/:id          # Update user
DELETE /api/v1/users/:id          # Delete user
GET    /api/v1/users/search?q=... # Search users
```

## 📚 Available Scripts

### Backend
```bash
npm run dev          # Start dev server with auto-reload
npm start           # Start production server
npm test            # Run tests
npm test:watch      # Run tests in watch mode
npm run lint        # Check for linting errors
npm run lint:fix    # Fix linting errors
```

## 🔐 Environment Variables

See `.env.example` for the complete list of required environment variables.

Key variables:
- `PORT` - Server port (default: 3001)
- `NODE_ENV` - Environment type (development/production)
- `DB_*` - Database connection details
- `CORS_ORIGIN` - Allowed CORS origin

## 📖 Development Roadmap

### ✅ Step 1: Project Initialization
- GitHub repository created
- Basic README

### ✅ Step 2: Backend & Project Structure (Current)
- Complete Node.js/Express API server
- Database models and services
- API endpoints with validation
- Error handling and logging
- Middleware setup
- Test suite scaffold

### 🔜 Step 3: Infrastructure as Code
- Terraform/Bicep configuration
- Cloud resource definitions
- Database setup
- CI/CD pipeline

### 🔜 Step 4: Frontend Development
- Frontend framework setup
- Component library
- API integration
- UI/UX implementation

### 🔜 Step 5: Test Automation
- E2E test suite
- Integration tests
- Performance testing
- CI/CD automation

## 🛠️ Development Workflow

### Adding New Features

1. Create a new branch:
   ```bash
   git checkout -b feature/feature-name
   ```

2. Make changes and commit:
   ```bash
   git add .
   git commit -m "Add feature description"
   ```

3. Push to GitHub:
   ```bash
   git push origin feature/feature-name
   ```

4. Create a Pull Request

## 📝 Code Style

- Follow ESLint rules (configured in backend)
- Use 2-space indentation
- Use meaningful variable/function names
- Add comments for complex logic
- Follow module pattern for organization

## 🐛 Troubleshooting

### Port Already in Use
```bash
# Find and kill process on port 3001
lsof -ti:3001 | xargs kill -9
```

### Dependencies Issues
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

## 📞 Support & Contribution

For issues, questions, or contributions, please open an issue or submit a pull request.

## 📄 License

MIT License - feel free to use this project as a template

## 🎯 Key Features

- ✅ Modular architecture
- ✅ Comprehensive error handling
- ✅ Input validation
- ✅ Request logging
- ✅ CORS support
- ✅ Environment-based configuration
- ✅ Test ready
- ✅ Production-ready setup
- ✅ Standard API response format
- ✅ Extensible middleware system

## 🔗 Resources

- [Express.js](https://expressjs.com/)
- [Node.js](https://nodejs.org/)
- [Git Documentation](https://git-scm.com/doc)

---

**Status**: Step 2 Complete ✅
**Next**: Step 3 - Infrastructure as Code
