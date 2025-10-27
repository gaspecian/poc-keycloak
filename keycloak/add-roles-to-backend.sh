#!/bin/bash

set -e

KEYCLOAK_URL="http://localhost:8080"
REALM="poc-realm"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

echo "Adding roles to backend client token..."

# Get admin token
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

# Get backend client ID
BACKEND_CLIENT_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM}/clients?clientId=todo-backend-client" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Add role mapper to backend client
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/clients/${BACKEND_CLIENT_ID}/protocol-mappers/models" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "realm-roles-backend",
    "protocol": "openid-connect",
    "protocolMapper": "oidc-usermodel-realm-role-mapper",
    "config": {
      "claim.name": "roles",
      "jsonType.label": "String",
      "multivalued": "true",
      "userinfo.token.claim": "true",
      "id.token.claim": "true",
      "access.token.claim": "true"
    }
  }' 2>&1

echo ""
echo "✅ Roles configured for backend client"
