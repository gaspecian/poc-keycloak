using Microsoft.AspNetCore.Mvc;
using TodoBackend.Services;
using System.Text.Json.Serialization;

namespace TodoBackend.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IKeycloakService _keycloakService;

    public AuthController(IKeycloakService keycloakService)
    {
        _keycloakService = keycloakService;
    }

    [HttpPost("token")]
    public async Task<IActionResult> Token([FromBody] TokenRequestDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        if (request.GrantType == "password" && (string.IsNullOrEmpty(request.Username) || string.IsNullOrEmpty(request.Password)))
            return BadRequest(new { error = "username and password are required for password grant type" });

        var tokenRequest = new TokenRequest(
            request.GrantType,
            request.ClientId,
            request.ClientSecret,
            request.Username,
            request.Password
        );

        var response = await _keycloakService.GetTokenAsync(tokenRequest);

        if (response == null)
            return Unauthorized(new { error = "invalid_grant", error_description = "Invalid credentials or client configuration" });

        return Ok(new
        {
            access_token = response.AccessToken,
            token_type = response.TokenType,
            expires_in = response.ExpiresIn,
            refresh_token = response.RefreshToken
        });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequestDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var refreshRequest = new RefreshTokenRequest(
            request.ClientId,
            request.ClientSecret,
            request.RefreshToken
        );

        var response = await _keycloakService.RefreshTokenAsync(refreshRequest);

        if (response == null)
            return Unauthorized(new { error = "invalid_grant", error_description = "Invalid refresh token" });

        return Ok(new
        {
            access_token = response.AccessToken,
            token_type = response.TokenType,
            expires_in = response.ExpiresIn,
            refresh_token = response.RefreshToken
        });
    }

    [HttpPost("revoke")]
    public async Task<IActionResult> Revoke([FromBody] RevokeTokenRequestDto request)
    {
        if (!ModelState.IsValid)
            return BadRequest(ModelState);

        var revokeRequest = new RevokeTokenRequest(
            request.ClientId,
            request.ClientSecret,
            request.Token
        );

        var success = await _keycloakService.RevokeTokenAsync(revokeRequest);

        if (!success)
            return BadRequest(new { error = "revocation_failed" });

        return Ok(new { message = "Token revoked successfully" });
    }
}

public record TokenRequestDto(
    [property: JsonPropertyName("grant_type")] string GrantType,
    [property: JsonPropertyName("client_id")] string ClientId,
    [property: JsonPropertyName("client_secret")] string ClientSecret,
    [property: JsonPropertyName("username")] string? Username = null,
    [property: JsonPropertyName("password")] string? Password = null
);

public record RefreshTokenRequestDto(
    [property: JsonPropertyName("client_id")] string ClientId,
    [property: JsonPropertyName("client_secret")] string ClientSecret,
    [property: JsonPropertyName("refresh_token")] string RefreshToken
);

public record RevokeTokenRequestDto(
    [property: JsonPropertyName("client_id")] string ClientId,
    [property: JsonPropertyName("client_secret")] string ClientSecret,
    [property: JsonPropertyName("token")] string Token
);
