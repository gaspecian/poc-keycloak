"use server"

import { revalidatePath } from "next/cache"
import { createTodo, updateTodo, deleteTodo } from "@/lib/api"
import type { CreateTodoDto, UpdateTodoDto } from "@/types"

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
