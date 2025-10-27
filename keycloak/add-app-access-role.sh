#!/bin/bash

set -e

KEYCLOAK_URL="http://localhost:8080"
REALM="poc-realm"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

echo "=========================================="
echo "Adding Application Access Role"
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

# Create app access role
echo "Creating role: todo-app-access..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/roles" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "todo-app-access",
    "description": "Access to Todo Application"
  }' 2>/dev/null || echo "  Role already exists"

echo "✅ Role created"
echo ""

# Get group ID
GROUP_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/groups?search=todo-app-user" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Get role data
ROLE_DATA=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/roles/todo-app-access" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}")

# Assign role to group
echo "Assigning todo-app-access role to todo-app-user group..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/groups/${GROUP_ID}/role-mappings/realm" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "[${ROLE_DATA}]"

echo "✅ Role assigned to group"
echo ""

echo "=========================================="
echo "✅ Application Access Role Added!"
echo "=========================================="
echo ""
echo "Role: todo-app-access"
echo "Assigned to: todo-app-user group"
echo ""
echo "Users in todo-app-user group now have:"
echo "  - todo-app-access (application access)"
echo "  - create-todo, update-todo, list-todos, delete-todo, get-todo"
echo ""
