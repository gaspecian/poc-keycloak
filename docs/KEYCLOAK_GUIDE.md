# Keycloak Operations Guide

Complete guide for managing Keycloak configuration, permissions, and applications.

## Table of Contents

1. [Understanding Keycloak Concepts](#understanding-keycloak-concepts)
2. [Current Implementation](#current-implementation)
3. [Managing Permissions](#managing-permissions)
4. [Adding New Applications](#adding-new-applications)
5. [User Management](#user-management)
6. [Advanced Scenarios](#advanced-scenarios)

## Understanding Keycloak Concepts

### Core Concepts

#### Realm
- **What:** Isolated namespace for users, clients, roles, and groups
- **Purpose:** Multi-tenancy, separate environments (dev/staging/prod)
- **Example:** `poc-realm` in this project

#### Client
- **What:** Application that uses Keycloak for authentication
- **Types:**
  - **Confidential:** Backend services with client secret (server-to-server)
  - **Public:** Frontend apps without secret (browser-based)
- **Example:** `todo-backend-client` (confidential), `todo-frontend-client` (public)

#### User
- **What:** Person who authenticates
- **Attributes:** Username, email, first name, last name, custom attributes
- **Example:** `testuser`

#### Role
- **What:** Permission or capability
- **Types:**
  - **Realm roles:** Available across all clients in realm
  - **Client roles:** Specific to one client
- **Example:** `create-todo`, `todo-app-access`

#### Group
- **What:** Collection of users with shared roles
- **Purpose:** Simplify role assignment
- **Example:** `todo-app-user` group with all todo permissions

#### Token
- **What:** JWT containing user identity and permissions
- **Types:**
  - **Access Token:** Used to access APIs (short-lived, 5 min)
  - **ID Token:** Contains user profile information
  - **Refresh Token:** Used to get new access tokens (long-lived)

### Authentication Flows

#### Authorization Code Flow (Frontend)
```
User → Frontend → Keycloak Login → Keycloak → Frontend (with code)
Frontend → Keycloak (exchange code for tokens) → Frontend (with tokens)
```

#### Password Grant Flow (Direct)
```
Client → Keycloak (username + password) → Keycloak → Client (with tokens)
```

#### Client Credentials Flow (Service-to-Service)
```
Service → Keycloak (client_id + client_secret) → Keycloak → Service (with token)
```

## Current Implementation

### Realm Structure

```
poc-realm
├── Clients
│   ├── todo-backend-client (Confidential)
│   │   ├── Client Secret: <generated>
│   │   ├── Flows: Standard, Direct Access Grants
│   │   └── Mappers: realm-roles-backend
│   └── todo-frontend-client (Public)
│       ├── Flows: Standard (with PKCE)
│       └── Mappers: realm-roles
├── Roles
│   ├── todo-app-access (Application access)
│   ├── create-todo (Feature permission)
│   ├── update-todo (Feature permission)
│   ├── list-todos (Feature permission)
│   ├── delete-todo (Feature permission)
│   └── get-todo (Feature permission)
├── Groups
│   └── todo-app-user
│       └── Role Mappings: All roles above
└── Users
    └── testuser
        └── Groups: todo-app-user
```

### How It Works

#### 1. User Login
```
1. User clicks "Sign in" on frontend
2. Redirected to Keycloak login page
3. User enters credentials
4. Keycloak validates credentials
5. Keycloak checks user's groups and roles
6. Keycloak generates tokens with roles in claims
7. User redirected back to frontend with tokens
```

#### 2. Token Structure
```json
{
  "sub": "user-id",
  "preferred_username": "testuser",
  "email": "testuser@example.com",
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

#### 3. Authorization Check
```
Frontend Middleware:
  ✓ Check if user has "todo-app-access" role
  → If not: redirect to /access-denied
  → If yes: allow access to dashboard

Backend API:
  ✓ Validate JWT signature
  ✓ Check if user has required role for endpoint
  → If not: return 403 Forbidden
  → If yes: process request
```

## Managing Permissions

### Creating New Roles

#### Via Admin Console (GUI)

1. **Access Keycloak Admin Console**
   ```
   URL: http://localhost:8080
   Username: admin
   Password: admin
   ```

2. **Navigate to Roles**
   ```
   Select Realm: poc-realm
   → Realm roles
   → Create role
   ```

3. **Create Role**
   ```
   Role name: export-todos
   Description: Permission to export todos to CSV
   → Save
   ```

4. **Assign to Group**
   ```
   Groups → todo-app-user
   → Role mapping
   → Assign role
   → Select "export-todos"
   → Assign
   ```

#### Via Script (Automated)

Create `keycloak/add-role.sh`:

```bash
#!/bin/bash

KEYCLOAK_URL="http://localhost:8080"
REALM="poc-realm"
ROLE_NAME="export-todos"
GROUP_NAME="todo-app-user"

# Get admin token
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

# Create role
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/roles" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"${ROLE_NAME}\",
    \"description\": \"Permission to export todos\"
  }"

# Get group ID
GROUP_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/groups?search=${GROUP_NAME}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Get role data
ROLE_DATA=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/roles/${ROLE_NAME}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}")

# Assign role to group
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/groups/${GROUP_ID}/role-mappings/realm" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "[${ROLE_DATA}]"

echo "✅ Role ${ROLE_NAME} created and assigned to ${GROUP_NAME}"
```

### Implementing Role in Backend

1. **Add Authorization Policy**

   Edit `apps/todo-backend/Program.cs`:

   ```csharp
   builder.Services.AddAuthorization(options =>
   {
       // Existing policies...
       options.AddPolicy("export-todos", policy => 
           policy.RequireRole("export-todos"));
   });
   ```

2. **Protect Endpoint**

   Edit `apps/todo-backend/Controllers/TodosController.cs`:

   ```csharp
   [HttpGet("export")]
   [Authorize(Policy = "export-todos")]
   public async Task<IActionResult> ExportTodos()
   {
       var todos = await _context.Todos.ToListAsync();
       // Generate CSV
       return File(csvBytes, "text/csv", "todos.csv");
   }
   ```

3. **Test**
   ```bash
   # User with export-todos role
   curl http://localhost:5001/api/todos/export \
     -H "Authorization: Bearer $TOKEN"
   
   # Should return CSV file
   ```

### Creating Role Hierarchies

#### Composite Roles

Create a role that includes other roles:

1. **Create Parent Role**
   ```
   Realm roles → Create role
   Name: todo-admin
   Description: Full admin access to todos
   ```

2. **Add Child Roles**
   ```
   Edit todo-admin role
   → Composite roles
   → Add roles:
     - create-todo
     - update-todo
     - list-todos
     - delete-todo
     - get-todo
     - export-todos
   → Save
   ```

3. **Assign to User**
   ```
   Users → Select user
   → Role mapping
   → Assign "todo-admin"
   
   User now has all child roles automatically
   ```

### Permission Patterns

#### Pattern 1: Feature-Level Permissions
```
Roles: create-todo, update-todo, delete-todo
Use case: Granular control over features
Example: Junior users can only create/read, not delete
```

#### Pattern 2: Application-Level Permissions
```
Role: todo-app-access
Use case: Control access to entire application
Example: Only employees can access the app
```

#### Pattern 3: Data-Level Permissions
```
Role: view-all-todos
Use case: Some users see all data, others only their own
Example: Managers see all todos, users see only theirs
```

#### Pattern 4: Hierarchical Permissions
```
Roles: todo-user < todo-manager < todo-admin
Use case: Progressive permissions
Example: Admin has all manager permissions + more
```

## Adding New Applications

### Scenario: Add a Reports Application

#### Step 1: Create New Client in Keycloak

**Via Admin Console:**

1. **Create Client**
   ```
   Clients → Create client
   Client ID: reports-backend-client
   Client type: OpenID Connect
   → Next
   ```

2. **Configure Capability**
   ```
   Client authentication: ON (for confidential client)
   Authorization: OFF (unless using fine-grained permissions)
   Authentication flow:
     ✓ Standard flow
     ✓ Direct access grants
   → Next
   ```

3. **Configure Access**
   ```
   Valid redirect URIs: http://localhost:5002/*
   Valid post logout redirect URIs: http://localhost:5002/*
   Web origins: http://localhost:3000
   → Save
   ```

4. **Get Client Secret**
   ```
   Credentials tab
   → Copy Client secret
   → Save to secure location
   ```

**Via Script:**

Create `keycloak/add-reports-client.sh`:

```bash
#!/bin/bash

KEYCLOAK_URL="http://localhost:8080"
REALM="poc-realm"

# Get admin token
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

# Create client
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "reports-backend-client",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": false,
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": true,
    "redirectUris": ["http://localhost:5002/*"],
    "webOrigins": ["http://localhost:3000"],
    "attributes": {
      "access.token.lifespan": "300"
    }
  }'

# Get client secret
CLIENT_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients?clientId=reports-backend-client" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

SECRET=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${CLIENT_ID}/client-secret" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.value')

echo "Client created!"
echo "Client ID: reports-backend-client"
echo "Client Secret: ${SECRET}"
```

#### Step 2: Create Application-Specific Roles

```bash
# Create roles
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/roles" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "reports-app-access",
    "description": "Access to Reports Application"
  }'

curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/roles" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "generate-report",
    "description": "Generate reports"
  }'

curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/roles" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "view-report",
    "description": "View reports"
  }'
