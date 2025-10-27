# Architecture Documentation

## Overview

This POC demonstrates a complete authentication and authorization system using Keycloak as an Identity Provider (IDP) for a modern web application stack.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         User Browser                         │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ HTTPS
                 ▼
┌─────────────────────────────────────────────────────────────┐
│              Next.js Frontend (Port 3000)                    │
│  - NextAuth.js v5 (OAuth 2.0 / OIDC)                        │
│  - Middleware for app-level access control                  │
│  - Role-based UI rendering                                  │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ REST API + JWT Bearer Token
                 ▼
┌─────────────────────────────────────────────────────────────┐
│              .NET 8 Backend API (Port 5001)                  │
│  - JWT Bearer Authentication                                 │
│  - Role-based Authorization Policies                        │
│  - User-specific data filtering                             │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ OAuth 2.0 / OIDC
                 ▼
┌─────────────────────────────────────────────────────────────┐
│              Keycloak IDP (Port 8080)                        │
│  - Realm: poc-realm                                          │
│  - Clients: todo-backend-client, todo-frontend-client       │
│  - Groups & Roles Management                                │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ PostgreSQL Protocol
                 ▼
┌─────────────────────────────────────────────────────────────┐
│              PostgreSQL Database (Port 5432)                 │
│  - Keycloak data (users, roles, sessions)                   │
│  - Application data (todos)                                  │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Keycloak (Identity Provider)

**Purpose:** Centralized authentication and authorization server

**Configuration:**
- **Realm:** `poc-realm`
- **Clients:**
  - `todo-backend-client` (Confidential)
    - Client Credentials flow for service-to-service
    - Password flow for user authentication
  - `todo-frontend-client` (Public)
    - Authorization Code flow with PKCE
    - Used by Next.js frontend

**Features:**
- User management
- Role-based access control (RBAC)
- Group management
- Token issuance and validation
- SSO (Single Sign-On)

### 2. PostgreSQL Database

**Purpose:** Persistent storage for both Keycloak and application data

**Databases:**
- `keycloak` - Keycloak configuration and user data
- `tododb` - Application todos data

**Shared Benefits:**
- Single database instance
- Simplified deployment
- Consistent backup strategy

### 3. Backend API (.NET 8)

**Purpose:** Business logic and data access layer

**Technology Stack:**
- ASP.NET Core 8.0
- Entity Framework Core
- JWT Bearer Authentication
- PostgreSQL (Npgsql)

**Key Features:**
- RESTful API endpoints
- JWT token validation
- Role-based authorization
- User-specific data filtering
- CORS configuration for frontend

**Authentication Flow:**
1. Receives JWT token from frontend
2. Validates token with Keycloak public keys
3. Extracts user identity and roles from claims
4. Enforces authorization policies per endpoint

### 4. Frontend (Next.js 16)

**Purpose:** User interface and client-side logic

**Technology Stack:**
- Next.js 16 (App Router)
- NextAuth.js v5
- React Server Components
- Tailwind CSS + shadcn/ui
- TypeScript

**Key Features:**
- Server-side authentication
- Middleware-based access control
- Role-based UI rendering
- Automatic token refresh
- Proper logout with Keycloak session cleanup

## Authentication & Authorization Flow

### 1. User Login Flow

```
User → Frontend → Keycloak → Frontend → Backend
  1. User clicks "Sign in"
  2. Redirected to Keycloak login page
  3. User enters credentials
  4. Keycloak validates and issues tokens
  5. Frontend receives access_token, id_token, refresh_token
  6. Frontend stores tokens in session
  7. Frontend makes API calls with access_token
  8. Backend validates token and processes request
```

### 2. Authorization Layers

#### Layer 1: Application Access (Frontend Middleware)
- **Check:** `todo-app-access` role
- **Location:** Next.js middleware
- **Action:** Block access to entire application if role missing
- **Redirect:** `/access-denied` page

#### Layer 2: Feature Access (Backend Policies)
- **Check:** Specific feature roles (create-todo, update-todo, etc.)
- **Location:** Backend controller endpoints
- **Action:** Return 403 Forbidden if role missing
- **Display:** User-friendly error message in UI

