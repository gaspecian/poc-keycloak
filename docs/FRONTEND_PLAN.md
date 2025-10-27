# Frontend Implementation Guide

Complete guide for the Next.js 16 frontend with Keycloak authentication.

## Technology Stack

- **Framework:** Next.js 16 (App Router)
- **Authentication:** NextAuth.js v5
- **UI Library:** shadcn/ui + Tailwind CSS
- **Language:** TypeScript
- **State Management:** React Server Components + Server Actions
- **HTTP Client:** Native Fetch API

## Project Structure

```
apps/todo-frontend/
├── app/
│   ├── page.tsx                    # Landing/login page
│   ├── dashboard/
│   │   └── page.tsx                # Main dashboard (protected)
│   ├── access-denied/
│   │   └── page.tsx                # Access denied page
│   └── api/
│       └── auth/
│           └── [...nextauth]/      # NextAuth.js routes
├── actions/
│   └── todos.ts                    # Server actions for CRUD
├── components/
│   ├── ui/                         # shadcn/ui components
│   └── todos/
│       ├── todo-list.tsx           # Todo list component
│       ├── todo-form.tsx           # Create/edit form
│       └── delete-dialog.tsx       # Delete confirmation
├── lib/
│   └── api.ts                      # API client with auth
├── types/
│   └── index.ts                    # TypeScript types
├── auth.ts                         # NextAuth.js configuration
├── middleware.ts                   # Route protection
└── .env.local                      # Environment variables
```

## Authentication Setup

### NextAuth.js Configuration

**File:** `auth.ts`

```typescript
import NextAuth from "next-auth"
import Keycloak from "next-auth/providers/keycloak"

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    Keycloak({
      clientId: process.env.AUTH_KEYCLOAK_ID!,
      clientSecret: process.env.AUTH_KEYCLOAK_SECRET!,
      issuer: process.env.AUTH_KEYCLOAK_ISSUER!,
    }),
  ],
  callbacks: {
    async jwt({ token, account }) {
      if (account) {
        token.accessToken = account.access_token
        token.refreshToken = account.refresh_token
        token.expiresAt = account.expires_at
      }
      return token
    },
    async session({ session, token }) {
      session.accessToken = token.accessToken as string
      session.error = token.error as string | undefined
      return session
    },
  },
  events: {
    async signOut({ token }) {
      // Logout from Keycloak
      if (token?.accessToken) {
        const issuerUrl = process.env.AUTH_KEYCLOAK_ISSUER!
        const logoutUrl = `${issuerUrl}/protocol/openid-connect/logout`
        await fetch(logoutUrl, {
          method: "POST",
          headers: { "Content-Type": "application/x-www-form-urlencoded" },
          body: new URLSearchParams({
            client_id: process.env.AUTH_KEYCLOAK_ID!,
            refresh_token: token.refreshToken as string,
          }),
        })
      }
    },
  },
})
```

### Environment Variables

**File:** `.env.local`

```env
AUTH_SECRET="generate-random-secret-here"
AUTH_KEYCLOAK_ID="todo-frontend-client"
AUTH_KEYCLOAK_SECRET=""
AUTH_KEYCLOAK_ISSUER="http://localhost:8080/realms/poc-realm"
NEXT_PUBLIC_API_URL="http://localhost:5001"
```

## Route Protection

### Middleware

**File:** `middleware.ts`

```typescript
import { auth } from "@/auth"
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export async function middleware(request: NextRequest) {
  const session = await auth()
  
  // Allow public routes
  if (request.nextUrl.pathname === "/" || 
      request.nextUrl.pathname.startsWith("/api/auth")) {
    return NextResponse.next()
  }
  
  // Redirect to login if not authenticated
  if (!session) {
    return NextResponse.redirect(new URL("/", request.url))
  }
  
  // Check for app access role
  const token = session.accessToken
  if (token) {
    const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString())
    const roles = payload.roles || []
    
    if (!roles.includes('todo-app-access')) {
      return NextResponse.redirect(new URL("/access-denied", request.url))
    }
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*']
}
```

## API Integration

### API Client

**File:** `lib/api.ts`

```typescript
import { auth } from "@/auth"

const API_URL = process.env.NEXT_PUBLIC_API_URL

async function apiClient(endpoint: string, options?: RequestInit) {
  const session = await auth()
  
  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      ...options?.headers,
      Authorization: `Bearer ${session?.accessToken}`,
      'Content-Type': 'application/json',
    },
  })
  
  if (!response.ok) {
    if (response.status === 403) {
      throw new Error('You do not have permission to perform this action')
    }
    if (response.status === 401) {
      throw new Error('Your session has expired. Please login again')
    }
    throw new Error(`API error: ${response.statusText}`)
  }
  
  if (response.status === 204) {
    return null
  }
  
  return response.json()
}

export async function getTodos() {
  return apiClient('/api/todos')
}

export async function createTodo(data: CreateTodoDto) {
  return apiClient('/api/todos', {
    method: 'POST',
    body: JSON.stringify(data),
  })
}

export async function updateTodo(id: number, data: UpdateTodoDto) {
  return apiClient(`/api/todos/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  })
}

export async function deleteTodo(id: number) {
  return apiClient(`/api/todos/${id}`, {
    method: 'DELETE',
  })
}
```

## Server Actions

**File:** `actions/todos.ts`

```typescript
"use server"

