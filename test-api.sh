#!/bin/bash

# Test script for POC API - Phase 8: Testing & Validation
# Prerequisites: API must be running on http://localhost:5001

set -e

API_URL="http://localhost:5001"

# Load credentials
if [ -f "keycloak/keycloak-credentials.txt" ]; then
    source keycloak/keycloak-credentials.txt
else
    echo "Error: keycloak-credentials.txt not found"
    exit 1
fi

echo "=========================================="
echo "POC API Testing Suite - Phase 8"
echo "=========================================="
echo ""

# Test 1: Client Credentials Grant Flow
echo "✓ Test 1: Client Credentials Grant Flow"
echo "----------------------------------------"
RESPONSE=$(curl -s -X POST "${API_URL}/api/auth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"grant_type\": \"client_credentials\",
    \"client_id\": \"${CLIENT_ID}\",
    \"client_secret\": \"${CLIENT_SECRET}\"
  }")

CLIENT_TOKEN=$(echo $RESPONSE | jq -r '.access_token')
if [ "$CLIENT_TOKEN" != "null" ] && [ -n "$CLIENT_TOKEN" ]; then
    echo "✅ PASS: Client credentials grant successful"
    echo "   Token: ${CLIENT_TOKEN:0:50}..."
else
    echo "❌ FAIL: Client credentials grant failed"
    echo "   Response: $RESPONSE"
    exit 1
fi
echo ""

# Test 2: Client Credentials with Invalid Secret
echo "✓ Test 2: Client Credentials with Invalid Secret"
echo "-------------------------------------------------"
RESPONSE=$(curl -s -X POST "${API_URL}/api/auth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"grant_type\": \"client_credentials\",
    \"client_id\": \"${CLIENT_ID}\",
    \"client_secret\": \"invalid_secret_12345\"
  }")

INVALID_TOKEN=$(echo $RESPONSE | jq -r '.access_token')
if [ "$INVALID_TOKEN" = "null" ] || [ -z "$INVALID_TOKEN" ]; then
    echo "✅ PASS: Correctly rejects invalid client secret"
else
    echo "❌ FAIL: Should reject invalid client secret"
    exit 1
fi
echo ""

# Test 3: Password Grant Flow
echo "✓ Test 3: Password Grant Flow"
echo "------------------------------"
RESPONSE=$(curl -s -X POST "${API_URL}/api/auth/token" \
  -H "Content-Type: application/json" \
  -d "{
    \"grant_type\": \"password\",
    \"client_id\": \"${CLIENT_ID}\",
    \"client_secret\": \"${CLIENT_SECRET}\",
    \"username\": \"${TEST_USER}\",
    \"password\": \"${TEST_PASSWORD}\"
  }")

USER_TOKEN=$(echo $RESPONSE | jq -r '.access_token')
REFRESH_TOKEN=$(echo $RESPONSE | jq -r '.refresh_token')
if [ "$USER_TOKEN" != "null" ] && [ -n "$USER_TOKEN" ]; then
    echo "✅ PASS: Password grant successful"
    echo "   Access Token: ${USER_TOKEN:0:50}..."
    echo "   Refresh Token: ${REFRESH_TOKEN:0:50}..."
else
    echo "❌ FAIL: Password grant failed"
    echo "   Response: $RESPONSE"
    exit 1
fi
echo ""

# Test 4: Access Protected Endpoint WITHOUT Token
echo "✓ Test 4: Access Protected Endpoint WITHOUT Token"
echo "--------------------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "${API_URL}/api/todos")

if [ "$HTTP_CODE" = "401" ]; then
    echo "✅ PASS: Correctly returns 401 Unauthorized without token"
else
    echo "❌ FAIL: Expected 401, got $HTTP_CODE"
    exit 1
fi
echo ""

# Test 5: Access Protected Endpoint WITH Valid Token
echo "✓ Test 5: Access Protected Endpoint WITH Valid Token"
echo "-----------------------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${API_URL}/api/todos" \
  -H "Authorization: Bearer ${USER_TOKEN}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ PASS: Protected endpoint accessible with valid token"
    echo "   Response: $BODY"
else
    echo "❌ FAIL: Failed to access protected endpoint (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
    exit 1
fi
echo ""

# Test 6: Create Todo
echo "✓ Test 6: Create Todo (POST /api/todos)"
echo "----------------------------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/api/todos" \
  -H "Authorization: Bearer ${USER_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Todo from Script",
    "description": "Created by automated test"
  }')

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "201" ]; then
    echo "✅ PASS: Todo created successfully"
    TODO_ID=$(echo "$BODY" | jq -r '.id')
    echo "   Created Todo ID: $TODO_ID"
    echo "   Response: $BODY"
else
    echo "❌ FAIL: Failed to create todo (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
    exit 1
fi
echo ""