```

#### Step 3: Create Group for Application

```bash
# Create group
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/groups" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "reports-app-user"
  }'

# Get group ID
GROUP_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/groups?search=reports-app-user" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Assign roles to group
for role in "reports-app-access" "generate-report" "view-report"; do
  ROLE_DATA=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/roles/${role}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
  
  curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/groups/${GROUP_ID}/role-mappings/realm" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "[${ROLE_DATA}]"
done
```

#### Step 4: Configure Backend Application

Create `apps/reports-backend/appsettings.json`:

```json
{
  "Keycloak": {
    "Authority": "http://localhost:8080/realms/poc-realm",
    "Audience": "reports-backend",
    "ClientId": "reports-backend-client",
    "ClientSecret": "YOUR_CLIENT_SECRET"
  }
}
```

Configure authentication in `Program.cs`:

```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Keycloak:Authority"];
        options.RequireHttpsMetadata = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = false,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            RoleClaimType = ClaimTypes.Role
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("generate-report", policy => 
        policy.RequireRole("generate-report"));
    options.AddPolicy("view-report", policy => 
        policy.RequireRole("view-report"));
});
```

#### Step 5: Add Frontend Client (Optional)

If you need a separate frontend:

```bash
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "reports-frontend-client",
    "enabled": true,
    "protocol": "openid-connect",
    "publicClient": true,
    "standardFlowEnabled": true,
    "redirectUris": ["http://localhost:3001/*"],
    "webOrigins": ["http://localhost:3001"],
    "attributes": {
      "pkce.code.challenge.method": "S256"
    }
  }'
