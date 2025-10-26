export interface Todo {
  id: number
  title: string
  description: string | null
  isCompleted: boolean
  createdAt: string
}

export interface CreateTodoDto {
  title: string
  description?: string
}

export interface UpdateTodoDto {
  title: string
  description?: string
  isCompleted: boolean
}
