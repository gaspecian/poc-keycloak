import { auth } from "@/auth"
import { redirect } from "next/navigation"
import { Button } from "@/components/ui/button"
import { signIn } from "@/auth"

export default async function Home() {
  const session = await auth()
  
  if (session) {
    redirect("/dashboard")
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="w-full max-w-md space-y-8 rounded-lg bg-white p-8 shadow-lg">
        <div className="text-center">
          <h1 className="text-3xl font-bold">Todo App</h1>
          <p className="mt-2 text-gray-600">Keycloak Authentication POC</p>
        </div>
        
        <form
          action={async () => {
            "use server"
            await signIn("keycloak", { redirectTo: "/dashboard" })
          }}
        >
          <Button type="submit" className="w-full">
            Sign in with Keycloak
          </Button>
        </form>
      </div>
    </div>
  )
}
