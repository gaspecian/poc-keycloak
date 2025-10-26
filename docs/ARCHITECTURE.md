# Architecture Documentation

## Overview
This POC demonstrates Keycloak as an Identity Provider (IDP) for third-party applications and internal APIs using OAuth 2.0 and OpenID Connect.

## Architecture Components

### 1. Keycloak (Identity Provider)
- **Purpose**: Centralized authentication and authorization server
- **Protocol**: OpenID Connect (OIDC) / OAuth 2.0
- **Deployment**: Docker container with PostgreSQL backend
- **Port**: 8080

### 2. PostgreSQL Database
- **Purpose**: Persistent storage for Keycloak and application data
- **Deployment**: Docker container
- **Databases**:
  - `keycloak` - Keycloak configuration and user data
  - `tododb` - Todo Backend application data

### 3. APIs (Application Ecosystem)
- **Todo Backend API** (.NET)
  - Port: 5001
  - Database: tododb
  - Swagger UI: Available at `/swagger`

## Authentication Flow

### OAuth 2.0 Endpoints (Implemented by APIs)
Each API implements these endpoints:
- `POST /api/auth/token` - Obtain access token
- `POST /api/auth/refresh` - Refresh access token
- `POST /api/auth/revoke` - Revoke token

### Grant Types Supported
1. **Client Credentials** (machine-to-machine)
   - Required: `grant_type`, `client_id`, `client_secret`
   
2. **Password Grant** (user authentication)
   - Required: `grant_type`, `client_id`, `client_secret`, `username`, `password`

3. **Refresh Token**
   - Required: `grant_type`, `client_id`, `client_secret`, `refresh_token`

## Security Model

### Client Scopes
- Each API has a corresponding client scope in Keycloak (e.g., `todo-backend`)
- Clients must have the required scope assigned to access specific APIs
- Scope is passed during token request to Keycloak

### Token Validation
- APIs validate tokens with Keycloak's OIDC discovery endpoint
- JWT tokens contain scope claims that determine API access
- Token introspection ensures real-time validation

## Data Flow

```
Third-Party App/User
        ↓
    API Endpoint (/api/auth/token)
        ↓
    Keycloak (OIDC Token Endpoint)
        ↓
    Token Validation & Scope Check
        ↓
    Access Token Returned
        ↓
    API Resources (Protected Endpoints)
```

## Network Architecture

```
┌─────────────────────────────────────────┐
│         Docker Network (poc-network)     │
│                                          │
│  ┌──────────────┐      ┌─────────────┐ │
│  │  Keycloak    │◄────►│ PostgreSQL  │ │
│  │  Port: 8080  │      │ Port: 5432  │ │
│  └──────────────┘      └─────────────┘ │
│         ▲                      ▲        │
│         │                      │        │
│  ┌──────┴──────────────────────┴─────┐ │
│  │      Todo Backend API (.NET)      │ │
│  │          Port: 5001                │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Keycloak Configuration

### Realm: `poc-realm`
- Master realm for all applications and users

### Clients
- **todo-backend-client**: Client for Todo Backend API
  - Access Type: Confidential
  - Service Accounts Enabled: Yes
  - Direct Access Grants: Yes

### Client Scopes
- **todo-backend**: Scope required to access Todo Backend API
  - Type: Default/Optional
  - Protocol: openid-connect

### Users
- Test users created for password grant flow
- Service accounts for client credentials flow

## Technology Stack

- **Keycloak**: 23.0
- **PostgreSQL**: 15
- **.NET**: 8.0
- **Docker & Docker Compose**: Latest
- **OpenID Connect**: 1.0
- **OAuth 2.0**: RFC 6749
