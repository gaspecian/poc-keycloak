import { auth, signOut } from "@/auth"
import { Button } from "@/components/ui/button"
import { ShieldX } from "lucide-react"

export default async function AccessDeniedPage() {
  const session = await auth()

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="w-full max-w-md rounded-lg bg-white p-8 shadow-lg">
        <div className="flex flex-col items-center text-center">
          <div className="rounded-full bg-red-100 p-3">
            <ShieldX className="h-12 w-12 text-red-600" />
          </div>
          
          <h1 className="mt-4 text-2xl font-bold text-gray-900">
            Access Denied
          </h1>
          
          <p className="mt-2 text-gray-600">
            You do not have permission to access the Todo Application.
          </p>
          
          {session?.user && (
            <p className="mt-4 text-sm text-gray-500">
              Logged in as: <span className="font-medium">{session.user.email || session.user.name}</span>
            </p>
          )}
          
          <div className="mt-6 space-y-3">
            <p className="text-sm text-gray-600">
              Please contact your administrator to request access.
            </p>
            
            <form
              action={async () => {
                "use server"
                await signOut({ redirectTo: "/" })
              }}
            >
              <Button type="submit" className="w-full">
                Sign Out
              </Button>
            </form>
          </div>
        </div>
      </div>
    </div>
  )
}
