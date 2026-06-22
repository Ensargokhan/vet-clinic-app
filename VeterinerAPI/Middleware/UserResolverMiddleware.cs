using System.Security.Claims;
using VeterinerAPI.Repositories.Interfaces;

namespace VeterinerAPI.Middleware;

public class UserResolverMiddleware
{
    private readonly RequestDelegate _next;

    public UserResolverMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, IUserRepository userRepository)
    {
        if (context.User.Identity?.IsAuthenticated == true)
        {
            var firebaseUid = context.User.FindFirstValue("FirebaseUid");
            if (!string.IsNullOrEmpty(firebaseUid))
            {
                var user = await userRepository.GetByFirebaseUidAsync(firebaseUid);
                if (user != null)
                {
                    context.Items["UserId"] = user.Id;
                    context.Items["UserRole"] = user.Role;
                }
            }
        }

        await _next(context);
    }
}
