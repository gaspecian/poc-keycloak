import { auth } from "@/auth"
import { getTodos } from "@/lib/api"
import { redirect } from "next/navigation"
import { Button } from "@/components/ui/button"
import { signOut } from "@/auth"

export default async function DashboardPage() {
  const session = await auth()
  
  if (!session) {
    redirect("/")
  }

  const todos = await getTodos()

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
        <div className="mb-6 flex items-center justify-between">
          <h2 className="text-2xl font-bold">My Todos</h2>
          <Button>Add Todo</Button>
        </div>

        <div className="rounded-lg bg-white shadow">
          {todos.length === 0 ? (
            <div className="p-8 text-center text-gray-500">
              No todos yet. Create your first one!
            </div>
          ) : (
            <ul className="divide-y">
              {todos.map((todo) => (
                <li key={todo.id} className="p-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-medium">{todo.title}</h3>
                      {todo.description && (
                        <p className="text-sm text-gray-600">{todo.description}</p>
                      )}
                    </div>
                    <span className={`rounded-full px-3 py-1 text-xs ${
                      todo.isCompleted 
                        ? "bg-green-100 text-green-800" 
                        : "bg-yellow-100 text-yellow-800"
                    }`}>
                      {todo.isCompleted ? "Completed" : "Pending"}
                    </span>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      </main>
    </div>
  )
}
