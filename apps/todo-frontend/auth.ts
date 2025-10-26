import NextAuth from "next-auth"
import Keycloak from "next-auth/providers/keycloak"

export const { handlers, signIn, signOut, auth } = NextAuth({
  providers: [
    Keycloak({
      clientId: process.env.AUTH_KEYCLOAK_ID!,
      issuer: process.env.AUTH_KEYCLOAK_ISSUER!,
    })
  ],
  callbacks: {
    async jwt({ token, account }) {
      if (account) {
        token.accessToken = account.access_token
        token.refreshToken = account.refresh_token
        token.idToken = account.id_token
      }
      return token
    },
    async session({ session, token }) {
      session.accessToken = token.accessToken as string
      session.idToken = token.idToken as string
      return session
    }
  },
  events: {
    async signOut({ token }) {
      if (token?.idToken) {
        const issuerUrl = process.env.AUTH_KEYCLOAK_ISSUER
        const logoutUrl = `${issuerUrl}/protocol/openid-connect/logout`
        const params = new URLSearchParams({
          id_token_hint: token.idToken as string,
          post_logout_redirect_uri: process.env.AUTH_URL || "http://localhost:3000",
        })
        
        try {
          await fetch(`${logoutUrl}?${params.toString()}`, { method: "GET" })
        } catch (error) {
          console.error("Error during Keycloak logout:", error)
        }
      }
    }
  }
})
