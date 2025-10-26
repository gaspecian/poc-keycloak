# Implementation Guide

## Development Plan - TODO List

### Phase 1: Infrastructure Setup
- [x] Create folder structure (docs, keycloak, apps/todo-backend)
- [x] Create docker-compose.yml for Keycloak and PostgreSQL
- [x] Create Keycloak realm import configuration (optional)
- [x] Start Docker containers and verify connectivity
- [x] Access Keycloak admin console and verify login

### Phase 2: Keycloak Configuration
- [x] Create realm: `poc-realm`
- [x] Create client scope: `todo-backend`
- [x] Create client: `todo-backend-client`
  - [x] Enable client authentication
  - [x] Enable direct access grants
  - [x] Enable service accounts
  - [x] Copy client secret for later use
  - [x] Assign `todo-backend` scope as default
- [x] Create test user: `testuser` with password
- [x] Verify OIDC discovery endpoint: `http://localhost:8080/realms/poc-realm/.well-known/openid-configuration`

### Phase 3: Todo Backend API - Project Setup
- [x] Create .NET Web API project
- [x] Add required NuGet packages:
  - [x] Microsoft.AspNetCore.Authentication.JwtBearer
  - [x] Microsoft.EntityFrameworkCore.Npgsql
  - [x] Swashbuckle.AspNetCore
  - [x] System.Net.Http
- [x] Configure appsettings.json with Keycloak and database settings
- [x] Create database context and Todo entity model

### Phase 4: Todo Backend API - Authentication Implementation
- [x] Create AuthController with three endpoints:
  - [x] POST /api/auth/token
  - [x] POST /api/auth/refresh
  - [x] POST /api/auth/revoke
- [x] Create KeycloakService to handle OIDC communication
- [x] Implement token request logic (client_credentials and password grants)
- [x] Implement refresh token logic
- [x] Implement token revocation logic
- [x] Add scope parameter (`todo-backend`) to all Keycloak requests

### Phase 5: Todo Backend API - JWT Validation
- [x] Configure JWT Bearer authentication in Program.cs
- [x] Set Keycloak as authority
- [x] Configure token validation parameters
- [x] Add authentication middleware
- [ ] Test token validation with protected endpoints

### Phase 6: Todo Backend API - Business Logic
- [x] Create Todo model (Id, Title, Description, IsCompleted, CreatedAt)
- [x] Create TodoController with CRUD endpoints
- [x] Add [Authorize] attribute to protect endpoints
- [x] Implement EF Core repository pattern (optional)
- [x] Create and run database migrations

### Phase 7: Swagger Configuration
- [ ] Configure Swagger with OAuth2 support
- [ ] Add security definitions for Bearer token
- [ ] Add authorization button in Swagger UI
- [ ] Test authentication flow through Swagger

### Phase 8: Testing & Validation
- [ ] Test client_credentials grant flow
- [ ] Test password grant flow
- [ ] Test refresh token flow
- [ ] Test token revocation
- [ ] Test protected endpoints with valid token
- [ ] Test protected endpoints without token (should return 401)
- [ ] Test with invalid/expired token
- [ ] Test scope validation

### Phase 9: Documentation
- [ ] Document all API endpoints
- [ ] Create example curl commands
- [ ] Document error responses
- [ ] Add troubleshooting guide
- [ ] Create README.md with quick start guide

### Phase 10: Cleanup & Best Practices
- [ ] Add error handling and logging
- [ ] Add input validation
- [ ] Configure CORS if needed
- [ ] Add health check endpoints
- [ ] Review security configurations
- [ ] Add .gitignore for secrets
- [ ] Create environment variable templates

---

## Prerequisites
- Docker and Docker Compose installed
- .NET 8.0 SDK installed
- curl or Postman for testing

## Setup Instructions

### Step 1: Start Keycloak and PostgreSQL

```bash
cd keycloak
docker-compose up -d
```

Wait for Keycloak to start (approximately 30-60 seconds).

### Step 2: Configure Keycloak

Access Keycloak Admin Console:
- URL: http://localhost:8080
- Username: admin
- Password: admin

#### Create Realm
1. Click "Create Realm"
2. Name: `poc-realm`
3. Click "Create"

