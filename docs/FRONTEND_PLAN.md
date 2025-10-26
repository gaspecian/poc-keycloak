# Frontend Implementation Plan

## Overview
Next.js frontend application that consumes the Todo Backend API with Keycloak authentication using OpenID Connect.

## Tech Stack
- **Framework**: Next.js 16.0.0 (App Router)
- **UI Library**: shadcn/ui
- **Authentication**: NextAuth.js v5 with Keycloak provider
- **Styling**: Tailwind CSS
- **HTTP Client**: Fetch API
- **State Management**: React hooks / Server Actions

## Architecture

```
┌─────────────────┐
│   Next.js App   │
│   (Port 3000)   │
└────────┬────────┘
         │
         ├──────────────┐
         │              │
         ▼              ▼
┌─────────────┐  ┌──────────────┐
│  Keycloak   │  │  Todo API    │
│  (OIDC)     │  │  (Port 5001) │
│  Port 8080  │  │              │
└─────────────┘  └──────────────┘
```

## Implementation Phases

### Phase 1: Project Setup ✅
- [x] Create Next.js 16 project with TypeScript
- [x] Install dependencies:
  - [x] next-auth@beta (v5)
  - [x] shadcn/ui components
  - [x] zod (validation)
- [x] Configure Tailwind CSS
- [x] Setup project structure

### Phase 2: Keycloak Configuration ✅
- [x] Create new client in Keycloak for frontend
  - [x] Client ID: `todo-frontend-client`
  - [x] Client Type: Public (SPA)
  - [x] Valid redirect URIs: `http://localhost:3000/*`
  - [x] Web origins: `http://localhost:3000`
  - [x] Enable Standard Flow (Authorization Code)
- [x] Configure client scopes (todo-backend)

### Phase 3: NextAuth.js v5 Setup ✅
- [x] Create `auth.ts` config file
- [x] Configure Keycloak provider
- [x] Setup session strategy (JWT)
- [x] Configure callbacks for token handling
- [x] Create auth middleware

### Phase 4: Layout & Navigation ✅
- [x] Create root layout with providers
- [x] Implement navigation bar with shadcn components
- [x] Add user menu with logout
- [x] Create protected route wrapper

### Phase 5: Authentication Pages ✅
- [x] Login redirects to Keycloak (no custom login page)
- [x] Callback page for OAuth redirect
- [x] Unauthorized page
- [x] Loading states

### Phase 6: Todo Management UI ✅
- [x] Dashboard page (list todos)
  - [x] shadcn components
  - [x] Todo list display
- [x] Create todo dialog/form
  - [x] shadcn Dialog + Form components
  - [x] Validation
- [x] Edit todo dialog
- [x] Delete confirmation dialog

### Phase 7: API Integration ✅
- [x] Create API client with fetch
- [x] Server Actions for mutations
- [x] Add Bearer token to requests
- [x] Error handling
- [x] CRUD operations:
  - [x] GET /api/todos
  - [x] GET /api/todos/{id}
  - [x] POST /api/todos
  - [x] PUT /api/todos/{id}
  - [x] DELETE /api/todos/{id}

### Phase 8: UI Components (shadcn) ✅
- [x] Button
- [x] Input
- [x] Label
- [x] Dialog
- [x] Checkbox
- [x] Icons (lucide-react)

### Phase 9: Testing & Polish ✅
- [x] Test authentication flow
- [x] Test CRUD operations
- [x] Test logout
- [x] Responsive design
- [x] Accessibility checks

## Project Structure

```
apps/todo-frontend/
├── src/
│   ├── app/
│   │   ├── (auth)/
│   │   │   ├── login/
│   │   │   │   └── page.tsx
│   │   │   └── unauthorized/
│   │   │       └── page.tsx
│   │   ├── (dashboard)/
│   │   │   ├── layout.tsx
│   │   │   └── page.tsx (todos list)
│   │   ├── api/
│   │   │   └── auth/
│   │   │       └── [...nextauth]/
│   │   │           └── route.ts
│   │   ├── layout.tsx
│   │   └── page.tsx
│   ├── components/
│   │   ├── ui/ (shadcn components)
│   │   ├── todos/
│   │   │   ├── todo-list.tsx
│   │   │   ├── todo-form.tsx
│   │   │   └── delete-dialog.tsx
│   │   └── layout/
│   │       ├── navbar.tsx
│   │       └── user-menu.tsx
│   ├── lib/
│   │   ├── api.ts
│   │   ├── auth.ts (NextAuth config)
│   │   └── utils.ts
│   ├── types/
│   │   └── todo.ts
│   └── actions/
│       └── todos.ts (Server Actions)
├── middleware.ts
├── auth.config.ts
├── .env.local
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

## Environment Variables

```env
# Keycloak
AUTH_KEYCLOAK_ID=todo-frontend-client
AUTH_KEYCLOAK_ISSUER=http://localhost:8080/realms/poc-realm

# NextAuth
AUTH_SECRET=<generate-random-secret>
AUTH_URL=http://localhost:3000

# API
NEXT_PUBLIC_API_URL=http://localhost:5001
```

## Dependencies

```json
{
  "dependencies": {
    "next": "16.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "next-auth": "^5.0.0-beta.25",
    "zod": "^3.23.0",
    "tailwindcss": "^3.4.0",
    "@radix-ui/react-dialog": "^1.1.0",
    "@radix-ui/react-dropdown-menu": "^2.1.0",
    "@radix-ui/react-label": "^2.1.0",
    "@radix-ui/react-slot": "^1.1.0",
    "class-variance-authority": "^0.7.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.3.0",
    "lucide-react": "^0.378.0",
    "sonner": "^1.5.0"
  },
  "devDependencies": {
    "@types/node": "^22",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "typescript": "^5",
    "eslint": "^9",
    "eslint-config-next": "16.0.0"
  }
}
```

## Keycloak Client Configuration

### Frontend Client Settings
- **Client ID**: `todo-frontend-client`
- **Client Protocol**: openid-connect
- **Access Type**: public
- **Standard Flow Enabled**: ON
- **Direct Access Grants**: OFF
- **Valid Redirect URIs**: 
  - `http://localhost:3000/*`
  - `http://localhost:3000/api/auth/callback/keycloak`
- **Web Origins**: `http://localhost:3000`
- **Client Scopes**: 
  - Default: `todo-backend`, `profile`, `email`

## NextAuth v5 Configuration

```typescript
// auth.ts
import NextAuth from "next-auth"
import Keycloak from "next-auth/providers/keycloak"

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    Keycloak({
      clientId: process.env.AUTH_KEYCLOAK_ID,
      issuer: process.env.AUTH_KEYCLOAK_ISSUER,
    })
  ],
  callbacks: {
    async jwt({ token, account }) {
      if (account) {
        token.accessToken = account.access_token
      }
      return token
    },
    async session({ session, token }) {
      session.accessToken = token.accessToken
      return session
    }
  }
})
```

## API Integration

```typescript
// lib/api.ts
import { auth } from "@/lib/auth"

export async function apiClient(endpoint: string, options?: RequestInit) {
  const session = await auth()
  
  const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}${endpoint}`, {
    ...options,
    headers: {
      ...options?.headers,
      Authorization: `Bearer ${session?.accessToken}`,
      'Content-Type': 'application/json',
    },
  })
  
  if (!response.ok) throw new Error('API request failed')
  return response.json()
}
```

## Next Steps

1. Create Keycloak frontend client configuration script
2. Initialize Next.js 16 project
3. Install dependencies
4. Configure NextAuth v5
5. Setup shadcn/ui
6. Build authentication flow
7. Implement todo management UI
8. Test end-to-end
