import { auth } from "@/auth"
import type { Todo, CreateTodoDto, UpdateTodoDto } from "@/types"

const API_URL = process.env.NEXT_PUBLIC_API_URL

async function apiClient(endpoint: string, options?: RequestInit) {
  const session = await auth()
  
  // Decode token to check roles
  if (session?.accessToken) {
    const payload = JSON.parse(Buffer.from(session.accessToken.split('.')[1], 'base64').toString())
    console.log('Token roles:', payload.roles || 'NO ROLES IN TOKEN')
  }
  
  console.log('API Client Debug:', {
    endpoint,
    hasSession: !!session,
    hasAccessToken: !!session?.accessToken,
    accessToken: session?.accessToken?.substring(0, 50) + '...'
  })
  
  const response = await fetch(`${API_URL}${endpoint}`, {
    ...options,
    headers: {
      ...options?.headers,
      Authorization: `Bearer ${session?.accessToken}`,
      'Content-Type': 'application/json',
    },
  })
  
  console.log('API Response:', {
    status: response.status,
    statusText: response.statusText,
    ok: response.ok
  })
  
  if (!response.ok) {
    throw new Error(`API error: ${response.statusText}`)
  }
  
  if (response.status === 204) {
    return null
  }
  
  return response.json()
}

export async function getTodos(): Promise<Todo[]> {
  return apiClient('/api/todos')
}

export async function getTodo(id: number): Promise<Todo> {
  return apiClient(`/api/todos/${id}`)
}

export async function createTodo(data: CreateTodoDto): Promise<Todo> {
  return apiClient('/api/todos', {
    method: 'POST',
    body: JSON.stringify(data),
  })
}

export async function updateTodo(id: number, data: UpdateTodoDto): Promise<void> {
  return apiClient(`/api/todos/${id}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  })
}

export async function deleteTodo(id: number): Promise<void> {
  return apiClient(`/api/todos/${id}`, {
    method: 'DELETE',
  })
}
