"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { TodoForm } from "./todo-form"
import { DeleteDialog } from "./delete-dialog"
import { Pencil, Trash2 } from "lucide-react"
import type { Todo } from "@/types"

interface TodoListProps {
  initialTodos: Todo[]
}

export function TodoList({ initialTodos }: TodoListProps) {
  const [createOpen, setCreateOpen] = useState(false)
  const [editTodo, setEditTodo] = useState<Todo | null>(null)
  const [deleteTodo, setDeleteTodo] = useState<{ id: number; title: string } | null>(null)

  return (
    <>
      <div className="mb-6 flex items-center justify-between">
        <h2 className="text-2xl font-bold">My Todos</h2>
        <Button onClick={() => setCreateOpen(true)}>Add Todo</Button>
      </div>

      <div className="rounded-lg bg-white shadow">
        {initialTodos.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            No todos yet. Create your first one!
          </div>
        ) : (
          <ul className="divide-y">
            {initialTodos.map((todo) => (
              <li key={todo.id} className="p-4">
                <div className="flex items-center justify-between">
                  <div className="flex-1">
                    <h3 className="font-medium">{todo.title}</h3>
                    {todo.description && (
                      <p className="text-sm text-gray-600">{todo.description}</p>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={`rounded-full px-3 py-1 text-xs ${
                      todo.isCompleted 
                        ? "bg-green-100 text-green-800" 
                        : "bg-yellow-100 text-yellow-800"
                    }`}>
                      {todo.isCompleted ? "Completed" : "Pending"}
                    </span>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => setEditTodo(todo)}
                    >
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => setDeleteTodo({ id: todo.id, title: todo.title })}
                    >
                      <Trash2 className="h-4 w-4 text-red-600" />
                    </Button>
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Create Dialog */}
      <Dialog open={createOpen} onOpenChange={setCreateOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Create Todo</DialogTitle>
          </DialogHeader>
          <TodoForm onClose={() => setCreateOpen(false)} />
        </DialogContent>
      </Dialog>

      {/* Edit Dialog */}
      <Dialog open={!!editTodo} onOpenChange={(open) => !open && setEditTodo(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Todo</DialogTitle>
          </DialogHeader>
          {editTodo && (
            <TodoForm todo={editTodo} onClose={() => setEditTodo(null)} />
          )}
        </DialogContent>
      </Dialog>

      {/* Delete Dialog */}
      {deleteTodo && (
        <DeleteDialog
          todoId={deleteTodo.id}
          todoTitle={deleteTodo.title}
          open={!!deleteTodo}
          onOpenChange={(open) => !open && setDeleteTodo(null)}
        />
      )}
    </>
  )
}
