# POC: Keycloak as IDP for APIs

This is a proof of concept demonstrating Keycloak as an Identity Provider (IDP) for third-party applications using OAuth 2.0 and OpenID Connect.

## Architecture

- **Keycloak**: Identity Provider (Port 8080)
- **PostgreSQL**: Shared database for Keycloak and APIs (Port 5432)
- **Todo Backend API**: .NET 8.0 Web API (Port 5001)

## Quick Start

### Prerequisites

- Docker and Docker Compose
- .NET 8.0 SDK (for running the API)

### 1. Start Infrastructure

```bash
cd keycloak
docker compose up -d
```

Wait for Keycloak to be ready (30-60 seconds).

### 2. Configure Keycloak

```bash
cd keycloak
./configure-keycloak.sh
```

This will create:
- Realm: `poc-realm`
- Client: `todo-backend-client`
- Client Scope: `todo-backend`
- Test User: `testuser` / `Test123!`

**Important**: Save the client secret from the output!

### 3. Configure API

Update `apps/todo-backend/appsettings.json` with the client secret from step 2:

```json
{
  "Keycloak": {
    "ClientSecret": "YOUR_CLIENT_SECRET_HERE"
  }
}
```

### 4. Run Todo Backend API

```bash
cd apps/todo-backend
dotnet restore
dotnet run
```

API will be available at: http://localhost:5001
Swagger UI: http://localhost:5001/swagger

## Testing

### Get Access Token (Password Grant)

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

### Get Access Token (Client Credentials)

```bash
curl -X POST http://localhost:5001/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "todo-backend-client",
    "client_secret": "YOUR_CLIENT_SECRET"
  }'
```

### Access Protected Endpoint

```bash
curl -X GET http://localhost:5001/api/todos \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Create Todo

```bash
curl -X POST http://localhost:5001/api/todos \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My First Todo",
    "description": "Testing the API"
  }'
```

## API Endpoints

### Authentication
- `POST /api/auth/token` - Get access token
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/revoke` - Revoke token

### Todos (Protected)
- `GET /api/todos` - List all todos
- `GET /api/todos/{id}` - Get todo by ID
- `POST /api/todos` - Create new todo
- `PUT /api/todos/{id}` - Update todo
- `DELETE /api/todos/{id}` - Delete todo

## Documentation

- [Architecture Documentation](docs/ARCHITECTURE.md)
- [Implementation Guide](docs/IMPLEMENTATION.md)

## Keycloak Admin Console

- URL: http://localhost:8080
- Username: `admin`
- Password: `admin`

## Stopping the Environment

```bash
cd keycloak
docker compose down
```

To remove all data:

```bash
docker compose down -v
```
