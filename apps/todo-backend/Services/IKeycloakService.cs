namespace TodoBackend.Services;

public interface IKeycloakService
{
    Task<TokenResponse?> GetTokenAsync(TokenRequest request);
    Task<TokenResponse?> RefreshTokenAsync(RefreshTokenRequest request);
    Task<bool> RevokeTokenAsync(RevokeTokenRequest request);
}

public record TokenRequest(string GrantType, string ClientId, string ClientSecret, string? Username = null, string? Password = null);
public record RefreshTokenRequest(string ClientId, string ClientSecret, string RefreshToken);
public record RevokeTokenRequest(string ClientId, string ClientSecret, string Token);
public record TokenResponse(string AccessToken, string TokenType, int ExpiresIn, string? RefreshToken, string? Scope);