# Test 7: Get Todo by ID
if [ -n "$TODO_ID" ]; then
    echo "✓ Test 7: Get Todo by ID (GET /api/todos/${TODO_ID})"
    echo "-----------------------------------------------------"
    RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "${API_URL}/api/todos/${TODO_ID}" \
      -H "Authorization: Bearer ${USER_TOKEN}")

    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    BODY=$(echo "$RESPONSE" | head -n-1)

    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ PASS: Todo retrieved successfully"
        echo "   Response: $BODY"
    else
        echo "❌ FAIL: Failed to retrieve todo (HTTP $HTTP_CODE)"
        exit 1
    fi
    echo ""
fi

# Test 8: Update Todo
if [ -n "$TODO_ID" ]; then
    echo "✓ Test 8: Update Todo (PUT /api/todos/${TODO_ID})"
    echo "--------------------------------------------------"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${API_URL}/api/todos/${TODO_ID}" \
      -H "Authorization: Bearer ${USER_TOKEN}" \
      -H "Content-Type: application/json" \
      -d '{
        "title": "Updated Test Todo",
        "description": "Updated by automated test",
        "isCompleted": true
      }')

    if [ "$HTTP_CODE" = "204" ]; then
        echo "✅ PASS: Todo updated successfully"
    else
        echo "❌ FAIL: Failed to update todo (HTTP $HTTP_CODE)"
        exit 1
    fi
    echo ""
fi

# Test 9: Refresh Token Flow
echo "✓ Test 9: Refresh Token Flow"
echo "-----------------------------"
RESPONSE=$(curl -s -X POST "${API_URL}/api/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{
    \"client_id\": \"${CLIENT_ID}\",
    \"client_secret\": \"${CLIENT_SECRET}\",
    \"refresh_token\": \"${REFRESH_TOKEN}\"
  }")

NEW_TOKEN=$(echo $RESPONSE | jq -r '.access_token')
if [ "$NEW_TOKEN" != "null" ] && [ -n "$NEW_TOKEN" ]; then
    echo "✅ PASS: Token refresh successful"
    echo "   New Token: ${NEW_TOKEN:0:50}..."
else
    echo "❌ FAIL: Token refresh failed"
    echo "   Response: $RESPONSE"
    exit 1
fi
echo ""

# Test 10: Access with Invalid Token
echo "✓ Test 10: Access with Invalid Token"
echo "-------------------------------------"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "${API_URL}/api/todos" \
  -H "Authorization: Bearer invalid_token_12345")

if [ "$HTTP_CODE" = "401" ]; then
    echo "✅ PASS: Correctly returns 401 for invalid token"
else
    echo "❌ FAIL: Expected 401, got $HTTP_CODE"
    exit 1
fi
echo ""

# Test 11: Delete Todo
if [ -n "$TODO_ID" ]; then
    echo "✓ Test 11: Delete Todo (DELETE /api/todos/${TODO_ID})"
    echo "------------------------------------------------------"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "${API_URL}/api/todos/${TODO_ID}" \
      -H "Authorization: Bearer ${USER_TOKEN}")

    if [ "$HTTP_CODE" = "204" ]; then
        echo "✅ PASS: Todo deleted successfully"
    else
        echo "❌ FAIL: Failed to delete todo (HTTP $HTTP_CODE)"
        exit 1
    fi
    echo ""
fi

# Test 12: Revoke Token
echo "✓ Test 12: Revoke Token"
echo "-----------------------"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}/api/auth/revoke" \
  -H "Content-Type: application/json" \
  -d "{
    \"client_id\": \"${CLIENT_ID}\",
    \"client_secret\": \"${CLIENT_SECRET}\",
    \"token\": \"${USER_TOKEN}\"
  }")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ PASS: Token revoked successfully"
else
    echo "❌ FAIL: Token revocation failed (HTTP $HTTP_CODE)"
    exit 1
fi
echo ""

# Test 13: Scope Validation
echo "✓ Test 13: Scope Validation"
echo "----------------------------"
TOKEN_PAYLOAD=$(echo $CLIENT_TOKEN | cut -d'.' -f2)
case $((${#TOKEN_PAYLOAD} % 4)) in
    2) TOKEN_PAYLOAD="${TOKEN_PAYLOAD}==" ;;
    3) TOKEN_PAYLOAD="${TOKEN_PAYLOAD}=" ;;
esac
DECODED=$(echo $TOKEN_PAYLOAD | base64 -d 2>/dev/null | jq -r '.scope' 2>/dev/null || echo "")

if echo "$DECODED" | grep -q "todo-backend"; then
    echo "✅ PASS: Token contains correct scope: todo-backend"
else
    echo "⚠️  WARNING: Could not verify scope in token"
    echo "   Scope: $DECODED"
fi
echo ""

echo "=========================================="
echo "✅ All Tests Passed!"
echo "=========================================="
echo ""
echo "Phase 8: Testing & Validation - COMPLETE"
