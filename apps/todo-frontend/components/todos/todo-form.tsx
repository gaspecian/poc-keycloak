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

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setLoading(true)

    const formData = new FormData(e.currentTarget)
    const data = {
      title: formData.get("title") as string,
      description: formData.get("description") as string,
      isCompleted: formData.get("isCompleted") === "on",
    }

    try {
      if (todo) {
        await updateTodoAction(todo.id, data)
      } else {
        await createTodoAction(data)
      }
      onClose()
    } catch (error) {
      console.error("Failed to save todo:", error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
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
