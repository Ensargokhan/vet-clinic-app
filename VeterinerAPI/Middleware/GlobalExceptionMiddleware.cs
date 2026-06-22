using System.Net;
using System.Text.Json;
using VeterinerAPI.DTOs.Common;

namespace VeterinerAPI.Middleware;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    private readonly IHostEnvironment _env;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger, IHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        HttpStatusCode statusCode;
        string message;

        switch (exception)
        {
            case UnauthorizedAccessException:
                statusCode = HttpStatusCode.Forbidden;
                message = exception.Message;
                _logger.LogWarning(exception, "Yetkisiz erişim denemesi: {Path}", context.Request.Path);
                break;

            case KeyNotFoundException:
                statusCode = HttpStatusCode.NotFound;
                message = exception.Message;
                _logger.LogWarning("Kaynak bulunamadı: {Path}", context.Request.Path);
                break;

            case ArgumentException or InvalidOperationException:
                statusCode = HttpStatusCode.BadRequest;
                message = exception.Message;
                _logger.LogWarning(exception, "Geçersiz istek: {Path}", context.Request.Path);
                break;

            default:
                statusCode = HttpStatusCode.InternalServerError;
                // Development ortamında gerçek hatayı göster, production'da gizle
                message = _env.IsDevelopment()
                    ? exception.Message
                    : "Sunucu kaynaklı bir hata oluştu. Lütfen daha sonra tekrar deneyiniz.";
                
                // Log'a kullanıcı bilgisi ekle (varsa)
                var userId = context.Items.TryGetValue("UserId", out var uid) ? uid?.ToString() : "anonymous";
                _logger.LogError(exception, "İşlenemeyen hata: {Path} | UserId: {UserId} | {Message}", 
                    context.Request.Path, userId, exception.Message);
                break;
        }

        context.Response.StatusCode = (int)statusCode;
        context.Response.ContentType = "application/json";

        var response = new ApiResponse<object>
        {
            Success = false,
            Message = message
        };

        var jsonOptions = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        var json = JsonSerializer.Serialize(response, jsonOptions);

        await context.Response.WriteAsync(json);
    }
}
