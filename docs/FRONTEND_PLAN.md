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

### Phase 1: Project Setup
- [ ] Create Next.js 16 project with TypeScript
- [ ] Install dependencies:
  - [ ] next-auth@beta (v5)
  - [ ] shadcn/ui components
  - [ ] zod (validation)
- [ ] Configure Tailwind CSS
- [ ] Setup project structure

### Phase 2: Keycloak Configuration
- [ ] Create new client in Keycloak for frontend
  - [ ] Client ID: `todo-frontend-client`
  - [ ] Client Type: Public (SPA)
  - [ ] Valid redirect URIs: `http://localhost:3000/*`
  - [ ] Web origins: `http://localhost:3000`
  - [ ] Enable Standard Flow (Authorization Code)
- [ ] Configure client scopes (todo-backend)

### Phase 3: NextAuth.js v5 Setup
- [ ] Create `auth.ts` config file
- [ ] Configure Keycloak provider
- [ ] Setup session strategy (JWT)
- [ ] Configure callbacks for token handling
- [ ] Create auth middleware

### Phase 4: Layout & Navigation
- [ ] Create root layout with providers
- [ ] Implement navigation bar with shadcn components
- [ ] Add user menu with logout
- [ ] Create protected route wrapper

### Phase 5: Authentication Pages
- [ ] Login redirects to Keycloak (no custom login page)
- [ ] Callback page for OAuth redirect
- [ ] Unauthorized page
- [ ] Loading states

### Phase 6: Todo Management UI
- [ ] Dashboard page (list todos)
  - [ ] shadcn Table component
  - [ ] Filter/search functionality
- [ ] Create todo dialog/form
  - [ ] shadcn Dialog + Form components
  - [ ] Validation with zod
- [ ] Edit todo dialog
- [ ] Delete confirmation dialog

### Phase 7: API Integration
- [ ] Create API client with fetch
- [ ] Server Actions for mutations
- [ ] Add Bearer token to requests
- [ ] Error handling
- [ ] CRUD operations:
  - [ ] GET /api/todos
  - [ ] GET /api/todos/{id}
  - [ ] POST /api/todos
  - [ ] PUT /api/todos/{id}
  - [ ] DELETE /api/todos/{id}

### Phase 8: UI Components (shadcn)
- [ ] Button
- [ ] Input
- [ ] Label
- [ ] Card
- [ ] Dialog
- [ ] Table
- [ ] Form
- [ ] Checkbox
- [ ] Toast/Sonner
- [ ] Avatar
- [ ] DropdownMenu
- [ ] Badge

### Phase 9: Testing & Polish
- [ ] Test authentication flow
- [ ] Test CRUD operations
- [ ] Test token refresh
- [ ] Test logout
- [ ] Add loading skeletons
- [ ] Responsive design
- [ ] Accessibility checks

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
