#!/bin/bash

KEYCLOAK_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"
REALM_NAME="poc-realm"
CLIENT_ID="todo-backend-client"
CLIENT_SCOPE="todo-backend"
TEST_USER="testuser"
TEST_PASSWORD="Test123!"

echo "Waiting for Keycloak to be ready..."
until curl -sf "${KEYCLOAK_URL}/health/ready" > /dev/null; do
  sleep 2
done
echo "Keycloak is ready!"

# Get admin token
echo "Getting admin access token..."
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" == "null" ] || [ -z "$ADMIN_TOKEN" ]; then
  echo "Failed to get admin token"
  exit 1
fi

# Create realm
echo "Creating realm: ${REALM_NAME}..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"realm\": \"${REALM_NAME}\",
    \"enabled\": true
  }"

# Create client scope
echo "Creating client scope: ${CLIENT_SCOPE}..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/client-scopes" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"${CLIENT_SCOPE}\",
    \"protocol\": \"openid-connect\",
    \"attributes\": {
      \"include.in.token.scope\": \"true\",
      \"display.on.consent.screen\": \"true\"
    }
  }"

# Get client scope ID
SCOPE_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/client-scopes" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r ".[] | select(.name==\"${CLIENT_SCOPE}\") | .id")

# Create client
echo "Creating client: ${CLIENT_ID}..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"clientId\": \"${CLIENT_ID}\",
    \"enabled\": true,
    \"clientAuthenticatorType\": \"client-secret\",
    \"redirectUris\": [\"*\"],
    \"webOrigins\": [\"*\"],
    \"publicClient\": false,
    \"protocol\": \"openid-connect\",
    \"directAccessGrantsEnabled\": true,
    \"serviceAccountsEnabled\": true,
    \"authorizationServicesEnabled\": false,
    \"defaultClientScopes\": [],
    \"optionalClientScopes\": []
  }"

# Get client UUID
CLIENT_UUID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r ".[] | select(.clientId==\"${CLIENT_ID}\") | .id")

# Add client scope to client as default
echo "Adding ${CLIENT_SCOPE} scope to client..."
curl -s -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients/${CLIENT_UUID}/default-client-scopes/${SCOPE_ID}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}"

# Get client secret
CLIENT_SECRET=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/clients/${CLIENT_UUID}/client-secret" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.value')

# Create test user
echo "Creating test user: ${TEST_USER}..."
curl -s -X POST "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${TEST_USER}\",
    \"email\": \"testuser@example.com\",
    \"enabled\": true,
    \"emailVerified\": true
  }"

# Get user ID
USER_ID=$(curl -s -X GET "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users?username=${TEST_USER}" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')

# Set user password
echo "Setting password for test user..."
curl -s -X PUT "${KEYCLOAK_URL}/admin/realms/${REALM_NAME}/users/${USER_ID}/reset-password" \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"password\",
    \"value\": \"${TEST_PASSWORD}\",
    \"temporary\": false
  }"

# Verify OIDC discovery endpoint
echo ""
echo "Verifying OIDC discovery endpoint..."
curl -s "${KEYCLOAK_URL}/realms/${REALM_NAME}/.well-known/openid-configuration" | jq -r '.issuer'

echo ""
echo "=========================================="
echo "Keycloak Configuration Complete!"
echo "=========================================="
echo "Realm: ${REALM_NAME}"
echo "Client ID: ${CLIENT_ID}"
echo "Client Secret: ${CLIENT_SECRET}"
echo "Client Scope: ${CLIENT_SCOPE}"
echo "Test User: ${TEST_USER}"
echo "Test Password: ${TEST_PASSWORD}"
echo "=========================================="
echo ""
echo "Save this client secret for API configuration!"
echo ""

# Save credentials to file
cat > keycloak-credentials.txt <<EOF
KEYCLOAK_URL=${KEYCLOAK_URL}
REALM_NAME=${REALM_NAME}
CLIENT_ID=${CLIENT_ID}
CLIENT_SECRET=${CLIENT_SECRET}
CLIENT_SCOPE=${CLIENT_SCOPE}
TEST_USER=${TEST_USER}
TEST_PASSWORD=${TEST_PASSWORD}
EOF

echo "Credentials saved to keycloak-credentials.txt"
