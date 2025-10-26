#!/bin/bash

set -e

KEYCLOAK_URL="http://localhost:8080"
REALM="poc-realm"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

echo "=========================================="
echo "Configuring Frontend Client in Keycloak"
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

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" = "null" ]; then
    echo "❌ Failed to get admin token"
    exit 1
fi
echo "✅ Admin token obtained"
echo ""

# Create frontend client
echo "Creating frontend client: todo-frontend-client..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "todo-frontend-client",
    "name": "Todo Frontend Client",
    "description": "Next.js frontend application",
    "enabled": true,
    "publicClient": true,
    "protocol": "openid-connect",
    "standardFlowEnabled": true,
    "directAccessGrantsEnabled": false,
    "implicitFlowEnabled": false,
    "serviceAccountsEnabled": false,
    "redirectUris": [
      "http://localhost:3000/*",
      "http://localhost:3000/api/auth/callback/keycloak"
    ],
    "webOrigins": [
      "http://localhost:3000"
    ],
    "defaultClientScopes": [
      "profile",
      "email",
      "todo-backend"
    ]
  }'

echo "✅ Frontend client created"
echo ""

# Assign todo-backend scope to client
echo "Assigning todo-backend scope to frontend client..."
CLIENT_SCOPE_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/client-scopes" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[] | select(.name=="todo-backend") | .id')

FRONTEND_CLIENT_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients?clientId=todo-frontend-client" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

curl -s -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${FRONTEND_CLIENT_ID}/default-client-scopes/${CLIENT_SCOPE_ID}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"

echo "✅ Scope assigned"
echo ""

echo "=========================================="
echo "✅ Frontend Client Configuration Complete!"
echo "=========================================="
echo ""
echo "Client Details:"
echo "  Client ID: todo-frontend-client"
echo "  Type: Public (SPA)"
echo "  Redirect URIs: http://localhost:3000/*"
echo "  Scopes: profile, email, todo-backend"
echo ""
echo "Next steps:"
echo "  1. Create Next.js project"
echo "  2. Configure NextAuth with these settings"
echo ""
