"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Checkbox } from "@/components/ui/checkbox"
import { createTodoAction, updateTodoAction } from "@/actions/todos"
import type { Todo } from "@/types"

interface TodoFormProps {
  todo?: Todo
  onClose: () => void
}

export function TodoForm({ todo, onClose }: TodoFormProps) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setLoading(true)
    setError(null)

    const formData = new FormData(e.currentTarget)
    const data = {
      title: formData.get("title") as string,
      description: formData.get("description") as string,
      isCompleted: formData.get("isCompleted") === "on",
    }

    try {
      const result = todo 
        ? await updateTodoAction(todo.id, data)
        : await createTodoAction(data)
      
      if (result.success) {
        onClose()
      } else {
        setError(result.error || 'An error occurred')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred')
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {error && (
        <div className="rounded-md bg-red-50 p-3 text-sm text-red-800">
          {error}
        </div>
      )}

      <div className="space-y-2">
        <Label htmlFor="title">Title</Label>
        <Input
          id="title"
          name="title"
          defaultValue={todo?.title}
          required
          placeholder="Enter todo title"
        />
      </div>

      <div className="space-y-2">
        <Label htmlFor="description">Description</Label>
        <Input
          id="description"
          name="description"
          defaultValue={todo?.description || ""}
          placeholder="Enter description (optional)"
        />
      </div>

      {todo && (
        <div className="flex items-center space-x-2">
          <Checkbox
            id="isCompleted"
            name="isCompleted"
            defaultChecked={todo.isCompleted}
          />
          <Label htmlFor="isCompleted">Completed</Label>
        </div>
      )}

      <div className="flex justify-end gap-2">
        <Button type="button" variant="outline" onClick={onClose}>
          Cancel
        </Button>
        <Button type="submit" disabled={loading}>
          {loading ? "Saving..." : todo ? "Update" : "Create"}
        </Button>
      </div>
    </form>
  )
}
