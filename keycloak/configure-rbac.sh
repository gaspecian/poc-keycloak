#!/bin/bash

set -e

KEYCLOAK_URL="http://localhost:8080"
REALM="poc-realm"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

echo "=========================================="
echo "Configuring RBAC with Authorization Services"
echo "=========================================="
echo ""

# Get admin token
echo "Getting admin access token..."
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

echo "✅ Admin token obtained"
echo ""

# Get backend client ID
BACKEND_CLIENT_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients?clientId=todo-backend-client" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Enable Authorization Services on backend client
echo "Enabling Authorization Services on backend client..."
curl -s -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${BACKEND_CLIENT_ID}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "todo-backend-client",
    "authorizationServicesEnabled": true,
    "serviceAccountsEnabled": true
  }'

echo "✅ Authorization Services enabled"
echo ""

# Create realm role: todo-manager
echo "Creating realm role: todo-manager..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/roles" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "todo-manager",
    "description": "Can manage todos"
  }' 2>/dev/null || echo "Role already exists"

echo "✅ Role created"
echo ""

# Get testuser ID
echo "Getting testuser ID..."
USER_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/users?username=testuser" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Get role
ROLE=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/roles/todo-manager" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}")

# Assign role to testuser
echo "Assigning todo-manager role to testuser..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/role-mappings/realm" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "[${ROLE}]"

echo "✅ Role assigned"
echo ""

# Create Resources
echo "Creating authorization resources..."

# Create Todo resource
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${BACKEND_CLIENT_ID}/authz/resource-server/resource" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Todo",
    "type": "urn:todo-backend:resources:todo",
    "ownerManagedAccess": false,
    "displayName": "Todo Resource",
    "uris": ["/api/todos/*"]
  }'

echo "✅ Resources created"
echo ""

# Create Scopes
echo "Creating authorization scopes..."
for scope in "create-todo" "read-todo" "update-todo" "delete-todo" "list-todos"; do
  curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${BACKEND_CLIENT_ID}/authz/resource-server/scope" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"${scope}\",
      \"displayName\": \"${scope}\"
    }"
done

echo "✅ Scopes created"
echo ""

# Create Role-based Policy
echo "Creating role-based policy..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${BACKEND_CLIENT_ID}/authz/resource-server/policy/role" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Todo Manager Policy",
    "description": "Policy for todo-manager role",
    "logic": "POSITIVE",
    "roles": [
      {
        "id": "todo-manager",
        "required": true
      }
    ]
  }'

echo "✅ Policy created"
echo ""

# Get policy ID
POLICY_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${BACKEND_CLIENT_ID}/authz/resource-server/policy?name=Todo%20Manager%20Policy" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Get resource ID
RESOURCE_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${BACKEND_CLIENT_ID}/authz/resource-server/resource?name=Todo" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0]._id')

# Get scope IDs
SCOPE_IDS=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${BACKEND_CLIENT_ID}/authz/resource-server/scope" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '[.[] | select(.name | startswith("create-todo") or startswith("read-todo") or startswith("update-todo") or startswith("delete-todo") or startswith("list-todos")) | .id] | join("\",\"")' | sed 's/^/["/' | sed 's/$/"]/')

# Create Scope-based Permission
echo "Creating scope-based permissions..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${BACKEND_CLIENT_ID}/authz/resource-server/permission/scope" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Todo Management Permission\",
    \"description\": \"Permission to manage todos\",
    \"scopes\": ${SCOPE_IDS},
    \"policies\": [\"${POLICY_ID}\"],
    \"resources\": [\"${RESOURCE_ID}\"],
    \"decisionStrategy\": \"UNANIMOUS\"
  }"

echo "✅ Permissions created"
echo ""

echo "=========================================="
echo "✅ RBAC Configuration Complete!"
echo "=========================================="
echo ""
echo "Created:"
echo "  - Role: todo-manager (assigned to testuser)"
echo "  - Resource: Todo"
echo "  - Scopes: create-todo, read-todo, update-todo, delete-todo, list-todos"
echo "  - Policy: Todo Manager Policy (requires todo-manager role)"
echo "  - Permission: Todo Management Permission"
echo ""
