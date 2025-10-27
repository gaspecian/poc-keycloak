import { auth } from "@/auth"
import { getTodos } from "@/lib/api"
import { redirect } from "next/navigation"
import { Button } from "@/components/ui/button"
import { signOut } from "@/auth"
import { TodoList } from "@/components/todos/todo-list"

export default async function DashboardPage() {
  const session = await auth()
  
  if (!session) {
    redirect("/")
  }

  let todos = []
  let error = null

  try {
    todos = await getTodos()
  } catch (e) {
    error = e instanceof Error ? e.message : 'Failed to load todos'
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="border-b bg-white">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 items-center justify-between">
            <h1 className="text-xl font-bold">Todo App</h1>
            <div className="flex items-center gap-4">
              <span className="text-sm text-gray-600">{session.user?.name || session.user?.email}</span>
              <form
                action={async () => {
                  "use server"
                  await signOut({ redirectTo: "/" })
                }}
              >
                <Button variant="outline" type="submit">
                  Sign out
                </Button>
              </form>
            </div>
          </div>
        </div>
      </nav>

      <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
        {error ? (
          <div className="rounded-lg border border-red-200 bg-red-50 p-6 text-center">
            <h2 className="text-lg font-semibold text-red-900">Access Denied</h2>
            <p className="mt-2 text-red-700">{error}</p>
            <p className="mt-4 text-sm text-red-600">
              Please contact your administrator to request access.
            </p>
          </div>
        ) : (
          <TodoList initialTodos={todos} />
        )}
      </main>
    </div>
  )
}
