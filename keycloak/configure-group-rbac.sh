#!/bin/bash

set -e

KEYCLOAK_URL="http://localhost:8080"
REALM="poc-realm"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

echo "=========================================="
echo "Configuring Group-Based RBAC"
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

# Create roles
echo "Creating roles..."
for role in "create-todo" "update-todo" "list-todos" "delete-todo" "get-todo"; do
  curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/roles" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"${role}\",
      \"description\": \"Permission to ${role}\"
    }" 2>/dev/null || echo "  Role ${role} already exists"
done

echo "✅ Roles created"
echo ""

# Create group
echo "Creating group: todo-app-user..."
GROUP_RESPONSE=$(curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/groups" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "todo-app-user"
  }' -w "\n%{http_code}")

HTTP_CODE=$(echo "$GROUP_RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "409" ]; then
  echo "✅ Group created"
else
  echo "⚠️  Group may already exist"
fi
echo ""

# Get group ID
GROUP_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/groups?search=todo-app-user" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Assign roles to group
echo "Assigning roles to group..."
for role in "create-todo" "update-todo" "list-todos" "delete-todo" "get-todo"; do
  ROLE_DATA=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/roles/${role}" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}")
  
  curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/groups/${GROUP_ID}/role-mappings/realm" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "[${ROLE_DATA}]"
done

echo "✅ Roles assigned to group"
echo ""

# Get testuser ID
echo "Adding testuser to group..."
USER_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/users?username=testuser" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Add user to group
curl -s -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/groups/${GROUP_ID}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"

echo "✅ User added to group"
echo ""

echo "=========================================="
echo "✅ Group-Based RBAC Configuration Complete!"
echo "=========================================="
echo ""
echo "Created:"
echo "  - Group: todo-app-user"
echo "  - Roles: create-todo, update-todo, list-todos, delete-todo, get-todo"
echo "  - testuser added to todo-app-user group"
echo ""
echo "Note: Logout and login again to get new roles in token"
echo ""