```

## User Management

### Adding Users

#### Via Admin Console

1. **Create User**
   ```
   Users → Add user
   Username: john.doe
   Email: john.doe@company.com
   First name: John
   Last name: Doe
   Email verified: ON
   → Create
   ```

2. **Set Password**
   ```
   Credentials tab
   → Set password
   Password: SecurePass123!
   Temporary: OFF
   → Save
   ```

3. **Assign to Groups**
   ```
   Groups tab
   → Join Group
   → Select "todo-app-user"
   → Join
   ```

#### Via Script

```bash
#!/bin/bash

USERNAME="john.doe"
EMAIL="john.doe@company.com"
PASSWORD="SecurePass123!"
GROUP="todo-app-user"

# Create user
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/users" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${USERNAME}\",
    \"email\": \"${EMAIL}\",
    \"firstName\": \"John\",
    \"lastName\": \"Doe\",
    \"enabled\": true,
    \"emailVerified\": true
  }"

# Get user ID
USER_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/users?username=${USERNAME}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Set password
curl -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/reset-password" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"password\",
    \"value\": \"${PASSWORD}\",
    \"temporary\": false
  }"

# Add to group
GROUP_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/groups?search=${GROUP}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

curl -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/groups/${GROUP_ID}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"

echo "✅ User ${USERNAME} created and added to ${GROUP}"
```

### Bulk User Import

Create `users.json`:

```json
[
  {
    "username": "user1",
    "email": "user1@company.com",
    "firstName": "User",
    "lastName": "One",
    "enabled": true,
    "credentials": [
      {
        "type": "password",
        "value": "Pass123!",
        "temporary": false
      }
    ],
    "groups": ["/todo-app-user"]
  },
  {
    "username": "user2",
    "email": "user2@company.com",
    "firstName": "User",
    "lastName": "Two",
    "enabled": true,
    "credentials": [
      {
        "type": "password",
        "value": "Pass123!",
        "temporary": false
      }
    ],
    "groups": ["/todo-app-user"]
  }
]
```

Import via Admin Console:
```
Realm settings → Partial import
→ Select file: users.json
→ Import
```

## Advanced Scenarios

### Scenario 1: Multi-Application Access

**Requirement:** User needs access to both Todo and Reports apps

**Solution:**

1. **Add user to both groups**
   ```bash
   # Add to todo-app-user group
   curl -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/groups/${TODO_GROUP_ID}" \
     -H "Authorization: Bearer ${ADMIN_TOKEN}"
   
   # Add to reports-app-user group
   curl -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/groups/${REPORTS_GROUP_ID}" \
     -H "Authorization: Bearer ${ADMIN_TOKEN}"
   ```

2. **Token will contain roles from both groups**
   ```json
   {
     "roles": [
       "todo-app-access",
       "create-todo",
       "reports-app-access",
       "generate-report"
     ]
   }
   ```

### Scenario 2: Read-Only Users

**Requirement:** Some users can only view, not modify

**Solution:**

1. **Create read-only group**
   ```bash
   # Create group
   curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/groups" \
     -H "Authorization: Bearer ${ADMIN_TOKEN}" \
     -d '{"name": "todo-app-readonly"}'
   
   # Assign only read roles
   # - todo-app-access
   # - list-todos
   # - get-todo
   ```

2. **Assign users to read-only group**

### Scenario 3: Temporary Access

**Requirement:** Grant access for limited time

**Solution:**

1. **Set user account expiration**
   ```bash
   # Calculate expiration timestamp (30 days from now)
   EXPIRATION=$(($(date +%s) + 2592000))
   
   curl -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}" \
     -H "Authorization: Bearer ${ADMIN_TOKEN}" \
     -H "Content-Type: application/json" \
     -d "{
       \"attributes\": {
         \"expirationDate\": [\"${EXPIRATION}\"]
       }
     }"
   ```

2. **Create scheduled job to disable expired users**

### Scenario 4: Department-Based Access

**Requirement:** Different departments have different permissions

**Solution:**

1. **Create department groups**
   ```
   Groups:
   ├── engineering
   │   └── Roles: todo-app-access, create-todo, update-todo, delete-todo
   ├── sales
   │   └── Roles: todo-app-access, create-todo, list-todos
   └── management
       └── Roles: todo-app-access, all permissions
   ```

2. **Add department attribute to users**
   ```bash
   curl -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}" \
     -H "Authorization: Bearer ${ADMIN_TOKEN}" \
     -d '{
       "attributes": {
         "department": ["engineering"]
       }
     }'
   ```

### Scenario 5: External Users (Partners/Customers)

**Requirement:** External users with limited access

**Solution:**

1. **Create external realm or group**
   ```
   Group: external-users
   Roles:
   - todo-app-access
   - list-todos (only their own data)
   ```

2. **Add custom claim for user type**
   ```
   Client Scopes → Create
   Name: user-type
   Add mapper:
   - Type: User Attribute
   - User Attribute: userType
   - Token Claim Name: user_type
   ```

3. **Filter data in backend based on user_type claim**

## Best Practices

### 1. Role Naming Convention
```
Format: <app>-<resource>-<action>
Examples:
- todo-app-access
- todo-item-create
- reports-dashboard-view
```

### 2. Group Strategy
```
- Use groups for role assignment
- Don't assign roles directly to users
- Create groups per application or department
```

### 3. Token Lifespan
```
- Access Token: 5-15 minutes (short-lived)
- Refresh Token: 30 days (long-lived)
- ID Token: Same as access token
```

### 4. Client Configuration
```
- Backend: Confidential client with secret
- Frontend: Public client with PKCE
- Service: Confidential with service account
```

### 5. Security
```
- Always use HTTPS in production
- Rotate client secrets regularly
- Enable MFA for admin accounts
- Audit logs for compliance
- Regular security updates
```

### 6. Testing
```
- Test with different user roles
- Test token expiration
- Test logout flow
- Test unauthorized access
```

## Troubleshooting

### Issue: Roles not appearing in token

**Solution:**
1. Check role mapper is configured
2. Verify user has role assigned (via group)
3. Logout and login to get fresh token
4. Check token claims: `echo $TOKEN | cut -d'.' -f2 | base64 -d | jq`

### Issue: 403 Forbidden despite having role

**Solution:**
1. Check backend RoleClaimType matches token claim
2. Verify policy name matches role name
3. Check role is in token claims
4. Restart backend after policy changes

### Issue: User can't login

**Solution:**
1. Check user is enabled
2. Verify password is correct
3. Check client redirect URIs
4. Review Keycloak logs: `docker logs poc-keycloak`

## Resources

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak Admin REST API](https://www.keycloak.org/docs-api/latest/rest-api/)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [OpenID Connect Specification](https://openid.net/connect/)
