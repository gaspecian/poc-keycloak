"use server"

import { revalidatePath } from "next/cache"
import { createTodo, updateTodo, deleteTodo } from "@/lib/api"
import type { CreateTodoDto, UpdateTodoDto } from "@/types"

export async function createTodoAction(data: CreateTodoDto) {
  await createTodo(data)
  revalidatePath("/dashboard")
}

export async function updateTodoAction(id: number, data: UpdateTodoDto) {
  await updateTodo(id, data)
  revalidatePath("/dashboard")
}

export async function deleteTodoAction(id: number) {
  await deleteTodo(id)
  revalidatePath("/dashboard")
}
