import { auth } from "@/auth"
import { NextResponse } from "next/server"
import type { NextRequest } from "next/server"

export async function middleware(request: NextRequest) {
  const session = await auth()
  
  // Allow public routes
  if (request.nextUrl.pathname === "/" || 
      request.nextUrl.pathname.startsWith("/api/auth")) {
    return NextResponse.next()
  }
  
  // Redirect to login if not authenticated
  if (!session) {
    return NextResponse.redirect(new URL("/", request.url))
  }
  
  // Check for app access role
  const token = session.accessToken
  if (token) {
    const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString())
    const roles = payload.roles || []
    
    if (!roles.includes('todo-app-access')) {
      return NextResponse.redirect(new URL("/access-denied", request.url))
    }
  }
  
  return NextResponse.next()
}

export const config = {
  matcher: ['/dashboard/:path*']
}