import { revalidatePath } from "next/cache"
import { createTodo, updateTodo, deleteTodo } from "@/lib/api"

export async function createTodoAction(data: CreateTodoDto) {
  try {
    await createTodo(data)
    revalidatePath("/dashboard")
    return { success: true }
  } catch (error) {
    return { 
      success: false, 
      error: error instanceof Error ? error.message : 'Failed to create todo' 
    }
  }
}

export async function updateTodoAction(id: number, data: UpdateTodoDto) {
  try {
    await updateTodo(id, data)
    revalidatePath("/dashboard")
    return { success: true }
  } catch (error) {
    return { 
      success: false, 
      error: error instanceof Error ? error.message : 'Failed to update todo' 
    }
  }
}

export async function deleteTodoAction(id: number) {
  try {
    await deleteTodo(id)
    revalidatePath("/dashboard")
    return { success: true }
  } catch (error) {
    return { 
      success: false, 
      error: error instanceof Error ? error.message : 'Failed to delete todo' 
    }
  }
}
```

## UI Components

### Landing Page

**File:** `app/page.tsx`

- Shows "Sign in with Keycloak" button
- Redirects to dashboard if already authenticated
- Clean, centered layout

### Dashboard Page

**File:** `app/dashboard/page.tsx`

- Server component that fetches todos
- Shows navigation with user info and logout
- Displays TodoList component
- Error handling for authorization failures

### Todo List Component

**File:** `components/todos/todo-list.tsx`

- Client component for interactivity
- Shows list of todos with status
- Create, edit, delete actions
- Optimistic updates
- Error messages for failed operations

### Todo Form

**File:** `components/todos/todo-form.tsx`

- Modal form for create/edit
- Form validation
- Loading states
- Error display

### Delete Dialog

**File:** `components/todos/delete-dialog.tsx`

- Confirmation dialog
- Shows todo title
- Loading state during deletion
- Error handling

### Access Denied Page

**File:** `app/access-denied/page.tsx`

- User-friendly error message
- Shows logged-in user
- Sign out button
- Instructions to contact admin

## Styling

### Tailwind Configuration

```javascript
// tailwind.config.js
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Custom colors from shadcn/ui
      },
    },
  },
  plugins: [],
}
```

### shadcn/ui Components Used

- Button
- Input
- Label
- Checkbox
- Dialog
- Card

## Error Handling

### API Errors

```typescript
// 403 Forbidden
"You do not have permission to perform this action"

// 401 Unauthorized
"Your session has expired. Please login again"

// Network errors
"Failed to connect to server"
```

### Display Errors

1. **Page-level errors:** Red banner at top
2. **Form errors:** Inline below form
3. **Toast notifications:** For success messages

## State Management

### Server Components (Default)

- Fetch data on server
- Pass as props to client components
- No client-side state needed

### Client Components (When Needed)

- Form state (controlled inputs)
- Modal open/close state
- Loading states
- Optimistic updates

### Server Actions

- Handle mutations
- Revalidate cache
- Return success/error objects

## Performance Optimizations

### 1. Server Components

- Reduce JavaScript bundle size
- Faster initial page load
- Better SEO

### 2. Streaming

```typescript
// Use Suspense for loading states
<Suspense fallback={<Loading />}>
  <TodoList />
</Suspense>
```

### 3. Caching

- Next.js automatically caches fetch requests
- Use `revalidatePath` to invalidate cache
- Configure cache duration per request

### 4. Code Splitting

- Automatic with Next.js App Router
- Dynamic imports for heavy components

## Testing Strategy

### Unit Tests

```typescript
// Test API client
describe('apiClient', () => {
  it('should include auth token', async () => {
    // Mock auth()
    // Call apiClient
    // Verify Authorization header
  })
})
```

### Integration Tests

```typescript
// Test server actions
describe('createTodoAction', () => {
  it('should create todo and revalidate', async () => {
    // Mock API
    // Call action
    // Verify revalidatePath called
  })
})
```

### E2E Tests (Playwright)

```typescript
test('user can create todo', async ({ page }) => {
  await page.goto('/')
  await page.click('text=Sign in')
  // Login flow
  await page.fill('[name=title]', 'Test Todo')
  await page.click('text=Create')
  await expect(page.locator('text=Test Todo')).toBeVisible()
})
```

## Deployment

### Build

```bash
npm run build
```

### Environment Variables (Production)

```env
AUTH_SECRET="production-secret"
AUTH_KEYCLOAK_ID="todo-frontend-client"
AUTH_KEYCLOAK_SECRET=""
AUTH_KEYCLOAK_ISSUER="https://keycloak.yourdomain.com/realms/poc-realm"
NEXT_PUBLIC_API_URL="https://api.yourdomain.com"
```

### Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

### Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

## Best Practices

1. **Always use Server Components by default**
   - Only use "use client" when needed

2. **Handle errors gracefully**
   - Show user-friendly messages
   - Log errors for debugging

3. **Validate on both client and server**
   - Client: Better UX
   - Server: Security

4. **Use TypeScript strictly**
   - No `any` types
   - Define all interfaces

5. **Keep components small**
   - Single responsibility
   - Easy to test

6. **Use semantic HTML**
   - Accessibility
   - SEO

7. **Optimize images**
   - Use Next.js Image component
   - Lazy loading

8. **Monitor performance**
   - Core Web Vitals
   - Lighthouse scores
