using System.Text.Json;
using System.Text.Json.Serialization;

namespace TodoBackend.Services;

public class KeycloakService : IKeycloakService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;

    public KeycloakService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _configuration = configuration;
    }

    public async Task<TokenResponse?> GetTokenAsync(TokenRequest request)
    {
        var tokenUrl = _configuration["Keycloak:TokenUrl"]!;
        var scope = _configuration["Keycloak:Scope"]!;

        var parameters = new Dictionary<string, string>
        {
            ["grant_type"] = request.GrantType,
            ["client_id"] = request.ClientId,
            ["client_secret"] = request.ClientSecret,
            ["scope"] = scope
        };

        if (request.GrantType == "password" && !string.IsNullOrEmpty(request.Username))
        {
            parameters["username"] = request.Username;
            parameters["password"] = request.Password!;
        }

        var content = new FormUrlEncodedContent(parameters);
        var response = await _httpClient.PostAsync(tokenUrl, content);

        if (!response.IsSuccessStatusCode)
            return null;

        var json = await response.Content.ReadAsStringAsync();
        var keycloakResponse = JsonSerializer.Deserialize<KeycloakTokenResponse>(json);

        return keycloakResponse == null ? null : new TokenResponse(
            keycloakResponse.AccessToken,
            keycloakResponse.TokenType,
            keycloakResponse.ExpiresIn,
            keycloakResponse.RefreshToken,
            keycloakResponse.Scope
        );
    }

    public async Task<TokenResponse?> RefreshTokenAsync(RefreshTokenRequest request)
    {
        var tokenUrl = _configuration["Keycloak:TokenUrl"]!;

        var parameters = new Dictionary<string, string>
        {
            ["grant_type"] = "refresh_token",
            ["client_id"] = request.ClientId,
            ["client_secret"] = request.ClientSecret,
            ["refresh_token"] = request.RefreshToken
        };

        var content = new FormUrlEncodedContent(parameters);
        var response = await _httpClient.PostAsync(tokenUrl, content);

        if (!response.IsSuccessStatusCode)
            return null;

        var json = await response.Content.ReadAsStringAsync();
        var keycloakResponse = JsonSerializer.Deserialize<KeycloakTokenResponse>(json);

        return keycloakResponse == null ? null : new TokenResponse(
            keycloakResponse.AccessToken,
            keycloakResponse.TokenType,
            keycloakResponse.ExpiresIn,
            keycloakResponse.RefreshToken,
            keycloakResponse.Scope
        );
    }

    public async Task<bool> RevokeTokenAsync(RevokeTokenRequest request)
    {
        var revokeUrl = _configuration["Keycloak:RevokeUrl"]!;

        var parameters = new Dictionary<string, string>
        {
            ["client_id"] = request.ClientId,
            ["client_secret"] = request.ClientSecret,
            ["token"] = request.Token
        };

        var content = new FormUrlEncodedContent(parameters);
        var response = await _httpClient.PostAsync(revokeUrl, content);

        return response.IsSuccessStatusCode;
    }

    private class KeycloakTokenResponse
    {
        [JsonPropertyName("access_token")]
        public string AccessToken { get; set; } = string.Empty;

        [JsonPropertyName("token_type")]
        public string TokenType { get; set; } = string.Empty;

        [JsonPropertyName("expires_in")]
        public int ExpiresIn { get; set; }

        [JsonPropertyName("refresh_token")]
        public string? RefreshToken { get; set; }

        [JsonPropertyName("scope")]
        public string? Scope { get; set; }
    }
}