#### Create Client Scope
1. Navigate to "Client Scopes"
2. Click "Create client scope"
3. Name: `todo-backend`
4. Protocol: `openid-connect`
5. Click "Save"

#### Create Client
1. Navigate to "Clients"
2. Click "Create client"
3. Client ID: `todo-backend-client`
4. Client Protocol: `openid-connect`
5. Click "Next"
6. Enable "Client authentication"
7. Enable "Direct access grants"
8. Enable "Service accounts roles"
9. Click "Save"
10. Go to "Credentials" tab and copy the "Client Secret"
11. Go to "Client Scopes" tab
12. Add `todo-backend` scope as "Default" scope

#### Create Test User
1. Navigate to "Users"
2. Click "Create user"
3. Username: `testuser`
4. Email: `testuser@example.com`
5. Click "Create"
6. Go to "Credentials" tab
7. Set password: `Test123!`
8. Disable "Temporary"
9. Click "Set password"

### Step 3: Configure API

Update the `appsettings.json` in the Todo Backend API with:
- Keycloak URL
- Realm name
- Client ID and Secret (from Step 2)
- Database connection string

### Step 4: Run Todo Backend API

```bash
cd apps/todo-backend
dotnet restore
dotnet run
```

API will be available at: http://localhost:5001
Swagger UI: http://localhost:5001/swagger

## Testing the Implementation

### 1. Client Credentials Flow (Machine-to-Machine)

```bash
curl -X POST http://localhost:5001/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "todo-backend-client",
    "client_secret": "<YOUR_CLIENT_SECRET>"
  }'
```

### 2. Password Grant Flow (User Authentication)

```bash
curl -X POST http://localhost:5001/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "password",
    "client_id": "todo-backend-client",
    "client_secret": "<YOUR_CLIENT_SECRET>",
    "username": "testuser",
    "password": "Test123!"
  }'
```

### 3. Refresh Token

```bash
curl -X POST http://localhost:5001/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "refresh_token",
    "client_id": "todo-backend-client",
    "client_secret": "<YOUR_CLIENT_SECRET>",
    "refresh_token": "<YOUR_REFRESH_TOKEN>"
  }'
```

### 4. Revoke Token

```bash
curl -X POST http://localhost:5001/api/auth/revoke \
  -H "Content-Type: application/json" \
  -d '{
    "client_id": "todo-backend-client",
    "client_secret": "<YOUR_CLIENT_SECRET>",
    "token": "<YOUR_ACCESS_TOKEN>"
  }'
```

### 5. Access Protected Endpoint

```bash
curl -X GET http://localhost:5001/api/todos \
  -H "Authorization: Bearer <YOUR_ACCESS_TOKEN>"
```

## API Endpoints

### Authentication Endpoints
- `POST /api/auth/token` - Get access token
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/revoke` - Revoke token

### Todo Endpoints (Protected)
- `GET /api/todos` - List all todos
- `GET /api/todos/{id}` - Get todo by ID
- `POST /api/todos` - Create new todo
- `PUT /api/todos/{id}` - Update todo
- `DELETE /api/todos/{id}` - Delete todo

## Troubleshooting

### Keycloak not starting
- Check Docker logs: `docker-compose logs keycloak`
- Ensure PostgreSQL is healthy: `docker-compose ps`

### Token validation fails
- Verify Keycloak URL is accessible from API
- Check client scope is assigned to client
- Ensure realm name matches configuration

### Database connection issues
- Verify PostgreSQL is running
- Check connection string in appsettings.json
- Ensure database exists (created by EF migrations)

## Security Considerations

1. **Never commit secrets**: Use environment variables or secret management
2. **Use HTTPS in production**: Configure SSL/TLS certificates
3. **Token expiration**: Configure appropriate token lifetimes in Keycloak
4. **Scope validation**: Always validate scopes in API endpoints
5. **Rate limiting**: Implement rate limiting on auth endpoints
6. **Audit logging**: Enable logging for authentication events

## Next Steps

1. Add more APIs to the ecosystem
2. Implement role-based access control (RBAC)
3. Add API gateway (e.g., Kong, Ocelot)
4. Implement token caching
5. Add monitoring and observability
6. Configure production-ready settings
