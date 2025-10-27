# POC: Keycloak as IDP for APIs

This is a proof of concept demonstrating Keycloak as an Identity Provider (IDP) for third-party applications using OAuth 2.0 and OpenID Connect with Role-Based Access Control (RBAC).

## Architecture

- **Keycloak**: Identity Provider (Port 8080)
- **PostgreSQL**: Shared database for Keycloak and APIs (Port 5432)
- **Todo Backend API**: .NET 8.0 Web API (Port 5001)
- **Todo Frontend**: Next.js 16 with NextAuth.js v5 (Port 3000)

## Features

✅ OAuth 2.0 / OpenID Connect authentication  
✅ Role-Based Access Control (RBAC)  
✅ Application-level access control  
✅ Feature-level permissions  
✅ Group-based role management  
✅ User-specific data filtering  
✅ Full CRUD operations  

## Quick Start

### Prerequisites

- Docker and Docker Compose
- .NET 8.0 SDK
- Node.js 18+
- Make

### 1. Full Setup (Recommended)

```bash
make setup
```

This will:
- Install all dependencies
- Start Keycloak and PostgreSQL
- Configure realm, clients, roles, and groups
- Create test user

### 2. Start Services

```bash
# Terminal 1 - Backend
make start-backend

# Terminal 2 - Frontend
make start-frontend
```

### 3. Access Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:5001
- **Keycloak Admin**: http://localhost:8080
- **Swagger**: http://localhost:5001/swagger

**Test Credentials:**
- Username: `testuser`
- Password: `Test123!`

## Makefile Commands

```bash
make help              # Show all available commands
make install           # Install dependencies
make start             # Start all services
make stop              # Stop all services
make restart           # Restart all services
make clean             # Stop and remove all data
make configure         # Configure Keycloak
make status            # Check service status
make logs              # Show logs
make test-api          # Test API with curl
```

## Manual Setup

If you prefer manual setup:

### 1. Start Infrastructure

```bash
cd keycloak
docker compose up -d
```

### 2. Configure Keycloak

```bash
cd keycloak
./configure-keycloak.sh
./configure-group-rbac.sh
./add-app-access-role.sh
```

### 3. Start Backend

```bash
cd apps/todo-backend
dotnet restore
dotnet run
```

### 4. Start Frontend

```bash
cd apps/todo-frontend
npm install --legacy-peer-deps
npm run dev
```

## RBAC Configuration

### Roles

- **todo-app-access**: Access to the application
- **create-todo**: Create todos
- **get-todo**: Get single todo
- **list-todos**: List all todos
- **update-todo**: Update todos
- **delete-todo**: Delete todos

### Groups

- **todo-app-user**: Has all roles above

### How It Works

1. **Application Access**: Middleware checks for `todo-app-access` role
2. **Feature Access**: Each endpoint checks for specific role
3. **Data Filtering**: Users see only their own todos (password grant)

## API Endpoints

### Authentication
- `POST /api/auth/token` - Get access token
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/revoke` - Revoke token

### Todos (Protected)
- `GET /api/todos` - List todos (requires: list-todos)
- `GET /api/todos/{id}` - Get todo (requires: get-todo)
- `POST /api/todos` - Create todo (requires: create-todo)
- `PUT /api/todos/{id}` - Update todo (requires: update-todo)
- `DELETE /api/todos/{id}` - Delete todo (requires: delete-todo)

## Testing

### Get Access Token

```bash
curl -X POST http://localhost:5001/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "password",
    "client_id": "todo-backend-client",
    "client_secret": "YOUR_CLIENT_SECRET",
    "username": "testuser",
    "password": "Test123!"
  }'
```

### Create Todo

```bash
curl -X POST http://localhost:5001/api/todos \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My Todo",
    "description": "Testing"
  }'
```

### Quick Test

```bash
make test-api
```

## Keycloak Admin Console

- URL: http://localhost:8080
- Username: `admin`
- Password: `admin`

## Documentation

- [Architecture Documentation](docs/ARCHITECTURE.md)
- [Implementation Guide](docs/IMPLEMENTATION.md)
- [Frontend Plan](docs/FRONTEND_PLAN.md)

## Stopping the Environment

```bash
make stop              # Stop services
make clean             # Stop and remove all data
```

## Troubleshooting

**Services not starting?**
```bash
make status            # Check service status
make logs              # View logs
```

**Need to reset everything?**
```bash
make clean             # Remove all data
make setup             # Start fresh
```

**Backend not connecting to Keycloak?**
- Wait 30 seconds after starting infrastructure
- Check Keycloak is running: `curl http://localhost:8080`

## License

MIT