#### Layer 3: Data Access (Backend Logic)
- **Check:** User ownership of data
- **Location:** Database queries
- **Action:** Filter data by user ID
- **Applies to:** Password grant flow only (not service accounts)

### 3. Token Structure

**Access Token Claims:**
```json
{
  "exp": 1234567890,
  "iat": 1234567890,
  "jti": "unique-token-id",
  "iss": "http://localhost:8080/realms/poc-realm",
  "sub": "user-id",
  "typ": "Bearer",
  "azp": "todo-frontend-client",
  "sid": "session-id",
  "scope": "openid email profile todo-backend",
  "email_verified": true,
  "preferred_username": "testuser",
  "roles": [
    "todo-app-access",
    "create-todo",
    "update-todo",
    "list-todos",
    "delete-todo",
    "get-todo"
  ]
}
```

## RBAC Model

### Roles Hierarchy

```
todo-app-access (Application Access)
  └── todo-app-user (Group)
      ├── create-todo
      ├── update-todo
      ├── list-todos
      ├── delete-todo
      └── get-todo
```

### Role Definitions

| Role | Description | Scope |
|------|-------------|-------|
| `todo-app-access` | Access to the application | Application-level |
| `create-todo` | Create new todos | Feature-level |
| `update-todo` | Update existing todos | Feature-level |
| `list-todos` | List all user's todos | Feature-level |
| `delete-todo` | Delete todos | Feature-level |
| `get-todo` | Get single todo details | Feature-level |

### Group Management

**Group:** `todo-app-user`
- Contains all feature roles
- Simplifies user management
- Add user to group → gets all permissions
- Remove user from group → loses all access

## Security Considerations

### 1. Token Security
- ✅ Tokens stored in secure HTTP-only cookies (NextAuth.js)
- ✅ Short-lived access tokens (5 minutes)
- ✅ Refresh token rotation
- ✅ Proper token validation on backend

### 2. CORS Configuration
- ✅ Restricted to frontend origin
- ✅ Credentials allowed for cookies
- ✅ Specific methods and headers allowed

### 3. Data Isolation
- ✅ Users see only their own data (password grant)
- ✅ Service accounts can see all data (client credentials)
- ✅ User ID extracted from JWT claims

### 4. Authorization
- ✅ Multi-layer authorization (app, feature, data)
- ✅ Centralized policy management in Keycloak
- ✅ No hardcoded credentials in code

## Scalability Considerations

### Horizontal Scaling
- **Frontend:** Stateless, can scale horizontally
- **Backend:** Stateless, can scale horizontally
- **Keycloak:** Can be clustered with shared database
- **Database:** Can use read replicas for scaling reads

### Performance Optimizations
- JWT validation uses cached public keys
- Database connection pooling
- Efficient queries with proper indexing
- Server-side rendering for initial page load

## Deployment Architecture

### Development
```
Docker Compose (Keycloak + PostgreSQL)
  + Local .NET API (dotnet run)
  + Local Next.js (npm run dev)
```

### Production (Recommended)
```
Kubernetes Cluster
  ├── Keycloak (StatefulSet)
  ├── PostgreSQL (StatefulSet with persistent volume)
  ├── Backend API (Deployment with HPA)
  └── Frontend (Deployment with HPA)
  
Ingress Controller
  ├── /api/* → Backend Service
  └── /* → Frontend Service
```

## Monitoring & Observability

### Recommended Tools
- **Logs:** Structured logging with Serilog (.NET) and Winston (Node.js)
- **Metrics:** Prometheus + Grafana
- **Tracing:** OpenTelemetry
- **APM:** Application Insights or Datadog

### Key Metrics to Monitor
- Authentication success/failure rate
- Token validation latency
- API response times
- Database query performance
- Active user sessions

## Future Enhancements

1. **Multi-tenancy:** Support multiple organizations
2. **Advanced RBAC:** Attribute-based access control (ABAC)
3. **Audit Logging:** Track all user actions
4. **Rate Limiting:** Prevent abuse
5. **API Gateway:** Centralized routing and policies
6. **Caching:** Redis for session and data caching
7. **WebSockets:** Real-time updates
8. **Mobile Apps:** OAuth 2.0 support for mobile clients
