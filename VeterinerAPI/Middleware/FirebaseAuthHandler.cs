using System.Security.Claims;
using System.Text.Encodings.Web;
using FirebaseAdmin.Auth;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace VeterinerAPI.Middleware;

public class FirebaseAuthHandler : AuthenticationHandler<AuthenticationSchemeOptions>
{
    public FirebaseAuthHandler(
        IOptionsMonitor<AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder)
        : base(options, logger, encoder)
    {
    }

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.ContainsKey("Authorization"))
        {
            return AuthenticateResult.NoResult();
        }

        string authorizationHeader = Request.Headers["Authorization"]!;
        if (string.IsNullOrEmpty(authorizationHeader) || !authorizationHeader.StartsWith("Bearer "))
        {
            return AuthenticateResult.NoResult();
        }

        string token = authorizationHeader.Substring("Bearer ".Length).Trim();

        try
        {
            FirebaseToken decodedToken = await FirebaseAuth.DefaultInstance.VerifyIdTokenAsync(token);

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, decodedToken.Uid),
                new Claim("FirebaseUid", decodedToken.Uid)
            };

            // Email varsa ekle
            if (decodedToken.Claims.TryGetValue("email", out object? emailObj) && emailObj is string email)
            {
                claims.Add(new Claim(ClaimTypes.Email, email));
            }

            var identity = new ClaimsIdentity(claims, Scheme.Name);
            var principal = new ClaimsPrincipal(identity);
            var ticket = new AuthenticationTicket(principal, Scheme.Name);

            return AuthenticateResult.Success(ticket);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Firebase token validation failed.");
            return AuthenticateResult.Fail("Invalid Firebase ID token.");
        }
    }
}
